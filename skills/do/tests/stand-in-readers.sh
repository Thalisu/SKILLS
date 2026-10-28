#!/usr/bin/env bash
# stand-in-readers.sh: stand-in.md, the reference a session reads when it cannot fork the reader or
# the Builder, opens on every reader that reaches it and on the condition that sends them.
# Run: bash skills/do/tests/stand-in-readers.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
stand_in="$here/../references/stand-in.md"
fails=0

echo "# stand-in.md's readers: named in its opening, with the condition that sends them"

# The opening is the first paragraph past the title.
flat="$(awk 'BEGIN { RS = "" } !/^#/ { gsub(/\n/, " "); print; exit }' "$stand_in" 2>/dev/null | tr -s ' ')"
expect "stand-in.md opens on a paragraph" test -n "$flat"
carries "the opening names the door that forks the reader" "door" "do-reader"
carries "the opening names the second run that re-forks the reader on moved documents" "second run"
carries "the opening names the re-fork after a Ruling that rewrote a criterion" "Ruling"
carries "the opening names the resume after discuss" "discuss"
carries "the opening names the build step that forks the Builder" "build step" "do-builder"
carries "the opening names the Resume that forks the Builder for unbuilt behaviours" "Resume"
carries_each "the opening names the condition: the Agent tool withheld, or the agent not listed" \
  "Agent tool" -- "withheld" -- "not listed" "lists no" "no \`do-reader\`"

echo "# the session in the reader's place"

flat="$(flat_section "$stand_in" "## The reader")"
expect "stand-in.md carries a section for the reader" test -n "$flat"
carries "the session reads the Spec and the journey itself" "reads both documents itself"
carries_each "it writes the Digest at the same path and in the same format, Sources from the door's hashes" \
  "same path" -- "same format" -- "the door's own hashes"
carries "a document not on disk is recorded absent" "\`absent\`"
carries "one line names the branch that holds, and the command that links the reader" \
  "in one line which branch holds" "scripts/link-skills.sh"
carries "the run neither stops nor asks for the tool or the agent" "neither stops nor asks"
carries "no other agent is forked in the reader's place" "never forks another agent in the reader's place"
carries "a reader failure is never stood in for" "never on a return the reader actually made"

[ "$fails" -eq 0 ]
