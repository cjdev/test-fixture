{-# LANGUAGE CPP #-}
#if MIN_VERSION_GLASGOW_HASKELL(8,0,0,0)

{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE TemplateHaskell #-}
{-# OPTIONS_GHC -fno-warn-unused-top-binds #-}

module Test.Control.Monad.TestFixture.THSpec (spec) where

import Test.Hspec

import Control.Applicative ((<|>))
import Control.Monad (when)
import Control.Monad.Except (runExcept, throwError)
import Control.Monad.Fail (MonadFail(..))
import Language.Haskell.TH.Syntax

import Control.Monad.TestFixture
import Control.Monad.TestFixture.TH
import Control.Monad.TestFixture.TH.Internal (methodNameToFieldName)

class MultiParam a b where

mkFixture "Fixture" [ts| MonadFail, Quasi |]

spec :: Spec
spec = do
  describe "mkFixture" $
    it "raises an error for multi-parameter typeclasses" $ do
      let fixture = def
            { _qReport = \b s -> when b $ throwError s
            , _qNewName = \s -> return $ Name (OccName s) (NameU 0)
            , _qReify = \_ -> return $(lift =<< reify ''MultiParam)
            }
      let result = runExcept $ unTestFixtureT (runQ $ mkFixture "Fixture" [ts| MultiParam |]) fixture
      result `shouldBe` (Left $
           "mkFixture: cannot derive instance for multi-parameter typeclass\n"
        ++ "      in: Test.Control.Monad.TestFixture.THSpec.MultiParam\n"
        ++ "      expected: * -> GHC.Types.Constraint\n"
        ++ "      given: * -> * -> GHC.Types.Constraint")

  describe "methodNameToFieldName" $ do
    it "prepends an underscore to ordinary names" $ do
      nameBase (methodNameToFieldName 'id) `shouldBe` "_id"
      nameBase (methodNameToFieldName '_fail) `shouldBe` "__fail"

    it "prepends a tilde to infix operators" $ do
      nameBase (methodNameToFieldName '(>>=)) `shouldBe` "~>>="
      nameBase (methodNameToFieldName '(<|>)) `shouldBe` "~<|>"

#else
module Test.Control.Monad.TestFixture.THSpec (spec) where

import Test.Hspec

spec :: Spec
spec = return ()
#endif
