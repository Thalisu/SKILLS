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

exit "$((fails > 0))"
