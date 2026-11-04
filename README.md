# lean-mastermind

Mastermind giocabile da terminale, scritto in Lean 4: il cuore del gioco è
verificato con dimostrazioni controllate dal kernel, il resto è coperto da test.

4 peg, numeri da 1 a 6, 10 tentativi.

## Giocare

```bash
lake build
./.lake/build/bin/mastermind        # codice segreto casuale
./.lake/build/bin/mastermind 1243   # codice segreto fisso
```

Input: 4 cifre da 1 a 6 (`1234`), `q` per uscire.

## Struttura

| file | contenuto |
|---|---|
| `Mastermind.lean` | logica pura (punteggio) + specifiche e teoremi |
| `Main.lean` | parsing, loop di I/O, `main` |
| `Tests.lean` | test unitari e sul dominio, con LSpec |
| `Checks.lean` | confronto esaustivo con un'implementazione di riferimento |
| `integration_test.sh` | test di confine sul binario |

## Cosa è dimostrato

```lean
theorem score_bound (g s : Code) : (score g s).exact + (score g s).misplaced ≤ g.length
theorem score_self  (c : Code)   : score c c = { exact := c.length, misplaced := 0 }
```

`score_bound` esclude che il gioco assegni più peg di quanti ne ha il codice
(l'errore che rende il gioco ingiocabile); `score_self` ancora la scala del
punteggio. Entrambi valgono per liste di qualunque lunghezza: non assumono
4 peg né 6 numeri. Verifica delle dipendenze:

```
#print axioms Mastermind.score_bound   -- [propext, Quot.sound]
```

## Cosa non è dimostrato

La specifica completa del punteggio è

> `misplaced = |multinsiemi(tentativo) ∩ multinsiemi(segreto)| − esatti`

Non è dimostrata come teorema. È invece confrontata con un'implementazione di
riferimento scritta in modo indipendente (`oracleScore`, intersezione di
multinsiemi) su **tutte** le coppie di codici:

```
codici su 4 peg e numeri 1..6: 1296, coppie: 1679616
scarto dalla versione verificata: 0
scarto dalla versione ingenua:   514740
```

Questo è un test esaustivo, non una prova: vale per questi parametri.
La versione "ingenua" (quella che non consuma i peg abbinati) sbaglia in
514.740 casi, per esempio con segreto `1112` e tentativo `1111`.

Fuori dal confine verificato restano parsing, I/O e loop: coperti da
`integration_test.sh`.

## Test

```bash
lake build tests && ./.lake/build/bin/tests   # LSpec, exit code 1 se fallisce
./integration_test.sh                        # test sul binario
lake env lean Checks.lean                    # confronto esaustivo
```

In CI conviene `lake build -DwarningAsError=true`, così un `sorry` diventa un
errore invece di un warning.

## Toolchain

Lean 4.34.1, pinnata in `lean-toolchain`; `elan` installa la versione al primo
build. LSpec e Plausible sono dipendenze git dichiarate in `lakefile.toml`.
