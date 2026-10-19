#!/usr/bin/env bash
# review-findings.sh: the contract of .agents/scripts/review-findings.sh, the one reading of a
# Review's Findings, their Bucket and the latest Fix run line for each, that the debt gather and the
# fix run share. Run: bash scripts/tests/review-findings.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/lib.sh"
script="$here/../../.agents/scripts/review-findings.sh"
fails=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

run() {
  rc=0
  # shellcheck disable=SC2034 # lib.sh's same and check_absent read $out
  out="$(bash "$script" "$@" 2>&1)" || rc=$?
}

tab=$'\t'
review="$tmp/spec.review.md"
review_at 8b1d0e4 "$review" "### 1. Correctness at src/a.sh:3
Claim: a call with no argument exits on an unbound variable.
Evidence: \`bash src/a.sh\` exits 1 with \`\$1: unbound variable\`.
Rung: 4
Fix: a call with no argument prints an empty line and exits 0, in tests/a.test.sh

### 2. Correctness at src/b.sh:8
Claim: an empty input file prints a stray header.
Evidence: \`bash src/b.sh /dev/null\` prints \`id,name\`.
Rung: 4
Fix: an empty input prints nothing, in tests/b.test.sh" "## Fix run

Date: 2026-09-24 · at 8b1d0e4

- 1: not fixed: the Fixer never returned
- 2: not fixed: the test stays red
- gate fixer: not needed
- gate: \`bash tests/a.test.sh\`: green
- not landed: a Fixer did not return

## Fix run

Date: 2026-09-25 · at 8b1d0e4

- 1: fixed abc1234, verified (\`bash tests/a.test.sh\`)
- gate fixer: not needed
- gate: \`bash tests/a.test.sh\`: green
- landed at abc1234" "" "### 3. Standards at src/c.sh:12
Claim: \`echo -e\` in \`src/\`, which CLAUDE.md forbids.
Evidence: CLAUDE.md, \"use printf\".
Rung: 2
Fix: the script writes through printf, in src/c.sh" "### 4. Principles at src/d.sh:5
Claim: the parser and the printer share one function.
Evidence: \`render\` both splits the line and formats it.
Rung: 2" "### 5. Blast radius at src/e.sh:7, outside the diff
Claim: the caller breaks on the new argument order.
Evidence: the caller passes the path first.
Rung: 4
Refuted by: a proof script that calls src/e.sh exits 0." "Print the first argument.

### 9. Not a Finding at src/z.sh:1

A sub-heading the author wrote under the Intent."

# Every Finding under a Bucket, in file order, each with its Bucket, the line the last Fix run wrote
# for it (none when no run wrote one) and its header; a heading outside the Buckets is no Finding.
run "$review"
same "each Finding prints one record in file order, with its Bucket, its latest fix line and its header" \
  "finding=1${tab}bucket=Act on${tab}latest=fixed abc1234, verified (\`bash tests/a.test.sh\`)${tab}header=Correctness at src/a.sh:3
finding=2${tab}bucket=Act on${tab}latest=not fixed: the test stays red${tab}header=Correctness at src/b.sh:8
finding=3${tab}bucket=Consider${tab}latest=none${tab}header=Standards at src/c.sh:12
finding=4${tab}bucket=Noted${tab}latest=none${tab}header=Principles at src/d.sh:5
finding=5${tab}bucket=Cleared${tab}latest=none${tab}header=Blast radius at src/e.sh:7, outside the diff"
expect "a Review with Findings exits 0" test "$rc" = 0

# A Finding the first Fix run left not fixed and a later one fixed reads as fixed, never as the
# first run's verdict, so a fix run does not fix it twice.
check_absent "a later Fix run's line overrides an earlier one's" 0 "$rc" \
  "finding=1${tab}bucket=Act on${tab}latest=not fixed: the Fixer never returned"

# A Review whose four Buckets read none has no Finding to report.
empty="$tmp/clean.review.md"
review_at 8b1d0e4 "$empty" "none" "## Fix run

Date: 2026-09-24 · at 8b1d0e4

- gate fixer: not needed
- gate: \`bash tests/a.test.sh\`: green
- landed at 8b1d0e4"
run "$empty"
same "a Review whose four Buckets read none prints nothing" ""
expect "a Review with no Finding exits 0" test "$rc" = 0

# A Review that is not there is refused, naming the file the caller handed.
missing="$tmp/absent.review.md"
refuses "a missing Review is refused, naming the file" names "$missing" "$missing"

exit "$fails"
