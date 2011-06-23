{-#OPTIONS -XGADTs -XOverloadedStrings -XNoMonomorphismRestriction#-}
------------------------------------------------------------------------------ 
-- | 
-- Author       : Ulisses Araujo Costa
-- Stability    : experimental
-- Portability  : portable
--
-- This module is part of 'Static-Code-Analyzer', a library to automatic
-- calculate some metrics related with C99 and GNU C extensions code.
--
-- In this module I implement the latex exporter
--
------------------------------------------------------------------------------
module Latex where

import Text.LaTeX
import Data.List
import System.Path.NameManip
import Data.Maybe
import qualified Data.Map as M

import Metrics
import AbsolutePath

{- Convert Metrics to LaTeX -}
generatePDF exM = do
    t <- render $ example exM "test"
    writeFile "test.tex" t
{-    (inp,out,err,proc) <- runInteractiveProcess "pdflatex" [] Nothing Nothing
    hPutStr inp t
    hGetContents out >>= print
    exitCode <- waitForProcess proc
    case exitCode of
        ExitSuccess -> do
            (_,_,_,proc) <- runInteractiveProcess "open" ["article.pdf"] Nothing Nothing
            exitCode <- waitForProcess proc
            case exitCode of
                ExitSuccess -> return()
                exitError -> do
                    terminateProcess proc
                    exitWith exitError
        exitError -> do
            terminateProcess proc
            exitWith exitError
-}

example m packageName = do
    "\n%This file was generated by Static-Code-Analyzer\n"
    documentclass [a4paper,oneside] article
    "\\usepackage{verbatim}"
    "\\usepackage[pdftex]{hyperref}"
    "\\usepackage{footnote}"
    "\\makesavenoteenv{tabular}"
    title (("Metrics Report" >> footnote disclamer >> "  \\ on package ") >> (textsf $ fromString packageName))
    document $ do
           maketitle
           tableofcontents
           fromFunSigToLaTeX m
           fromNumToLaTeX m
           fromCloneToLaTeX m
    where disclamer = "This was automatically generated by \\href{github.com/ulisses/Static-Code-Analyzer}{Static-Code-Analyzer}."

{- Convert a (FunSig _) metricvalue to LaTeX -}
fromFunSigToLaTeX :: Monad m => Metrics -> LaTeX m
fromFunSigToLaTeX = fromFunSigLaTeX' . getAllFunSig

fromFunSigLaTeX' :: Monad m => Metrics -> LaTeX m
fromFunSigLaTeX' m | nullM  m = noop
                   | otherwise = do section "Functions Signatures"
                                    "Found " >> (texString $ sizeM m) >> singularOrPlural
                                    foldrM step noop m
    where singularOrPlural | sizeM m == 1 = " function"
                           | otherwise = " functions"
          step k v r = let fp = getFileName k
                           (p,fn) = split_path $ mkAbsolutePathUnsafe fp
                       in subsection (myfromString fn)
                               >> myfromString ("This file can be found at: " ++ p) // newline
                               >> myfromString ("This file have "++(texString $ length $ fromFunSig v)++" functions:") // newline
                               >> (foldr stepL noop $ fromFunSig v)
                             >> r
          getFileName (_,Just f,_) = f
          fromFunSig (FunSig l) = l
          stepL h r = myfromString h // r

{- Convert a (Clone _ _) metricvalue to LaTeX -}
fromCloneToLaTeX :: Monad m => Metrics -> LaTeX m
fromCloneToLaTeX = fromCloneToLaTeX' . getAllClone

fromCloneToLaTeX' :: Monad m => Metrics -> LaTeX m
fromCloneToLaTeX' m | nullM  m = noop
                    | otherwise = do section "Clones"
                                     "Found " >> (texString $ sizeM m) >> singularOrPlural
                                     foldrM step noop m
    where singularOrPlural | sizeM m == 1 = " possible cloned file"
                           | otherwise = " possible cloned files"
          step k v r = let fileName = myfromString $ getClonedFile k
                       in  subsection fileName
                               >> myfromString ("This file was possible cloned from "++(texString $ length $ getClonedLst v)++" files:") >> newline
                               >> (foldr stepL noop $ getClonedLst v)
                           >> r
          getClonedFile (_,f,_) = maybe "" texString f
          getClonedLst (Clone m) = M.toList m
          stepL (s,l) r = (textbf $ myfromString s) >> (foldr stepOcorrencies noop l) // r
          stepOcorrencies (o,lsrc,ldst) r = newline
                                                >> fromString ("Found at line " ++ (texString lsrc)
                                                               ++ " in source file and at line "
                                                               ++ (texString ldst)
                                                    ++ " in destination file")
                                                >> (verbatim $ fromString o)
                                            >> r

{- Convert a (Num _) metricvalue to LaTeX -}
fromNumToLaTeX :: Monad m => Metrics -> LaTeX m
fromNumToLaTeX = fromNumToLaTeX' . getAllNum

fromNumToLaTeX' :: Monad m => Metrics -> LaTeX m
fromNumToLaTeX' m | nullM m   = noop
                  | otherwise = do section "Numeric metrics"
                                   (texString $ sizeM m) >> " metrics analyzed." // newline
                                   foldr (>>) newpage $ intersperse newpage $ map toTabular $ toTabularParts m
    where
    {- This function will break a bag of metrics into a list of bags, each bag has maxPowsPerPage bags.
       This is usefull because LaTeX won't break tables if they don't fit in one page.
    -}
    toTabularParts :: Metrics -> [Metrics]
    toTabularParts m | sizeM m > maxRowsPerPage = let (k,v)   = elemAtM maxRowsPerPage m
                                                      (m1,m2) = splitM k m
                                                  in m1 : toTabularParts m2
                     | otherwise = [m]
        where maxRowsPerPage = 25
    {- This version of toTabular will print a tabular environment, without taking care
       if the elements are too much and the tabular won't fit in just one page.
       So, this we only send to this function parts of our main tabular
    -}
    toTabular :: Monad m => Metrics -> LaTeX m
    toTabular m = tabular ["c"] "|c|c|c|c|" (myhline >> textbf "Metric Name" & textbf "File Name" & textbf "Function Name"
                                                      & textbf "Metric Value" // myhline >> foldrM step noop m)
        where step (k1,k2,k3) v r = myfromString k1 & file & maybe "" myfromString k3 & (fromNum v) // myhline >> r
               where fromNum (Num a) = texString a
                     file = let (path,f) = split_path $ maybe "" id k2
                            in (myfromString f) >> (footnote $ myfromString ("This file can be found at: " ++ path))

myfromString = fromString . fixString
texString = myfromString . show
newline = noop // noop
myhline = "\\hline "
noop = ""

fixString "" = ""
fixString ('_':t) = "\\_" ++ fixString t
fixString (h:t) = h : fixString t

r m = render $ example m "clone"
