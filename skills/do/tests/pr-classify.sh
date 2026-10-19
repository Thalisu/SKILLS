#!/usr/bin/env bash
# pr-classify.sh: the contract of scripts/pr-classify.sh, which reads each red check of a pr round
# against the pull request's diff from the merge base with its base branch, and calls a check stale
# when every file it names is outside that diff.
# Run: bash skills/do/tests/pr-classify.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/pr-classify.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

run() { # $1.. the script's arguments, its stdin the caller's: its stdout in $out, its exit in $rc
  rc=0
  # shellcheck disable=SC2034 # $out is read by lib.sh's check_lines and absent
  out="$(bash "$script" "$@" 2>/dev/null)" || rc=$?
}

fresh seed
mkdir -p src tests/e2e
printf 'base\n' >src/app.js
printf 'test("login")\n' >tests/e2e/login.spec.ts
commit base
g clone -q --bare "$tmp/seed" "$tmp/origin.git"
g clone -q "$tmp/origin.git" "$tmp/tree"
cd "$tmp/tree" || exit 1
g config gc.auto 0
g config maintenance.auto false
g checkout -q -b head main
printf 'changed\n' >src/app.js
commit head
run "$tmp/tree" main <<<$'1\ttests/e2e/login.spec.ts\n2\tsrc/app.js'
check_lines "a check naming only a file the pull request leaves untouched prints stale with that file, and one naming a file it changes prints real: exit 0" \
  0 "$rc" "stale 1 tests/e2e/login.spec.ts" "real 2"
absent "the check naming the untouched file is not read as real" "real 1"
absent "the check naming the changed file is not read as stale" "stale 2"

run "$tmp/tree" main <<<$'1\t\n2\tsrc/app.js tests/e2e/login.spec.ts'
check_lines "a check naming no file, and one naming a changed file beside an untouched one, both print real: exit 0" \
  0 "$rc" "real 1" "real 2"
absent "neither the check naming no file nor the mixed check is read as stale" "stale "

fresh moved
mkdir -p src lib
printf 'a\n' >src/a.js
printf 'export const old = 1;\nexport const kept = 2;\n' >src/old.js
printf 'gone\n' >src/gone.js
printf 'base\n' >lib/base.js
commit base
g checkout -q -b head main
g mv src/old.js src/new.js
commit rename
g rm -q src/gone.js
commit delete
g checkout -q main
printf 'base moved on\n' >lib/base.js
commit "base after the cut"
g checkout -q head
g clone -q --bare "$tmp/moved" "$tmp/moved-origin.git"
g remote add origin "$tmp/moved-origin.git"
run "$tmp/moved" main <<<$'1\tlib/base.js\n2\tsrc/old.js\n3\tsrc/gone.js'
check_lines "a file only the base changed after the cut reads stale, and the path the head renamed away and a file it deleted read real: exit 0" \
  0 "$rc" "stale 1 lib/base.js" "real 2" "real 3"
absent "the file only the base changed is not read as the pull request's" "real 1"
absent "the path the head renamed away is not read as untouched" "stale 2"
absent "the file the head deleted is not read as untouched" "stale 3"

fresh fetched-seed
mkdir -p src lib
printf 'base\n' >src/app.js
printf 'base\n' >lib/base.js
commit base
g clone -q --bare "$tmp/fetched-seed" "$tmp/fetched-origin.git"
g clone -q "$tmp/fetched-origin.git" "$tmp/fetched-tree"
g -C "$tmp/fetched-tree" config gc.auto 0
g -C "$tmp/fetched-tree" config maintenance.auto false
g clone -q "$tmp/fetched-origin.git" "$tmp/fetched-pusher"
cd "$tmp/fetched-pusher" || exit 1
g config gc.auto 0
g config maintenance.auto false
printf 'base moved on\n' >lib/base.js
commit "base after the clone"
g push -q origin main
g checkout -q -b head main
printf 'changed\n' >src/app.js
commit head
g push -q origin head
cd "$tmp/fetched-tree" || exit 1
g fetch -q origin head
g checkout -q --detach FETCH_HEAD
origin_tip="$(git --git-dir="$tmp/fetched-origin.git" rev-parse main)"
run "$tmp/fetched-tree" main <<<$'1\tlib/base.js\n2\tsrc/app.js'
check_lines "with the clone's main left behind origin's, base= names origin's tip, a file only that later base commit changed reads stale, and the head's own change reads real: exit 0" \
  0 "$rc" "base=$origin_tip" "stale 1 lib/base.js" "real 2"
absent "the file only origin's later base commit changed is not read as the pull request's" "real 1"

fresh unread-seed
mkdir -p src tests/e2e
printf 'base\n' >src/app.js
printf 'test("login")\n' >tests/e2e/login.spec.ts
commit base
g checkout -q --orphan other
g rm -rqf .
printf 'unrelated\n' >other.txt
commit "unrelated history"
g checkout -q main
g clone -q --bare "$tmp/unread-seed" "$tmp/unread-origin.git"
g clone -q "$tmp/unread-origin.git" "$tmp/unread-tree"
cd "$tmp/unread-tree" || exit 1
g config gc.auto 0
g config maintenance.auto false
g checkout -q -b head main
printf 'changed\n' >src/app.js
commit head
run "$tmp/unread-tree" nope <<<$'1\ttests/e2e/login.spec.ts\n2\t'
check_lines "a base origin does not have prints failed naming it, and every check reads real, the one naming an untouched file too: exit 1" \
  1 "$rc" "failed: base nope not fetched from origin" "real 1" "real 2"
same "on an unfetched base the failed line comes first, then one real line per check in input order, with no stale, base= or merge-base= line" \
  $'failed: base nope not fetched from origin\nreal 1\nreal 2'

run "$tmp/unread-tree" other <<<$'1\ttests/e2e/login.spec.ts\n2\t'
check_lines "a base sharing no history with HEAD prints failed naming the missing merge base, and every check reads real: exit 1" \
  1 "$rc" "failed: no merge base of other and HEAD" "real 1" "real 2"
same "with no merge base the failed line comes first, then one real line per check in input order, with no stale, base= or merge-base= line" \
  $'failed: no merge base of other and HEAD\nreal 1\nreal 2'

exit "$((fails > 0))"
