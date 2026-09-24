#!/usr/bin/env bash
# unsettled.sh: the contract of scripts/unsettled.sh, the Act on Findings a fix call has yet to
# settle, each with the commit since the Review that touched its files, which the fix call settles
# the Finding from instead of forking a Fixer that would report it stale.
# Run: bash skills/do-code-review/tests/unsettled.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/unsettled.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

git() { g "$@"; }
run() {
  rc=0
  # shellcheck disable=SC2034  # lib.sh's check_lines reads $out
  out="$(cd "$tmp" && bash "$script" "$@" 2>&1)" || rc=$?
}

fresh touched
wt="$tmp/touched"
mkdir -p src
printf '#!/usr/bin/env bash\nset -u\necho "$1"\n' >src/a.sh
commit base
reviewed="$(git rev-parse --short HEAD)"
printf '#!/usr/bin/env bash\nset -u\necho "${1:-}"\n' >src/a.sh
commit "fix: a.sh reads a missing argument as empty"
fixed="$(git rev-parse HEAD)"

review_at() { # $1 the Review's Commit: sha, $2 the review file: one Act on Finding on src/a.sh, not fixed by the last Fix run
  local reviewed="$1"
  cat >"$2" <<MD
# Review: main

Ticket: none
Fixed point: main ($reviewed), inferred
Commit: $reviewed
Spec source: no spec
Mode: fix
Language: English

## Intent

Print the first argument.

## Safe because

The script has no caller outside the diff. Rung 4.

## Act on

### 1. Correctness at src/a.sh:3
Claim: a call with no argument exits on an unbound variable.
Evidence: \`bash src/a.sh\` exits 1 with \`\$1: unbound variable\`.
Rung: 4
Fix: a call with no argument prints an empty line and exits 0, in tests/a.test.sh

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
- Security: 0 findings

## Fix run

Date: 2026-09-24 · at $reviewed

- 1: not fixed: the Fixer never returned
- diff tests: skip: no Fixer commit
- gate fixer: not needed
- gate: \`bash tests/a.test.sh\`: green
- not landed: a Fixer did not return
MD
}

review="$tmp/01-a.review.md"
review_at "$reviewed" "$review"
run "$wt" "$review"
check_lines "a not fixed Finding whose file a commit since the Review touched is listed with that commit" \
  0 "$rc" "finding=1 touched=$fixed"

fresh twice
wt="$tmp/twice"
mkdir -p src
printf '#!/usr/bin/env bash\nset -u\necho "$1"\n' >src/a.sh
commit base
reviewed="$(git rev-parse --short HEAD)"
printf '#!/usr/bin/env bash\nset -u\necho "${1-}"\n' >src/a.sh
commit "fix: a.sh reads a missing argument as empty"
earlier="$(git rev-parse HEAD)"
printf '#!/usr/bin/env bash\nset -u\necho "${1:-}"\n' >src/a.sh
commit "refactor: a.sh reads an empty argument as empty too"
later="$(git rev-parse HEAD)"

review="$tmp/02-a.review.md"
review_at "$reviewed" "$review"
run "$wt" "$review"
check_lines "a Finding whose files two commits since the Review touched is listed with the later one" \
  0 "$rc" "finding=1 touched=$later"
check_absent "a Finding whose files two commits since the Review touched is never listed with the earlier one" \
  0 "$rc" "touched=$earlier"

echo
if [ "$fails" = 0 ]; then echo "unsettled: all checks passed"; else
  echo "unsettled: $fails failed"
  exit 1
fi
