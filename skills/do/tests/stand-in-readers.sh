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

[ "$fails" -eq 0 ]
