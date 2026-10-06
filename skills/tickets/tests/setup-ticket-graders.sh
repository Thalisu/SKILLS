#!/usr/bin/env bash
# setup-ticket-graders.sh: the contract of the code-read graders of the tickets eval cases about the
# Setup ticket, exercised by calling scripts/run-eval.sh's own grade() against a throwaway work
# folder, so no claude session ever starts.
# In impeccable-setup-missing-cuts-setup-ticket the Spec reads Front-end: impeccable, its two Paths
# run from the command line, and the project lacks the setup: the run publishes three local Tickets
# under the notes-cli feature folder, the Setup ticket as 00, blocked by nothing, and one Logic
# ticket per Path, each blocked by the Setup ticket.
# Run: bash skills/tickets/tests/setup-ticket-graders.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
fails=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

source_grade

status='**Status:** ready-for-agent'
kind_setup="$status"$'\n\n''**Kind:** setup'
kind_logic="$status"$'\n\n''**Kind:** logic'
kind_front_end="$status"$'\n\n''**Kind:** front-end'
unblocked='None (can start immediately)'
by_setup='00 Set up impeccable'

# A run that published those local Tickets, in a new work folder under $tmp; its path on stdout
run_publishing() { # one group of three per Ticket: its file name, the lines between its Blocked by and its criteria, its Blocked by value
  # Optional, set on the call's own line: feature_folder=<name> the feature folder the Tickets land under (default notes-cli)
  local w issues
  w="$(mktemp -d "$tmp/w.XXXXXX")"
  issues="$w/fixture/.scratch/${feature_folder:-notes-cli}/issues"
  mkdir -p "$issues"
  while [ "$#" -ge 3 ]; do
    ticket "$1" "$2" "$3"
    shift 3
  done
  echo "$w"
}

# The run of a project without the setup: the Setup ticket as 00, then the two Notes CLI Logic tickets behind it
setup_missing_run() { # no argument: the faithful run
  # Optional, set on the call's own line, each replacing what the faithful run carries: lines_00, lines_01, lines_02 the lines between that Ticket's Blocked by and its criteria, blocked_00, blocked_01, blocked_02 its Blocked by value
  run_publishing \
    00-set-up-impeccable.md "${lines_00:-$kind_setup}" "${blocked_00:-$unblocked}" \
    01-export-the-notes.md "${lines_01:-$kind_logic}" "${blocked_01:-$by_setup}" \
    02-import-notes.md "${lines_02:-$kind_logic}" "${blocked_02:-$by_setup}"
}

case=impeccable-setup-missing-cuts-setup-ticket
graders="$here/../evals/$case/graders"

no_setup_ticket="$(run_publishing \
  01-export-the-notes.md "$kind_logic" "$unblocked" \
  02-import-notes.md "$kind_logic" "$unblocked")"
setup_ticket_as_01="$(run_publishing \
  01-set-up-impeccable.md "$kind_setup" "$unblocked" \
  02-export-the-notes.md "$kind_logic" '01 Set up impeccable' \
  03-import-notes.md "$kind_logic" '01 Set up impeccable')"

for name in ticket-00-written ticket-00-kind-setup ticket-00-blocked-by-nothing \
  ticket-01-blocked-by-setup ticket-02-blocked-by-setup ticket-01-kind-logic ticket-02-kind-logic; do
  # shellcheck disable=SC2034 # read by lib.sh's grade_passes and grade_fails
  grader="$graders/$name.md"

  expect "$case holds a $name grader" test -f "$grader"

  grade_passes "$case: a run that published the Setup ticket as 00, blocked by nothing, and both Logic tickets blocked by it passes $name" \
    "$(setup_missing_run)"
  grade_fails "$case: Tickets published under another feature folder fail $name" \
    "$(feature_folder=archive-notes setup_missing_run)"
done

for name in ticket-00-written ticket-00-kind-setup ticket-00-blocked-by-nothing \
  ticket-01-blocked-by-setup ticket-02-blocked-by-setup; do
  # shellcheck disable=SC2034 # read by lib.sh's grade_fails
  grader="$graders/$name.md"
  grade_fails "$case: a run that published no 00 Ticket, its two Logic tickets blocked by nothing, fails $name" \
    "$no_setup_ticket"
done

name=ticket-00-written
grader="$graders/$name.md"
grade_fails "$case: a run that published the Setup ticket as 01, the Logic tickets as 02 and 03, fails $name" \
  "$setup_ticket_as_01"

name=ticket-00-kind-setup
grader="$graders/$name.md"
grade_fails "$case: a 00 Ticket carrying **Kind:** logic fails $name" \
  "$(lines_00="$kind_logic" setup_missing_run)"
grade_fails "$case: a 00 Ticket carrying the kind unbolded fails $name" \
  "$(lines_00="$status"$'\n\n''Kind: setup' setup_missing_run)"
grade_fails "$case: a 00 Ticket with no **Kind:** line fails $name" \
  "$(lines_00="$status" setup_missing_run)"

name=ticket-00-blocked-by-nothing
grader="$graders/$name.md"
grade_fails "$case: a 00 Ticket whose Blocked by names another Ticket fails $name" \
  "$(blocked_00='01 Export the notes' setup_missing_run)"

name=ticket-01-blocked-by-setup
grader="$graders/$name.md"
grade_fails "$case: a Ticket 01 blocked by nothing fails $name, though Ticket 02 is blocked by 00" \
  "$(blocked_01="$unblocked" setup_missing_run)"
grade_fails "$case: a Ticket 01 blocked by the other Logic ticket only fails $name, though Ticket 02 is blocked by 00" \
  "$(blocked_01='02 Import notes' setup_missing_run)"

name=ticket-02-blocked-by-setup
grader="$graders/$name.md"
grade_fails "$case: a Ticket 02 blocked by nothing fails $name, though Ticket 01 is blocked by 00" \
  "$(blocked_02="$unblocked" setup_missing_run)"
grade_fails "$case: a Ticket 02 blocked by the other Logic ticket only fails $name, though Ticket 01 is blocked by 00" \
  "$(blocked_02='01 Export the notes' setup_missing_run)"

name=ticket-01-kind-logic
grader="$graders/$name.md"
grade_fails "$case: a Ticket 01 carrying **Kind:** setup fails $name" \
  "$(lines_01="$kind_setup" setup_missing_run)"
grade_fails "$case: a Ticket 01 carrying **Kind:** front-end fails $name" \
  "$(lines_01="$kind_front_end" setup_missing_run)"

name=ticket-02-kind-logic
# shellcheck disable=SC2034 # read by lib.sh's grade_fails
grader="$graders/$name.md"
grade_fails "$case: a Ticket 02 carrying **Kind:** setup fails $name" \
  "$(lines_02="$kind_setup" setup_missing_run)"
grade_fails "$case: a Ticket 02 carrying **Kind:** front-end fails $name" \
  "$(lines_02="$kind_front_end" setup_missing_run)"

[ "$fails" -eq 0 ] && exit 0
exit 1
