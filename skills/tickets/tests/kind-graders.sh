#!/usr/bin/env bash
# kind-graders.sh: the contract of the code-read graders ticket-01-kind-logic, ticket-02-kind-logic
# and ticket-03-kind-logic of the two tickets eval cases whose Spec has no screen, exercised by
# calling scripts/run-eval.sh's own grade() against a throwaway work folder, so no claude session
# ever starts.
# In front-end-none-cuts-as-today the Spec reads Front-end: none, and in auto-publishes-locally it
# carries no Front-end: line: either way the run publishes three local Tickets, and `do` routes each
# by the `**Kind:**` line it reads by name, so every one of them carries `**Kind:** logic` on a line
# of its own.
# Run: bash skills/tickets/tests/kind-graders.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
fails=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

source_grade

status='**Status:** ready-for-agent'
kind_logic="$status"$'\n\n''**Kind:** logic'

# A run that published the Archive notes Tickets as local files, in a new work folder under $tmp; its path on stdout
run_with_ticket_as() { # $1 the Ticket's number (01, 02, 03), $2 the lines between its Blocked by and its criteria, or empty when it was never written; the other two carry Kind: logic
  # Optional: $3 the lines the other two carry there instead of Kind: logic
  # Optional, set on the call's own line: feature_folder=<name> the feature folder the Tickets land under (default archive-notes), ticket_names=<file names, space separated> the Tickets the run published (default the three Archive notes ones)
  local w issues name
  w="$(mktemp -d "$tmp/w.XXXXXX")"
  issues="$w/fixture/.scratch/${feature_folder:-archive-notes}/issues"
  mkdir -p "$issues"
  for name in ${ticket_names:-01-archive-a-note.md 02-search-skips-archived.md 03-restore-a-note.md}; do
    if [ "${name%%-*}" != "$1" ]; then
      ticket "$name" "${3:-$kind_logic}" 'None (can start immediately)'
    elif [ -n "$2" ]; then
      ticket "$name" "$2" 'None (can start immediately)'
    fi
  done
  echo "$w"
}

for case in front-end-none-cuts-as-today auto-publishes-locally; do
  for n in 01 02 03; do
    name="ticket-$n-kind-logic"
    # shellcheck disable=SC2034 # read by lib.sh's grade_passes and grade_fails
    grader="$here/../evals/$case/graders/$name.md"

    expect "$case holds a $name grader" test -f "$grader"

    grade_passes "$case: a Ticket $n carrying **Kind:** logic on a line of its own passes $name" \
      "$(run_with_ticket_as "$n" "$kind_logic")"
    grade_fails "$case: a Ticket $n with no **Kind:** line fails $name, though the other two carry it" \
      "$(run_with_ticket_as "$n" "$status")"
    grade_fails "$case: a Ticket $n carrying **Kind:** front-end fails $name" \
      "$(run_with_ticket_as "$n" "$status"$'\n\n''**Kind:** front-end')"
    grade_fails "$case: a Ticket $n carrying the kind unbolded fails $name" \
      "$(run_with_ticket_as "$n" "$status"$'\n\n''Kind: logic')"
    grade_fails "$case: a Ticket $n carrying the kind on its Status line fails $name" \
      "$(run_with_ticket_as "$n" "$status · **Kind:** logic")"
    grade_fails "$case: a Ticket $n never written fails $name, though the other two carry **Kind:** logic" \
      "$(run_with_ticket_as "$n" "")"
  done
done

# In screen-path-cuts-logic-then-front-end the Spec reads Front-end: builder and its journey holds a
# Path walked on a screen and a Path with none, so the run publishes three local Tickets: the screen
# Path's Logic ticket, its Front-end ticket, and the other Path's Logic ticket. A run that kept the
# screen Path as one vertical Ticket publishes two.
case=screen-path-cuts-logic-then-front-end
nothing_published="$(mktemp -d "$tmp/w.XXXXXX")"
for n in 01 02 03; do
  name="ticket-$n-written"
  grader="$here/../evals/$case/graders/$name.md"

  expect "$case holds a $name grader" test -f "$grader"

  grade_passes "$case: a run that published Tickets 01, 02 and 03 passes $name" \
    "$(run_with_ticket_as "$n" "$kind_logic")"
  grade_fails "$case: a run that never wrote Ticket $n fails $name, though it published the other two" \
    "$(run_with_ticket_as "$n" "")"
  grade_fails "$case: a run that published nothing fails $name" "$nothing_published"
done
for n in 01 02; do
  # shellcheck disable=SC2034 # read by lib.sh's grade_passes
  grader="$here/../evals/$case/graders/ticket-$n-written.md"
  grade_passes "$case: a run that cut the screen Path as one vertical Ticket, publishing 01 and 02 only, passes ticket-$n-written" \
    "$(run_with_ticket_as 03 "")"
done

# `do` routes each published Ticket by the `**Kind:**` line it reads by name. Tickets are numbered
# blockers first, so Ticket 01 is a Logic ticket, and the screen Path's Front-end ticket, blocked by
# its Logic ticket, is 02 or 03.
kind_front_end="$status"$'\n\n''**Kind:** front-end'

name=ticket-01-kind-logic
grader="$here/../evals/$case/graders/$name.md"

expect "$case holds a $name grader" test -f "$grader"

grade_passes "$case: a Ticket 01 carrying **Kind:** logic on a line of its own passes $name" \
  "$(run_with_ticket_as 01 "$kind_logic")"
grade_passes "$case: a Ticket 01 carrying **Kind:** logic passes $name, whichever kind the other two carry" \
  "$(run_with_ticket_as 01 "$kind_logic" "$kind_front_end")"
grade_fails "$case: a Ticket 01 with no **Kind:** line fails $name, though the other two carry it" \
  "$(run_with_ticket_as 01 "$status")"
grade_fails "$case: a Ticket 01 carrying **Kind:** front-end fails $name" \
  "$(run_with_ticket_as 01 "$kind_front_end")"
grade_fails "$case: a Ticket 01 carrying the kind unbolded fails $name" \
  "$(run_with_ticket_as 01 "$status"$'\n\n''Kind: logic')"
grade_fails "$case: a Ticket 01 carrying the kind on its Status line fails $name" \
  "$(run_with_ticket_as 01 "$status · **Kind:** logic")"
grade_fails "$case: a Ticket 01 never written fails $name, though the other two carry **Kind:** logic" \
  "$(run_with_ticket_as 01 "")"

name=front-end-ticket-published
grader="$here/../evals/$case/graders/$name.md"

expect "$case holds a $name grader" test -f "$grader"

for n in 02 03; do
  grade_passes "$case: a Ticket $n carrying **Kind:** front-end on a line of its own passes $name, the other two being Logic tickets" \
    "$(run_with_ticket_as "$n" "$kind_front_end")"
done
grade_fails "$case: a run whose every published Ticket reads **Kind:** logic fails $name" \
  "$(run_with_ticket_as 02 "$kind_logic")"
grade_fails "$case: a run whose only front-end kind is unbolded fails $name" \
  "$(run_with_ticket_as 02 "$status"$'\n\n''Kind: front-end')"
grade_fails "$case: a run whose only front-end kind shares the Status line fails $name" \
  "$(run_with_ticket_as 02 "$status · **Kind:** front-end")"
grade_fails "$case: a run whose Tickets carry no **Kind:** line fails $name" \
  "$(run_with_ticket_as 02 "$status" "$status")"
grade_fails "$case: a run that published nothing fails $name" "$nothing_published"

# In no-screen-cuts-logic-alone the Spec reads Front-end: builder and its journey holds two Paths,
# both run from the command line, so neither has a screen: the run publishes two local Tickets under
# the notes-cli feature folder, one Logic ticket per Path and no Front-end ticket.
case=no-screen-cuts-logic-alone
notes_cli_run() { # run_with_ticket_as's arguments: the same run, of the two Notes CLI Tickets
  feature_folder=notes-cli ticket_names='01-export-the-notes.md 02-import-notes.md' run_with_ticket_as "$@"
}
for n in 01 02; do
  name="ticket-$n-kind-logic"
  # shellcheck disable=SC2034 # read by lib.sh's grade_passes and grade_fails
  grader="$here/../evals/$case/graders/$name.md"

  expect "$case holds a $name grader" test -f "$grader"

  grade_passes "$case: a Ticket $n carrying **Kind:** logic on a line of its own passes $name" \
    "$(notes_cli_run "$n" "$kind_logic")"
  grade_passes "$case: a Ticket $n carrying **Kind:** logic passes $name, whichever kind the other carries" \
    "$(notes_cli_run "$n" "$kind_logic" "$kind_front_end")"
  grade_fails "$case: a Ticket $n carrying **Kind:** front-end, cut for a Path with no screen, fails $name, though the other carries **Kind:** logic" \
    "$(notes_cli_run "$n" "$kind_front_end")"
  grade_fails "$case: a Ticket $n with no **Kind:** line fails $name, though the other carries it" \
    "$(notes_cli_run "$n" "$status")"
  grade_fails "$case: a Ticket $n carrying the kind unbolded fails $name" \
    "$(notes_cli_run "$n" "$status"$'\n\n''Kind: logic')"
  grade_fails "$case: a Ticket $n carrying the kind on its Status line fails $name" \
    "$(notes_cli_run "$n" "$status · **Kind:** logic")"
  grade_fails "$case: a Ticket $n never written fails $name, though the other carries **Kind:** logic" \
    "$(notes_cli_run "$n" "")"
  grade_fails "$case: Tickets published under another feature folder fail $name" \
    "$(run_with_ticket_as "$n" "$kind_logic")"
done

[ "$fails" -eq 0 ] && exit 0
exit 1
