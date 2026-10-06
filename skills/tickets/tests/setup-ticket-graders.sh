#!/usr/bin/env bash
# setup-ticket-graders.sh: the contract of the code-read graders of the tickets eval cases about the
# Setup ticket, exercised by calling scripts/run-eval.sh's own grade() against a throwaway work
# folder, so no claude session ever starts.
# In impeccable-setup-missing-cuts-setup-ticket the Spec reads Front-end: impeccable, its two Paths
# run from the command line, and the project lacks the setup: the run publishes three local Tickets
# under the notes-cli feature folder, the Setup ticket as 00, blocked by nothing, and one Logic
# ticket per Path, each blocked by the Setup ticket.
# In impeccable-setup-found-cuts-no-setup-ticket the project carries the setup: no 00 Ticket, the two
# Logic tickets blocked by nothing, and a close on /do --auto for Ticket 01.
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

# In impeccable-setup-found-cuts-no-setup-ticket the same Spec meets a project that carries the whole
# setup: the run publishes the two Logic tickets alone, as 01 and 02, each blocked by nothing, and its
# final message ends on the /do --auto command of Ticket 01.
case=impeccable-setup-found-cuts-no-setup-ticket
graders="$here/../evals/$case/graders"

issues_path='.scratch/notes-cli/issues'
close_head='Published the Tickets of the Notes command line Spec.'
close_auto_01="$close_head"$'\n\n'"/do --auto $issues_path/01-export-the-notes.md"
close_auto_02="$close_head"$'\n\n'"/do --auto $issues_path/02-import-notes.md"
close_plain_01="$close_head"$'\n\n'"/do $issues_path/01-export-the-notes.md"
close_plain_00="$close_head"$'\n\n'"/do $issues_path/00-set-up-impeccable.md"

# The final message a run closed on, as the runner leaves it in the work folder; the folder's path on stdout
closing_on() { # $1 work folder, $2 the final message
  printf '%s\n' "$2" >"$1/last_message"
  echo "$1"
}

# The run of a project that carries the setup: the two Notes CLI Logic tickets alone, closed on /do --auto for Ticket 01
setup_found_run() { # no argument: the faithful run
  # Optional, set on the call's own line: close=<text> the final message in place of the faithful one, feature_folder=<name> as run_publishing reads it
  closing_on "$(run_publishing \
    01-export-the-notes.md "$kind_logic" "$unblocked" \
    02-import-notes.md "$kind_logic" "$unblocked")" "${close:-$close_auto_01}"
}

setup_ticket_published="$(closing_on "$(setup_missing_run)" "$close_plain_00")"
nothing_published="$(closing_on "$(run_publishing)" "$close_head")"

for name in ticket-01-written ticket-02-written ticket-01-blocked-by-nothing ticket-02-blocked-by-nothing \
  ticket-01-kind-logic ticket-02-kind-logic close-names-do-auto-on-ticket-01; do
  # shellcheck disable=SC2034 # read by lib.sh's grade_passes
  grader="$graders/$name.md"

  expect "$case holds a $name grader" test -f "$grader"

  grade_passes "$case: a run that published the two Logic tickets alone, blocked by nothing, and closed on /do --auto for Ticket 01 passes $name" \
    "$(setup_found_run)"
done

for name in ticket-01-written ticket-02-written ticket-01-blocked-by-nothing ticket-02-blocked-by-nothing \
  ticket-01-kind-logic ticket-02-kind-logic; do
  # shellcheck disable=SC2034 # read by lib.sh's grade_fails
  grader="$graders/$name.md"
  grade_fails "$case: Tickets published under another feature folder fail $name" \
    "$(feature_folder=archive-notes setup_found_run)"
done

for name in ticket-01-written ticket-02-written; do
  # shellcheck disable=SC2034 # read by lib.sh's grade_fails
  grader="$graders/$name.md"
  grade_fails "$case: a run that published nothing fails $name" \
    "$nothing_published"
done

for name in ticket-01-blocked-by-nothing ticket-02-blocked-by-nothing close-names-do-auto-on-ticket-01; do
  # shellcheck disable=SC2034 # read by lib.sh's grade_fails
  grader="$graders/$name.md"
  grade_fails "$case: a run that published a Setup ticket as 00, both Logic tickets blocked by it, and closed on the plain /do for it fails $name" \
    "$setup_ticket_published"
done

name=ticket-01-kind-logic
grader="$graders/$name.md"
grade_fails "$case: a run whose Setup ticket took the number 01 fails $name" \
  "$setup_ticket_as_01"

name=close-names-do-auto-on-ticket-01
# shellcheck disable=SC2034 # read by lib.sh's grade_fails
grader="$graders/$name.md"
grade_fails "$case: a final message ending on /do --auto for Ticket 02 fails $name" \
  "$(close="$close_auto_02" setup_found_run)"
grade_fails "$case: a final message ending on the plain /do for Ticket 01, with no --auto, fails $name" \
  "$(close="$close_plain_01" setup_found_run)"
grade_fails "$case: a final message naming no /do command fails $name" \
  "$(close="$close_head" setup_found_run)"

[ "$fails" -eq 0 ] && exit 0
exit 1
