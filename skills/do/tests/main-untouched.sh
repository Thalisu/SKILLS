#!/usr/bin/env bash
# main-untouched.sh: the contract of scripts/main-untouched.sh, the read of whether the main
# checkout moved since a snapshot, exercised in a throwaway git repository.
# Run: bash skills/do/tests/main-untouched.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/main-untouched.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT
export HOME="$tmp/home"
mkdir -p "$HOME"

run() {
  rc=0
  # shellcheck disable=SC2034  # lib.sh's same reads $out
  out="$(bash "$script" "$@" 2>&1)" || rc=$?
}

fresh main
main="$tmp/main"
printf '.scratch/\n' >.gitignore
echo one >tracked.txt
echo one >other.txt
commit "base"
echo wip >>tracked.txt
echo staged >staged.txt
g add staged.txt
echo untracked >untracked.txt
state="$main/.scratch/main-state/ticket.state"
mkdir -p "$(dirname "$state")"

run snapshot "$main" "$state"
run check "$main" "$state"
same "a check right after a snapshot reads untouched in a checkout that already held uncommitted work" \
  $'verdict=untouched\nchanged=0'
expect "an untouched check exits 0" test "$rc" = 0

echo two >>other.txt
echo created >created.txt
run check "$main" "$state"
same "a check lists each file created or modified after the snapshot and none of the work uncommitted before it" \
  $'verdict=changed\nchanged=2\nfile=created.txt\nfile=other.txt'
expect "a changed check exits 0" test "$rc" = 0

[ "$fails" = 0 ]
