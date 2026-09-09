#!/usr/bin/env bash
# partial-test-data.sh: the contract of the partial test data rule, the Project map label that
# carries its helper, the scan section that counts the assertions already in the tree and the
# verifier key that reports the helper's state, exercised against throwaway fixture projects.
# Run: bash skills/testing-policy/tests/partial-test-data.sh
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
skill="$here/.."
render="$skill/scripts/render-agent.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

check() { # $1 label, $2 expected exit, $3 actual exit, $4.. lines that must appear (fixed strings); output in $out
  local label="$1" want="$2" rc="$3"; shift 3
  local ok=1 line
  [ "$rc" = "$want" ] || ok=0
  for line in "$@"; do grep -qF -- "$line" <<<"$out" || ok=0; done
  if [ "$ok" = 1 ]; then echo "ok    $label"; else
    echo "FAIL  $label (exit $rc, wanted $want)"; head -12 <<<"$out" | sed 's/^/      /'; fails=$((fails + 1)); fi
}
absent() { # $1 label, $2.. lines that must not appear; output in $out
  local label="$1"; shift
  local ok=1 line found=""
  for line in "$@"; do if grep -qF -- "$line" <<<"$out"; then ok=0; found="$found $line"; fi; done
  if [ "$ok" = 1 ]; then echo "ok    $label"; else echo "FAIL  $label (found:$found)"; fails=$((fails + 1)); fi
}
render() { rc=0; out="$(bash "$render" "$@" 2>&1)" || rc=$?; }

echo "# the rule in the core"
render unit --core-only
check "the unit core forbids building a fake by asserting a type at the compiler" 0 "$rc" \
  "a fake by asserting a type at the compiler"
check "the unit core points at the Project map for the helper" 0 "$rc" \
  "Partial test data"

echo
if [ "$fails" = 0 ]; then echo "partial-test-data: all checks passed"; else echo "partial-test-data: $fails failed"; exit 1; fi
