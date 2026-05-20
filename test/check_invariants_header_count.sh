#!/usr/bin/env bash
# test/check_invariants_header_count.sh
# Verifies src/Invariants.dfy header cites exactly 8 allium.md properties,
# matching the 8 entries actually present in the coverage matrix.
# Would have FAILED when comment said "10 invariant-like".
set -euo pipefail

FILE="$(dirname "$0")/../src/Invariants.dfy"

if grep -q "plus 8 invariant-like" "$FILE"; then
  echo "PASS: Invariants.dfy header count is 8"
  exit 0
else
  echo "FAIL: Invariants.dfy header does not say 'plus 8 invariant-like'"
  grep "invariant-like" "$FILE" || true
  exit 1
fi
