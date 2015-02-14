module System.Console.Hawk.UserExpression.ProcessedExpression where


import qualified Data.ByteString.Lazy.Char8 as B

import Control.Applicative
import Data.HaskellExpr
import Data.HaskellExpr.Base
import System.Console.Hawk.Runtime
import System.Console.Hawk.Runtime.HaskellExpr
import System.Console.Hawk.UserExpression.OriginalExpression


-- | While the original user input may describe a value or a function on a
--   single record, the processed user expression is always a function on
--   the entire input. Also, its output is wrapped in `SomeRows`, to make
--   sure we don't accidentally rely on the fake `()` return type used by
--   `OriginalUserExpression`.
type ProcessedUserExpression = UserExpression (() -> SomeRows)
                                              (B.ByteString -> SomeRows)
                                              ([B.ByteString] -> SomeRows)
                                              ([[B.ByteString]] -> SomeRows)

-- | Asserts that the user expression is not a function, and applies `const`
--   to it in order to make it a function.
constExpression :: OriginalUserExpression -> ProcessedUserExpression
constExpression (UserExpression e _ _ _) = UserExpression (eAp eConst . eAp eSomeRows <$> e)
                                                          (eAp eConst . eAp eSomeRows <$> e)
                                                          (eAp eConst . eAp eSomeRows <$> e)
                                                          (eAp eConst . eAp eSomeRows <$> e)

-- | Asserts that the user expression is a function.
applyExpression :: OriginalUserExpression -> ProcessedUserExpression
applyExpression (UserExpression _ e1 e2 e3) = UserExpression Nothing
                                                             (eComp eSomeRows <$> e1)
                                                             (eComp eSomeRows <$> e2)
                                                             (eComp eSomeRows <$> e3)

-- | Asserts that the user expression is a function on one record, and applies
--   `map` to it in order to make it a function on all records.
mapExpression :: OriginalUserExpression -> ProcessedUserExpression
mapExpression (UserExpression _ e1 e2 _) = UserExpression Nothing
                                                          Nothing
                                                          (eComp eSomeRows . eAp eMap <$> e1)
                                                          (eComp eSomeRows . eAp eMap <$> e2)
