{- ©Copyright Utrecht University (Department of Information and Computing Sciences) -}

module Domain.Scenarios.Services.ExtraServices where

import Data.Maybe

import Ideas.Common.Library
import Ideas.Service.State

import Domain.Scenarios.Condition
import Domain.Scenarios.Globals
import Domain.Scenarios.Scenario
import Domain.Scenarios.ScenarioState(ScenarioState)
import Domain.Scenarios.ScoringFunction(calculateScore, calculateSubScores)
import Domain.Scenarios.Services.Types

-- FeedbackForm Service -------------------------------------------------------------------------------------

feedbackform :: [(Id, Scenario)] -> State a -> [(ID, String)]
feedbackform fs fstate = map (getFeedbackFormResult state) (scenarioFeedbackForm scenario)
  where
    state = fromMaybe (error "Cannot give feedback on exercise: casting failed.") $
        castFrom (exercise fstate) (stateTerm fstate) :: ScenarioState
    scenario = findScenario "feedbackform" fs (exercise fstate)

-- If an entry contains conditioned feedback then it checks if it is fullfilled
-- and returns the corresponding feedback otherwise it returns the default feedback or an empty string
getFeedbackFormResult :: ScenarioState -> FeedbackFormEntry -> (ID, String)
getFeedbackFormResult state (FeedbackFormEntry paramID fbConds defaultFeedback) =
    case evalFBConds fbConds of
        Nothing       -> (paramID, fromMaybe "" defaultFeedback)
        Just feedback -> (paramID, feedback)
  where
    evalFBConds :: [(Condition, String)] -> Maybe String
    evalFBConds []                                                = Nothing
    evalFBConds ((cond, fb) : cfs) | evaluateCondition cond state = Just fb
                                   | otherwise                    = evalFBConds cfs


-- ScenarioList and Info Service -------------------------------------------------------------------------------------

-- Scenariolist service: lists all info for each scenario
scenariolist :: [(Id, Scenario)] -> [ScenarioInfo]
scenariolist = map (getScenarioInfo . snd)

-- Scenarioinfo service: shows the info for a specific scenario (exercise)
scenarioinfo :: [(Id, Scenario)] -> Exercise a -> ScenarioInfo
scenarioinfo fs ex = getScenarioInfo (findScenario "scenarioinfo" fs ex)

getScenarioInfo :: Scenario -> ScenarioInfo
getScenarioInfo scenario@(Scenario metadata _ _) = ScenarioInfo
                (scenarioName           metadata)
                (scenarioDescription    metadata)
                (scenarioDifficulty     metadata)
                (scenarioCharacter      metadata)
                (map describeParameter (scenarioParameters metadata))
                (scenarioToggles        metadata)
  where
    describeParameter param = ParameterInfo
        (parameterId          param)
        (parameterName        param)
        (parameterDescription param)


-- Score Service --------------------------------------------------------------------------------------------

score :: [(Id, Scenario)] -> State a -> ScoreResult
score fs fstate = ScoreResult mainScore subScores
    where metaData = scenarioMetaData (findScenario "score" fs (exercise fstate))
          state = fromMaybe (error "Cannot score exercise: casting failed.") $
            castFrom (exercise fstate) (stateTerm fstate) :: ScenarioState
          mainScore = calculateScore subScores (scenarioScoringFunction metaData) state
          subScores = calculateSubScores parameters state
          parameters = scenarioParameters metaData

-- | Finds the scenario of the exercise in the given scenario list
findScenario :: String -> [(Id, Scenario)] -> Exercise a -> Scenario
findScenario usage scenarios ex = fromMaybe
    (error $ "Cannot " ++ usage ++ " exercise: exercise is apparently not a scenario.")
    (lookup (getId ex) scenarios)
