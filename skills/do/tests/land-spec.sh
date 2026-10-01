#!/usr/bin/env bash
# land-spec.sh: the contract of scripts/land-spec.sh, the landing that moves a Spec branch no worktree
# has checked out onto the tip of a Ticket's gated branch and prints the one line the run reports.
# Run: bash skills/do/tests/land-spec.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/land-spec.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

run() {
  rc=0
  # shellcheck disable=SC2034  # lib.sh's check_lines and same read $out
  out="$(cd "$tmp" && bash "$script" "$@" 2>&1)" || rc=$?
}

fresh ff
repo="$tmp/ff"
printf 'base\n' >README.md
commit base
echo ".claude/worktrees/" >>.git/info/exclude
g -C "$repo" branch spec/feature
wt="$(branch_worktree "$repo" ticket)"
printf 'built\n' >"$wt/notes.txt"
g -C "$wt" add -A && g -C "$wt" commit -qm ticket
tip="$(g -C "$wt" rev-parse HEAD)"
run "$repo" spec/feature do/ticket
check_lines "lands a branch its Spec branch is an ancestor of: exit 0 and the landed line" 0 "$rc" "landed $tip"
same "the landed line is the whole output" "landed $tip"
expect "the Spec branch's ref moves to the branch's tip" \
  test "$(g -C "$repo" rev-parse refs/heads/spec/feature)" = "$tip"

# The developer's two files are the ones the Ticket's branch writes too: a landing that went through
# the checkout would have to overwrite them or refuse, so it cannot pass by leaving them alone.
fresh untouched
repo="$tmp/untouched"
printf 'base\n' >README.md
commit base
echo ".claude/worktrees/" >>.git/info/exclude
g -C "$repo" branch spec/feature
wt="$(branch_worktree "$repo" ticket)"
printf 'built\n' >"$wt/README.md"
printf 'built\n' >"$wt/notes.txt"
g -C "$wt" add -A && g -C "$wt" commit -qm ticket
tip="$(g -C "$wt" rev-parse HEAD)"
printf 'left modified\n' >"$repo/README.md"
printf 'left staged\n' >"$repo/notes.txt"
g -C "$repo" add notes.txt
branch_before="$(g -C "$repo" symbolic-ref HEAD)"
tip_before="$(g -C "$repo" rev-parse HEAD)"
status_before="$(g -C "$repo" status --short)"
state_before="$(cd "$repo" && stop_state)"
run "$repo" spec/feature do/ticket
check_lines "lands while the Main checkout holds the developer's uncommitted work: exit 0 and the landed line" 0 "$rc" "landed $tip"
expect "a landing leaves the Main checkout on the branch it was on" \
  test "$(g -C "$repo" symbolic-ref HEAD)" = "$branch_before"
expect "a landing leaves the tip of the Main checkout's branch where it was" \
  test "$(g -C "$repo" rev-parse HEAD)" = "$tip_before"
expect "a landing leaves the Main checkout's git status --short as it was, the modified file and the staged one" \
  test "$(g -C "$repo" status --short)" = "$status_before"
expect "a landing leaves the Main checkout's index and every working file as they were" \
  test "$(cd "$repo" && stop_state)" = "$state_before"

echo
if [ "$fails" = 0 ]; then echo "land-spec: all checks passed"; else
  echo "land-spec: $fails failed"
  exit 1
fi
