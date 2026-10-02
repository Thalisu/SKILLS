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
large_file() {                                                                  # $1 path: a new file of about 60k tokens, its directory made
  # Optional: $2 its rows, about 7.5 tokens each (default: 8000)
  mkdir -p "$(dirname "$1")"
  seq 1 "${2:-8000}" | sed 's/.*/export const row_& = &;/' >"$1"
}
manifest_paths() { sed -n 's/^file shard=[0-9]* tokens=[0-9]* path=//p' <<<"$manifest"; } # the path of every file line of the run in $manifest, one per line and unsorted, on stdout

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

# A Shard is what one reviewer's window has to hold. Five new files of about 60k tokens each, one
# per directory, are twice the budget together while any one of them, and any two, fit in it.
repo_at_fixed_point over-budget
large_files="api/routes.js db/schema.js docs/guide.js jobs/queue.js web/views.js"
for f in $large_files; do large_file "$f"; done
commit "five large files"
diff_tokens=0
for f in $large_files; do diff_tokens=$((diff_tokens + $(tracked_tokens "$f"))); done
run "$fixed_point"
budget="$(term budget)"
expect "the over-budget run exits 0" test "$rc" = 0
expect "the fixture's diff is over the budget the script prints" test "$diff_tokens" -gt "${budget:-$diff_tokens}"
expect "a diff over the budget is cut into more than one Shard" test "$(shard_lines)" -gt 1
expect "every Shard of a diff over the budget is within the budget" \
  test "$(awk -v b="$budget" '/^shard=/ { sub(/^tokens=/, "", $2); if (b == "" || $2 + 0 > b + 0) n++ } END { print n + 0 }' <<<"$out")" = 0
expect "the Shards of a diff over the budget hold the whole diff between them" \
  test "$(awk '/^shard=/ { sub(/^tokens=/, "", $2); sum += $2 } END { print sum + 0 }' <<<"$out")" = "$diff_tokens"

# A file in no Shard lands unreviewed, and a file in two is reviewed twice. The same over-budget diff,
# now holding every kind of path the diff can: a committed edit, a working-tree edit, a deletion, a
# rename (two paths with rename detection off), untracked files at the root and in a new directory,
# paths with a space, and ignored files, which are not part of the diff.
repo_at_fixed_point every-path
printf 'export function old() {}\n' >src/old.js
printf 'export function legacy() {}\n' >src/legacy.js
printf 'build/\n*.log\n' >.gitignore
commit "the files the diff deletes and renames, and the ignore list"
fixed_point="$(g rev-parse HEAD)"
for f in $large_files; do large_file "$f"; done
printf 'export function page(n) { return n; }\n' >src/notes.js
printf '# Release notes\n' >"docs/release notes.md"
commit "five large files, an edit and a path with a space"
printf 'export function token(t) { return t; }\n' >src/auth.js
rm src/old.js
g mv src/legacy.js src/modern.js
printf 'test("page", () => {});\n' >notes.test.js
printf '# Draft\n' >"draft notes.md"
mkdir -p fixtures build
printf '{}\n' >fixtures/sample.json
printf 'bundle();\n' >build/out.js
printf 'trace\n' >debug.log
diff_paths="$({
  g diff --no-renames --name-only "$fixed_point"
  g ls-files --others --exclude-standard
} | LC_ALL=C sort)"
out="$diff_paths"
same "the every-path fixture's diff holds each kind of path and no ignored one" "$(
  LC_ALL=C sort <<'EOF'
api/routes.js
db/schema.js
docs/guide.js
docs/release notes.md
draft notes.md
fixtures/sample.json
jobs/queue.js
notes.test.js
src/auth.js
src/legacy.js
src/modern.js
src/notes.js
src/old.js
web/views.js
EOF
)"
run "$fixed_point"
manifest="$out"
expect "the every-path run exits 0" test "$rc" = 0
expect "the every-path diff is cut into more than one Shard" test "$(shard_lines)" -gt 1
out="$(comm -23 <(printf '%s\n' "$diff_paths") <(manifest_paths | LC_ALL=C sort -u))"
same "places every file of the diff in a Shard, none missing (listed: the files in no Shard)" ""
out="$(manifest_paths | LC_ALL=C sort | uniq -d)"
same "places no file of the diff in two Shards (listed: the files placed twice)" ""
out="$(comm -13 <(printf '%s\n' "$diff_paths") <(manifest_paths | LC_ALL=C sort -u))"
same "places no file the diff does not have (listed: the paths the diff lacks)" ""

# One file can be larger than a reviewer's window on its own. Splitting it leaves a reviewer half a
# file, and adding it to its neighbours overflows a window twice over, so it is the one Shard allowed
# over the budget. Its neighbours in byte order of path sit on both sides of it, in its own directory
# and in others.
repo_at_fixed_point oversized-file
oversized=lib/generated.js
large_file "$oversized" 24000
for f in api/routes.js lib/a.js lib/z.js web/views.js; do
  mkdir -p "$(dirname "$f")"
  printf 'export function handler() {}\n' >"$f"
done
commit "a file larger than the budget, between small ones"
oversized_tokens="$(tracked_tokens "$oversized")"
run "$fixed_point"
manifest="$out"
budget="$(term budget)"
expect "the oversized-file run exits 0" test "$rc" = 0
expect "the fixture's file alone is over the budget the script prints" test "$oversized_tokens" -gt "${budget:-$oversized_tokens}"
out="$(sed -n "s|^file shard=[0-9]* tokens=\([0-9]*\) path=$oversized\$|\1|p" <<<"$manifest")"
same "lists a file larger than the budget once, at the size of its whole patch" "$oversized_tokens"
oversized_shard="$(sed -n "s|^file shard=\([0-9]*\) tokens=[0-9]* path=$oversized\$|\1|p" <<<"$manifest" | head -n 1)"
out="$(grep -E "^(file )?shard=$oversized_shard " <<<"$manifest")"
same "gives a single file larger than the budget a Shard of its own, whole" \
  "shard=$oversized_shard tokens=$oversized_tokens files=1
file shard=$oversized_shard tokens=$oversized_tokens path=$oversized"

echo
if [ "$fails" = 0 ]; then echo "all green"; else echo "$fails failing"; fi
exit "$fails"
