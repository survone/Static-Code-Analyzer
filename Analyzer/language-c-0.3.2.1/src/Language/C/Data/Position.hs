{-# LANGUAGE DeriveDataTypeable, PatternGuards #-}
-----------------------------------------------------------------------------
-- |
-- Module      :  Language.C.Data.Position
-- Copyright   :  (c) [1995..2000] Manuel M. T. Chakravarty
-- License     :  BSD-style
-- Maintainer  :  benedikt.huber@gmail.com
-- Stability   :  experimental
-- Portability :  ghc
--
-- Source code position
-----------------------------------------------------------------------------
module Language.C.Data.Position (
  --
  -- source text positions
  --
  Position(Position),initPos,
  posFile,posRow,posColumn,isSourcePos,
  nopos, isNoPos,
  builtinPos, isBuiltinPos,
  internalPos, isInternalPos,
  incPos, tabPos, retPos, adjustPos,
  Pos(..),
) where
import Data.Generics

-- | uniform representation of source file positions; the order of the arguments
-- is important as it leads to the desired ordering of source positions
data Position = Position String         -- file name
        {-# UNPACK #-}   !Int           -- row
        {-# UNPACK #-}   !Int           -- column
  deriving (Eq, Ord, Typeable, Data)

instance Show Position where
  show pos@(Position fname row col)
    | isNoPos pos = "<no file>"
    | isBuiltinPos pos = "<builtin>"
    | isInternalPos pos = "<internal>"
    | otherwise = show (fname, row, col)
instance Read Position where
    readsPrec p s = case s of
                       '<' : _  -> readInternal s
                       _        -> map (\((file,row,pos),r) -> (Position file row pos,r)) . readsPrec p $ s
readInternal :: ReadS Position
readInternal s | (Just rest) <- readString "<no file>" s = [(nopos,rest)]
               | (Just rest) <- readString "<builtin>" s = [(builtinPos,rest)]
               | (Just rest) <- readString "<internal>" s = [(internalPos,rest)]
               | otherwise                             = []
    where readString [] r = return r
          readString (c:cs) (c':cs') | c == c'    = readString cs cs'
                                     | otherwise = Nothing
          readString (_:_) [] = Nothing

-- | get the source file of the specified position. Fails unless @isSourcePos pos@.
posFile :: Position -> String
posFile (Position fname _ _) = fname

-- | get the line number of the specified position. Fails unless @isSourcePos pos@
posRow  :: Position -> Int
posRow (Position _ row _) = row

-- | get the column of the specified position. Fails unless @isSourcePos pos@
posColumn :: Position -> Int
posColumn (Position _ _ col) = col

-- | class of type which aggregate a source code location
class Pos a where
    posOf :: a -> Position

-- | initialize a Position to the start of the translation unit starting in the given file
initPos :: FilePath -> Position
initPos file = Position file 1 1

-- | returns @True@ if the given position refers to an actual source file
isSourcePos :: Position -> Bool
isSourcePos (Position _ row col) = row >= 0 && col >= 0

-- | no position (for unknown position information)
nopos :: Position
nopos  = Position "<no file>" (-1) 0

isNoPos :: Position -> Bool
isNoPos (Position _ (-1) 0) = True
isNoPos _                   = False

-- | position attached to built-in objects
--
builtinPos :: Position
builtinPos  = Position "<built into the parser>" (-1) 1

-- | returns @True@ if the given position refers to a builtin definition
isBuiltinPos :: Position -> Bool
isBuiltinPos (Position _ (-1) 1) = True
isBuiltinPos _                   = False

-- | position used for internal errors
internalPos :: Position
internalPos = Position "<internal error>" (-1) 2

-- | returns @True@ if the given position is internal
isInternalPos :: Position -> Bool
isInternalPos (Position _ (-1) 2) = True
isInternalPos _                      = False

{-# INLINE incPos #-}
-- | advance column
incPos :: Position -> Int -> Position
incPos (Position fname row col) n = Position fname row (col + n)

{-# DEPRECATED tabPos "Use 'incPos column-adjustment' instead" #-}
-- | advance column to next tab positions (tabs are considered to be at every 8th column)
tabPos :: Position -> Position
tabPos (Position fname row col) =
        Position fname row (col + 8 - (col - 1) `mod` 8)

{-# INLINE retPos #-}
-- | advance to next line
retPos :: Position -> Position
retPos (Position fname row _col) = Position fname (row + 1) 1

{-# INLINE adjustPos #-}
-- | adjust position: change file and line number, reseting column to 1. This is usually 
--   used for #LINE pragmas.
adjustPos :: FilePath -> Int -> Position -> Position
adjustPos fname row (Position _ _ _) = Position fname row 1
