#!/usr/bin/env bash
# shards.sh: the contract of scripts/shards.sh, the Shards the review forks its reviewers on, cut
# from the diff between a fixed point and the working tree, in throwaway git repositories.
# Run: bash skills/do-code-review/tests/shards.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/shards.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

run() { # $1.. the script's arguments, from $PWD: its stdout in $out, its stderr in $err, its exit in $rc
  rc=0
  out="$(bash "$script" "$@" 2>"$tmp/stderr")" || rc=$?
  # shellcheck disable=SC2034  # read by a case that asserts on a refusal
  err="$(cat "$tmp/stderr")"
}
repo_at_fixed_point() { # $1 name: a new repository at $tmp/<name>, entered, with one commit; its full sha in $fixed_point
  fresh "$1"
  mkdir -p src
  printf 'export function page() {}\n' >src/notes.js
  printf 'export function token() {}\n' >src/auth.js
  commit "fixed point"
  fixed_point="$(g rev-parse HEAD)"
}
shard_lines() { grep -c '^shard=' <<<"$out"; } # how many Shards the manifest in $out lists, on stdout

# A few small files changed since the fixed point (one committed, one edited in the working tree,
# one untracked) are far under the budget: one reviewer reads them all.
repo_at_fixed_point under-budget
printf 'export function page(n) { return n; }\n' >src/notes.js
commit "page takes a number"
printf 'export function token(t) { return t; }\n' >src/auth.js
printf 'test("page", () => {});\n' >notes.test.js
run "$fixed_point"
check_lines "a diff under the budget is one Shard" 0 "$rc" "shards=1"
expect "a diff under the budget lists exactly one Shard line" test "$(shard_lines)" = 1

echo
if [ "$fails" = 0 ]; then echo "all green"; else echo "$fails failing"; fi
exit "$fails"
