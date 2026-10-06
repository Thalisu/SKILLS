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

exit "$((fails > 0))"
