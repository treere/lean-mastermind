import Mastermind
import LSpec

open Mastermind LSpec

/-- Tutti i codici: numeri da 1 a `numColors`. -/
def codesAux : Nat → Nat → List Code
  | 0, _ => [[]]
  | n + 1, k => ((List.range k).map (· + 1)).flatMap fun c => (codesAux n k).map fun cs => c :: cs

def allCodes : List Code := codesAux numPegs numColors

/-- L'invariante regge su tutte le coppie: qui è un test, non un teorema. -/
def boundHoldsEverywhere : Bool :=
  allCodes.all fun g => allCodes.all fun s =>
    let fb := score g s
    fb.exact + fb.misplaced ≤ numPegs

/-- Ogni peg generato sta in 1..numColors: controlla la generazione del dominio. -/
def domainIsWellFormed : Bool :=
  allCodes.all fun c => c.length == numPegs && c.all validPeg

def scoreSuite : TestSeq :=
  group "punteggio" $
    test "codice indovinato" (score [1,2,3,4] [1,2,3,4] = { exact := 4, misplaced := 0 }) $
    test "tutti fuori posto" (score [4,1,2,3] [1,2,3,4] = { exact := 0, misplaced := 4 }) $
    test "duplicati consumati una volta sola" (score [1,1,1,1] [1,2,2,2] = { exact := 1, misplaced := 0 }) $
    test "3 esatti e 0 fuori posto, non 1" (score [2,2,2,2] [2,2,2,4] = { exact := 3, misplaced := 0 }) $
    test "nessun peg in comune" (score [1,1,2,2] [5,5,6,6] = { exact := 0, misplaced := 0 })

def domainSuite : TestSeq :=
  group "dominio" $
    test "bound su tutte le coppie di codici" boundHoldsEverywhere $
    test "ogni codice usa solo peg 1..numColors" domainIsWellFormed

def main (args : List String) : IO UInt32 :=
  lspecIO (.ofList [("punteggio", [scoreSuite]), ("dominio", [domainSuite])]) args
