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
patch_tokens() {                               # stdin one file's patch: its size in tokens at four bytes a token, rounded up, on stdout
  local bytes
  bytes="$(wc -c)"
  echo $(((bytes + 3) / 4))
}
tracked_tokens() { g diff --no-renames "$fixed_point" -- "$1" | patch_tokens; } # $1 a path the fixed point or the index knows
untracked_tokens() { g diff --no-index -- /dev/null "$1" | patch_tokens; }      # $1 a path git does not track
after_header() { sed -n '/^shards=/,$p' <<<"$out" | tail -n +2; }               # the Shard lines and the manifest in $out, on stdout

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

# The manifest is what the orchestrator hands each reviewer: every file of the diff under its Shard,
# sized by its own patch. The two untracked tests have names of one length and contents one byte
# apart, so their patches are one byte apart and at least one of them is not a multiple of four.
repo_at_fixed_point manifest
printf 'export function old() {}\n' >src/old.js
commit "a file the diff deletes"
fixed_point="$(g rev-parse HEAD)"
printf 'export function page(n) { return n; }\n' >src/notes.js
commit "page takes a number"
printf 'export function token(t) { return t; }\n' >src/auth.js
rm src/old.js
printf 'test("token", () => {});\n' >auth.test.js
printf 'test("page", () => {});\n' >page.test.js
printf '# Notes\n' >README.md
readme="$(untracked_tokens README.md)"
auth_test="$(untracked_tokens auth.test.js)"
page_test="$(untracked_tokens page.test.js)"
auth="$(tracked_tokens src/auth.js)"
notes="$(tracked_tokens src/notes.js)"
old="$(tracked_tokens src/old.js)"
run "$fixed_point"
expect "the manifest run exits 0" test "$rc" = 0
out="$(after_header)"
same "names every Shard in the manifest with each file it holds and that file's size in tokens at four bytes a token" \
  "shard=1 tokens=$((readme + auth_test + page_test + auth + notes + old)) files=6
file shard=1 tokens=$readme path=README.md
file shard=1 tokens=$auth_test path=auth.test.js
file shard=1 tokens=$page_test path=page.test.js
file shard=1 tokens=$auth path=src/auth.js
file shard=1 tokens=$notes path=src/notes.js
file shard=1 tokens=$old path=src/old.js"

echo
if [ "$fails" = 0 ]; then echo "all green"; else echo "$fails failing"; fi
exit "$fails"
