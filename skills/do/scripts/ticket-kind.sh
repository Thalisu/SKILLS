#!/usr/bin/env bash
# ticket-kind.sh: the kind of a Ticket, read by the router of do before its table, so a Setup
# ticket reaches the setup Playbook and every other Ticket the ticket Playbook. The rule is
# kind_of's in ticket-read.sh: the one **Kind:** line at column 0, logic with none, ambiguous on two
# or on a word outside logic, front-end and setup.
#
#   ticket-kind.sh <the Ticket's path>    read as given, from the directory the script runs in
#
# Prints kind=<logic|front-end|setup|ambiguous>, then ambiguous=<detail> when the kind is ambiguous.
# Writes nothing.
#
# Exit codes: 0 the kind was read · 2 usage, or no file at the path.
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd -P)"
# shellcheck source=skills/do/scripts/ticket-read.sh
. "$here/ticket-read.sh"

[ "$#" = 1 ] || {
  echo "usage: ticket-kind.sh <the Ticket's path>" >&2
  exit 2
}
[ -f "$1" ] || {
  echo "no Ticket at $1" >&2
  exit 2
}

kind_of "$1"
# shellcheck disable=SC2154 # kind_of sets word and detail.
echo "kind=$word"
[ -z "$detail" ] || echo "ambiguous=$detail"
