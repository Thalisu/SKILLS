#!/usr/bin/env bash
# integrate-door.sh: the door checks of the integrate Playbook of do that a script can observe, so a
# reviewer can rerun them. Run from anywhere inside the project.
#
#   integrate-door.sh rebase <onto> [<moves>]   <moves> rebased onto <onto>; <moves> defaults to the
#                                               current branch, and is the branch written to
#   integrate-door.sh merge <moves> [<onto>]    <moves> merged into <onto>; <onto> defaults to the
#                                               current branch, and is the branch written to
#
# Prints op=, moves=, onto= and writes=, then refused= and one message= line ending
# `nothing integrated` on a refusal, or in_progress= (none, rebase or merge) and the commands the
# run integrates with, start=, continue= and abort=, when the door holds. The refusals, first match
# wins: missing-branch, protected-target (a merge only), wrong-branch, dirty-tree (only with no
# integration in progress, whose conflicted state is not uncommitted work). A branch exists when it is a local branch or a remote-tracking
# ref of that name. Exit codes: 0 the door holds · 1 refused · 2 usage, or not a git repository.
set -uo pipefail

usage() {
  echo "usage: integrate-door.sh rebase <onto> [<moves>] | integrate-door.sh merge <moves> [<onto>]" >&2
  exit 2
}

git rev-parse --show-toplevel >/dev/null 2>&1 || {
  echo "not a git repository" >&2
  exit 2
}
[ $# -ge 2 ] && [ $# -le 3 ] || usage

integration_in_progress() {
  local dir
  for dir in rebase-merge rebase-apply; do
    [ -d "$(git rev-parse --git-path "$dir")" ] && {
      echo rebase
      return
    }
  done
  git rev-parse -q --verify MERGE_HEAD >/dev/null && {
    echo merge
    return
  }
  echo none
}

op="$1"
in_progress="$(integration_in_progress)"
current="$(git symbolic-ref --short -q HEAD || echo HEAD)"
# A stopped rebase leaves HEAD detached; the branch it is rebasing is in its state directory.
if [ "$in_progress" = rebase ]; then
  for dir in rebase-merge rebase-apply; do
    head_name="$(git rev-parse --git-path "$dir/head-name")"
    [ -f "$head_name" ] && current="$(sed 's#^refs/heads/##' "$head_name")"
  done
fi
case "$op" in
  rebase) onto="$2" moves="${3:-$current}" writes="$moves" ;;
  merge) moves="$2" onto="${3:-$current}" writes="$onto" ;;
  *) usage ;;
esac

echo "op=$op"
echo "moves=$moves"
echo "onto=$onto"
echo "writes=$writes"

refuse() { # $1 kind, $2 message
  echo "refused=$1"
  echo "message=$2; nothing integrated"
  exit 1
}

# A qualified ref, so a tag sharing the branch's name can never shadow it.
branch_ref() {
  local ref
  for ref in "refs/heads/$1" "refs/remotes/$1"; do
    git show-ref -q --verify "$ref" && {
      echo "$ref"
      return 0
    }
  done
  return 1
}

for branch in "$moves" "$onto"; do
  branch_ref "$branch" >/dev/null || refuse missing-branch "no branch named $branch"
done

if [ "$op" = merge ]; then
  guard="$(bash "$(dirname "$0")/trivial-door.sh" branch "$onto")" ||
    refuse protected-target "$onto is protected: $(sed -n 's/^reason=//p' <<<"$guard"), and the rule is $(sed -n 's/^rule=//p' <<<"$guard")"
fi

[ "$writes" = "$current" ] ||
  refuse wrong-branch "the $op writes to $writes, and you are on $current: run git switch $writes first"

if [ "$in_progress" = none ]; then
  dirty="$(git status --porcelain --untracked-files=all | cut -c4- | paste -sd ' ' -)"
  [ -z "$dirty" ] || refuse dirty-tree "uncommitted work in the way: $dirty"
fi

echo "in_progress=$in_progress"
norerere="git -c rerere.enabled=false -c rerere.autoupdate=false"
case "$op" in
  rebase) echo "start=$norerere rebase $(branch_ref "$onto")" ;;
  merge) echo "start=$norerere merge --no-edit $(branch_ref "$moves")" ;;
esac
# An integration already in progress is resumed or dropped with its own commands, whatever the request named.
held="$op"
[ "$in_progress" = none ] || held="$in_progress"
echo "continue=$norerere -c core.editor=true $held --continue"
echo "abort=git $held --abort"
