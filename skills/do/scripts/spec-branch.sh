#!/usr/bin/env bash
# spec-branch.sh: the Spec branch a Ticket of a Spec lands on, spec/<feature-slug>, cut from the
# branch the main checkout is on and remembering that branch as its local upstream. Run from
# anywhere inside the project: the main checkout is the first `git worktree list` entry.
#
#   spec-branch.sh cut <Ticket path>    cut the Spec branch, or reuse the one already there
#
# <Ticket path> is absolute, or relative to the main checkout (the door's ticket= value). The
# feature slug is the name of the folder that holds the Ticket's issues/ folder, as
# .agents/scripts/resolve-feature-folder.sh normalises it.
#
# cut prints key=value lines, in this order: spec_branch, action (cut), upstream, tip, reason.
#
# Exit codes: 0 cut · 2 usage, not a git repository, a Ticket outside a feature folder's issues/,
# or a ref creation that failed.
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd -P)"
resolver="$here/../../../.agents/scripts/resolve-feature-folder.sh"

usage() { echo "usage: spec-branch.sh cut <Ticket path>" >&2; exit 2; }

main_checkout() {
  local top main
  top="$(git rev-parse --show-toplevel 2>/dev/null)" || return 1
  # A bare main worktree has no working tree to anchor on, and git lists it first all the same.
  main="$(git worktree list --porcelain 2>/dev/null |
    awk '/^$/ { exit } /^worktree /{ p = substr($0, 10) } /^bare$/ { p = "" } END { print p }')"
  [ -n "$main" ] && [ -d "$main" ] || main="$top"
  echo "$main"
}

feature_slug() { # $1 the Ticket's absolute path: the normalised feature slug, or nothing
  local issues folder
  issues="$(dirname "$1")"
  [ "$(basename "$issues")" = issues ] || return 0
  folder="$(basename "$(dirname "$issues")")"
  bash "$resolver" "$folder" 2>/dev/null | sed -n 's/^slug=//p'
}

cmd_cut() {
  local main path slug name dev tip
  main="$(main_checkout)" || { echo "not a git repository" >&2; exit 2; }
  case "$1" in /*) path="$1" ;; *) path="$main/${1#./}" ;; esac
  slug="$(feature_slug "$path")"
  [ -n "$slug" ] || { echo "no feature folder holds $1" >&2; exit 2; }
  name="spec/$slug"
  dev="$(git -C "$main" symbolic-ref --short -q HEAD)"
  tip="$(git -C "$main" rev-parse --verify -q "refs/heads/$dev")"
  git -C "$main" update-ref "refs/heads/$name" "$tip" "" 2>/dev/null || { echo "could not create $name" >&2; exit 2; }
  git -C "$main" branch -q --set-upstream-to="$dev" "$name" >/dev/null
  echo "spec_branch=$name"
  echo "action=cut"
  echo "upstream=$dev"
  echo "tip=$tip"
  echo "reason="
}

[ "$#" = 2 ] || usage
case "$1" in
  cut) cmd_cut "$2" ;;
  *) usage ;;
esac
