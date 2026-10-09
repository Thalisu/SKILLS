#!/usr/bin/env bash
# completion-check.sh: what a Spec still has open, read from the status of every Ticket in the
# issues/ folder that holds the Ticket it is given. Reads only: no file written, no ref moved, no
# lock taken. Run from anywhere inside the project, the main checkout or a worktree of it.
#
#   completion-check.sh <the Ticket's path>    a relative path is read from the directory the script
#                                              runs in, then from the main checkout
#
# Prints key=value lines, in this order: ticket, spec_branch as `spec-branch.sh probe` prints it,
# one spec_ticket=<NN> <status> <path> per Ticket of the folder in number order, the argument's own
# included, one open=<NN> <status> <path> per Ticket not resolved (open=none when every one is),
# next, next_build, next_build_location, next_location, last, then verdict. An ambiguous=<NN>
# <detail> line follows the spec_ticket line it concerns. What a Ticket file is and what its status reads are ticket-read.sh's rules.
#
# next, first match wins: the path of the first open Ticket reading ready-for-agent · none (nothing
# is open) · wait (every open Ticket reads claimed, so other runs hold them) · ambiguous (nothing
# is ready and an open Ticket cannot be read).
#
# next_build, next_build_location and next_location follow next only when it is a path and that
# Ticket is built in another repository, as ticket-read.sh's build_of reads it: the name on its
# **Build repository:** line, that entry's location in the Spec's ## Repositories section as
# written (unlisted with no entry), and the Ticket's absolute path. Absent means built here: a
# Ticket built in this session's repository, or one with no Build repository line.
#
# last is yes when every Ticket other than the argument reads resolved, and no otherwise, an
# ambiguous one included. The argument's own status never enters it, so the Gate reads the same
# answer before the close writes resolved as the close reads after.
#
# A Ticket outside a feature folder's issues/ has no Spec behind it (spec_branch=none): its folder
# is not walked, and the record reads spec_ticket=none, open=none, next=none, last=yes.
#
# verdict, first match wins: no-spec (spec_branch=none) · ambiguous (a Ticket's status cannot be
# read) · complete (every Ticket reads resolved) · incomplete.
#
# Exit codes: 0 the Spec's state was read · 1 ambiguous, with the lines above still printed ·
# 2 usage, no file at the path, a path in a feature folder's issues/ that is not one of the Tickets
# of its folder, or not a git repository.
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
main="$(main_of .)"

case "$1" in
  /*) path="$1" ;;
  *) if [ -f "$1" ]; then path="$(pwd -P)/${1#./}"; else path="$main/${1#./}"; fi ;;
esac
[ -f "$path" ] || {
  echo "no Ticket at $1" >&2
  exit 2
}
spec_branch="$(bash "$here/spec-branch.sh" probe "$path" | sed -n 's/^spec_branch=//p')"
if [ "$spec_branch" = none ]; then
  echo "ticket=${path#"$main"/}"
  echo "spec_branch=none"
  printf '%s\n' spec_ticket=none open=none next=none last=yes verdict=no-spec
  exit 0
fi

folder="$(dirname "$path")"
tickets="$(ticket_files "$folder")"
grep -qxF -- "$path" <<<"$tickets" || {
  echo "not a Ticket of its folder: $1" >&2
  exit 2
}

echo "ticket=${path#"$main"/}"
echo "spec_branch=$spec_branch"

open="" unreadable=0 ready="" ready_file="" last=yes
while IFS= read -r file; do
  status_of "$file"
  number="$(basename "$file")"
  row="${number%%-*} $word ${file#"$main"/}"
  echo "spec_ticket=$row"
  [ "$word" = resolved ] || open+="open=$row"$'\n'
  [ "$word" = resolved ] || [ "$file" = "$path" ] || last=no
  [ "$word" != ready-for-agent ] || [ -n "$ready" ] || ready="${file#"$main"/}" ready_file="$file"
  if [ "$word" = ambiguous ]; then
    echo "ambiguous=${number%%-*} $detail"
    unreadable=1
  fi
done <<<"$tickets"
printf '%s' "${open:-open=none$'\n'}"

if [ -n "$ready" ]; then
  echo "next=$ready"
  build_of "$ready_file"
  case "$build_check" in
    here | none | ambiguous) ;;
    *)
      echo "next_build=$build_name"
      echo "next_build_location=${build_place/#none/unlisted}"
      echo "next_location=$ready_file"
      ;;
  esac
elif [ -z "$open" ]; then
  echo "next=none"
elif [ "$unreadable" = 0 ]; then
  echo "next=wait"
else
  echo "next=ambiguous"
fi
echo "last=$last"

if [ "$unreadable" = 1 ]; then
  verdict=ambiguous
elif [ -z "$open" ]; then
  verdict=complete
else
  verdict=incomplete
fi
echo "verdict=$verdict"
[ "$verdict" != ambiguous ]
