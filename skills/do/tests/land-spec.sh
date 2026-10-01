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

echo
if [ "$fails" = 0 ]; then echo "land-spec: all checks passed"; else
  echo "land-spec: $fails failed"
  exit 1
fi
