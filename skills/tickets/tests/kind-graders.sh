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
  local w issues name
  w="$(mktemp -d "$tmp/w.XXXXXX")"
  issues="$w/fixture/.scratch/archive-notes/issues"
  mkdir -p "$issues"
  for name in 01-archive-a-note.md 02-search-skips-archived.md 03-restore-a-note.md; do
    if [ "${name%%-*}" != "$1" ]; then
      ticket "$name" "$kind_logic" 'None (can start immediately)'
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

[ "$fails" -eq 0 ] && exit 0
exit 1
