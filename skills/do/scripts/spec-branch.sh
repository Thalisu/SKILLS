#!/usr/bin/env bash
# spec-branch.sh: the Spec branch a Ticket of a Spec lands on, spec/<feature-slug>, cut from the
# branch the main checkout is on and remembering that branch as its local upstream. Run from
# anywhere inside the project: the main checkout is the first `git worktree list` entry.
#
#   spec-branch.sh probe <Ticket path>  the Spec branch facts, read-only: its name, whether it
#                                       exists, and the branch the Spec integrates into, read from
#                                       the Spec branch's upstream and never from the checkout's HEAD
#   spec-branch.sh cut <Ticket path>    cut the Spec branch, or reuse the one already there with
#                                       its ref and its upstream untouched; of two first cuts at
#                                       once, git's atomic ref creation lets one cut and the other
#                                       reuses what it cut
#   spec-branch.sh remove <Ticket path> delete the Spec branch once it landed
#
# <Ticket path> is absolute, or relative to the main checkout (the door's ticket= value). The
# feature slug is the name of the folder that holds the Ticket's issues/ folder, as
# .agents/scripts/resolve-feature-folder.sh normalises it.
#
# probe prints three key=value lines, in this order: spec_branch (spec/<feature-slug>, or none for a
# Ticket outside a feature folder's issues/, such as one on a remote tracker), spec_exists (yes or
# no), spec_upstream (empty when the branch is absent or records none).
#
# cut prints key=value lines, in this order: spec_branch, action (cut, reused or refused), upstream
# (the one recorded at the first cut, never the checkout's branch of a later run; empty when
# refused), tip, reason (empty, or with refused: protected or detached, a first cut whose main
# checkout is on a protected branch or on no branch at all, which creates nothing; no-upstream, a
# Spec branch that still records no upstream after a wait of about two seconds, which the cut never
# fills in: `git branch --set-upstream-to=<branch> spec/<feature-slug>` is the developer's fix).
#
# remove prints key=value lines, in this order: spec_branch, action (removed, absent when there is
# no such branch, or refused), then tip with removed, the commit the branch pointed at, and reason
# with refused: no-upstream, a branch that records no upstream to prove its landing against;
# checked-out, a branch a worktree holds or is rebasing. A refusal deletes nothing.
#
# Exit codes: 0 probe printed, or cut or reused, or removed or absent · 1 refused · 2 usage, not a
# git repository, a cut or a remove of a Ticket outside a feature folder's issues/, or a ref
# creation that failed.
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd -P)"
resolver="$here/../../../.agents/scripts/resolve-feature-folder.sh"

usage() { echo "usage: spec-branch.sh probe|cut|remove <Ticket path>" >&2; exit 2; }

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

# A run that finds the ref may have found it between the two git commands of the run that created
# it, the only moment a Spec branch legitimately has no upstream, so it waits that gap out.
wait_upstream() { # $1 main checkout, $2 branch: its upstream after at most 20 polls 0.1 s apart
  local up _
  for _ in $(seq 20); do
    up="$(upstream_of "$1" "$2")"
    [ -z "$up" ] || break
    sleep 0.1
  done
  echo "$up"
}

# A branch still with no upstream after the wait is refused rather than given the upstream this
# run's checkout happens to be on, which would silently retarget the whole Spec.
reuse() { # $1 main checkout, $2 name
  local up tip
  up="$(wait_upstream "$1" "$2")"
  tip="$(git -C "$1" rev-parse --verify -q "refs/heads/$2")"
  if [ -z "$up" ]; then
    record "$2" refused "" "$tip" no-upstream
    exit 1
  fi
  record "$2" reused "$up" "$tip"
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
  if git -C "$main" rev-parse --verify -q "refs/heads/$name" >/dev/null; then
    reuse "$main" "$name"
    return 0
  fi
  # Not --short: a tag named like the branch makes it print heads/<name>.
  dev="$(git -C "$main" symbolic-ref -q HEAD)" && dev="${dev#refs/heads/}" || { record "$name" refused "" "" detached; exit 1; }
  # trivial-door.sh stays the one place in do that decides what is protected.
  (cd "$main" && bash "$here/trivial-door.sh" branch "$dev") >/dev/null
  case "$?" in
    0) ;;
    1) record "$name" refused "" "" protected; exit 1 ;;
    *) echo "trivial-door.sh could not read $dev" >&2; exit 2 ;;
  esac
  tip="$(git -C "$main" rev-parse --verify -q "refs/heads/$dev")"
  # The empty old value makes the creation atomic: of two first runs of one Spec, git lets exactly
  # one create the ref, and the other reuses the branch the winner made.
  if ! git -C "$main" update-ref "refs/heads/$name" "$tip" "" 2>/dev/null; then
    git -C "$main" rev-parse --verify -q "refs/heads/$name" >/dev/null || { echo "could not create $name" >&2; exit 2; }
    reuse "$main" "$name"
    return 0
  fi
  git -C "$main" branch -q --set-upstream-to="$dev" "$name" >/dev/null 2>&1 || { record "$name" refused "" "$tip" no-upstream; exit 1; }
  record "$name" cut "$dev" "$tip"
}

cmd_probe() {
  local main path slug name
  main="$(main_checkout)" || { echo "not a git repository" >&2; exit 2; }
  case "$1" in /*) path="$1" ;; *) path="$main/${1#./}" ;; esac
  slug="$(feature_slug "$path")"
  if [ -z "$slug" ]; then
    printf 'spec_branch=none\nspec_exists=no\nspec_upstream=\n'
    return 0
  fi
  name="spec/$slug"
  echo "spec_branch=$name"
  if git -C "$main" rev-parse --verify -q "refs/heads/$name" >/dev/null; then
    echo "spec_exists=yes"
    echo "spec_upstream=$(upstream_of "$main" "$name")"
  else
    echo "spec_exists=no"
    echo "spec_upstream="
  fi
}

refuse_removal() { # $1 reason
  printf 'action=refused\nreason=%s\n' "$1"
  exit 1
}

cmd_remove() {
  local main path slug name tip up
  main="$(main_checkout)" || { echo "not a git repository" >&2; exit 2; }
  case "$1" in /*) path="$1" ;; *) path="$main/${1#./}" ;; esac
  slug="$(feature_slug "$path")"
  [ -n "$slug" ] || { echo "no feature folder holds $1" >&2; exit 2; }
  name="spec/$slug"
  echo "spec_branch=$name"
  tip="$(git -C "$main" rev-parse --verify -q "refs/heads/$name")" || { echo "action=absent"; return 0; }
  up="$(upstream_of "$main" "$name")"
  [ -n "$up" ] || refuse_removal no-upstream
  # git itself refuses to delete a branch a worktree has checked out or is rebasing.
  git -C "$main" branch -q -D "$name" >/dev/null 2>&1 || refuse_removal checked-out
  echo "action=removed"
  echo "tip=$tip"
}

[ "$#" = 2 ] || usage
case "$1" in
  probe) cmd_probe "$2" ;;
  cut) cmd_cut "$2" ;;
  remove) cmd_remove "$2" ;;
  *) usage ;;
esac
