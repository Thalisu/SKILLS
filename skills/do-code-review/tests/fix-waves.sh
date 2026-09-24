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

shared="$tmp/03-shared-test-file.review.md"
cat >"$shared" <<'MD'
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
Fix: an expired token is rejected, in tests/notes.test.js

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

run "$shared"
check_lines "two Findings in different source files whose Fix lines name one test file come back on two Waves" 0 "$rc" \
  "wave=1 findings=1" \
  "wave=2 findings=2"

prose="$tmp/03-prose-target.review.md"
cat >"$prose" <<'MD'
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
Fix: revert the limit, in the change and pinned in tests/shared.sh

### 2. Security at src/auth.js:12
Claim: an expired token is accepted.
Evidence: a token past its expiry reaches the sink with no gate on the claim.
Rung: 4
Risk: auth
Fix: reject the token, in the check and pinned in tests/shared.sh

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

run "$prose"
check_lines "two Findings in different source files whose Fix lines name one test file inside a prose target come back on two separate Waves" 0 "$rc" \
  "wave=1 findings=1" \
  "wave=2 findings=2"

unreadable="$tmp/04-spec-finding.review.md"
cat >"$unreadable" <<'MD'
# Review: feat/export-notes

Ticket: none
Fixed point: main (3f2a9c1), inferred
Commit: 8b1d0e4
Spec source: specs/export-notes.md
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

### 2. Spec at "the export must carry a header line"
Claim: the export carries no header line.
Evidence: the spec line is unimplemented; the CSV opens on the first note.
Rung: 4
Fix: the export carries a header line, in the exportNotes handler

### 3. Security at src/auth.js:12
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
- Spec: 1 finding, worst #2 (Act on)
- Standards: 0 findings
- Principles: 0 findings
- Blast radius: 0 findings
- Security: 1 finding, worst #3 (Act on)
MD

run "$unreadable"
check_lines "a Finding whose location and Fix line name no file comes back on a Wave of its own, the others grouped around it" 0 "$rc" \
  "wave=1 findings=1,3" \
  "wave=2 findings=2"
absent "the Finding whose files cannot be read is joined by nothing" "wave=3"

unreadable_first="$tmp/04-spec-finding-first.review.md"
cat >"$unreadable_first" <<'MD'
# Review: feat/export-notes

Ticket: none
Fixed point: main (3f2a9c1), inferred
Commit: 8b1d0e4
Spec source: specs/export-notes.md
Mode: fix
Language: English

## Intent

Export the active notes as CSV, with a header line and one row per note.

## Safe because

The only caller of `page` outside the diff runs green in a proof script. Rung 4.

## Act on

### 1. Spec at "the export must carry a header line"
Claim: the export carries no header line.
Evidence: the spec line is unimplemented; the CSV opens on the first note.
Rung: 4
Fix: the export carries a header line, in the exportNotes handler

### 2. Correctness at src/notes.js:31
Claim: a page of ten notes returns nine.
Evidence: eleven notes created, `page(1, 10)` called; nine rows returned, `slice` ends one short.
Rung: 4
Fix: a page of size ten over eleven notes returns ten rows, in tests/notes.test.js

### 3. Security at src/auth.js:12
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

- Correctness: 1 finding, worst #2 (Act on)
- Spec: 1 finding, worst #1 (Act on)
- Standards: 0 findings
- Principles: 0 findings
- Blast radius: 0 findings
- Security: 1 finding, worst #3 (Act on)
MD

run "$unreadable_first"
check_lines "a Finding whose location and Fix line name no file, coming first, prints alone on its own Wave, with the joinable Findings after it joined together on the next Wave" 0 "$rc" \
  "wave=1 findings=1" \
  "wave=2 findings=2,3"
absent "the Finding whose files cannot be read is never joined by the Correctness Finding that comes after it" "wave=1 findings=1,2"
absent "the Finding whose files cannot be read is never joined by the Security Finding that comes after it" "wave=1 findings=1,3"
absent "the Finding whose files cannot be read is never joined by every Finding that comes after it" "wave=1 findings=1,2,3"

printf 'test("other", () => {});\n' >"$tmp/tests/other.test.js"

punctuated="$tmp/05-punctuated-header-location.review.md"
cat >"$punctuated" <<'MD'
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

### 1. Correctness at src/notes.js:31, outside the diff
Claim: a page of ten notes returns nine.
Evidence: eleven notes created, `page(1, 10)` called; nine rows returned, `slice` ends one short.
Rung: 4
Fix: a page of size ten over eleven notes returns ten rows, in tests/notes.test.js

### 2. Security at src/notes.js:45
Claim: an expired token is accepted.
Evidence: a token past its expiry reaches the sink with no gate on the claim.
Rung: 4
Risk: auth
Fix: an expired token is rejected, in tests/other.test.js

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

run "$punctuated"
check_lines "a header location punctuated with a trailing comma still names its file, so two Findings sharing that file come back on two separate Waves" 0 "$rc" \
  "wave=1 findings=1" \
  "wave=2 findings=2"
absent "the Findings sharing src/notes.js through a punctuated header location are never merged onto one Wave" "wave=1 findings=1,2"

ranged="$tmp/06-range-header-location.review.md"
cat >"$ranged" <<'MD'
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

### 1. Correctness at src/notes.js:31-52
Claim: a page of ten notes returns nine.
Evidence: eleven notes created, `page(1, 10)` called; nine rows returned, `slice` ends one short.
Rung: 4
Fix: a page of size ten over eleven notes returns ten rows, in tests/notes.test.js

### 2. Security at src/notes.js:60
Claim: an expired token is accepted.
Evidence: a token past its expiry reaches the sink with no gate on the claim.
Rung: 4
Risk: auth
Fix: an expired token is rejected, in tests/other.test.js

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

run "$ranged"
check_lines "a header location written as a line range still names its file, so two Findings sharing that file come back on two separate Waves" 0 "$rc" \
  "wave=1 findings=1" \
  "wave=2 findings=2"
absent "the Findings sharing src/notes.js through a range header location are never merged onto one Wave" "wave=1 findings=1,2"

wrapped="$tmp/07-wrapped-fix-line.review.md"
cat >"$wrapped" <<'MD'
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

### 1. Correctness at src/a.js:3
Claim: a page of ten notes returns nine.
Evidence: eleven notes created, `page(1, 10)` called; nine rows returned, `slice` ends one short.
Rung: 4
Fix: a page of size ten over eleven notes returns ten rows, in
tests/shared.test.js

### 2. Security at src/b.js:9
Claim: an expired token is accepted.
Evidence: a token past its expiry reaches the sink with no gate on the claim.
Rung: 4
Risk: auth
Fix: an expired token is rejected, in tests/shared.test.js

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

run "$wrapped"
check_lines "a Fix line wrapped onto a continuation line still names its target file, so a Finding sharing that file with another comes back on two separate Waves" 0 "$rc" \
  "wave=1 findings=1" \
  "wave=2 findings=2"
absent "the Findings sharing tests/shared.test.js through a wrapped Fix line are never merged onto one Wave" "wave=1 findings=1,2"

capped="$tmp/08-six-disjoint-findings.review.md"
cat >"$capped" <<'MD'
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

### 1. Correctness at src/f1.js:3
Claim: a page of ten notes returns nine.
Evidence: eleven notes created, `page(1, 10)` called; nine rows returned, `slice` ends one short.
Rung: 4
Fix: a page of size ten over eleven notes returns ten rows, in tests/f1.test.js

### 2. Correctness at src/f2.js:3
Claim: a page of ten notes returns nine.
Evidence: eleven notes created, `page(1, 10)` called; nine rows returned, `slice` ends one short.
Rung: 4
Fix: a page of size ten over eleven notes returns ten rows, in tests/f2.test.js

### 3. Correctness at src/f3.js:3
Claim: a page of ten notes returns nine.
Evidence: eleven notes created, `page(1, 10)` called; nine rows returned, `slice` ends one short.
Rung: 4
Fix: a page of size ten over eleven notes returns ten rows, in tests/f3.test.js

### 4. Correctness at src/f4.js:3
Claim: a page of ten notes returns nine.
Evidence: eleven notes created, `page(1, 10)` called; nine rows returned, `slice` ends one short.
Rung: 4
Fix: a page of size ten over eleven notes returns ten rows, in tests/f4.test.js

### 5. Correctness at src/f5.js:3
Claim: a page of ten notes returns nine.
Evidence: eleven notes created, `page(1, 10)` called; nine rows returned, `slice` ends one short.
Rung: 4
Fix: a page of size ten over eleven notes returns ten rows, in tests/f5.test.js

### 6. Correctness at src/f6.js:3
Claim: a page of ten notes returns nine.
Evidence: eleven notes created, `page(1, 10)` called; nine rows returned, `slice` ends one short.
Rung: 4
Fix: a page of size ten over eleven notes returns ten rows, in tests/f6.test.js

## Consider

none

## Noted

none

## Cleared

none

## Axes

- Correctness: 6 findings, worst #1 (Act on)
- Spec: no spec
- Standards: 0 findings
- Principles: 0 findings
- Blast radius: 0 findings
- Security: 0 findings
MD

run "$capped"
check_lines "six disjoint Findings on six disjoint files are cut into consecutive Waves of at most four Findings each" 0 "$rc" \
  "wave=1 findings=1,2,3,4" \
  "wave=2 findings=5,6"
absent "a Wave never grows past four Findings even when every remaining Finding is disjoint from it" "wave=1 findings=1,2,3,4,5"
absent "six disjoint Findings never land on one Wave" "wave=1 findings=1,2,3,4,5,6"

capped12="$tmp/09-twelve-disjoint-findings.review.md"
cat >"$capped12" <<'MD'
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

### 1. Correctness at src/f1.js:3
Claim: a page of ten notes returns nine.
Evidence: eleven notes created, `page(1, 10)` called; nine rows returned, `slice` ends one short.
Rung: 4
Fix: a page of size ten over eleven notes returns ten rows, in tests/f1.test.js

### 2. Correctness at src/f2.js:3
Claim: a page of ten notes returns nine.
Evidence: eleven notes created, `page(1, 10)` called; nine rows returned, `slice` ends one short.
Rung: 4
Fix: a page of size ten over eleven notes returns ten rows, in tests/f2.test.js

### 3. Correctness at src/f3.js:3
Claim: a page of ten notes returns nine.
Evidence: eleven notes created, `page(1, 10)` called; nine rows returned, `slice` ends one short.
Rung: 4
Fix: a page of size ten over eleven notes returns ten rows, in tests/f3.test.js

### 4. Correctness at src/f4.js:3
Claim: a page of ten notes returns nine.
Evidence: eleven notes created, `page(1, 10)` called; nine rows returned, `slice` ends one short.
Rung: 4
Fix: a page of size ten over eleven notes returns ten rows, in tests/f4.test.js

### 5. Correctness at src/f5.js:3
Claim: a page of ten notes returns nine.
Evidence: eleven notes created, `page(1, 10)` called; nine rows returned, `slice` ends one short.
Rung: 4
Fix: a page of size ten over eleven notes returns ten rows, in tests/f5.test.js

### 6. Correctness at src/f6.js:3
Claim: a page of ten notes returns nine.
Evidence: eleven notes created, `page(1, 10)` called; nine rows returned, `slice` ends one short.
Rung: 4
Fix: a page of size ten over eleven notes returns ten rows, in tests/f6.test.js

### 7. Correctness at src/f7.js:3
Claim: a page of ten notes returns nine.
Evidence: eleven notes created, `page(1, 10)` called; nine rows returned, `slice` ends one short.
Rung: 4
Fix: a page of size ten over eleven notes returns ten rows, in tests/f7.test.js

### 8. Correctness at src/f8.js:3
Claim: a page of ten notes returns nine.
Evidence: eleven notes created, `page(1, 10)` called; nine rows returned, `slice` ends one short.
Rung: 4
Fix: a page of size ten over eleven notes returns ten rows, in tests/f8.test.js

### 9. Correctness at src/f9.js:3
Claim: a page of ten notes returns nine.
Evidence: eleven notes created, `page(1, 10)` called; nine rows returned, `slice` ends one short.
Rung: 4
Fix: a page of size ten over eleven notes returns ten rows, in tests/f9.test.js

### 10. Correctness at src/f10.js:3
Claim: a page of ten notes returns nine.
Evidence: eleven notes created, `page(1, 10)` called; nine rows returned, `slice` ends one short.
Rung: 4
Fix: a page of size ten over eleven notes returns ten rows, in tests/f10.test.js

### 11. Correctness at src/f11.js:3
Claim: a page of ten notes returns nine.
Evidence: eleven notes created, `page(1, 10)` called; nine rows returned, `slice` ends one short.
Rung: 4
Fix: a page of size ten over eleven notes returns ten rows, in tests/f11.test.js

### 12. Correctness at src/f12.js:3
Claim: a page of ten notes returns nine.
Evidence: eleven notes created, `page(1, 10)` called; nine rows returned, `slice` ends one short.
Rung: 4
Fix: a page of size ten over eleven notes returns ten rows, in tests/f12.test.js

## Consider

none

## Noted

none

## Cleared

none

## Axes

- Correctness: 12 findings, worst #1 (Act on)
- Spec: no spec
- Standards: 0 findings
- Principles: 0 findings
- Blast radius: 0 findings
- Security: 0 findings
MD

run "$capped12"
check_lines "twelve disjoint Findings on twelve disjoint files are cut into three consecutive Waves of at most four Findings each" 0 "$rc" \
  "wave=1 findings=1,2,3,4" \
  "wave=2 findings=5,6,7,8" \
  "wave=3 findings=9,10,11,12"
absent "twelve disjoint Findings are never cut into only two Waves" "wave=1 findings=1,2,3,4,5"
absent "no Wave among twelve disjoint Findings ever names more than four Findings" "wave=2 findings=5,6,7,8,9"
absent "the third Wave among twelve disjoint Findings never grows past four Findings" "wave=3 findings=9,10,11,12,13"

settled="$tmp/10-settled-finding.review.md"
review_at 8b1d0e4 "$settled" "### 1. Correctness at src/notes.js:31
Claim: a page of ten notes returns nine.
Evidence: eleven notes created, \`page(1, 10)\` called; nine rows returned, \`slice\` ends one short.
Rung: 4
Fix: a page of size ten over eleven notes returns ten rows, in tests/notes.test.js

### 2. Security at src/auth.js:12
Claim: an expired token is accepted.
Evidence: a token past its expiry reaches the sink with no gate on the claim.
Rung: 4
Risk: auth
Fix: an expired token is rejected, in tests/notes.test.js" "## Fix run

Date: 2026-09-23 · at 8b1d0e4

- 1: not fixed: the Fixer never returned
- 2: not fixed: the Fixer never returned
- diff tests: skip: no Fixer commit
- gate fixer: not needed
- gate: \`node --test tests/notes.test.js\`: green
- not landed: a Fixer did not return

## Fix run

Date: 2026-09-24 · at 8b1d0e4

- 1: fixed 4c07ab2, verified (\`node --test tests/notes.test.js\`)
- 2: not fixed: the Fixer could not turn it green
- diff tests: \`node --test tests/notes.test.js\`: 1 passing
- gate fixer: not needed
- gate: \`node --test tests/notes.test.js\`: green
- not landed: a Finding not fixed"

run "$settled"
check_lines "a Finding not fixed in an earlier Fix run and fixed in a later one is left out of every Wave, so the Finding that shared a file with it comes back alone on the first Wave" 0 "$rc" \
  "wave=1 findings=2"
same "a settled Finding forks no Fixer on any Wave, and its neighbour is never pushed onto a second Wave" "wave=1 findings=2"

echo
if [ "$fails" = 0 ]; then echo "fix-waves: all checks passed"; else
  echo "fix-waves: $fails failed"
  exit 1
fi
