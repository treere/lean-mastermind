#!/usr/bin/env bash
# Binary-level tests: only what cannot be checked from Lean
# (argv handling, stdin/EOF behaviour, exit status). Parsing and scoring are
# covered by Tests.lean.
set -uo pipefail
BIN=./.lake/build/bin/mastermind
fail=0

run() { # description, expected substring, expected status, stdin, args...
  local desc="$1" want="$2" want_status="$3" stdin="$4"
  shift 4
  local out status
  out=$(printf "%b" "$stdin" | "$BIN" "$@" 2>&1)
  status=$?
  if [[ "$out" == *"$want"* && "$status" == "$want_status" ]]; then
    echo "  ok   $desc"
  else
    echo "  FAIL $desc (status $status, wanted $want_status)"
    echo "       output: $out"
    fail=1
  fi
}

echo "binary:"
run "argv sets the secret code"          "Got it!"                 0 '1234\n' 1234
run "invalid argv falls back to random"  "Generating a random one"  0 'q\n'    0000
run "EOF on stdin quits with status 0"   "You give up"             0 ''       1234

exit $fail
