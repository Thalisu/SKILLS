#!/usr/bin/env bash
# stand-in-readers.sh: stand-in.md, the reference a session reads when it cannot fork the reader or
# the Builder, opens on every reader that reaches it and on the condition that sends them.
# Run: bash skills/do/tests/stand-in-readers.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
stand_in="$here/../references/stand-in.md"
mechanics="$here/../references/mechanics.md"
ticket="$here/../references/ticket.md"
builder="$here/../references/builder.md"
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

echo "# a run that forks both agents reads no stand-in text"

# The files every run that forks the reader and the Builder reads hold a pointer to stand-in.md in
# place of the stand-in itself.
flat="$(flat_section "$mechanics" "## The reader")"
carries "mechanics.md's reader section points at stand-in.md" "[stand-in.md](stand-in.md)"
out="$flat"
absent "mechanics.md's reader section no longer has the session read the documents itself" \
  "reads both documents itself"
absent "mechanics.md's reader section no longer names the installer for an unlisted reader" \
  "link-skills.sh"

flat="$(flat_section "$ticket" "## Door")"
carries "ticket.md's door points at stand-in.md" "[stand-in.md](stand-in.md)"
out="$flat"
absent "ticket.md's door no longer has the session read the documents itself" \
  "the session reads both itself"

flat="$(item_holding "$ticket" '\*\*[0-9]+\.' "subagent_type: do-builder" | tr '\n' ' ' | tr -s ' ')"
carries "ticket.md's build step points at stand-in.md" "[stand-in.md](stand-in.md)"
out="$flat"
absent "ticket.md's build step no longer has the session run the loop itself" \
  "the session runs the loop itself"
absent "ticket.md's build step no longer has the session author the flows itself" \
  "authors the flows itself"

flat="$(awk 'BEGIN { RS = "" } /^## / { exit } { gsub(/\n/, " "); print }' "$builder" | tr -s ' ')"
carries "builder.md's preamble points at stand-in.md" "[stand-in.md](stand-in.md)"
out="$flat"
absent "builder.md's preamble no longer has the session run the loop itself" \
  "the session runs the loop itself"

echo "# every pointer to stand-in.md reads \`Read [stand-in.md](stand-in.md) when <condition>\`"

# SKILL.md's Links entry is the references list, not a pointer; stand-in.md links nothing to itself.
pointers=0
misshapen=""
for file in "$here"/../references/*.md "$here"/../agents/*.md; do
  [ "$file" = "$stand_in" ] && continue
  while IFS= read -r hit; do
    [ -n "$hit" ] || continue
    pointers=$((pointers + 1))
    grep -qE '^Read \[stand-in\.md\]\(stand-in\.md\) when ' <<<"$hit" ||
      misshapen="$misshapen${misshapen:+; }$(basename "$file"): $hit"
  done < <(tr '\n' ' ' <"$file" | tr -s ' ' | grep -oE '(Read )?\[[^]]*\]\([^)]*stand-in\.md[^)]*\)( when )?')
done
expect "the do skill points at stand-in.md from the steps that stand in" test "$pointers" -ge 4
if [ -z "$misshapen" ]; then
  ok "every pointer to stand-in.md has the \`Read <file> when <condition>\` shape"
else
  fail "every pointer to stand-in.md has the \`Read <file> when <condition>\` shape (misshapen: $misshapen)"
fi

[ "$fails" -eq 0 ]
