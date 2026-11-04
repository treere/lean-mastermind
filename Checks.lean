import Mastermind

open Mastermind

/-- Every code of length `n` with pegs drawn from `1 .. k`. -/
def codesAux : Nat → Nat → List Code
  | 0, _ => [[]]
  | n + 1, k => ((List.range k).map (· + 1)).flatMap fun c => (codesAux n k).map fun cs => c :: cs

def allCodes : List Code := codesAux numPegs numColors

/-- Independent reference: score as multiset intersection,
    min(occurrences in guess, occurrences in secret) summed over the numbers,
    minus the exact matches. Uses neither `splitEq` nor `matchCount`. -/
def oracleScore (g s : Code) : Feedback :=
  let exact := (g.zip s).countP fun p => p.1 == p.2
  let inter := ((List.range numColors).map (· + 1)).foldl
    (fun acc c => acc + min (List.count c g) (List.count c s)) 0
  { exact := exact, misplaced := inter - exact }

/-- NAIVE implementation: "misplaced but present in the secret", without
    consuming the pegs. The classic mistake. -/
def naiveScore (g s : Code) : Feedback :=
  let pairs := g.zip s
  { exact := pairs.countP (fun p => p.1 == p.2)
    misplaced := pairs.countP (fun p => p.1 != p.2 && s.contains p.1) }

def countDisagreements (f : Code → Code → Feedback) : Nat := Id.run do
  let mut n := 0
  for g in allCodes do
    for s in allCodes do
      if f g s != oracleScore g s then n := n + 1
  return n

def firstDisagreement (f : Code → Code → Feedback) : Option (Code × Code) :=
  allCodes.findSome? fun g =>
    allCodes.findSome? fun s => if f g s != oracleScore g s then some (g, s) else none

def showCode (c : Code) : String := String.join (c.map fun p => toString p)

def main : IO Unit := do
  let total := allCodes.length * allCodes.length
  IO.println s!"codes with {numPegs} pegs and numbers 1..{numColors}: {allCodes.length}, pairs: {total}"
  IO.println s!"disagreements of the verified version (splitEq + matchCount): {countDisagreements score}"
  IO.println s!"disagreements of the naive version: {countDisagreements naiveScore}"
  match firstDisagreement naiveScore with
  | some (g, s) =>
      IO.println s!"example: secret {showCode s}, guess {showCode g}"
      IO.println s!"  naive:   {(naiveScore g s).exact} exact / {(naiveScore g s).misplaced} misplaced"
      IO.println s!"  correct: {(oracleScore g s).exact} exact / {(oracleScore g s).misplaced} misplaced"
  | none => IO.println "no disagreement"

#eval main
