#!/usr/bin/env bash
# fix-worktrees.sh: the worktree and branch each Fixer of a Wave works and commits in, per ADR 0053.
#
#   fix-worktrees.sh add <reviewed tree> <slug> <at> <wave> <n>...
#
# add cuts one worktree per Finding <n> from the reviewed tree's HEAD, on the branch
# fixer/<slug>/<at>/w<wave>-<n>, at <main checkout>/.claude/worktrees/fixer-<slug>-<at>-w<wave>-<n>,
# where the main checkout is the one the reviewed tree's git common directory belongs to. It prints
# `worktree <n> <abs path> <branch>` per Finding, in argument order. This script owns those names:
# the orchestrator passes back the branches it printed and composes none.
#
#   fix-worktrees.sh remove <reviewed tree> <branch>...
#
# remove takes back only what add made: a branch outside the fixer/<slug>/<at>/w<k>-<n> namespace,
# the caller's do/<slug> or fix/<slug> among them, refuses the whole list before anything is touched.
#
# Exit codes: 0 every worktree created · 2 usage.
set -uo pipefail

usage() {
  echo "usage: fix-worktrees.sh add <reviewed tree> <slug> <at> <wave> <n>..." >&2
  echo "usage: fix-worktrees.sh remove <reviewed tree> <branch>..." >&2
  exit 2
}
[ "$#" -ge 1 ] || usage
verb="$1"
shift

add() {
  [ "$#" -ge 5 ] || usage
  local tree="$1" slug="$2" at="$3" wave="$4" main n branch path
  shift 4
  main="$(dirname "$(git -C "$tree" rev-parse --path-format=absolute --git-common-dir)")"
  for n in "$@"; do
    branch="fixer/$slug/$at/w$wave-$n"
    path="$main/.claude/worktrees/fixer-$slug-$at-w$wave-$n"
    git -C "$tree" worktree add -q -b "$branch" "$path" HEAD >/dev/null 2>&1
    echo "worktree $n $path $branch"
  done
}

remove() {
  [ "$#" -ge 2 ] || usage
  local branch
  shift
  for branch in "$@"; do
    [[ "$branch" =~ ^fixer/[^/]+/[^/]+/w[0-9]+-[0-9]+$ ]] || usage
  done
}

case "$verb" in
  add) add "$@" ;;
  remove) remove "$@" ;;
  *) usage ;;
esac
