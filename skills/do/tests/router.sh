#!/usr/bin/env bash
# router.sh: the router row that sends a runnable throwaway to the prototype door, checked where the
# router writes it and everywhere the repository repeats it, so the word `sketch` cannot drift back
# into a trigger the `sketch` skill owns: the row in the skill file, the door table on the docs page,
# the Playbook rule in the glossary, and the eval case named for what it grades.
# Run: bash skills/do/tests/router.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
repo="$(cd "$here/../../.." && pwd -P)"
fails=0

has() { # $1 label, $2 file, $3.. fixed strings that must appear in the file
  local label="$1" file="$2"; shift 2
  local ok=1 line
  [ -f "$file" ] || ok=0
  for line in "$@"; do [ "$ok" = 1 ] && grep -qF -- "$line" "$file" || ok=0; done
  if [ "$ok" = 1 ]; then echo "ok    $label"; else echo "FAIL  $label ($file)"; fails=$((fails + 1)); fi
}
expect() { # $1 label, $2.. a command that must succeed
  local label="$1"; shift
  if "$@"; then echo "ok    $label"; else echo "FAIL  $label"; fails=$((fails + 1)); fi
}
# The rows of one markdown table: from its header line to the first line that is not a row.
table() { awk -v h="$2" 'index($0, h) == 1 { t = 1 } t && $0 !~ /^\|/ { exit } t' "$1"; }

# The router row itself, where `do` reads it. The door is named by what the request is, a runnable
# throwaway, so it still matches without the word the `sketch` skill took.
router="$repo/skills/do/SKILL.md"
has "the router sends a runnable throwaway to the prototype door" "$router" \
  "| a runnable throwaway: a layout, a variant to try | \`Playbook: none\`; \`/prototype\` |"
expect "no row of the router table matches the word \`sketch\`" \
  test -z "$(table "$router" '| The argument | Match |' | grep -F sketch)"

if [ "$fails" = 0 ]; then echo "PASS"; else echo "$fails failing"; exit 1; fi
