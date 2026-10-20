#!/usr/bin/env bash
# pr-guard.sh: the contract of scripts/pr-guard.sh, which reads each fixer branch of a pr round
# against the commit the run tree was cut at and names every CI workflow, secret or migration file it
# changes.
# Run: bash skills/do/tests/pr-guard.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/pr-guard.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

run() { # $1.. the script's arguments: its stdout in $out, its exit in $rc
  rc=0
  out="$(bash "$script" "$@" 2>/dev/null)" || rc=$?
}

fresh guard
mkdir -p src .github/workflows db/migrations
printf 'base\n' >src/app.js
printf 'on: push\n' >.github/workflows/ci.yml
printf 'TOKEN=base\n' >.env
printf -- '-- base\n' >db/migrations/0002_add_users.sql
commit base
fixer_branch fix-1 src/app.js "fixed"
fixer_branch fix-2 src/app.js "fixed" \
  .github/workflows/ci.yml "on: pull_request" \
  .env "TOKEN=fixed" \
  db/migrations/0002_add_users.sql "-- fixed"
run "$tmp/guard" main 1=fix-1 2=fix-2
check_lines "a branch changing only a plain file prints clean, and one changing a workflow, a secret and a migration prints a touches line naming each with its class: exit 1" \
  1 "$rc" "clean 1" \
  "touches 2 workflow .github/workflows/ci.yml" \
  "touches 2 secret .env" \
  "touches 2 migration db/migrations/0002_add_users.sql"
expect "the plain file a touching branch also changes gets no touches line, so the branch has exactly three" \
  test "$(grep -c '^touches ' <<<"$out")" = 3

fresh guard-ops
mkdir -p .github/workflows db/migrations
printf 'on: push\n' >.github/workflows/ci.yml
printf -- '-- init\n' >db/migrations/0001_init.sql
printf 'KEY\n' >deploy.pem
commit base
g checkout -q -b delete main
g rm -q db/migrations/0001_init.sql
commit delete
g checkout -q -b rename main
mkdir -p docs
g mv .github/workflows/ci.yml docs/ci.yml
commit rename
g checkout -q -b mode main
chmod +x deploy.pem
commit mode
g checkout -q main
run "$tmp/guard-ops" main 1=delete 2=rename 3=mode
check_lines "a branch deleting a migration, one renaming a workflow out of .github/workflows/ and one only changing a secret's mode each print a touches line naming the protected path: exit 1" \
  1 "$rc" "touches 1 migration db/migrations/0001_init.sql" \
  "touches 2 workflow .github/workflows/ci.yml" \
  "touches 3 secret deploy.pem"
absent "the plain path a workflow is renamed to gets no touches line" "docs/ci.yml"

# A fixer steered by a check's log can plant a commit in the run tree itself, and every branch cut
# after it carries that commit: read against the tree's moving HEAD it shows no change, so the
# guard reads against the commit the run tree was cut at.
fresh guard-moved
mkdir -p src .github/workflows
printf 'base\n' >src/app.js
printf 'on: push\n' >.github/workflows/ci.yml
commit base
base_sha="$(g rev-parse HEAD)"
printf 'on: pull_request_target\n' >.github/workflows/ci.yml
commit planted
fixer_branch fix-1 src/app.js "fixed"
run "$tmp/guard-moved" "$base_sha" 1=fix-1
check_lines "a branch cut over a run tree whose HEAD moved by a planted workflow commit prints a touches line for it, read against the commit the tree was cut at: exit 1" \
  1 "$rc" "touches 1 workflow .github/workflows/ci.yml"
run "$tmp/guard-moved" HEAD 1=fix-1
check_lines "the same branch read against the moved HEAD prints clean, which is why HEAD is never the base" \
  0 "$rc" "clean 1"

run "$tmp/guard-moved" 1=fix-1
check "a call without a base is a usage error: exit 2" 2 "$rc"
expect "a call without a base prints nothing on stdout" test -z "$out"
run "$tmp/guard-moved" no-such-base 1=fix-1
check "a base that is no commit is a usage error: exit 2" 2 "$rc"
expect "a base that is no commit prints nothing on stdout" test -z "$out"

exit "$((fails > 0))"
