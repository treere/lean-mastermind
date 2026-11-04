import Parse
import LSpec

open Mastermind LSpec

/-- Every code: numbers from 1 to `numColors`. -/
def codesAux : Nat → Nat → List Code
  | 0, _ => [[]]
  | n + 1, k => ((List.range k).map (· + 1)).flatMap fun c => (codesAux n k).map fun cs => c :: cs

def allCodes : List Code := codesAux numPegs numColors

/-- The invariant holds on every pair: here it is a test, not a theorem. -/
def boundHoldsEverywhere : Bool :=
  allCodes.all fun g => allCodes.all fun s =>
    let fb := score g s
    fb.exact + fb.misplaced ≤ numPegs

/-- Every generated peg is in 1..numColors: checks the domain generation. -/
def domainIsWellFormed : Bool :=
  allCodes.all fun c => c.length == numPegs && c.all validPeg

def scoreSuite : TestSeq :=
  group "scoring" $
    test "guessed code" (score [1,2,3,4] [1,2,3,4] = { exact := 4, misplaced := 0 }) $
    test "all misplaced" (score [4,1,2,3] [1,2,3,4] = { exact := 0, misplaced := 4 }) $
    test "duplicates consumed once" (score [1,1,1,1] [1,2,2,2] = { exact := 1, misplaced := 0 }) $
    test "3 exact and 0 misplaced, not 1" (score [2,2,2,2] [2,2,2,4] = { exact := 3, misplaced := 0 }) $
    test "no peg in common" (score [1,1,2,2] [5,5,6,6] = { exact := 0, misplaced := 0 })

def parseSuite : TestSeq :=
  group "parsing" $
    test "plain digits" (parseGuess "1234" = some [1,2,3,4]) $
    test "spaces are ignored" (parseGuess "1 2 3 4" = some [1,2,3,4]) $
    test "zero is rejected" (parseGuess "0123" = none) $
    test "out-of-range digit is rejected" (parseGuess "9999" = none) $
    test "wrong length is rejected" (parseGuess "123" = none) $
    test "letters are rejected" (parseGuess "abcd" = none) $
    test "render a code" (showCode [1,2,3,4] = "1234") $
    test "render feedback" (showFeedback { exact := 2, misplaced := 1 } = "●●○")

def domainSuite : TestSeq :=
  group "domain" $
    test "bound on every pair of codes" boundHoldsEverywhere $
    test "every code only uses pegs 1..numColors" domainIsWellFormed

def main (args : List String) : IO UInt32 :=
  lspecIO (.ofList [("scoring", [scoreSuite]), ("parsing", [parseSuite]), ("domain", [domainSuite])]) args
