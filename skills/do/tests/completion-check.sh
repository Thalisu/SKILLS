#!/usr/bin/env bash
# completion-check.sh: the contract of scripts/completion-check.sh, what a Spec still has open once
# a Ticket of it lands, exercised in a throwaway git repository.
# Run: bash skills/do/tests/completion-check.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/completion-check.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT
export HOME="$tmp/home"
mkdir -p "$HOME"

run() {
  rc=0
  # shellcheck disable=SC2034  # lib.sh's check_lines reads $out
  out="$(bash "$script" "$@" 2>&1)" || rc=$?
}

fresh main
printf '.scratch/\n' >.gitignore
printf 'one\n' >notes.txt
commit fixture
g branch spec/x
issues=".scratch/20260930-x/issues"
mkdir -p "$issues"
printf '# Spec: x\n\nSomething to build.\n' >.scratch/20260930-x/spec.md
ticket 01-a.md '**Status:** resolved' 'None (can start immediately)'
ticket 02-b.md '**Status:** claimed' 'None (can start immediately)'
ticket 03-c.md '**Status:** resolved' 'None (can start immediately)'

run "$issues/03-c.md"
check_lines "a Spec with one Ticket still claimed reads incomplete and names that Ticket with its status" 0 "$rc" \
  "verdict=incomplete" "open=02 claimed $issues/02-b.md"

ticket 02-b.md '**Status:** resolved' 'None (can start immediately)'
run "$issues/02-b.md"
check_lines "a Spec whose every Ticket reads resolved reads complete, with nothing open" 0 "$rc" \
  "verdict=complete" "open=none"
check_absent "a complete Spec names no Ticket as open" 0 "$rc" \
  "open=01" "open=02" "open=03"

ticket 02-b.md '**Status:** claimed' 'None (can start immediately)'
ticket 01-a.review.md '**Status:** claimed' 'None (can start immediately)'
ticket 01-a.digest.md '**Status:** ready-for-agent' 'None (can start immediately)'
ticket 03-c.sketch.md '**Status:** claimed' 'None (can start immediately)'
ticket 03-c.plan.md '**Status:** ready-for-agent' 'None (can start immediately)'
ticket 03-c.project-map.md '**Status:** claimed' 'None (can start immediately)'
sidecars=(".review.md" ".digest.md" ".sketch.md" ".plan.md" ".project-map.md")

run "$issues/03-c.md"
expect "prints one line per Ticket of the Spec with its status, in number order, and none for a sidecar beside a Ticket" \
  test "$(term spec_ticket)" = "01 resolved $issues/01-a.md
02 claimed $issues/02-b.md
03 resolved $issues/03-c.md"
check_lines "a sidecar carrying a Status line leaves the open Tickets as they are" 0 "$rc" \
  "verdict=incomplete" "open=02 claimed $issues/02-b.md"
check_absent "a sidecar carrying a Status line is never named in the output" 0 "$rc" "${sidecars[@]}"

ticket 02-b.md '**Status:** resolved' 'None (can start immediately)'
run "$issues/02-b.md"
check_lines "a Spec whose real Tickets all read resolved reads complete beside sidecars that read claimed" 0 "$rc" \
  "verdict=complete" "open=none" \
  "spec_ticket=01 resolved $issues/01-a.md" "spec_ticket=02 resolved $issues/02-b.md" "spec_ticket=03 resolved $issues/03-c.md"
check_absent "a complete Spec names no sidecar as a Ticket" 0 "$rc" "${sidecars[@]}"

# ADR 0038: a Ruling reversed after its Ticket landed is built by a Ticket the developer types by
# hand, so the file carries none of the generated fields beyond its Status line.
reversal="$issues/04-reverse-the-ruling-on-x.md"
printf '# Reverse the ruling on x\n\nThe ruling on x went the other way after 02 landed: build the new side.\n\n**Status:** ready-for-agent\n' >"$reversal"
run "$issues/03-c.md"
check_lines "a hand-written reversal Ticket still ready-for-agent among resolved Tickets reads incomplete and is named like any other" 0 "$rc" \
  "spec_ticket=04 ready-for-agent $reversal" "open=04 ready-for-agent $reversal" "verdict=incomplete"
rm -f "$reversal"

exit "$((fails > 0))"
