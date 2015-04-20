module Domain.Scenarios.Services.StatementsInfo where

import Data.Maybe
import Data.Char

import Ideas.Common.Library

import Domain.Scenarios.Parser
import Domain.Scenarios.Globals(ID, Name, Script)
import Domain.Scenarios.Id
          
type StatementText = (Either String [(String, String)])

data StatementInfo = StatementInfo ID
                                   String         -- type
                                   StatementText
                                   [String]       -- intentions
                                   (Maybe String) -- feedback
                                   MediaInfo

data MediaInfo = MediaInfo [(String, ID)] [ID] -- MediaInfo [(VisualType, VisualID)] AudioIDs where VisualType is either an "image" or a "video"
     
-- StatementsInfo service: for a scenario get all statements and return the info      
statementsinfo :: [Script] -> Exercise a -> [StatementInfo]
statementsinfo scripts ex = map statementInfo (getScriptStatements scenario)
  where scenario = parseScenario (findScript "get info for" scripts ex)
        statementInfo statement = StatementInfo
            (show (createFullId scenario statement))
            (toIdTypeSegment (statType statement))
            (either Left (Right . map showConversationText) (statText statement))
            (statIntents statement)
            (statFeedback statement)
            ((\(Media vs as) -> MediaInfo vs as) (statMedia statement))              
        showConversationText (ct, s) = (map toLower (show ct), s)

        getScriptStatements :: Scenario -> [Statement]
        getScriptStatements (Scenario _ dialogue) =  concatMap treeStatements allTrees
          where 
            allTrees = concatMap (\(_, trees) -> trees) dialogue


