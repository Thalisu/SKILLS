#!/usr/bin/env bash
# elsewhere-readers.sh: elsewhere.md, the reference a ticket run reads when it meets work for
# another repository, opens on every reader that reaches it and on the condition that sends them.
# Run: bash skills/do/tests/elsewhere-readers.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
elsewhere="$here/../references/elsewhere.md"
skill="$here/../SKILL.md"
ticket="$here/../references/ticket.md"
fails=0

echo "# elsewhere.md's readers: named in its opening, with the condition that sends them"

# The opening is the first paragraph past the title.
flat="$(awk 'BEGIN { RS = "" } !/^#/ { gsub(/\n/, " "); print; exit }' "$elsewhere" 2>/dev/null | tr -s ' ')"
expect "elsewhere.md opens on a paragraph" test -n "$flat"
carries "the opening names the ticket Playbook" "\`ticket\`"
carries "the opening names the Plan step" "Plan step"
carries "the opening names the condition that sends the Plan step: an \`Elsewhere:\` item in the Plan's behaviours" \
  "\`Elsewhere:\`"
carries "the opening names the build step" "build step"
carries "the opening names the condition that sends the build step: the Builder's work-for-another-repository stopped line" \
  "\`stopped: work for another repository:\`"

echo "# ticket.md's steps that meet work for another repository read elsewhere.md then"

# The pointer sentence of one step of ticket.md, flattened.
pointer_in_step() { # $1 the step's marker text
  item_holding "$ticket" '\*\*[0-9]+\.' "$1" | tr '\n' ' ' | tr -s ' ' |
    grep -oE 'Read \[elsewhere\.md\]\(elsewhere\.md\) when [^.]*\.' | head -n 1
}

flat="$(pointer_in_step '**1. Plan.**')"
expect "ticket.md's Plan step points at elsewhere.md with \`Read [elsewhere.md](elsewhere.md) when\`" test -n "$flat"
carries "the Plan step reads it when the verified Plan's behaviours carry an \`Elsewhere:\` item" \
  "\`Elsewhere:\`" "\`## Behaviours\`"

flat="$(pointer_in_step '**3. Build.**')"
expect "ticket.md's build step points at elsewhere.md with \`Read [elsewhere.md](elsewhere.md) when\`" test -n "$flat"
carries "the build step reads it when the Builder's return carries a work-for-another-repository stopped line" \
  "\`stopped: work for another repository:\`"

echo "# every pointer to elsewhere.md reads \`Read [elsewhere.md](elsewhere.md) when <condition>\`"

# SKILL.md's Links entry is the references list, not a pointer; elsewhere.md links nothing to itself.
pointers=0
misshapen=""
for file in "$here"/../references/*.md "$here"/../agents/*.md; do
  [ "$file" = "$elsewhere" ] && continue
  while IFS= read -r hit; do
    [ -n "$hit" ] || continue
    pointers=$((pointers + 1))
    grep -qE '^Read \[elsewhere\.md\]\(elsewhere\.md\) when ' <<<"$hit" ||
      misshapen="$misshapen${misshapen:+; }$(basename "$file"): $hit"
  done < <(tr '\n' ' ' <"$file" | tr -s ' ' | grep -oE '(Read )?\[[^]]*\]\([^)]*elsewhere\.md[^)]*\)( when )?')
done
expect "the do skill points at elsewhere.md from the two steps that meet the work" test "$pointers" -ge 2
if [ -z "$misshapen" ]; then
  ok "every pointer to elsewhere.md has the \`Read <file> when <condition>\` shape"
else
  fail "every pointer to elsewhere.md has the \`Read <file> when <condition>\` shape (misshapen: $misshapen)"
fi

echo "# SKILL.md's references list names elsewhere.md with its readers and its condition"

flat="$(grep -F -- '- [elsewhere.md](references/elsewhere.md):' "$skill" | tr -s ' ')"
expect "SKILL.md's Links list carries an entry for elsewhere.md" test -n "$flat"
carries "the entry names its readers: the ticket Plan step and build step" "\`ticket\`" "Plan step" "build step"
carries "the entry names the conditions: an \`Elsewhere:\` item, and the Builder's stopped line" \
  "\`Elsewhere:\`" "\`stopped: work for another repository:\`"

[ "$fails" -eq 0 ]
