#!/usr/bin/env bash
# Boundary tests: what the proofs do NOT cover (input, I/O, the binary).
set -u
BIN=./.lake/build/bin/mastermind
fail=0
check() { # description, expected substring, command
  local desc="$1" want="$2" got
  got=$(eval "$3")
  if [[ "$got" == *"$want"* ]]; then echo "  ok   $desc"; else echo "  FAIL $desc (expected '$want', got '$got')"; fail=1; fi
}

echo "integration:"
check "correct code wins" "Got it!" "printf '1234\n' | $BIN 1234"
check "duplicates counted once" "3 exact, 0 misplaced" "printf '2222\n' | $BIN 2224"
check "out-of-range digit rejected" "Invalid input" "printf '9999\nq\n' | $BIN 1234"
check "zero rejected" "Invalid input" "printf '0123\nq\n' | $BIN 1234"
check "bad input does not crash" "Invalid input" "printf 'zzzz\nq\n' | $BIN 1234"
check "runs out of the 10 attempts" "Out of attempts" "printf '1111\n%.0s' {1..10} | $BIN 6666"
check "invalid argument -> random" "Generating a random one" "printf 'q\n' | $BIN 0000"
check "EOF quits immediately" "You give up" "printf '' | $BIN 1234"
exit $fail
