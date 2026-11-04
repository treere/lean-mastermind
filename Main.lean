import Mastermind

open Mastermind

/-- 1, 2, ... numColors: i numeri che il giocatore può digitare. -/
def pegsRange : List Peg := (List.range numColors).map (· + 1)

/-- Un carattere è un peg valido se è 1..numColors. -/
def parsePeg (c : Char) : Option Peg :=
  let n := c.toNat - '0'.toNat
  if c.isDigit && 0 < n && n ≤ numColors then some n else none

/-- Legge un tentativo: `numPegs` cifre, ignorando gli spazi. -/
def parseGuess (line : String) : Option Code :=
  let cs := line.toList.filter (fun c => c ≠ ' ' && c ≠ '\n' && c ≠ '\r')
  if cs.length ≠ numPegs then none
  else cs.mapM parsePeg

def showCode (c : Code) : String :=
  String.join (c.map fun p => toString p)

def showFeedback (fb : Feedback) : String :=
  String.ofList (List.replicate fb.exact '●' ++ List.replicate fb.misplaced '○')

def help : String :=
  s!"Numeri da 1 a {numColors}, {numPegs} cifre — es. 1234. 'q' per uscire."

/-- Rilegge finché l'input non è valido; `n` tentativi di battitura per turno. -/
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
            IO.println s!"Input non valido. {help}"
            readValid n

/-- Il loop del gioco è `def`, non `partial`: diminuisce `fuel`, quindi è totale. -/
def loop (secret : Code) : Nat → IO Unit
  | 0 => IO.println s!"Tentativi finiti. Il codice era {showCode secret}."
  | fuel + 1 => do
      IO.print s!"[{fuel} tentativi rimasti] "
      match ← readValid 3 with
      | none => IO.println s!"Ti arrendi. Il codice era {showCode secret}."
      | some g =>
          let fb := score g secret
          IO.println s!"{showCode g}  {showFeedback fb}  ({fb.exact} esatti, {fb.misplaced} fuori posto)"
          if won fb then
            IO.println "Preso!"
          else
            loop secret fuel

/-- Codice segreto casuale: `numPegs` numeri presi da 1..numColors. -/
def randomCode : IO Code := do
  let mut acc : Code := []
  for _ in [0:numPegs] do
    let p ← IO.rand 1 numColors
    acc := acc ++ [p]
  return acc

def main (args : List String) : IO Unit := do
  IO.println s!"=== MASTERMIND === ({numPegs} peg, numeri 1..{numColors}, 10 tentativi)"
  IO.println help
  let secret ←
    match args.head? with
    | some s =>
        match parseGuess s with
        | some c => pure c
        | none   => do
            IO.println s!"Codice non valido: {s}. Ne genero uno casuale."
            randomCode
    | none => randomCode
  loop secret 10
