#!/usr/bin/env bash
# completion-check.sh: what a Spec still has open, read from the status of every Ticket in the
# issues/ folder that holds the Ticket it is given. Reads only: no file written, no ref moved, no
# lock taken. Run from anywhere inside the project, the main checkout or a worktree of it.
#
#   completion-check.sh <the Ticket's path>    a relative path is read from the directory the script
#                                              runs in, then from the main checkout
#
# Prints key=value lines, in this order: ticket, spec_branch as `spec-branch.sh probe` prints it,
# one open=<NN> <status> <path> per Ticket not resolved, then verdict. What a Ticket file is and
# what its status reads are ticket-read.sh's rules.
#
# verdict, first match wins: ambiguous (a Ticket's status cannot be read) · complete (every Ticket
# reads resolved) · incomplete.
#
# Exit codes: 0 the Spec's state was read · 1 ambiguous, with the lines above still printed ·
# 2 usage, no file at the path, a path that is not one of the Tickets of its folder, or not a git
# repository.
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd -P)"
# shellcheck source=skills/do/scripts/ticket-read.sh
. "$here/ticket-read.sh"

usage() {
  echo "usage: completion-check.sh <the Ticket's path>" >&2
  exit 2
}
[ "$#" = 1 ] || usage

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
folder="$(dirname "$path")"
tickets="$(ticket_files "$folder")"
grep -qxF -- "$path" <<<"$tickets" || {
  echo "not a Ticket of its folder: $1" >&2
  exit 2
}

echo "ticket=${path#"$main"/}"
bash "$here/spec-branch.sh" probe "$path" | grep '^spec_branch='

open="" unreadable=0
while IFS= read -r file; do
  status_of "$file"
  number="$(basename "$file")"
  [ "$word" = resolved ] || open+="open=${number%%-*} $word ${file#"$main"/}"$'\n'
  [ "$word" != ambiguous ] || unreadable=1
done <<<"$tickets"
printf '%s' "$open"

if [ "$unreadable" = 1 ]; then
  verdict=ambiguous
elif [ -z "$open" ]; then
  verdict=complete
else
  verdict=incomplete
fi
echo "verdict=$verdict"
[ "$verdict" != ambiguous ]
