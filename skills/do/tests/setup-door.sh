#!/usr/bin/env bash
# setup-door.sh: the contract of scripts/setup-door.sh, the door the setup Playbook opens on a Setup
# ticket, exercised in a throwaway git repository.
# Run: bash skills/do/tests/setup-door.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/setup-door.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT
export HOME="$tmp/home"
mkdir -p "$HOME"

run() { # $1.. the script's arguments: its stdout in $out, its exit in $rc
  rc=0
  # shellcheck disable=SC2034  # lib.sh's check_lines reads $out
  out="$(bash "$script" "$@" 2>/dev/null)" || rc=$?
}

fresh main
printf '.scratch/\n' >.gitignore
printf 'one\n' >notes.txt
commit fixture
issues=".scratch/20261006-x/issues"
mkdir -p "$issues"

# The setup Playbook claims the Ticket on start only, and a developer who left a step half done
# types /do on the claimed Ticket again to be shown that step, never refused nor claimed twice.
for pair in ready-for-agent:start claimed:resume; do
  IFS=: read -r st verdict <<<"$pair"
  ticket 00-setup.md "**Status:** $st"$'\n\n**Kind:** setup' 'None (can start immediately)'
  before="$(door_state)"
  run "$issues/00-setup.md"
  check_lines "a $st Setup ticket opens with verdict=$verdict and exit 0" 0 "$rc" "verdict=$verdict"
  expect "opening a $st Setup ticket leaves the Ticket, the refs and git status as they were" \
    test "$(door_state)" = "$before"
done

stops() { # $1 label, $2 file name, $3 status and kind line(s), $4.. whole lines the door must print
  local label="$1" file="$2" lines="$3" before
  shift 3
  ticket "$file" "$lines" 'None (can start immediately)'
  before="$(door_state)"
  run "$issues/$file"
  check_lines "$label, exit 1" 1 "$rc" "$@"
  expect "$label, leaving the Ticket, the refs and git status as they were" \
    test "$(door_state)" = "$before"
}
stops "a resolved Setup ticket stops with verdict=resolved" 00-setup.md \
  $'**Status:** resolved\n\n**Kind:** setup' "verdict=resolved"
stops "a Ticket of kind logic stops with verdict=not-setup" 01-logic.md \
  $'**Status:** ready-for-agent\n\n**Kind:** logic' "verdict=not-setup"
stops "a Setup ticket with two Kind lines stops with verdict=ambiguous, naming both lines" 00-setup.md \
  $'**Status:** ready-for-agent\n\n**Kind:** setup\n\n**Kind:** logic' \
  "kind=ambiguous" "ambiguous=kind lines 9 11" "verdict=ambiguous"
stops "a Setup ticket whose status is no word of the walk stops with verdict=ambiguous, naming the word" 00-setup.md \
  $'**Status:** on-hold\n\n**Kind:** setup' \
  "status=ambiguous" "ambiguous=status word on-hold" "verdict=ambiguous"

refuses "a path with no Ticket at it exits 2 with no verdict" names "no Ticket" "$issues/none.md"

exit "$((fails > 0))"
