import Std

namespace Mastermind

/-- A peg is a number: valid values are `1 .. numColors`. -/
abbrev Peg := Nat
abbrev Code := List Peg

def numPegs : Nat := 4
def numColors : Nat := 6

/-- Is the peg a number the game accepts? -/
def validPeg (p : Peg) : Bool := 0 < p && p ≤ numColors

/-! ## The core of the game: scoring

`splitEq` splits equal-position pairs from the leftovers.
`matchCount` counts the pegs matchable out of position, consuming them
(each secret peg can be used once: the rule everybody gets wrong when
implementing Mastermind by hand).

Neither function depends on `numColors` or `numPegs`: both work on any list,
and the proofs below never mention 4 or 6. -/

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

/-! ## Specs and theorems -/

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

/-- SPEC: the game can never award more pegs than the code has.
    Holds for codes of any length: it assumes neither 4 pegs nor 6 numbers. -/
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

/-- SPEC: guessing the secret scores every peg exact and none misplaced. -/
theorem score_self (c : Code) : score c c = { exact := c.length, misplaced := 0 } := by
  simp [score, splitEq_self, matchCount]

end Mastermind
