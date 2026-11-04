import Mastermind

open Mastermind

/-- Tutti i codici di lunghezza `n` con peg presi da `1 .. k`. -/
def codesAux : Nat → Nat → List Code
  | 0, _ => [[]]
  | n + 1, k => ((List.range k).map (· + 1)).flatMap fun c => (codesAux n k).map fun cs => c :: cs

def allCodes : List Code := codesAux numPegs numColors

/-- Riferimento indipendente: punteggio come intersezione di multinsiemi,
    min(occorrenze nel tentativo, occorrenze nel segreto) sommato sui numeri,
    meno gli esatti. Non usa né `splitEq` né `matchCount`. -/
def oracleScore (g s : Code) : Feedback :=
  let exact := (g.zip s).countP fun p => p.1 == p.2
  let inter := ((List.range numColors).map (· + 1)).foldl
    (fun acc c => acc + min (List.count c g) (List.count c s)) 0
  { exact := exact, misplaced := inter - exact }

/-- Implementazione INGENUA: "fuori posto ma presente nel segreto", senza
    consumare i peg. Errore classico. -/
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
  IO.println s!"codici su {numPegs} peg e numeri 1..{numColors}: {allCodes.length}, coppie: {total}"
  IO.println s!"scarto dalla versione verificata (splitEq + matchCount): {countDisagreements score}"
  IO.println s!"scarto dalla versione ingenua: {countDisagreements naiveScore}"
  match firstDisagreement naiveScore with
  | some (g, s) =>
      IO.println s!"esempio: segreto {showCode s}, tentativo {showCode g}"
      IO.println s!"  ingenua: {(naiveScore g s).exact} esatti / {(naiveScore g s).misplaced} fuori posto"
      IO.println s!"  corretta: {(oracleScore g s).exact} esatti / {(oracleScore g s).misplaced} fuori posto"
  | none => IO.println "nessuna divergenza"

#eval main
