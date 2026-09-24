#!/usr/bin/env bash
# fix-worktrees.sh: the contract of scripts/fix-worktrees.sh, which gives each Fixer of a wave its
# own worktree and branch, cut from the reviewed tree's HEAD, and prints where each one is.
# Run: bash skills/do-code-review/tests/fix-worktrees.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/fix-worktrees.sh"
fails=0
tmp="$(cd "$(mktemp -d)" && pwd -P)"
trap 'cd /; rm -rf "$tmp"' EXIT

git() { g "$@"; }
run() {
  rc=0
  # shellcheck disable=SC2034  # lib.sh's check_lines reads $out
  out="$(cd "$tmp" && bash "$script" "$@" 2>&1)" || rc=$?
}
branch_of_worktree() { # $1 main checkout, $2 worktree path: the branch git lists that worktree on, on stdout
  git -C "$1" worktree list --porcelain | awk -v wt="worktree $2" '$0 == wt { on = 1; next } on && /^branch / { print $2; exit } /^$/ { on = 0 }'
}

fresh add
main="$tmp/add"
printf 'base\n' >README.md
commit base
reviewed="$(branch_worktree "$main" x)"
printf 'reviewed\n' >"$reviewed/notes.txt"
git -C "$reviewed" add -A && git -C "$reviewed" commit -qm notes
head="$(git -C "$reviewed" rev-parse HEAD)"
wt3="$main/.claude/worktrees/fixer-x-r1-w2-3"
wt1="$main/.claude/worktrees/fixer-x-r1-w2-1"
run add "$reviewed" x r1 2 3 1
check_lines "each Finding of the wave gets its own worktree and branch beside the reviewed tree under the main checkout: exit 0" \
  0 "$rc" "worktree 3 $wt3 fixer/x/r1/w2-3" "worktree 1 $wt1 fixer/x/r1/w2-1"
expect "the worktree lines come in argument order" \
  test "$(grep '^worktree ' <<<"$out")" = "worktree 3 $wt3 fixer/x/r1/w2-3
worktree 1 $wt1 fixer/x/r1/w2-1"
for n in 3 1; do
  wt="$main/.claude/worktrees/fixer-x-r1-w2-$n"
  expect "Finding $n's path is a worktree git lists on its own branch" \
    test "$(branch_of_worktree "$main" "$wt")" = "refs/heads/fixer/x/r1/w2-$n"
  expect "Finding $n's worktree starts at the reviewed tree's HEAD, not the main checkout's" \
    test "$(git -C "$wt" rev-parse HEAD 2>/dev/null)" = "$head"
done

echo
if [ "$fails" = 0 ]; then echo "fix-worktrees: all checks passed"; else
  echo "fix-worktrees: $fails failed"
  exit 1
fi
