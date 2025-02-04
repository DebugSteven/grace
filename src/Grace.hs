{-# LANGUAGE ApplicativeDo     #-}
{-# LANGUAGE BlockArguments    #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}

{-| This module contains the top-level `main` function that implements the
    command-line API
-}
module Grace
    ( -- * Main
      main
    ) where

import Control.Applicative (many, (<|>))
import Data.Foldable (traverse_)
import Data.Text (Text)
import Data.Void (Void)
import Grace.Interpret (Input(..))
import Grace.Location (Location(..))
import Grace.Syntax (Builtin(..), Node(..), Syntax(..))
import Options.Applicative (Parser, ParserInfo)
import Prettyprinter (Doc)
import Prettyprinter.Render.Terminal (AnsiStyle)
import System.Console.Terminal.Size (Window(..))

import qualified Control.Monad.Except         as Except
import qualified Data.Text.IO                 as Text.IO
import qualified Prettyprinter                as Pretty
import qualified Grace.Infer                  as Infer
import qualified Grace.Interpret              as Interpret
import qualified Grace.Normalize              as Normalize
import qualified Grace.Parser                 as Parser
import qualified Grace.Pretty
import qualified Options.Applicative          as Options
import qualified System.Console.ANSI          as ANSI
import qualified System.Console.Terminal.Size as Size
import qualified System.Exit                  as Exit
import qualified System.IO                    as IO

data Highlight
    = Color
    -- ^ Force the use of ANSI color escape sequences to highlight source code
    | Plain
    -- ^ Don't highlight source code
    | Auto
    -- ^ Auto-detect whether to highlight source code based on whether or not
    --   @stdout@ is a terminal

data Options
    = Interpret { annotate :: Bool, highlight :: Highlight, file :: FilePath }
    | Format { highlight :: Highlight, files :: [FilePath] }
    | Builtins { highlight :: Highlight }

parserInfo :: ParserInfo Options
parserInfo =
    Options.info (Options.helper <*> parser)
        (Options.progDesc "Command-line utility for the Grace language")

parser :: Parser Options
parser = do
    let interpret = do
            annotate <- Options.switch 
                (   Options.long "annotate"
                <>  Options.help "Add a type annotation for the inferred type"
                )

            file <- Options.strArgument
                (   Options.help "File to interpret"
                <>  Options.metavar "FILE"
                )

            highlight <- parseHighlight

            return Interpret{..}

    let format = do
            let parseFile =
                    Options.strArgument
                        (   Options.help "File to format"
                        <>  Options.metavar "FILE"
                        )

            highlight <- parseHighlight

            files <- many parseFile

            return Format{..}

    let builtins = do
            highlight <- parseHighlight

            return Builtins{..}

    Options.hsubparser
        (   Options.command "format"
                (Options.info format
                    (Options.progDesc "Format Grace code")
                )

        <>  Options.command "interpret"
                (Options.info interpret
                    (Options.progDesc "Interpret a Grace file")
                )

        <>  Options.command "builtins"
                (Options.info builtins
                    (Options.progDesc "List all built-in functions and their types")
                )
        )
  where
    parseHighlight =
            Options.flag' Color
                (    Options.long "color"
                <>   Options.help "Enable syntax highlighting"
                )
        <|> Options.flag' Plain
                (    Options.long "plain"
                <>   Options.help "Disable syntax highlighting"
                )
        <|> pure Auto


detectColor :: Highlight -> IO Bool
detectColor Color = do return True
detectColor Plain = do return False
detectColor Auto  = do ANSI.hSupportsANSI IO.stdout

getWidth :: IO Int
getWidth = do
    maybeWindow <- Size.size

    let renderWidth =
            case maybeWindow of
                Nothing         -> Grace.Pretty.defaultColumns
                Just Window{..} -> width

    return renderWidth

getRender :: Highlight -> IO (Doc AnsiStyle -> IO ())
getRender highlight = do
    color <- detectColor highlight
    width <- getWidth

    return (Grace.Pretty.renderIO color width IO.stdout)

throws :: Either Text a -> IO a
throws (Left text) = do
    Text.IO.hPutStrLn IO.stderr text
    Exit.exitFailure
throws (Right result) = do
    return result

-- | Command-line entrypoint
main :: IO ()
main = do
    options <- Options.execParser parserInfo

    case options of
        Interpret{..} -> do
            input <- case file of
                "-" -> do
                    text <- Text.IO.getContents
                    return (Code text)
                _ -> do
                    return (Path file)

            eitherResult <- do
                Except.runExceptT (Interpret.interpret Nothing input)

            (inferred, value) <- throws eitherResult

            let syntax = Normalize.quote [] value

            let annotatedExpression
                    | annotate =
                        Syntax
                            { node =
                                Annotation syntax (fmap (\_ -> ()) inferred)
                            , location = ()
                            }
                    | otherwise =
                        syntax

            render <- getRender highlight

            render (Grace.Pretty.pretty annotatedExpression <> Pretty.hardline)

        Format{..} -> do
            case files of
                [ "-" ] -> do
                    text <- Text.IO.getContents

                    syntax <- throws (Parser.parse "(input)" text)

                    render <- getRender highlight

                    render (Grace.Pretty.pretty syntax <> Pretty.hardline)
                _ -> do
                    let formatFile file = do
                            text <- Text.IO.readFile file

                            syntax <- throws (Parser.parse file text)

                            IO.withFile file IO.WriteMode \handle -> do
                                Grace.Pretty.renderIO
                                    False
                                    Grace.Pretty.defaultColumns
                                    handle
                                    (Grace.Pretty.pretty syntax <> Pretty.hardline)

                    traverse_ formatFile files

        Builtins{..} -> do
            let displayBuiltin :: Builtin -> IO ()
                displayBuiltin builtin = do
                    let expression =
                            Syntax
                                { location =
                                    Location
                                        { name = "(input)"
                                        , code =
                                            Grace.Pretty.renderStrict
                                                False
                                                Grace.Pretty.defaultColumns
                                                (Grace.Pretty.pretty builtin)
                                        , offset = 0
                                        }
                                , node = Builtin builtin
                                }

                    type_ <- throws (Infer.typeOf expression)

                    let annotated :: Node Location Void
                        annotated = Annotation expression type_

                    render <- getRender highlight

                    render (Grace.Pretty.pretty annotated <> Pretty.hardline)

            let builtins = [ minBound .. maxBound ]

            case builtins of
                [] -> do
                    return ()

                b0 : bs -> do
                    displayBuiltin b0

                    traverse_ (\b -> Text.IO.putStrLn "" >> displayBuiltin b) bs
