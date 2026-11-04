import Std

namespace Mastermind

/-- Un peg è un numero: i valori validi sono `1 .. numColors`. -/
abbrev Peg := Nat
abbrev Code := List Peg

def numPegs : Nat := 4
def numColors : Nat := 6

/-- Il peg è un numero ammesso dal gioco? -/
def validPeg (p : Peg) : Bool := 0 < p && p ≤ numColors

/-! ## Il cuore del gioco: il punteggio

`splitEq` separa le coppie "stesso peg nella stessa posizione" dai residui.
`matchCount` conta i peg abbinabili fuori posizione, consumandoli
(ogni peg segreto può essere usato una volta sola: è la regola che tutti
sbagliano implementando Mastermind a mano).

Nessuna delle due funzioni dipende da `numColors` o `numPegs`: valgono per
qualunque lista, e le dimostrazioni infatti non nominano né 4 né 6. -/

def splitEq : Code → Code → Code × Code
  | [], _ => ([], [])
  | _, [] => ([], [])
  | a :: as, b :: bs =>
      let (ra, rb) := splitEq as bs
      if a = b then (ra, rb) else (a :: ra, b :: rb)

def matchCount : Code → Code → Nat
  | [], _ => 0
  | x :: xs, pool =>
      if pool.contains x then 1 + matchCount xs (pool.erase x) else matchCount xs pool

structure Feedback where
  exact : Nat
  misplaced : Nat
deriving Repr, BEq, DecidableEq

def score (guess secret : Code) : Feedback :=
  let (rg, rs) := splitEq guess secret
  { exact := guess.length - rg.length, misplaced := matchCount rg rs }

def won (fb : Feedback) : Bool := fb.exact == numPegs

/-! ## Specifiche e teoremi -/

theorem splitEq_fst_len (a b : Code) : (splitEq a b).1.length ≤ a.length := by
  induction a generalizing b with
  | nil => simp [splitEq]
  | cons x xs ih =>
    cases b with
    | nil => simp [splitEq]
    | cons y ys =>
      simp only [splitEq]
      split <;> simp only [List.length_cons] <;> (have := ih ys; omega)

theorem matchCount_le (xs pool : Code) : matchCount xs pool ≤ xs.length := by
  induction xs generalizing pool with
  | nil => simp [matchCount]
  | cons x xs ih =>
    simp only [matchCount]
    split
    · simp only [List.length_cons]; have := ih (pool.erase x); omega
    · simp only [List.length_cons]; have := ih pool; omega

/-- SPEC: il gioco non può mai assegnare più peg di quanti ne ha il codice.
    Vale per liste di qualunque lunghezza: non assume 4 peg né 6 numeri. -/
theorem score_bound (g s : Code) : (score g s).exact + (score g s).misplaced ≤ g.length := by
  simp only [score]
  have h1 := splitEq_fst_len g s
  have h2 := matchCount_le (splitEq g s).1 (splitEq g s).2
  omega

theorem splitEq_self : ∀ c : Code, splitEq c c = ([], [])
  | [] => by simp [splitEq]
  | x :: xs => by
      simp only [splitEq, splitEq_self xs]
      simp

/-- SPEC: indovinare il codice segreto dà tutti peg esatti e zero fuori posto. -/
theorem score_self (c : Code) : score c c = { exact := c.length, misplaced := 0 } := by
  simp [score, splitEq_self, matchCount]

end Mastermind
