#!/usr/bin/env bash
# write-blob.sh: the contract of scripts/write-blob.sh, the whole-side reapply write the reapply
# state of conflict-loop.md's `## The conflict loop` calls on a block carrying `take the Incoming blob
# whole`, exercised on a symlink stop a rebase can leave at the path.
# Run: bash skills/do/tests/write-blob.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/write-blob.sh"
fails=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "# write-blob.sh: the symlink stop the Evidence describes"

printf 'base\000binary\n' > "$tmp/base.bin"
printf 'outside-original\000\n' > "$tmp/outside-original.bin"
printf 'run edit\000bytes\n' > "$tmp/incoming.bin"

fresh repo
cp "$tmp/base.bin" data.bin
commit "base: a real binary file"

outside="$tmp/outside.bin"
cp "$tmp/outside-original.bin" "$outside"
rm -f data.bin
ln -s "$outside" data.bin
commit "target: data.bin turned into a symlink out of the repository"

incoming_sha="$(git hash-object -w -- "$tmp/incoming.bin")"

# The redirect conflict-loop.md wrote before this fix: it follows the symlink still at data.bin and
# lands the run's bytes outside the worktree, leaving the symlink, and so the index, untouched.
git cat-file blob "$incoming_sha" > data.bin
expect "the redirect wrote the run's bytes to the file outside the worktree, not to the tracked path" \
  cmp -s "$outside" "$tmp/incoming.bin"
expect "the symlink at data.bin survived the redirect unchanged" test -L data.bin
rc=0
git add -- data.bin || rc=$?
staged=1
git diff --cached --quiet HEAD || staged=0
expect "with nothing tying a block to a path, the redirect's write leaves the index unchanged: no commit, applied would read none" \
  bash -c 'test "$1" = 1' _ "$staged"

# Reset the stop back to the symlink and put the outside file back the way a fresh stop would find
# it, so the fix is proven from the same starting point, not from the damage the redirect just did.
git reset --hard -q HEAD
cp "$tmp/outside-original.bin" "$outside"

echo "# write-blob.sh: the fix, through the index"

rc=0
out="$(bash "$script" data.bin "$incoming_sha" 2>&1)" || rc=$?
check "the script exits 0 once the blob is staged and checked out" 0 "$rc"

expect "the outside file is left exactly as the symlink stop found it" \
  cmp -s "$outside" "$tmp/outside-original.bin"
expect "data.bin in the worktree is no longer a symlink" bash -c '[ ! -L data.bin ]'
expect "data.bin in the worktree now holds the blob's bytes" cmp -s data.bin "$tmp/incoming.bin"
staged=0
git diff --cached --quiet HEAD || staged=1
expect "the index now differs from HEAD, so the reapply commit this entry is owed can be made" \
  bash -c 'test "$1" = 1' _ "$staged"

echo "# write-blob.sh: usage"

rc=0
# shellcheck disable=SC2034  # lib.sh's check reads $out
out="$(bash "$script" 2>&1)" || rc=$?
check "one argument is a usage error" 2 "$rc"

echo
[ "$fails" = 0 ] && echo "all passed" || {
  echo "$fails failed"
  exit 1
}
