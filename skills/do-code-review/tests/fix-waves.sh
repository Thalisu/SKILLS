#!/usr/bin/env bash
# fix-waves.sh: the contract of scripts/fix-waves.sh, the Waves the fix step forks its Fixers on,
# one Fixer per Finding on a Wave line, the whole line at once.
# Run: bash skills/do-code-review/tests/fix-waves.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/fix-waves.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

run() {
  rc=0
  # shellcheck disable=SC2034  # lib.sh's check_lines and absent read $out
  out="$(cd "$tmp" && bash "$script" "$@" 2>&1)" || rc=$?
}

mkdir -p "$tmp/src" "$tmp/tests"
printf 'export function page() {}\n' >"$tmp/src/notes.js"
printf 'export function token() {}\n' >"$tmp/src/auth.js"
printf 'test("page", () => {});\n' >"$tmp/tests/notes.test.js"
printf 'test("token", () => {});\n' >"$tmp/tests/auth.test.js"

review="$tmp/02-export-notes.review.md"
cat >"$review" <<'MD'
# Review: feat/export-notes

Ticket: none
Fixed point: main (3f2a9c1), inferred
Commit: 8b1d0e4
Spec source: no spec
Mode: fix
Language: English

## Intent

Export the active notes as CSV, with a header line and one row per note.

## Safe because

The only caller of `page` outside the diff runs green in a proof script. Rung 4.

## Act on

### 1. Correctness at src/notes.js:31
Claim: a page of ten notes returns nine.
Evidence: eleven notes created, `page(1, 10)` called; nine rows returned, `slice` ends one short.
Rung: 4
Fix: a page of size ten over eleven notes returns ten rows, in tests/notes.test.js

### 2. Security at src/auth.js:12
Claim: an expired token is accepted.
Evidence: a token past its expiry reaches the sink with no gate on the claim.
Rung: 4
Risk: auth
Fix: an expired token is rejected, in tests/auth.test.js

## Consider

none

## Noted

none

## Cleared

none

## Axes

- Correctness: 1 finding, worst #1 (Act on)
- Spec: no spec
- Standards: 0 findings
- Principles: 0 findings
- Blast radius: 0 findings
- Security: 1 finding, worst #2 (Act on)
MD

run "$review"
check_lines "two Act on Findings naming no file in common come back on one Wave" 0 "$rc" \
  "wave=1 findings=1,2"
absent "two Findings that cannot collide are never split across Waves" "wave=2"

echo
if [ "$fails" = 0 ]; then echo "fix-waves: all checks passed"; else
  echo "fix-waves: $fails failed"
  exit 1
fi
