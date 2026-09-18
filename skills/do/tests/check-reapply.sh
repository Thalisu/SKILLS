#!/usr/bin/env bash
# check-reapply.sh: the contract of scripts/check-reapply.sh, the gate the reapply state of
# mechanics.md's `## The integration` puts between a judge's block and the write the block asks
# for, since the block's `file:` and `blob:` are read off a ledger entry's Incoming side, a
# stranger's diff text a judge only reads.
# Run: bash skills/do/tests/check-reapply.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/check-reapply.sh"
ledgersh="$here/../scripts/ledger.sh"
fails=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

fresh repo
mkdir -p sub
echo hi > sub/f.txt
commit "base: a tracked file the entry below names"
mkdir -p .scratch
ledger="$PWD/.scratch/l.md"

ledger_entry_fixture "$tmp/entry" 1122334455aa sub/f.txt whole-file delete-vs-edit \
  3333333333333333333333333333333333333333 4444444444444444444444444444444444444444 \
  'target text' \
  '(too large, 999 bytes, blob abababababababababababababababababababab, before 4444444444444444444444444444444444444444)'
bash "$ledgersh" put "$ledger" "$tmp/entry" >/dev/null

echo "# check-reapply.sh: a block bound to the entry it answers"

block="$tmp/block-ok"
mkdir -p "$block"
printf '1122334455aa\n' >"$block/id"
printf 'sub/f.txt\n' >"$block/file"
printf 'abababababababababababababababababababab\n' >"$block/blob"
rc=0
bash "$script" "$ledger" "$PWD" "$block" >/dev/null 2>&1 || rc=$?
expect "a block whose file and blob both match the entry is not refused" test "$rc" = 0

echo "# check-reapply.sh: file mismatch"

block="$tmp/block-file-mismatch"
mkdir -p "$block"
printf '1122334455aa\n' >"$block/id"
printf 'sub/other.txt\n' >"$block/file"
rc=0
out="$(bash "$script" "$ledger" "$PWD" "$block" 2>&1)" || rc=$?
check "a block naming a file other than the entry's own - file: line is refused" 1 "$rc" \
  "block names file sub/other.txt, entry 1122334455aa names sub/f.txt"

echo "# check-reapply.sh: path escapes the worktree root"

fresh escape-entry
mkdir -p .scratch
eledger="$PWD/.scratch/l.md"
ledger_entry_fixture "$tmp/entry-escape" 9988776655bb ../../outside.txt whole-file delete-vs-edit \
  3333333333333333333333333333333333333333 4444444444444444444444444444444444444444 \
  'target text' '(deleted)'
bash "$ledgersh" put "$eledger" "$tmp/entry-escape" >/dev/null
block="$tmp/block-escape"
mkdir -p "$block"
printf '9988776655bb\n' >"$block/id"
printf '../../outside.txt\n' >"$block/file"
rc=0
out="$(bash "$script" "$eledger" "$PWD" "$block" 2>&1)" || rc=$?
check "a block whose file resolves outside the worktree root is refused, even matching the entry" \
  1 "$rc" "outside $PWD"

echo "# check-reapply.sh: blob mismatch"

fresh blob-mismatch
mkdir -p sub .scratch
echo hi > sub/f.txt
commit "base"
bledger="$PWD/.scratch/l.md"
ledger_entry_fixture "$tmp/entry-blob" 1122334455aa sub/f.txt whole-file delete-vs-edit \
  3333333333333333333333333333333333333333 4444444444444444444444444444444444444444 \
  'target text' \
  '(too large, 999 bytes, blob abababababababababababababababababababab, before 4444444444444444444444444444444444444444)'
bash "$ledgersh" put "$bledger" "$tmp/entry-blob" >/dev/null
block="$tmp/block-blob-mismatch"
mkdir -p "$block"
printf '1122334455aa\n' >"$block/id"
printf 'sub/f.txt\n' >"$block/file"
printf 'ffffffffffffffffffffffffffffffffffffffff\n' >"$block/blob"
rc=0
out="$(bash "$script" "$bledger" "$PWD" "$block" 2>&1)" || rc=$?
check "a block whose blob is not the sha the entry's Incoming side names is refused" 1 "$rc" \
  "entry 1122334455aa's Incoming side names abababababababababababababababababababab"

echo "# check-reapply.sh: nothing is written on a refusal"

expect "the worktree's tracked file is untouched by any of the refused checks above" \
  cmp -s sub/f.txt <(printf 'hi\n')

echo "# check-reapply.sh: usage"

rc=0
# shellcheck disable=SC2034  # lib.sh's check reads $out
out="$(bash "$script" 2>&1)" || rc=$?
check "one argument is a usage error" 2 "$rc"

echo
[ "$fails" = 0 ] && echo "all passed" || {
  echo "$fails failed"
  exit 1
}
