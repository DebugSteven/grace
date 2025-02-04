{-# LANGUAGE BlockArguments    #-}
{-# LANGUAGE NamedFieldPuns    #-}
{-# LANGUAGE OverloadedStrings #-}

module Main where

import Data.Text (Text)
import Grace.Interpret (Input(..))
import Grace.Location (Location(..))
import Grace.Pretty (Pretty(..))
import Grace.Type (Type(..))
import System.FilePath ((</>))
import Test.Tasty (TestTree)

import qualified Control.Monad.Except as Except
import qualified Data.Text            as Text
import qualified Grace.Interpret      as Interpret
import qualified Grace.Monotype       as Monotype
import qualified Grace.Normalize      as Normalize
import qualified Grace.Pretty
import qualified Grace.Syntax         as Syntax
import qualified Grace.Type           as Type
import qualified Grace.Value          as Value
import qualified Prettyprinter        as Pretty
import qualified System.Directory     as Directory
import qualified System.FilePath      as FilePath
import qualified Test.Tasty           as Tasty
import qualified Test.Tasty.HUnit     as Tasty.HUnit
import qualified Test.Tasty.Silver    as Silver

pretty_ :: Pretty a => a -> Text
pretty_ x =
    Grace.Pretty.renderStrict False Grace.Pretty.defaultColumns
        (pretty x <> Pretty.hardline)

fileToTestTree :: FilePath -> IO TestTree
fileToTestTree prefix = do
    let input              = prefix <> "-input.grace"
    let expectedTypeFile   = prefix <> "-type.grace"
    let expectedOutputFile = prefix <> "-output.grace"
    let expectedStderrFile = prefix <> "-stderr.txt"

    let name = FilePath.takeBaseName input

    eitherResult <- Except.runExceptT (Interpret.interpret Nothing (Path input))

    case eitherResult of
        Left message -> do
            return
                (Tasty.testGroup name
                    [ Silver.goldenVsAction
                        (name <> " - error")
                        expectedStderrFile
                        (return message)
                        id
                    ]
                )
        Right (inferred, value) -> do
            let generateTypeFile = return (pretty_ inferred)

            let generateOutputFile = return (pretty_ (Normalize.quote [] value))

            return
                (Tasty.testGroup name
                    [ Silver.goldenVsAction
                        (name <> " - type")
                        expectedTypeFile
                        generateTypeFile
                        id
                    , Silver.goldenVsAction
                        (name <> " - output")
                        expectedOutputFile
                        generateOutputFile
                        id
                    ]
                )

inputFileToPrefix :: FilePath -> Maybe FilePath
inputFileToPrefix inputFile =
    fmap Text.unpack (Text.stripSuffix "-input.grace" (Text.pack inputFile))

directoryToTestTree :: FilePath -> IO TestTree
directoryToTestTree directory = do
    let name = FilePath.takeBaseName directory

    children <- Directory.listDirectory directory

    let process child = do
            let childPath = directory </> child

            isDirectory <- Directory.doesDirectoryExist childPath

            if isDirectory
                then do
                    testTree <- directoryToTestTree childPath

                    return [ testTree ]

                else do
                    case inputFileToPrefix childPath of
                        Just prefix -> do
                            testTree <- fileToTestTree prefix

                            return [ testTree ]

                        Nothing -> do
                            return [ ]

    testTreess <- traverse process children

    return (Tasty.testGroup name (concat testTreess))

main :: IO ()
main = do
    autogeneratedTestTree <- directoryToTestTree "tasty/data"

    let manualTestTree =
            Tasty.testGroup "Manual tests"
                [ interpretCode
                , interpretCodeWithImport
                ]

    let tests = Tasty.testGroup "Tests" [ autogeneratedTestTree, manualTestTree ]

    Tasty.defaultMain tests

interpretCodeWithImport :: TestTree
interpretCodeWithImport = Tasty.HUnit.testCase "interpret code with import" do
    actualValue <- Except.runExceptT (Interpret.interpret Nothing (Interpret.Code "./tasty/data/unit/plus-input.grace"))

    let expectedValue =
            Right (Type{ location, node }, Value.Scalar (Syntax.Natural 5))
          where
            location = Location{ name = "tasty/data/unit/plus-input.grace", code = "2 + 3\n", offset = 2 }

            node = Type.Scalar Monotype.Natural

    Tasty.HUnit.assertEqual "" expectedValue actualValue

interpretCode :: TestTree
interpretCode = Tasty.HUnit.testCase "interpret code with import" do
    actualValue <- Except.runExceptT (Interpret.interpret Nothing (Interpret.Code "2 + 2"))

    let expectedValue =
            Right (Type{ location, node }, Value.Scalar (Syntax.Natural 4))
          where
            location = Location{ name = "(input)", code = "2 + 2", offset = 2 }

            node = Type.Scalar Monotype.Natural

    Tasty.HUnit.assertEqual "" expectedValue actualValue

    return ()
