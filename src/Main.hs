module Main where

import Idris.Core.TT
import Idris.AbsSyntax
import Idris.Options
import Idris.ElabDecls
import Idris.REPL
import Idris.Main

import IRTS.Compiler
import IRTS.CodegenLisp

import System.Environment
import System.Exit

import Paths_idris_lisp

data Opts = Opts { inputs :: [FilePath],
                   output :: FilePath }

showUsage = do putStrLn "Usage: idris-lisp <ibc-files> [-o <output-file>]"
               exitWith ExitSuccess

getOpts :: IO Opts
getOpts = do xs <- getArgs
             return $ process (Opts [] "a.lisp") xs
  where
    process opts ("-o":o:xs) = process (opts { output = o }) xs
    process opts (x:xs) = process (opts { inputs = x:inputs opts }) xs
    process opts [] = opts

cg_main :: Opts -> Idris ()
cg_main opts = do elabPrims
                  loadInputs (inputs opts) Nothing
                  mainProg <- elabMain
                  ir <- compile (Via IBCFormat "lisp") (output opts) (Just mainProg)
                  runIO $ codegenLisp ir

main :: IO ()
main = do opts <- getOpts
          if (null (inputs opts)) 
             then showUsage
             else runMain (cg_main opts)
