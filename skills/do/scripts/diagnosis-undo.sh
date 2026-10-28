#!/usr/bin/env bash
# diagnosis-undo.sh: the undo of the worktree and the do/<slug> branch a refused diagnosis run cut,
# decided from the two values the door printed before the cut. Run from the main checkout or any
# directory of the project outside that worktree; every git command runs in the main checkout.
#
#   diagnosis-undo.sh <Ticket path | issue ref> worktree=<path | none> run_branch=<do/<slug> | none>
#
# The door values say what this run cut: worktree=none run_branch=none, the worktree and the
# branch; worktree=none run_branch=do/<slug>, the worktree alone (a start-over); worktree=<path>
# run_branch=do/<slug>, nothing (entered); worktree=<path> run_branch=none is usage.
#
# Prints key=value lines, in this order:
#   start=<spec branch> | start=HEAD     the Spec branch when spec-branch.sh probe prints
#                                        spec_exists=yes, else the main checkout's HEAD
#   ancestry=holds | fails | skipped     whether do/<slug> is an ancestor of the start; skipped
#                                        when this run cut nothing or the branch is gone
#   worktree=removed <path> | worktree=kept <path> <reason> | worktree=absent <path>
#   branch=removed do/<slug> | branch=kept do/<slug> <reason> | branch=absent do/<slug>
# Reasons: entered (the door printed a worktree) · not-cut (the door printed a branch) · ancestry
# (the branch carries a commit its start lacks) · worktree-kept (the worktree stayed, so the delete
# is not tried) · git: <git's first error line>.
#
# The ancestry check gates every removal. The worktree is removed with `git worktree remove` and
# never --force, then the branch with `git branch -d` and never -D, only when the worktree was
# removed and this run cut the branch. Nothing is retried.
#
# Exit codes: 0 both removed · 1 anything kept · 2 usage, a missing or malformed argument, the
# invalid pair, a door worktree that is not the Ticket's worktree path, or not a git repository ·
# 3 the working directory is inside the worktree, nothing touched.
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd -P)"
# shellcheck source=skills/do/scripts/ticket-read.sh
. "$here/ticket-read.sh"

usage() {
  echo "usage: diagnosis-undo.sh <the Ticket's path, or its issue reference> worktree=<path|none> run_branch=<do/<slug>|none>" >&2
  exit 2
}
[ "$#" = 3 ] || usage
case "$2" in worktree=?*) door_wt="${2#worktree=}" ;; *) usage ;; esac
case "$3" in run_branch=?*) door_branch="${3#run_branch=}" ;; *) usage ;; esac

main="$(main_of .)"
[ -n "$main" ] || {
  echo "not a git repository" >&2
  exit 2
}

case "$1" in
  /*) path="$1" ;;
  *) if [ -f "$1" ]; then path="$(pwd -P)/${1#./}"; else path="$main/${1#./}"; fi ;;
esac
if [ -f "$path" ]; then
  slug="$(basename "$path" .md)"
  slug="$(sed -E 's/^[0-9]+-//' <<<"$slug")"
else
  case "${1#\#}" in
    '' | *[!0-9]*)
      echo "no Ticket at $1" >&2
      exit 2
      ;;
    *) slug="${1#\#}" ;;
  esac
fi
wt="$main/.claude/worktrees/do-$slug"
branch="do/$slug"

[ "$door_wt" = none ] || [ "$door_wt" = "$wt" ] || {
  echo "worktree=$door_wt is not the Ticket's worktree $wt" >&2
  exit 2
}
[ "$door_branch" = none ] || [ "$door_branch" = "$branch" ] || {
  echo "run_branch=$door_branch is not the Ticket's branch $branch" >&2
  exit 2
}
[ "$door_wt" = none ] || [ "$door_branch" != none ] || {
  echo "the door printed a worktree with no run branch: nothing a run cuts reads that way" >&2
  exit 2
}

here_now="$(pwd -P)"
case "$here_now/" in "$wt"/*)
  echo "the working directory $here_now is inside $wt: cd to the main checkout first" >&2
  exit 3
  ;;
esac

spec="$(bash "$here/spec-branch.sh" probe "$path" 2>/dev/null)"
if grep -qx 'spec_exists=yes' <<<"$spec"; then
  start="$(sed -n 's/^spec_branch=//p' <<<"$spec")"
  start_ref="refs/heads/$start"
else
  start=HEAD
  start_ref=HEAD
fi
echo "start=$start"

listed=0
git -C "$main" worktree list --porcelain | grep -xF -- "worktree $wt" >/dev/null && listed=1
has_branch=0
git -C "$main" show-ref --verify --quiet "refs/heads/$branch" && has_branch=1

if [ "$door_wt" != none ] || [ "$has_branch" = 0 ]; then
  echo "ancestry=skipped"
elif git -C "$main" merge-base --is-ancestor "refs/heads/$branch" "$start_ref" 2>/dev/null; then
  echo "ancestry=holds"
else
  echo "ancestry=fails"
  [ "$listed" = 1 ] && echo "worktree=kept $wt ancestry" || echo "worktree=absent $wt"
  echo "branch=kept $branch ancestry"
  exit 1
fi

kept=0
wt_gone=0
if [ "$listed" = 0 ]; then
  echo "worktree=absent $wt"
  wt_gone=1
elif [ "$door_wt" != none ]; then
  echo "worktree=kept $wt entered"
  kept=1
elif err="$(git -C "$main" worktree remove "$wt" 2>&1)"; then
  echo "worktree=removed $wt"
  wt_gone=1
else
  echo "worktree=kept $wt git: $(head -1 <<<"$err")"
  kept=1
fi

if [ "$has_branch" = 0 ]; then
  echo "branch=absent $branch"
elif [ "$door_wt" != none ]; then
  echo "branch=kept $branch entered"
  kept=1
elif [ "$door_branch" != none ]; then
  echo "branch=kept $branch not-cut"
  kept=1
elif [ "$wt_gone" = 0 ]; then
  echo "branch=kept $branch worktree-kept"
  kept=1
elif err="$(git -C "$main" branch -d "$branch" 2>&1)"; then
  echo "branch=removed $branch"
else
  echo "branch=kept $branch git: $(head -1 <<<"$err")"
  kept=1
fi
exit "$kept"
