{-
macroclean.hs
Inputs: 
  file containing one-line macro definitions
  multiple tex files which use the macros in the above file

Finds all unused macro definitions and sends to stdout the macro
file, omitting the unused lines.

Sample Usage:
ghc -i macroclean.hs macros_file.sty file1.tex file2.tex > new_macros_file.sty
or
ghc macroclean
./macroclean macros_file.sty file1.tex file2.tex > new_macros_file.sty

Copyright (c) 2014 Philip Hackney

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
-}

import Data.List(stripPrefix, nub)
import Data.Maybe(listToMaybe, catMaybes, mapMaybe)
import Data.Char(isAlphaNum)
import System.Environment(getArgs)


type Command = String

-- This is supposed to take a single line
decomposeCommand :: String -> Maybe (Command, String)
decomposeCommand = (fmap splitShit) . stripCmdType
  where splitShit = break (== '}')

decomposeCommands :: [String] -> [(Command, String)]
decomposeCommands = catMaybes . (map decomposeCommand)

--decomposeCommands' :: [String] -> [(Command, [Command])]
--decomposeCommands' = (map $ liftSecond findCommands) . decomposeCommands

stripCmdList :: Eq a => [[a]] -> [a] -> Maybe [a]
stripCmdList prefixes = listToMaybe . stripCmdList' prefixes
stripCmdList' :: Eq a => [[a]] -> [a] -> [[a]]
stripCmdList' prefixes toStrip = 
	mapMaybe (flip stripPrefix toStrip) prefixes

stripCmdType :: String -> Maybe String
stripCmdType = stripCmdList  
  ["\\newcommand{", 
   "\\providecommand{", 
   "\\renewcommand{",
   "\\DeclareMathOperator{",
   "\\DeclareMathOperator*{"]

findCommands :: String -> [Command]
findCommands str 
  | null (killPrefix str) 	= []
  | otherwise	 			= ('\\' : noSlash) : (findCommands rest)
  where
  	killPrefix = dropWhile (/= '\\')
  	(noSlash, rest) = span isAlphaNum (tail (killPrefix str))

findCommands' :: String -> [Command]
findCommands' = nub . findCommands

liftSecond :: (a -> b) -> ( (c,a) -> (c,b) )
liftSecond f (x,y) = (x, f y)

buildTable :: String -> [(Command, [Command])]
buildTable = (map $ liftSecond findCommands). decomposeCommands . lines

nonRedundant :: [(Command, [Command])] -> Bool
nonRedundant table = (fst . unzip) table == (nub . fst . unzip) table

data Used = Yes | No deriving (Eq, Show)

appendNo :: (a,b) -> (a,b, Used)
appendNo (x, y) = (x, y, No)
appendNos :: [(a,b)] -> [(a,b,Used)]
appendNos = map appendNo

markUsed :: [(Command, [Command], Used)] -> Command -> [(Command, [Command], Used)]
markUsed table cmd 
  | null second     = first
  | otherwise       = first ++ [(x, xs, Yes)] ++ tail second
    where 
      (first, second) = break (\(x,_,_) -> x == cmd) table
      (x, xs, _) = head second

markUp :: [(Command, [Command], Used)] -> [Command] -> [(Command, [Command], Used)]
markUp = foldl markUsed

dependencies :: [(Command, [Command], Used)] -> [Command]
dependencies table = nub fullCmdList
  where
    shrunkTable = filter (\(_,_,z) -> z == Yes) table
    (_,zs,_) = unzip3 shrunkTable
    fullCmdList = concat zs

iter :: [(Command, [Command], Used)] -> [(Command, [Command], Used)]
iter table = markUp table (dependencies table)

stabilize :: Eq a => (a -> a) -> a -> a
stabilize f x = y
  where Just y = findEqual (iterate f x)

findEqual :: Eq a => [a] -> Maybe a
findEqual (x : y : xs)
  | x == y      = Just x
  | otherwise   = findEqual (y : xs)
findEqual _ = Nothing

unusedCommands :: [(Command,[Command])] -> [Command] -> [Command]
unusedCommands table cmds = [x | (x,_,No) <- mainTable]
  where
    mainTable = stabilize iter $ markUp (appendNos table) cmds

processLine :: [Command] -> String -> Maybe String
processLine killList str
  | decomposeCommand str == Nothing     = Just str -- leave trash lines alone
  | elem cmd killList                   = Nothing
  | otherwise                           = Just str
  where
    Just (cmd,_) = decomposeCommand str 




main = do
  args <- getArgs
  macrosFile <- readFile (head args)
  let splitFile = lines macrosFile
  let initTable = buildTable macrosFile
  let fileNames = tail args
  usedCmds <- fmap (nub . findCommands . concat) (mapM readFile fileNames)
  let orphans = unusedCommands initTable usedCmds
  let cleanedSplit = catMaybes $ map (processLine orphans) splitFile
  putStr $ unlines cleanedSplit
