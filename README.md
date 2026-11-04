# lean-mastermind

Mastermind in Lean 4, playable from the terminal. The core of the game is verified
with kernel-checked proofs; everything outside it is covered by tests.

4 pegs, numbers from 1 to 6, 10 attempts.

## Play

```bash
lake build
./.lake/build/bin/mastermind        # random secret code
./.lake/build/bin/mastermind 1243   # fixed secret code
```

Input: 4 digits from 1 to 6 (`1234`), `q` to quit.

## Layout

| file | content |
|---|---|
| `Mastermind.lean` | pure logic (scoring) + specs and theorems |
| `Main.lean` | parsing, I/O loop, `main` |
| `Tests.lean` | unit tests and domain tests, with LSpec |
| `Checks.lean` | exhaustive comparison against a reference implementation |
| `integration_test.sh` | boundary tests against the binary |

## What is proven

```lean
theorem score_bound (g s : Code) : (score g s).exact + (score g s).misplaced ≤ g.length
theorem score_self  (c : Code)   : score c c = { exact := c.length, misplaced := 0 }
```

`score_bound` rules out the game awarding more pegs than the code has (the bug
that makes the game unplayable); `score_self` anchors the scale of the score.
Both hold for codes of any length: they assume neither 4 pegs nor 6 numbers, so
changing `numColors` or `numPegs` leaves the proofs untouched. Axiom check:

```
#print axioms Mastermind.score_bound   -- [propext, Quot.sound]
```

## What is NOT proven

The full functional spec of scoring is

> `misplaced = |multiset(guess) ∩ multiset(secret)| − exact`

It is not a theorem here. Instead the implementation is compared against an
independently written reference (`oracleScore`, multiset intersection) over
**every** pair of codes:

```
codes with 4 pegs and numbers 1..6: 1296, pairs: 1679616
disagreements of the verified version: 0
disagreements of the naive version:   514740
```

That is an exhaustive test, not a proof: it holds for these parameters only.
The naive version (the one that does not consume matched pegs) is wrong in
514,740 cases, for example with secret `1112` and guess `1111`.

Parsing, I/O and the loop live outside the verified boundary and are covered by
`integration_test.sh`.

## Tests

```bash
lake build tests && ./.lake/build/bin/tests   # LSpec, exit code 1 on failure
./integration_test.sh                        # binary-level tests
lake env lean Checks.lean                    # exhaustive comparison
```

In CI use `lake build -DwarningAsError=true`, so that a `sorry` is an error
instead of a warning.

## Toolchain

Lean 4.34.1, pinned in `lean-toolchain`; `elan` installs it on first build.
LSpec and Plausible are git dependencies declared in `lakefile.toml`.
