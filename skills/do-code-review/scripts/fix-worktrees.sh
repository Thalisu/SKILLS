#!/usr/bin/env bash
# fix-worktrees.sh: the worktree and branch each Fixer of a Wave works and commits in, per ADR 0053.
#
#   fix-worktrees.sh add <reviewed tree> <slug> <at> <wave> <n>...
#
# add cuts one worktree per Finding <n> from the reviewed tree's HEAD, on the branch
# fixer/<slug>/<at>/w<wave>-<n>, at <main checkout>/.claude/worktrees/fixer-<slug>-<at>-w<wave>-<n>,
# where the main checkout is the one the reviewed tree's git common directory belongs to. It prints
# `worktree <n> <abs path> <branch>` per Finding, in argument order. This script owns those names:
# the orchestrator passes back the branches it printed and composes none. It adds `.claude/worktrees/`
# to the main checkout's .git/info/exclude when nothing ignores it yet, once. A branch or a path that
# already exists, an earlier run's leftover, fails the whole call with `failed exists <branch>`
# before anything is made; any other refusal from git prints `failed <git's line>` once the
# worktrees this call made are taken back. Either way no `worktree` line is printed.
#
#   fix-worktrees.sh remove <reviewed tree> <branch>...
#
# remove takes back only what add made: a branch outside the fixer/<slug>/<at>/w<k>-<n> namespace,
# the caller's do/<slug> or fix/<slug> among them, refuses the whole list before anything is touched.
# A Fixer worktree is removed with its branch when its tree is clean and its commit, if it made one,
# is on the reviewed branch by patch, whatever sha the pick gave it: `removed <branch> <path>`. Any
# other is left as it stands, for the developer to read: `kept <branch> <path> dirty tree` or
# `kept <branch> <path> unlanded commit`.
#
# Exit codes: add 0 every worktree created · remove 0 every one removed, 1 some kept · 2 usage ·
# 3 add failed.
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
  local tree="$1" slug="$2" at="$3" wave="$4" common main n branch path
  shift 4
  common="$(git -C "$tree" rev-parse --path-format=absolute --git-common-dir)"
  main="$(dirname "$common")"
  # Every name is checked before the first is made, so a clash leaves nothing of this call behind
  # and never touches what an earlier run left.
  for n in "$@"; do
    branch="fixer/$slug/$at/w$wave-$n"
    path="$main/.claude/worktrees/fixer-$slug-$at-w$wave-$n"
    if git -C "$tree" show-ref -q --verify "refs/heads/$branch" || [ -e "$path" ]; then
      echo "failed exists $branch"
      exit 3
    fi
  done
  # The exclude list and never the project's .gitignore: the list is this clone's, and the fix door
  # measures the main checkout's status, which a worktree folder would otherwise read as untracked.
  if ! git -C "$main" check-ignore -q .claude/worktrees/; then
    mkdir -p "$common/info"
    echo ".claude/worktrees/" >>"$common/info/exclude"
  fi
  local made=() lines=() said pair
  for n in "$@"; do
    branch="fixer/$slug/$at/w$wave-$n"
    path="$main/.claude/worktrees/fixer-$slug-$at-w$wave-$n"
    if ! said="$(git -C "$tree" worktree add -q -b "$branch" "$path" HEAD 2>&1)"; then
      for pair in "${made[@]}"; do
        git -C "$tree" worktree remove --force "${pair#* }" >/dev/null 2>&1
        git -C "$tree" branch -D "${pair%% *}" >/dev/null 2>&1
      done
      echo "failed $(grep -m1 -E '^(error|fatal):' <<<"$said" || head -n1 <<<"$said")"
      exit 3
    fi
    made+=("$branch $path")
    lines+=("worktree $n $path $branch")
  done
  printf '%s\n' "${lines[@]}"
}

worktree_of() { # $1 reviewed tree, $2 branch: the path of the worktree it is checked out in, on stdout
  git -C "$1" worktree list --porcelain | awk -v b="branch refs/heads/$2" '
    /^worktree / { path = substr($0, 10) }
    $0 == b { print path; exit }
  '
}

remove() {
  [ "$#" -ge 2 ] || usage
  local tree="$1" main branch path
  shift
  main="$(dirname "$(git -C "$tree" rev-parse --path-format=absolute --git-common-dir)")"
  declare -A path_of=()
  for branch in "$@"; do
    [[ "$branch" =~ ^fixer/[^/]+/[^/]+/w[0-9]+-[0-9]+$ ]] || usage
    path="$(worktree_of "$tree" "$branch")"
    case "$path" in "$main/.claude/worktrees/"?*) ;; *) usage ;; esac
    path_of[$branch]="$path"
  done
  local verdict=0
  for branch in "$@"; do
    path="${path_of[$branch]}"
    if [ -n "$(git -C "$path" status --porcelain)" ]; then
      echo "kept $branch $path dirty tree"
      verdict=1
      continue
    fi
    if ! landed "$tree" "$branch"; then
      echo "kept $branch $path unlanded commit"
      verdict=1
      continue
    fi
    git -C "$tree" worktree remove "$path" >/dev/null 2>&1
    # The pick gave the commit a new sha, so `branch -d` would refuse a branch landed() just proved
    # is on the reviewed branch; the force is safe only behind that check and the namespace above.
    git -C "$tree" branch -D "$branch" >/dev/null 2>&1
    # git's remove and -D each fail silently above (a locked worktree, most simply): this is what
    # actually decides removed vs kept, so a refusal never gets reported as a success.
    if [ -n "$(worktree_of "$tree" "$branch")" ] || git -C "$tree" show-ref -q --verify "refs/heads/$branch"; then
      echo "kept $branch $path removal refused"
      verdict=1
      continue
    fi
    echo "removed $branch $path"
  done
  return "$verdict"
}

landed() { # $1 reviewed tree, $2 branch: true when every commit of the branch is on the reviewed branch, by patch
  [ -z "$(git -C "$1" cherry HEAD "$2" | grep -v '^-')" ]
}

case "$verb" in
  add) add "$@" ;;
  remove) remove "$@" ;;
  *) usage ;;
esac
