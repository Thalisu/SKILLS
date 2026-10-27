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

# fix-integrate.sh --compose refuses the whole Wave over one branch of a shape it cannot pick, so
# the guard fails that check alone and keeps the clean checks of the same call clean.
fresh guard-shape
mkdir -p src
printf 'base\n' >src/app.js
commit base
fixer_branch fix-1 src/app.js "fixed"
fixer_branch fix-2 src/app.js "fixed"
g checkout -q fix-2
printf 'more\n' >src/more.js
commit "fix-2 second"
g checkout -q main
run "$tmp/guard-shape" main 1=fix-1 2=fix-2
check_lines "a branch two commits ahead whose first commit is no chore(e2e) compose prints a failed line, and a one-commit branch in the same call still prints clean: exit 1" \
  1 "$rc" "clean 1"
expect "the two-commit branch's line opens failed 2:" grep -q '^failed 2: ' <<<"$out"

# The Reply tells the developer the chore(e2e) commit can be dropped unread, so fix-integrate.sh
# --compose refuses one holding a file not named like a compose, and with it the whole Wave.
fresh guard-compose-name
mkdir -p src
printf 'base\n' >src/app.js
commit base
compose_pair fix-1 src/app.js "fixed"
compose_path=docker/e2e-stack.yml compose_pair fix-2 src/app.js "fixed"
run "$tmp/guard-compose-name" main 1=fix-1 2=fix-2
check_lines "a compose-then-fix branch whose chore(e2e) commit changes a file not named like a compose prints a failed line, and a pair whose chore(e2e) commit adds only a compose still prints clean: exit 1" \
  1 "$rc" "clean 1"
expect "the branch whose chore(e2e) commit holds a non-compose file has a line opening failed 2:" grep -q '^failed 2: ' <<<"$out"

# fix-integrate.sh --compose refuses a one-commit branch whose parent is not the tree's HEAD, and
# with it the whole Wave, even when HEAD..branch counts one.
fresh guard-stale
mkdir -p src
printf 'base\n' >src/app.js
commit base
cut_sha="$(g rev-parse HEAD)"
fixer_branch fix-1 src/app.js "fixed"
printf 'advance\n' >src/other.js
commit advance
fixer_branch fix-2 src/app.js "fixed"
for stale_base in cut HEAD; do
  base_arg="$cut_sha"
  [ "$stale_base" = HEAD ] && base_arg=HEAD
  run "$tmp/guard-stale" "$base_arg" 1=fix-1 2=fix-2
  check_lines "base $stale_base: a branch one commit ahead whose parent is an earlier commit than the tree's HEAD prints a failed line, and a branch cut on HEAD in the same call still prints clean: exit 1" \
    1 "$rc" "clean 2"
  expect "base $stale_base: the branch cut before HEAD advanced has a line opening failed 1:" grep -q '^failed 1: ' <<<"$out"
done

# A symlink compose can point anywhere, so fix-integrate.sh --compose refuses a chore(e2e) commit
# making a compose path one, and with it the whole Wave.
fresh guard-compose-link
mkdir -p src
printf 'base\n' >src/app.js
commit base
compose_pair fix-1 src/app.js "fixed"
compose_link=/etc/passwd compose_pair fix-2 src/app.js "fixed"
run "$tmp/guard-compose-link" main 1=fix-1 2=fix-2
check_lines "a compose-then-fix branch whose compose is a symlink prints a failed line, and a pair whose compose is a regular file still prints clean: exit 1" \
  1 "$rc" "clean 1"
expect "the branch whose chore(e2e) commit makes the compose a symlink has a line opening failed 2:" grep -q '^failed 2: ' <<<"$out"

run "$tmp/guard-moved" 1=fix-1
check "a call without a base is a usage error: exit 2" 2 "$rc"
expect "a call without a base prints nothing on stdout" test -z "$out"
run "$tmp/guard-moved" no-such-base 1=fix-1
check "a base that is no commit is a usage error: exit 2" 2 "$rc"
expect "a base that is no commit prints nothing on stdout" test -z "$out"

exit "$((fails > 0))"
