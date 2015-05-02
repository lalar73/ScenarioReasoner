-----------------------------------------------------------------------------
-- Copyright 2015, Open Universiteit Nederland. This file is distributed
-- under the terms of the GNU General Public License. For more information,
-- see the file "LICENSE.txt", which is included in the distribution.
-----------------------------------------------------------------------------
-- |
-- Maintainer  :  bastiaan.heeren@ou.nl
-- Stability   :  provisional
-- Portability :  portable (depends on ghc)
--
-- Converting a strategy to XML, and the other way around.
--
-----------------------------------------------------------------------------
--  $Id: StrategyInfo.hs 7638 2015-04-30 13:23:05Z bastiaan $

module Ideas.Encoding.StrategyInfo (strategyToXML) where

import Ideas.Common.Id
import Ideas.Common.CyclicTree
import Ideas.Common.Strategy.Abstract
import Ideas.Common.Strategy.Prefix
import Ideas.Common.Strategy.Def
import Ideas.Text.XML

-----------------------------------------------------------------------
-- Strategy to XML

strategyToXML :: IsStrategy f => f a -> XML
strategyToXML = coreToXML . toCore . toStrategy

nameAttr :: Id -> XMLBuilder
nameAttr info = "name" .=. showId info

coreToXML :: Core a -> XML
coreToXML core = makeXML "label" $
   case isLabel core of
      Just (l, a) -> nameAttr l <> coreBuilder a
      _ -> coreBuilder core

coreBuilder :: Core a -> XMLBuilder
coreBuilder = fold emptyAlg
   { fNode = \def xs -> 
        case xs of
           [x] | isProperty def 
             -> addProperty (show def) x
           _ -> tag (show def) (mconcat xs)
   , fLeaf = \r -> 
        tag "rule" ("name" .=. show r)
   , fLabel = \l a ->
        tag "label" (nameAttr l <> a)
   , fRec = \n a ->
        tag "rec" (("var" .=. show n) <> a)
   , fVar = \n -> 
        tag "var" ("var" .=. show n)
   } . flatten

flatten :: Core a -> Core a
flatten = replaceNode $ \def -> node def . concatMap (collect def)
 where
   collect def core = 
      case isNode core of
         Just (d, xs) | d == def -> xs
         _ -> [core]

addProperty :: String -> XMLBuilder -> XMLBuilder
addProperty s a =
   case fromBuilder a of
      Just e | name e `elem` ["label", "rule"] ->
         builder e { attributes = attributes e ++ [s := "true"] }
      _      -> tag s a

-----------------------------------------------------------------------
-- XML to strategy

{-
xmlToStrategy :: Monad m => (String -> Maybe (Rule a)) ->  XML -> m (Strategy a)
xmlToStrategy f = liftM fromCore . readStrategy xmlToInfo g
 where
   g info = case f (showId info) of
               Just r  -> return r
               Nothing -> fail $ "Unknown rule: " ++ showId info

xmlToInfo :: Monad m => XML -> m Id
xmlToInfo xml = do
   n <- findAttribute "name" xml
   -- let boolAttr s = fromMaybe False (findBool s xml)
   return (newId n)

findBool :: Monad m => String -> XML -> m Bool
findBool attr xml = do
   s <- findAttribute attr xml
   case map toLower s of
      "true"  -> return True
      "false" -> return False
      _       -> fail "not a boolean"

readStrategy :: Monad m => (XML -> m Id) -> (Id -> m (Rule a)) -> XML -> m (Core a)
readStrategy toLabel findRule xml = error "not implemented" do
   xs <- mapM (readStrategy toLabel findRule) (children xml)
   let s = name xml
   case lookup s table of
      Just f  -> f s xs
      Nothing ->
         fail $ "Unknown strategy combinator " ++ show s
 where
   buildSequence _ xs
      | null xs   = return Succeed
      | otherwise = return (foldr1 (:*:) xs)
   buildChoice _ xs
      | null xs   = return Fail
      | otherwise = return (foldr1 (:|:) xs) 
   buildOrElse _ xs
      | null xs   = return Fail
      | otherwise = return (foldr1 (:|>:) xs) 
   buildInterleave _ xs
      | null xs   = return succeedCore
      | otherwise = return (foldr1 (:%:) xs)
   buildLabel x = do
      info <- toLabel xml
      return (Label info x)
   buildRule = do
      info <- toLabel xml
      r    <- findRule info
      return (Label info (Sym r))
   buildVar = do
      s <- findAttribute "var" xml
      i <- maybe (fail "var: not an int") return (readInt s)
      return (Var i)

   comb0 a _ [] = return a
   comb0 _ s _  = fail $ "Strategy combinator " ++ s ++ "expects 0 args"

   comb1 f _ [x] = return (f x)
   comb1 _ s _   = fail $ "Strategy combinator " ++ s ++ "expects 1 arg"

   join2 f g a b = join (f g a b)

   table =
      [ ("sequence",   buildSequence)
      , ("choice",     buildChoice)
      , ("orelse",     buildOrElse)
      , ("interleave", buildInterleave)
      , ("label",      join2 comb1 buildLabel)
     -- , ("atomic",     comb1 Atomic)
      , ("rule",       join2 comb0 buildRule)
      , ("var",        join2 comb0 buildVar)
--      , ("succeed",    comb0 Succeed)
      --, ("fail",       comb0 Fail)
      ]

-}