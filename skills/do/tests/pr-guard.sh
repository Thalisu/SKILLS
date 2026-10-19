#!/usr/bin/env bash
# pr-guard.sh: the contract of scripts/pr-guard.sh, which reads each fixer branch of a pr round
# against the tree's HEAD and names every CI workflow, secret or migration file it changes.
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
run "$tmp/guard" 1=fix-1 2=fix-2
check_lines "a branch changing only a plain file prints clean, and one changing a workflow, a secret and a migration prints a touches line naming each with its class: exit 1" \
  1 "$rc" "clean 1" \
  "touches 2 workflow .github/workflows/ci.yml" \
  "touches 2 secret .env" \
  "touches 2 migration db/migrations/0002_add_users.sql"
expect "the plain file a touching branch also changes gets no touches line, so the branch has exactly three" \
  test "$(grep -c '^touches ' <<<"$out")" = 3

exit "$((fails > 0))"
