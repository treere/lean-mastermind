import Mastermind

/-! Pure text ↔ code conversion: no I/O, so it is testable from Lean. -/

namespace Mastermind

/-- A character is a valid peg when it is a digit in `1 .. numColors`. -/
def parsePeg (c : Char) : Option Peg :=
  let n := c.toNat - '0'.toNat
  if c.isDigit && 0 < n && n ≤ numColors then some n else none

/-- Reads a guess: `numPegs` digits, spaces ignored. -/
def parseGuess (line : String) : Option Code :=
  let cs := line.toList.filter (fun c => c ≠ ' ' && c ≠ '\n' && c ≠ '\r')
  if cs.length ≠ numPegs then none
  else cs.mapM parsePeg

def showCode (c : Code) : String :=
  String.join (c.map fun p => toString p)

def showFeedback (fb : Feedback) : String :=
  String.ofList (List.replicate fb.exact '●' ++ List.replicate fb.misplaced '○')

end Mastermind
