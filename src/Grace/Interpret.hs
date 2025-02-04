{-# LANGUAGE DataKinds        #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE NamedFieldPuns   #-}
{-# LANGUAGE RecordWildCards  #-}
{-# LANGUAGE TypeApplications #-}

-- | This module implements support for file-based imports
module Grace.Interpret
    ( -- * Interpret
      Input(..)
    , interpret
    ) where

import Control.Monad.Except (MonadError(..))
import Control.Monad.IO.Class (MonadIO(..))
import Data.Bifunctor (Bifunctor(..))
import Data.Generics.Product (the)
import Data.Text (Text)
import Grace.Location (Location(..))
import Grace.Syntax (Node(..), Syntax(..))
import Grace.Type (Type)
import Grace.Value (Value)
import System.FilePath ((</>))

import qualified Control.Lens         as Lens
import qualified Control.Monad.Except as Except
import qualified Data.Text.IO         as Text.IO
import qualified Grace.Infer          as Infer
import qualified Grace.Normalize      as Normalize
import qualified Grace.Parser         as Parser
import qualified Grace.Syntax         as Syntax
import qualified System.FilePath      as FilePath

{-| Input to the `interpret` function

    You should prefer to use `Path` if possible (for better error messages and
    correctly handling transitive imports).  The `Code` constructor is intended
    for cases like interpreting code read from standard input.
-}
data Input
    = Path FilePath
    -- ^ The path to the code
    | Code Text
    -- ^ Source code

{-| Interpret Grace source code, return the inferred type and the evaluated
    result

    This is the top-level function for the Grace interpreter
-}
interpret
    :: (MonadError Text m, MonadIO m)
    => Maybe (Type Location)
    -- ^ Optional expected type for the input
    -> Input
    -> m (Type Location, Value)
interpret maybeAnnotation input = do
    code <- case input of
        Path file -> liftIO (Text.IO.readFile file)
        Code text -> return text

    let name = case input of
            Path file -> file
            Code _    -> "(input)"

    expression <- case Parser.parse name code of
        Left message -> do
            Except.throwError message

        Right expression -> do
            let locate offset = Location{..}

            return (first locate expression)

    let resolve (maybeAnnotation', file) =
            interpret maybeAnnotation' (Path path)
          where
            path = case input of
                Path parent -> FilePath.takeDirectory parent </> file
                Code _      -> file

    resolvedExpression <- traverse resolve (annotate expression)

    let annotatedExpression =
            case maybeAnnotation of
                Nothing         -> resolvedExpression
                Just annotation ->
                    Syntax
                        { node = Annotation resolvedExpression annotation
                        , location = Syntax.location resolvedExpression
                        }

    case Infer.typeOf annotatedExpression of
        Left message -> do
            Except.throwError message

        Right inferred -> do
            return (inferred, Normalize.evaluate [] resolvedExpression)

{-| We use this utility so that when we resolve an import of the form:

    > ./someImport.grace : SomeType

    … then the type-annotation is used when type-checking the import.  This
    allows the user to supply an expected type to fix imports that would
    otherwise not type-check in isolation.  You can think of this function as
    \"pushing\" the type annotation into the imported expression.

    This is particularly useful when importing JSON.  For example, suppose
    that we had the following JSON expression:

    > [ 1, true ]

    We can't interpret that directly because it is a type error, and we also
    can't import that without a type annotation for the same reason.  However,
    we can import the JSON like this:

    > ./example.json : List (exists (a : Type) . a)

    … and the expression will succeed since the type annotation is used when
    type-checking @./example.json@.  We wouldn't be able to add that same type
    annotation directly to @./example.json@ because then it would no longer be
    valid JSON.
-}
annotate :: Syntax s a -> Syntax s (Maybe (Type s), a)
annotate = Lens.transform transformSyntax . fmap ((,) Nothing)
  where
    transformSyntax = Lens.over (the @"node") transformNode

    transformNode (Annotation Syntax{ node = Embed (_, a) } annotation) =
        Embed (Just annotation, a)
    transformNode node =
        node
