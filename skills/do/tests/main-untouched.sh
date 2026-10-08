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

fresh redirtied
redirtied="$tmp/redirtied"
printf '.scratch/\n' >.gitignore
echo one >tracked.txt
echo one >kept-tracked.txt
commit "base"
echo wip >>tracked.txt
echo wip >>kept-tracked.txt
echo staged >staged.txt
echo staged >kept-staged.txt
g add staged.txt kept-staged.txt
echo untracked >untracked.txt
echo untracked >kept-untracked.txt
redirtied_state="$redirtied/.scratch/main-state/ticket.state"
mkdir -p "$(dirname "$redirtied_state")"

run snapshot "$redirtied" "$redirtied_state"
echo again >>tracked.txt
echo again >>staged.txt
echo again >>untracked.txt
run check "$redirtied" "$redirtied_state"
same "a file already uncommitted before the snapshot and edited again after it is listed as changed, and one left alone is not" \
  $'verdict=changed\nchanged=3\nfile=staged.txt\nfile=tracked.txt\nfile=untracked.txt'

fresh own-work
own_work="$tmp/own-work"
printf '.scratch/\n' >.gitignore
echo one >tracked.txt
commit "base"
own_work_state="$own_work/.scratch/main-state/ticket.state"
mkdir -p "$(dirname "$own_work_state")"
standing="$(branch_worktree "$own_work" standing)"

run snapshot "$own_work" "$own_work_state"
echo screen >"$standing/screen.html"
echo two >>"$standing/tracked.txt"
recut="$(branch_worktree "$own_work" recut)"
echo screen >"$recut/screen.html"
echo two >>"$recut/tracked.txt"
echo ticket >"$own_work/.scratch/ticket.md"
run check "$own_work" "$own_work_state"
same "files written in a worktree under .claude/worktrees/, standing at the snapshot or cut after it, and files git ignores are never listed" \
  $'verdict=untouched\nchanged=0'

[ "$fails" = 0 ]
