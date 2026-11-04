import Mastermind

open Mastermind

/-- 1, 2, ... numColors: the numbers the player can type. -/
def pegsRange : List Peg := (List.range numColors).map (· + 1)

/-- A character is a valid peg when it is 1..numColors. -/
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

/-- Re-reads until the input is valid; `n` typing attempts per turn. -/
def readValid : Nat → IO (Option Code)
  | 0 => pure none
  | n + 1 => do
      let line ← (← IO.getStdin).getLine
      let t := line.trimAscii.toString
      if t == "q" || t.isEmpty then
        pure none
      else
        match parseGuess t with
        | some g => pure (some g)
        | none => do
            IO.println s!"Invalid input. Numbers 1 to {numColors}, {numPegs} digits, e.g. 1234. 'q' to quit."
            readValid n

/-- The game loop is a `def`, not `partial`: `fuel` decreases, so Lean accepts
    it as a total function. I/O does not force you to give up totality. -/
def loop (secret : Code) : Nat → IO Unit
  | 0 => IO.println s!"Out of attempts. The code was {showCode secret}."
  | fuel + 1 => do
      IO.print s!"[{fuel} attempts left] "
      match ← readValid 3 with
      | none => IO.println s!"You give up. The code was {showCode secret}."
      | some g =>
          let fb := score g secret
          IO.println s!"{showCode g}  {showFeedback fb}  ({fb.exact} exact, {fb.misplaced} misplaced)"
          if won fb then
            IO.println "Got it!"
          else
            loop secret fuel

/-- Random secret code: `numPegs` numbers drawn from 1..numColors. -/
def randomCode : IO Code := do
  let mut acc : Code := []
  for _ in [0:numPegs] do
    let p ← IO.rand 1 numColors
    acc := acc ++ [p]
  return acc

def main (args : List String) : IO Unit := do
  IO.println s!"=== MASTERMIND === ({numPegs} pegs, numbers 1..{numColors}, 10 attempts)"
  IO.println s!"Numbers 1 to {numColors}, {numPegs} digits, e.g. 1234. 'q' to quit."
  let secret ←
    match args.head? with
    | some s =>
        match parseGuess s with
        | some c => pure c
        | none   => do
            IO.println s!"Invalid code: {s}. Generating a random one."
            randomCode
    | none => randomCode
  loop secret 10
