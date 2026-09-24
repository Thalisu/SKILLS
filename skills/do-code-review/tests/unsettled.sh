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

fresh settled
wt="$tmp/settled"
mkdir -p src
printf '#!/usr/bin/env bash\nset -u\necho "$1"\n' >src/a.sh
commit base
reviewed="$(git rev-parse --short HEAD)"
printf '#!/usr/bin/env bash\nset -u\necho "${1:-}"\n' >src/a.sh
commit "fix: a.sh reads a missing argument as empty"
fixed="$(git rev-parse --short HEAD)"

act_on="$(for n in 1 2 3 4; do
  printf '### %s. Correctness at src/a.sh:3\nClaim: a call with no argument exits on an unbound variable.\n' "$n"
  printf 'Evidence: `bash src/a.sh` exits 1.\nRung: 4\nFix: a call with no argument exits 0, in tests/a.test.sh\n\n'
done)"
fix_runs="## Fix run

Date: 2026-09-23 · at $reviewed

- 1: not fixed: the Fixer never returned
- 2: not fixed: the Fixer never returned
- 4: not fixed: the Fixer never returned
- diff tests: skip: no Fixer commit
- gate fixer: not needed
- gate: \`bash tests/a.test.sh\`: green
- not landed: a Fixer did not return

## Fix run

Date: 2026-09-24 · at $reviewed

- 1: not fixed: the Fixer never returned
- 2: stale
- 4: fixed $fixed, verified (\`bash tests/a.test.sh\`)
- diff tests: \`bash tests/a.test.sh\`: 1 passing
- gate fixer: not needed
- gate: \`bash tests/a.test.sh\`: green
- not landed: a Finding not fixed"
review="$tmp/03-a.review.md"
review_at "$reviewed" "$review" "$act_on" "$fix_runs"
run "$wt" "$review"
check "a Finding whose latest line across every Fix run reads not fixed or stale, or that has none, is listed" \
  0 "$rc" "finding=1 touched=" "finding=2 touched=" "finding=3 touched="
check_absent "a Finding not fixed in an earlier Fix run and fixed in a later one is not listed" \
  0 "$rc" "finding=4 "

fresh untouched
wt="$tmp/untouched"
mkdir -p src
printf '#!/usr/bin/env bash\nset -u\necho "$1"\n' >src/a.sh
printf '#!/usr/bin/env bash\necho b\n' >src/b.sh
commit base
reviewed="$(git rev-parse --short HEAD)"
printf '#!/usr/bin/env bash\necho "b, changed"\n' >src/b.sh
commit "feat: b.sh prints a longer line"

act_on="### 1. Correctness at src/a.sh:3
Claim: a call with no argument exits on an unbound variable.
Evidence: \`bash src/a.sh\` exits 1 with \`\$1: unbound variable\`.
Rung: 4
Fix: a call with no argument prints an empty line and exits 0, in tests/a.test.sh

### 2. Correctness at the argument handling
Claim: a call with no argument exits on an unbound variable.
Evidence: a call with no argument exits 1.
Rung: 4
Fix: a call with no argument prints an empty line and exits 0"
review="$tmp/04-a.review.md"
review_at "$reviewed" "$review" "$act_on"
run "$wt" "$review"
check_lines "a Finding whose files no commit since the Review touched, while another file was changed since, is listed with touched=none" \
  0 "$rc" "finding=1 touched=none"
check_lines "a Finding whose location and Fix target name no file is listed with touched=none" \
  0 "$rc" "finding=2 touched=none"

fresh other-line-touched
wt="$tmp/other-line-touched"
mkdir -p src
printf '#!/usr/bin/env bash\nset -u\necho "$1"\nnoop() { :; }\n' >src/a.sh
commit base
reviewed="$(git rev-parse --short HEAD)"
printf '#!/usr/bin/env bash\nset -u\necho "$1"\nnoop() { echo "noop"; }\n' >src/a.sh
commit "feat: a.sh gains a debug helper"

review="$tmp/13-a.review.md"
review_at "$reviewed" "$review"
run "$wt" "$review"
check_lines "a Finding whose header line no commit since the Review changed, though a commit changed another line of the same file, is listed with touched=none" \
  0 "$rc" "finding=1 touched=none"

fresh fix-target-only
wt="$tmp/fix-target-only"
mkdir -p src tests
printf '#!/usr/bin/env bash\nset -u\necho "$1"\n' >src/a.sh
printf '#!/usr/bin/env bash\nset -u\ntest "$(bash src/a.sh x)" = x\n' >tests/a.test.sh
commit base
reviewed="$(git rev-parse --short HEAD)"
printf '#!/usr/bin/env bash\nset -u\ntest "$(bash src/a.sh x)" = x\ntest "$(bash src/a.sh y)" = y\n' >tests/a.test.sh
commit "test: a.test.sh gains an unrelated passing case"

act_on="### 1. Correctness at src/a.sh:3
Claim: a call with no argument exits on an unbound variable.
Evidence: \`bash src/a.sh\` exits 1 with \`\$1: unbound variable\`.
Rung: 4
Fix: a call with no argument prints an empty line and exits 0, in tests/a.test.sh"
review="$tmp/10-a.review.md"
review_at "$reviewed" "$review" "$act_on"
run "$wt" "$review"
check_lines "a Finding whose location's file no commit since the Review touched is listed with touched=none, though a commit touched its Fix target file" \
  0 "$rc" "finding=1 touched=none"

fresh all-settled
wt="$tmp/all-settled"
mkdir -p src
printf '#!/usr/bin/env bash\nset -u\necho "$1"\n' >src/a.sh
commit base
reviewed="$(git rev-parse --short HEAD)"
printf '#!/usr/bin/env bash\nset -u\necho "${1:-}"\n' >src/a.sh
commit "fix: a.sh reads a missing argument as empty"
fixed="$(git rev-parse --short HEAD)"

act_on="$(for n in 1 2; do
  printf '### %s. Correctness at src/a.sh:3\nClaim: a call with no argument exits on an unbound variable.\n' "$n"
  printf 'Evidence: `bash src/a.sh` exits 1.\nRung: 4\nFix: a call with no argument exits 0, in tests/a.test.sh\n\n'
done)"
fix_runs="## Fix run

Date: 2026-09-23 · at $reviewed

- 1: fixed $fixed, verified (\`bash tests/a.test.sh\`)
- 2: not fixed: the Fixer never returned
- diff tests: \`bash tests/a.test.sh\`: 1 passing
- gate fixer: not needed
- gate: \`bash tests/a.test.sh\`: green
- not landed: a Finding not fixed

## Fix run

Date: 2026-09-24 · at $reviewed

- 2: fixed $fixed, verified (\`bash tests/a.test.sh\`)
- diff tests: \`bash tests/a.test.sh\`: 1 passing
- gate fixer: not needed
- gate: \`bash tests/a.test.sh\`: green
- landed: main"
review="$tmp/05-a.review.md"
review_at "$reviewed" "$review" "$act_on" "$fix_runs"
run "$wt" "$review"
check_absent "a Review whose every Act on Finding is settled by its latest Fix run line lists no Finding and exits 1" \
  1 "$rc" "finding="

review="$tmp/06-a.review.md"
review_at "$reviewed" "$review" "none" ""
run "$wt" "$review"
check_absent "a Review whose Act on reads none lists no Finding and exits 1" \
  1 "$rc" "finding="

fresh unrelated
wt="$tmp/unrelated"
mkdir -p src
printf '#!/usr/bin/env bash\nset -u\necho "$1"\n' >src/a.sh
commit base
reviewed="$(git rev-parse --short HEAD)"
git checkout -q -b side
printf '#!/usr/bin/env bash\nset -u\necho "side: $1"\n' >src/a.sh
commit "feat: a.sh prefixes its line"
side="$(git rev-parse --short HEAD)"
git checkout -q main
printf '#!/usr/bin/env bash\nset -u\necho "${1:-}"\n' >src/a.sh
commit "fix: a.sh reads a missing argument as empty"
fixed="$(git rev-parse HEAD)"

review="$tmp/07-a.review.md"
review_at "$side" "$review"
run "$wt" "$review"
check_lines "a Review whose Commit: is not an ancestor of HEAD lists every unsettled Finding with touched=none and exits 3" \
  3 "$rc" "finding=1 touched=none"

review_at "$reviewed" "$tmp/08-full.review.md"
review="$tmp/08-a.review.md"
grep -v '^Commit: ' "$tmp/08-full.review.md" >"$review"
run "$wt" "$review"
check_lines "a Review with no Commit: header lists every unsettled Finding with touched=none and exits 3" \
  3 "$rc" "finding=1 touched=none"

fresh rebased-fixed
wt="$tmp/rebased-fixed"
mkdir -p src
printf '#!/usr/bin/env bash\nset -u\necho "$1"\n' >src/a.sh
commit base
old_base="$(git rev-parse --short HEAD)"
git checkout -q -b feat
printf '#!/usr/bin/env bash\nset -u\necho "$1" # reviewed\n' >src/a.sh
commit "refactor: a.sh notes it is reviewed"
reviewed="$(git rev-parse --short HEAD)"
printf '#!/usr/bin/env bash\nset -u\necho "${1:-}" # reviewed\n' >src/a.sh
commit "fix: a.sh reads a missing argument as empty"
git checkout -q main
printf 'unrelated\n' >other.txt
commit "chore: the landing target moves"
git checkout -q feat
git rebase -q main
after_rebase_fix="$(git rev-parse HEAD)"

review="$tmp/11-a.review.md"
review_at "$reviewed" "$review" "" "" "$old_base"
run "$wt" "$review"
check_lines "after a rebase off the reviewed Commit:, a Finding whose location a replayed after-review commit touched is listed with that replayed commit" \
  0 "$rc" "finding=1 touched=$after_rebase_fix"

fresh rebased-unfixed
wt="$tmp/rebased-unfixed"
mkdir -p src
printf '#!/usr/bin/env bash\nset -u\necho "$1"\n' >src/a.sh
commit base
old_base="$(git rev-parse --short HEAD)"
git checkout -q -b feat
printf '#!/usr/bin/env bash\nset -u\necho "$1" # reviewed\n' >src/a.sh
commit "refactor: a.sh notes it is reviewed"
reviewed="$(git rev-parse --short HEAD)"
git checkout -q main
printf 'unrelated\n' >other.txt
commit "chore: the landing target moves"
git checkout -q feat
git rebase -q main

review="$tmp/12-a.review.md"
review_at "$reviewed" "$review" "" "" "$old_base"
run "$wt" "$review"
check_lines "after a rebase off the reviewed Commit:, a Finding whose location only a replay of a commit the Review read touched is listed with touched=none" \
  0 "$rc" "finding=1 touched=none"

fresh dirty
wt="$tmp/dirty"
mkdir -p src
printf '#!/usr/bin/env bash\nset -u\necho "$1"\n' >src/a.sh
commit base
reviewed="$(git rev-parse --short HEAD)"
printf '#!/usr/bin/env bash\nset -u\necho "${1:-}"\n' >src/a.sh
commit "fix: a.sh reads a missing argument as empty"

review_at "$reviewed" "$tmp/09-clean.review.md"
review="$tmp/09-a.review.md"
sed "s/^Commit: $reviewed\$/Commit: $reviewed, dirty/" "$tmp/09-clean.review.md" >"$review"
has "the dirty fixture carries a Commit: header with the dirty suffix" "$review" "Commit: $reviewed, dirty"
run "$wt" "$review"
check_lines "a Review whose Commit: carries the dirty suffix names the commit that materialized the reviewed dirty diff, which does not by itself count as a touch" \
  0 "$rc" "finding=1 touched=none"

printf '#!/usr/bin/env bash\nset -u\necho "${1:-}" #\n' >src/a.sh
commit "style: a.sh trails a comment"
later="$(git rev-parse HEAD)"
run "$wt" "$review"
check_lines "a further commit on top of the one that materialized the reviewed dirty diff still counts as a touch" \
  0 "$rc" "finding=1 touched=$later"

echo
if [ "$fails" = 0 ]; then echo "unsettled: all checks passed"; else
  echo "unsettled: $fails failed"
  exit 1
fi
