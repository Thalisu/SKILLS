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

exit "$((fails > 0))"
