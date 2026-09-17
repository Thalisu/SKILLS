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
# `nothing integrated` on a refusal. A branch exists when it is a local branch or a remote-tracking
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

op="$1"
current="$(git symbolic-ref --short -q HEAD || echo HEAD)"
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

branch_exists() {
  git show-ref -q --verify "refs/heads/$1" || git show-ref -q --verify "refs/remotes/$1"
}

for branch in "$moves" "$onto"; do
  branch_exists "$branch" || refuse missing-branch "no branch named $branch"
done

exit 0
