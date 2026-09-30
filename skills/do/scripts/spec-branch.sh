#!/usr/bin/env bash
# spec-branch.sh: the Spec branch a Ticket of a Spec lands on, spec/<feature-slug>, cut from the
# branch the main checkout is on and remembering that branch as its local upstream. Run from
# anywhere inside the project: the main checkout is the first `git worktree list` entry.
#
#   spec-branch.sh cut <Ticket path>    cut the Spec branch, or reuse the one already there with
#                                       its ref and its upstream untouched
#
# <Ticket path> is absolute, or relative to the main checkout (the door's ticket= value). The
# feature slug is the name of the folder that holds the Ticket's issues/ folder, as
# .agents/scripts/resolve-feature-folder.sh normalises it.
#
# cut prints key=value lines, in this order: spec_branch, action (cut or reused), upstream (the
# one recorded at the first cut, never the checkout's branch of a later run), tip, reason.
#
# Exit codes: 0 cut or reused · 2 usage, not a git repository, a Ticket outside a feature folder's issues/,
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

upstream_of() { # $1 main checkout, $2 branch: its upstream, or nothing
  git -C "$1" for-each-ref --format='%(upstream:short)' "refs/heads/$2"
}

record() { # $1 name, $2 action, $3 upstream, $4 tip, $5 reason
  echo "spec_branch=$1"
  echo "action=$2"
  echo "upstream=$3"
  echo "tip=$4"
  echo "reason=${5:-}"
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
  if tip="$(git -C "$main" rev-parse --verify -q "refs/heads/$name")"; then
    record "$name" reused "$(upstream_of "$main" "$name")" "$tip"
    return 0
  fi
  dev="$(git -C "$main" symbolic-ref --short -q HEAD)"
  tip="$(git -C "$main" rev-parse --verify -q "refs/heads/$dev")"
  git -C "$main" update-ref "refs/heads/$name" "$tip" "" 2>/dev/null || { echo "could not create $name" >&2; exit 2; }
  git -C "$main" branch -q --set-upstream-to="$dev" "$name" >/dev/null
  record "$name" cut "$dev" "$tip"
}

[ "$#" = 2 ] || usage
case "$1" in
  cut) cmd_cut "$2" ;;
  *) usage ;;
esac
