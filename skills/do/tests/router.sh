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
lacks() { # $1 label, $2 file, $3.. fixed strings that must not appear
  local label="$1" file="$2"; shift 2
  local ok=1 line
  [ -f "$file" ] || ok=0
  for line in "$@"; do grep -qF -- "$line" "$file" 2>/dev/null && ok=0; done
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

# The two places the repository repeats the row. A reader who takes either at its word and types
# `/do sketch a shape` has to land on the same door the router sends them to.
page="$repo/docs/do.md"
has "the page's door table quotes the router's row" "$page" \
  "| a runnable throwaway: a layout, a variant to try | \`/prototype\` |"
expect "no row of the page's door table matches the word \`sketch\`" \
  test -z "$(table "$page" '| The request | Where it goes |' | grep -F sketch)"
glossary="$repo/CONTEXT.md"
has "the glossary's Playbook rule sends a runnable throwaway to prototype" "$glossary" \
  "throwaway is \`prototype\`"
lacks "the glossary rule no longer calls a request for a throwaway a sketch" "$glossary" \
  "a sketch is \`prototype\`"

# The eval case that grades the row. Its name is the row's, so a case whose name still carries the
# word grades a door the router no longer has.
evals="$repo/skills/do/evals"
case="$evals/layout-goes-to-prototype"
expect "no eval case folder is named after the word the \`sketch\` skill owns" \
  test -z "$(find "$evals" -maxdepth 1 -type d -name '*sketch*')"
expect "the case that grades the row is named for what it grades" test -d "$case"
has "the case file names the case" "$case/case.yaml" "name: layout-goes-to-prototype"
has "the door grader's line names what the case grades" "$case/graders/names-prototype.md" \
  "A layout goes to prototype; do never builds a throwaway."
has "the evals README carries the case's row" "$evals/README.md" \
  "| \`layout-goes-to-prototype\` |"
# A rename that misses the README leaves a row grading nothing, which reads as coverage.
rows_ok=1
while read -r name; do
  [ -d "$evals/$name" ] || { echo "      README row with no case folder: $name"; rows_ok=0; }
done < <(awk -F'|' '/^\| `/ { gsub(/[` ]/, "", $2); print $2 }' "$evals/README.md")
expect "every row of the evals README names a case folder that exists" test "$rows_ok" = 1

if [ "$fails" = 0 ]; then echo "PASS"; else echo "$fails failing"; exit 1; fi
