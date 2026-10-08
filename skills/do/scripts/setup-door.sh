#!/usr/bin/env bash
# setup-door.sh: the door facts of the setup Playbook of do, the ones a script can observe. Run from
# anywhere inside the project, the main checkout or a worktree of it. Writes nothing: the claim is
# the session's own edit of the Ticket file.
#
#   setup-door.sh <the Ticket's path>    a relative path is read from the directory the script runs
#                                        in, then from the main checkout
#
# Prints key=value lines, in this order: ticket (relative to the main checkout), main (the main
# checkout's absolute path), status, kind, then verdict. An ambiguous=<detail> line follows the
# status or kind line it concerns. What a status and a kind read are ticket-read.sh's rules.
#
# verdict, first match wins: ambiguous (the status or the kind cannot be read) · not-setup (the
# kind is not setup) · resolved · resume (claimed) · start (ready-for-agent). A status outside those
# three is never read: ticket-read.sh already reads it ambiguous.
#
# Exit codes: 0 start or resume · 1 every other verdict · 2 usage, no Ticket at the path, or not a
# git repository.
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd -P)"
# shellcheck source=skills/do/scripts/ticket-read.sh
. "$here/ticket-read.sh"

[ "$#" = 1 ] || {
  echo "usage: setup-door.sh <the Ticket's path>" >&2
  exit 2
}

top="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "not a git repository" >&2
  exit 2
}
# A bare main worktree has no working tree to anchor on, and git lists it first all the same.
main="$(git worktree list --porcelain 2>/dev/null |
  awk '/^$/ { exit } /^worktree /{ p = substr($0, 10) } /^bare$/ { p = "" } END { print p }')"
[ -n "$main" ] && [ -d "$main" ] || main="$top"

case "$1" in
  /*) path="$1" ;;
  *) if [ -f "$1" ]; then path="$(pwd -P)/${1#./}"; else path="$main/${1#./}"; fi ;;
esac
[ -f "$path" ] || {
  echo "no Ticket at $1" >&2
  exit 2
}

echo "ticket=${path#"$main"/}"
echo "main=$main"
# shellcheck disable=SC2154 # status_of and kind_of set word and detail.
{
  status_of "$path"
  status="$word"
  echo "status=$status"
  [ -z "$detail" ] || echo "ambiguous=$detail"
  kind_of "$path"
  kind="$word"
  echo "kind=$kind"
  [ -z "$detail" ] || echo "ambiguous=$detail"
}

if [ "$status" = ambiguous ] || [ "$kind" = ambiguous ]; then
  verdict=ambiguous
elif [ "$kind" != setup ]; then
  verdict=not-setup
elif [ "$status" = resolved ]; then
  verdict=resolved
elif [ "$status" = claimed ]; then
  verdict=resume
else
  verdict=start
fi
echo "verdict=$verdict"
case "$verdict" in
  start | resume) exit 0 ;;
  *) exit 1 ;;
esac
