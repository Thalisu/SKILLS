#!/usr/bin/env bash
# debt-branch.sh: cuts the Fixers' debt/<slug> branch at the Debt review's Fixed point, in a worktree
# of its own under the main checkout. Run from anywhere.
#
#   debt-branch.sh <slug> <review path>    the Debt review whose `Fixed point:` header names the cut
#
# Prints branch=debt/<slug>, worktree=<main>/.claude/worktrees/debt-<slug>, main=<main checkout>,
# target=<the branch the review recorded in its Fixed point> and tip=<the short sha of that header>.
# The main checkout's HEAD, branch and working tree are never touched, and neither is the developer's
# branch. On a git failure it prints one line=<git's error line> instead.
#
# Exit codes: 0 it cut the branch · 2 usage: not two arguments, a missing review, or a review with no
# Spec: header or no parsable Fixed point: header · 3 git failed, or debt/<slug> or its
# worktree path already exists (one line= says so), nothing cut.
set -uo pipefail

usage() {
  echo "usage: debt-branch.sh <slug> <review path>" >&2
  exit 2
}

[ "$#" -eq 2 ] || usage
slug="$1" review="$2"
[ -f "$review" ] || usage
grep -q '^Spec: ' "$review" || usage
header="$(grep -m1 '^Fixed point: ' "$review")" || usage
tip="$(sed -n 's/^Fixed point: .*(\([^)]*\)).*/\1/p' <<<"$header" | head -n 1)"
target="${header#Fixed point: }"
target="${target%% (*}"
[ -n "$tip" ] && [ -n "$target" ] || usage

dir="$(cd "$(dirname "$review")" && pwd -P)"
common="$(git -C "$dir" rev-parse --path-format=absolute --git-common-dir 2>&1)" || {
  echo "line=$(grep -m1 -E '^(error|fatal):' <<<"$common" || head -n1 <<<"$common")"
  exit 3
}
main="$(dirname "$common")"
full="$(git -C "$main" rev-parse --verify -q "$tip^{commit}" 2>&1)" || {
  echo "line=fatal: Fixed point $tip names no commit"
  exit 3
}

path="$main/.claude/worktrees/debt-$slug"
if git -C "$main" show-ref -q --verify "refs/heads/debt/$slug" || [ -e "$path" ]; then
  echo "line=debt/$slug or its worktree $path already exists; nothing cut"
  exit 3
fi

# The exclude list and never the project's .gitignore: the list is this clone's, and the worktree
# folder would otherwise read as untracked in the main checkout's status.
if ! git -C "$main" check-ignore -q .claude/worktrees/; then
  mkdir -p "$common/info"
  echo ".claude/worktrees/" >>"$common/info/exclude"
fi

if ! said="$(git -C "$main" worktree add -q -b "debt/$slug" "$path" "$full" 2>&1)"; then
  echo "line=$(grep -m1 -E '^(error|fatal):' <<<"$said" || head -n1 <<<"$said")"
  exit 3
fi
echo "branch=debt/$slug"
echo "worktree=$path"
echo "main=$main"
echo "target=$target"
echo "tip=$tip"
