#!/usr/bin/env bash
# Test di confine: quello che le prove NON coprono (input, I/O, binario).
set -u
BIN=./.lake/build/bin/mastermind
fail=0
check() { # descrizione, atteso, comando
  local desc="$1" want="$2" got
  got=$(eval "$3")
  if [[ "$got" == *"$want"* ]]; then echo "  ok   $desc"; else echo "  FAIL $desc (atteso '$want', ottenuto '$got')"; fail=1; fi
}

echo "integrazione:"
check "vince con il codice giusto" "Preso!" "printf '1234\n' | $BIN 1234"
check "duplicati contati una volta" "3 esatti, 0 fuori posto" "printf '2222\n' | $BIN 2224"
check "cifra fuori range rifiutata" "Input non valido" "printf '9999\nq\n' | $BIN 1234"
check "zero rifiutato" "Input non valido" "printf '0123\nq\n' | $BIN 1234"
check "input non valido non crasha" "Input non valido" "printf 'zzzz\nq\n' | $BIN 1234"
check "esaurisce i 10 tentativi" "Tentativi finiti" "printf '1111\n%.0s' {1..10} | $BIN 6666"
check "argomento invalido -> casuale" "Ne genero uno casuale" "printf 'q\n' | $BIN 0000"
check "EOF chiude subito" "Ti arrendi" "printf '' | $BIN 1234"
exit $fail
