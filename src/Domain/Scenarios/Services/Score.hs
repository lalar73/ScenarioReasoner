{-# LANGUAGE FlexibleInstances, UndecidableInstances, MultiParamTypeClasses #-}
module Domain.Scenarios.Services.Score where

import Data.Maybe

import Ideas.Common.Library
import Ideas.Service.State

import Domain.Scenarios.Parser
import Domain.Scenarios.ScoreFunction(calculateScore, calculateSubScores)
import Domain.Scenarios.TypeDefs(ID, Name, Score)

data ScoreResult = ScoreResult Score 
                               [SubScore] 
                               (Maybe [Score])

type SubScore = (ID, Name, Score)
        
-- Type-customized result structure
-- Score extremes are returned in a list, because EncoderJSON
-- merges a tuple into the main structure of the result
score :: [ScriptElem] -> State a -> ScoreResult
score scripts fstate = ScoreResult mainScore subScores mainScoreExtremes
    where script = findScript "score" scripts $ exercise fstate
          state = (fromMaybe (error "Cannot score exercise: casting failed.") $
                      castFrom (exercise fstate) (stateTerm fstate))
          mainScore = calculateScore (parseScriptScoringFunction script) state
          subScores = calculateSubScores (parseScriptParameters script) state
          mainScoreExtremes = (errorOnFail $ getScriptScoreExtremes script) >>= return . (\(min, max) -> [min, max])          