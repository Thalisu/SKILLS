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

# Another Ticket landed on the Spec branch after this one forked: its commit is on the Spec branch
# and not on the branch, so moving the ref onto the branch would drop it.
fresh moved
repo="$tmp/moved"
printf 'base\n' >README.md
commit base
echo ".claude/worktrees/" >>.git/info/exclude
g -C "$repo" branch spec/feature
wt="$(branch_worktree "$repo" ticket)"
printf 'built\n' >"$wt/notes.txt"
g -C "$wt" add -A && g -C "$wt" commit -qm ticket
other="$(branch_worktree "$repo" other)"
printf 'landed first\n' >"$other/other.txt"
g -C "$other" add -A && g -C "$other" commit -qm other
g -C "$repo" branch -f spec/feature do/other
spec_tip="$(g -C "$repo" rev-parse refs/heads/spec/feature)"
run "$repo" spec/feature do/ticket
check_lines "a Spec branch holding a commit the branch lacks is not landed on: exit 1 and the moved line naming its tip" 1 "$rc" "moved $spec_tip"
same "the moved line is the whole output" "moved $spec_tip"
expect "a Spec branch holding a commit the branch lacks keeps its ref where it was" \
  test "$(g -C "$repo" rev-parse refs/heads/spec/feature)" = "$spec_tip"

worktree_on() { # $1 main checkout, $2 branch: the path of the worktree git lists on that branch, on stdout
  g -C "$1" worktree list --porcelain |
    awk -v b="branch refs/heads/$2" '/^worktree / { path = substr($0, 10) } $0 == b { print path; exit }'
}

# In both cases the Spec branch is an ancestor of the Ticket's branch, so nothing but the checkout
# stands between the landing and a fast-forward.
fresh linked
repo="$tmp/linked"
printf 'base\n' >README.md
commit base
echo ".claude/worktrees/" >>.git/info/exclude
g -C "$repo" branch spec/feature
g -C "$repo" worktree add -q "$repo/.claude/worktrees/spec" spec/feature
wt="$(branch_worktree "$repo" ticket)"
printf 'built\n' >"$wt/notes.txt"
g -C "$wt" add -A && g -C "$wt" commit -qm ticket
spec_tip="$(g -C "$repo" rev-parse refs/heads/spec/feature)"
holder="$(worktree_on "$repo" spec/feature)"
run "$repo" spec/feature do/ticket
check_lines "a Spec branch checked out in a linked worktree is refused: exit 4 and the checked-out line naming that worktree" 4 "$rc" "checked-out $holder"
expect "a Spec branch checked out in a linked worktree keeps its ref where it was" \
  test "$(g -C "$repo" rev-parse refs/heads/spec/feature)" = "$spec_tip"

fresh switched
repo="$tmp/switched"
printf 'base\n' >README.md
commit base
echo ".claude/worktrees/" >>.git/info/exclude
g -C "$repo" switch -qc spec/feature
wt="$(branch_worktree "$repo" ticket)"
printf 'built\n' >"$wt/notes.txt"
g -C "$wt" add -A && g -C "$wt" commit -qm ticket
spec_tip="$(g -C "$repo" rev-parse refs/heads/spec/feature)"
holder="$(worktree_on "$repo" spec/feature)"
run "$repo" spec/feature do/ticket
check_lines "a Spec branch the Main checkout is switched onto is refused: exit 4 and the checked-out line naming the Main checkout" 4 "$rc" "checked-out $holder"
expect "a Spec branch the Main checkout is switched onto keeps its ref where it was" \
  test "$(g -C "$repo" rev-parse refs/heads/spec/feature)" = "$spec_tip"

# A rebase stopped on a conflict detaches its worktree's HEAD, so git lists that worktree on no
# branch while the rebase still owns the Spec branch and writes its ref when it finishes.
fresh rebasing
repo="$tmp/rebasing"
printf 'base\n' >README.md
commit base
echo ".claude/worktrees/" >>.git/info/exclude
g -C "$repo" switch -qc spec/feature
printf 'spec side\n' >README.md
commit spec
wt="$(branch_worktree "$repo" ticket)"
printf 'built\n' >"$wt/notes.txt"
g -C "$wt" add -A && g -C "$wt" commit -qm ticket
g -C "$repo" switch -q main
printf 'main side\n' >README.md
commit main
g -C "$repo" worktree add -q "$repo/.claude/worktrees/spec" spec/feature
holder="$(cd "$repo/.claude/worktrees/spec" && pwd -P)"
g -C "$holder" rebase main >/dev/null 2>&1
expect "the fixture's worktree is stopped in a rebase of the Spec branch, its HEAD detached" \
  test "$(cat "$(g -C "$holder" rev-parse --path-format=absolute --git-path rebase-merge/head-name 2>/dev/null)" 2>/dev/null) $(g -C "$holder" rev-parse --abbrev-ref HEAD)" = "refs/heads/spec/feature HEAD"
spec_tip="$(g -C "$repo" rev-parse refs/heads/spec/feature)"
run "$repo" spec/feature do/ticket
check_lines "a Spec branch a worktree holds in an open rebase is refused: exit 4 and the checked-out line naming that worktree" 4 "$rc" "checked-out $holder"
expect "a Spec branch a worktree holds in an open rebase keeps its ref where it was" \
  test "$(g -C "$repo" rev-parse refs/heads/spec/feature)" = "$spec_tip"

# The window between one landing's read of the Spec branch and its ref update is a few git calls
# wide, so one round may miss it: each round races a fresh pair on a fresh Spec branch of one
# repository, whose landing lock they all share.
fresh race
repo="$tmp/race"
printf 'base\n' >README.md
commit base
echo ".claude/worktrees/" >>.git/info/exclude
rounds=30
bad=""
for r in $(seq "$rounds"); do
  g -C "$repo" branch "spec/r$r"
  for side in a b; do
    wt="$(branch_worktree "$repo" "r$r$side")"
    printf '%s\n' "$side$r" >"$wt/$side$r.txt"
    g -C "$wt" add -A && g -C "$wt" commit -qm "$side$r"
  done
  tip_a="$(g -C "$repo" rev-parse "refs/heads/do/r${r}a")"
  tip_b="$(g -C "$repo" rev-parse "refs/heads/do/r${r}b")"
  for side in a b; do
    (
      cd "$tmp" && bash "$script" "$repo" "spec/r$r" "do/r$r$side" >"$tmp/r$r$side.out" 2>&1
      echo "$?" >"$tmp/r$r$side.rc"
    ) &
  done
  wait
  ra="$(cat "$tmp/r${r}a.rc") $(cat "$tmp/r${r}a.out")"
  rb="$(cat "$tmp/r${r}b.rc") $(cat "$tmp/r${r}b.out")"
  spec_tip="$(g -C "$repo" rev-parse "refs/heads/spec/r$r")"
  if [ "$ra" = "0 landed $tip_a" ] && [ "$rb" = "1 moved $tip_a" ] && [ "$spec_tip" = "$tip_a" ]; then
    :
  elif [ "$rb" = "0 landed $tip_b" ] && [ "$ra" = "1 moved $tip_b" ] && [ "$spec_tip" = "$tip_b" ]; then
    :
  else
    bad="${bad}round $r: a $tip_a exit $ra | b $tip_b exit $rb | Spec branch $spec_tip"$'\n'
  fi
done
# shellcheck disable=SC2034  # lib.sh's same reads $out
out="${bad%$'\n'}"
same "two landings at once on one Spec branch: one lands its tip, the other reports moved on that tip, the Spec branch ends there" ""

echo
if [ "$fails" = 0 ]; then echo "land-spec: all checks passed"; else
  echo "land-spec: $fails failed"
  exit 1
fi
