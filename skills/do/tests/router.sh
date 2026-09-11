#!/usr/bin/env bash
# router.sh: the router row that sends a runnable throwaway to the prototype door, checked where the
# router writes it and everywhere the repository repeats it, so the word `sketch` cannot drift back
# into a trigger the `sketch` skill owns: the row in the skill file, the door table on the docs page,
# the Playbook rule in the glossary, and the eval case named for what it grades.
# The word is looked for in any casing: the glossary spells the artifact `Sketch`, so a row or a
# folder that brings the trigger back capitalized is the same drift as the lowercase one.
# It also checks the router's rule for a Ticket's blockers: a session matching a Ticket's path opens
# no Ticket its Blocked by line names before the ticket door reads that blocker's status line.
# Run: bash skills/do/tests/router.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
repo="$(cd "$here/../../.." && pwd -P)"
fails=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# The rows of one markdown table: from its header line to the first line that is not a row.
table() { awk -v h="$2" 'index($0, h) == 1 { t = 1 } t && $0 !~ /^\|/ { exit } t' "$1"; }
rows_lack() { # $1 label, $2 file, $3 the table's header line, $4.. fixed strings no row may carry
  # A reworded header makes `table` print nothing, and a word looked for in nothing is always
  # absent, so the rows are demanded first and their absence fails the check like the word's
  # presence does.
  local label="$1" file="$2" header="$3"
  shift 3
  local rows ok=1 word
  rows="$(table "$file" "$header" | tail -n +3)"
  if [ -z "$rows" ]; then
    echo "FAIL  $label (no rows under \"$header\") ($file)"
    fails=$((fails + 1))
    return
  fi
  for word in "$@"; do printf '%s\n' "$rows" | grep -qiF -- "$word" && ok=0; done
  if [ "$ok" = 1 ]; then echo "ok    $label"; else
    echo "FAIL  $label ($file)"
    fails=$((fails + 1))
  fi
}
# The lines of one markdown bullet: the line it opens with, then the indented lines under it, up to
# the next bullet or the first line that is not indented.
bullet() {
  awk -v h="$2" '
    index($0, h) == 1 { b = 1; print; next }
    b && /^[[:space:]]*-[[:space:]]/ { exit }
    b && /^[[:space:]]+[^[:space:]]/ { print; next }
    b { exit }
  ' "$1"
}
bullet_has() { # $1 label, $2 file, $3 the bullet's opening, $4.. fixed strings the bullet must carry
  # A rule the file states somewhere is not the rule the bullet states, so the strings are looked
  # for in the bullet alone: a reworded opening prints nothing and fails here like a dropped rule.
  local label="$1" file="$2" opening="$3"
  shift 3
  local lines ok=1 word
  lines="$(bullet "$file" "$opening")"
  for word in "$@"; do printf '%s\n' "$lines" | grep -qF -- "$word" || ok=0; done
  if [ "$ok" = 1 ]; then echo "ok    $label"; else
    echo "FAIL  $label ($file)"
    fails=$((fails + 1))
  fi
}
bullet_lacks() { # $1 label, $2 file, $3 the bullet's opening, $4.. fixed strings the bullet may not carry
  # A reworded opening makes `bullet` print nothing, and a word looked for in nothing is always
  # absent, so the bullet is demanded first and its absence fails the check like the word's
  # presence does.
  local label="$1" file="$2" opening="$3"
  shift 3
  local lines ok=1 word
  lines="$(bullet "$file" "$opening")"
  if [ -z "$lines" ]; then
    echo "FAIL  $label (no bullet opening \"$opening\") ($file)"
    fails=$((fails + 1))
    return
  fi
  for word in "$@"; do printf '%s\n' "$lines" | grep -qiF -- "$word" && ok=0; done
  if [ "$ok" = 1 ]; then echo "ok    $label"; else
    echo "FAIL  $label ($file)"
    fails=$((fails + 1))
  fi
}

# The router row itself, where `do` reads it. The door is named by what the request is, a runnable
# throwaway, so it still matches without the word the `sketch` skill took.
router="$repo/skills/do/SKILL.md"
has "the router sends a runnable throwaway to the prototype door" "$router" \
  "| a runnable throwaway: a layout, a variant to try | \`Playbook: none\`; \`/prototype\` |"
rows_lack "no row of the router table matches the word \`sketch\`" "$router" \
  '| The argument | Match |' sketch

# The sentences and table cells of one section, from its heading to the next `## ` heading, with the
# wrapping flattened. A rule the file states in another section is not the router's rule.
section_sentences() { # $1 file, $2 the section's heading line
  awk -v h="$2" '$0 == h { s = 1; next } s && /^## / { exit } s' "$1" | tr '\n' ' ' | tr -s ' ' |
    sed 's/\. /.\n/g; s/ *| */\n/g'
}
one_sentence_says() { # $1.. extended regexes, case ignored, that one sentence of $out must all match
  local sentences="$out" re
  for re in "$@"; do sentences="$(grep -iE -- "$re" <<<"$sentences")"; done
  [ -n "$sentences" ]
}

# A session that opens a blocker to learn its state reads the blocker's whole body before the ticket
# door does the read it names, the status line alone. One sentence of the Router section names the
# blocker, forbids opening or reading it, and sends it to the door or its status line. The negation
# is tied to the verb whose object is the blocker: the blocker's own mention, a short run of filler
# words (the clause naming it: "line names is"), the negation, then the verb, in that order. A
# negation that sits on some other clause's verb (a later "reads no other file", or a "nothing else
# is read" far from the blocker's mention) does not satisfy this chain.
out="$(section_sentences "$router" "## Router")"
expect "the router tells a Ticket's path to open no blocker before the ticket door reads its status line" \
  one_sentence_says 'blocker|blocked by' \
  '(blocked by|blocker)([^ ]+ ){1,8}(never|not|no|nothing) ([^ ]+ ){0,2}(open|read)' \
  'door|status'

# A Router sentence that inverts the rule (the blocker opened whole, some other read negated
# instead) must not pass as if it stated the rule: the negation has to sit on the verb whose object
# is the blocker, not on an unrelated clause that only happens to share the sentence.
not() { ! "$@"; }
inverted_router="$tmp/inverted-router.md"
cat >"$inverted_router" <<'EOF'
## Router

A Ticket's path is matched on that file alone: a Ticket its `Blocked by` line names is opened whole before the ticket door, and nothing else is read.

## Non-negotiables
EOF
out="$(section_sentences "$inverted_router" "## Router")"
expect "the check rejects a Router sentence that opens the blocker whole and negates an unrelated read" \
  not one_sentence_says 'blocker|blocked by' \
  '(blocked by|blocker)([^ ]+ ){1,8}(never|not|no|nothing) ([^ ]+ ){0,2}(open|read)' \
  'door|status'

# The two places the repository repeats the row. A reader who takes either at its word and types
# `/do sketch a shape` has to land on the same door the router sends them to.
page="$repo/docs/do.md"
has "the page's door table quotes the router's row" "$page" \
  "| a runnable throwaway: a layout, a variant to try | \`/prototype\` |"
rows_lack "no row of the page's door table matches the word \`sketch\`" "$page" \
  '| The request | Where it goes |' sketch
glossary="$repo/CONTEXT.md"
bullet_has "the glossary's Playbook rule sends a runnable throwaway to prototype" "$glossary" \
  "- \`do\` ships five **Playbooks**" "throwaway is \`prototype\`"
bullet_lacks "no line of the glossary's Playbook rule matches the word \`sketch\`" "$glossary" \
  "- \`do\` ships five **Playbooks**" sketch

# The eval case that grades the row. Its name is the row's, so a case whose name still carries the
# word grades a door the router no longer has.
evals="$repo/skills/do/evals"
case="$evals/layout-goes-to-prototype"
expect "no eval case folder is named after the word the \`sketch\` skill owns" \
  test -z "$(find "$evals" -maxdepth 1 -type d -iname '*sketch*')"
expect "the case that grades the row is named for what it grades" test -d "$case"
has "the case file names the case" "$case/case.yaml" "name: layout-goes-to-prototype"
has "the door grader's line names what the case grades" "$case/graders/names-prototype.md" \
  "A layout goes to prototype; do never builds a throwaway."
has "the evals README carries the case's row" "$evals/README.md" \
  "| \`layout-goes-to-prototype\` |"
# A rename that misses the README leaves a row grading nothing, which reads as coverage.
rows_ok=1
while read -r name; do
  [ -d "$evals/$name" ] || {
    echo "      README row with no case folder: $name"
    rows_ok=0
  }
done < <(awk -F'|' '/^\| `/ { gsub(/[` ]/, "", $2); print $2 }' "$evals/README.md")
expect "every row of the evals README names a case folder that exists" test "$rows_ok" = 1

if [ "$fails" = 0 ]; then echo "PASS"; else
  echo "$fails failing"
  exit 1
fi
