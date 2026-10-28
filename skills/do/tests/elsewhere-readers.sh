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
reply="$here/../references/reply.md"
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

echo "# the stop at the Plan step, as it runs today"

flat="$(flat_section "$elsewhere" "## At the Plan step")"
expect "elsewhere.md carries a section for the Plan step" test -n "$flat"
carries_each "one \`Elsewhere:\` item stops the run as blocked before the claim, the worktree and the Spec branch" \
  "as blocked" -- "before the claim, the worktree and the Spec branch"
carries "the Ticket keeps the status the door printed" "\`status=\`"
carries_each "a change of direction runs no spec-finding.sh and ends on change-of-direction.md's /discuss command" \
  "change of direction" -- "\`spec-finding.sh\` is not run" -- "\`direction\`" -- "\`/discuss\`" -- "Read [change-of-direction.md](change-of-direction.md) when "
carries "spec-finding.sh is run once per \`Elsewhere:\` item, its output saved per item" \
  "scripts/spec-finding.sh <the Ticket's path> '<Belongs to>' '<the behaviour>' '<Location>' | tee <state>/finding.<n>"
carries_each "each value is single-quoted, a quote inside written as '\\''" "single quotes" -- "'\\''"
carries "the fourth argument is left out on \`Location: not known\`" "The fourth argument is left out"
carries "no choice-taker is forked over a finding" "No \`choice-taker\` is forked"
carries "the stop is the \`outward\` Handover class" "\`outward\` Handover class"
carries "the Reply is the lines reply-lines.sh elsewhere prints" \
  "scripts/reply-lines.sh elsewhere --door <state>/door <state>/finding.1 '<the behaviour>'"
carries "on exit 3 the run copies nothing" "On exit 3 the run copies nothing"
carries "under --auto the stop is the same lines" "under \`--auto\` the stop is the same lines"

echo "# the stop at the build step, as it runs today"

flat="$(flat_section "$elsewhere" "## At the build step")"
expect "elsewhere.md carries a section for the build step" test -n "$flat"
carries "the Builder is not forked again" "The Builder is not forked again"
carries "spec-finding.sh runs with --step build ahead of the Ticket's path" "\`--step build\`"
carries "the Reply passes --build with the run's worktree after --door" \
  "\`--build <the run's worktree>\` after \`--door <state>/door\`"
carries "the worktree, its branch and the commits on it are kept" \
  "The worktree, its branch and the commits already on it are kept"
carries "a change of direction there ends on the same /discuss command" "\`/discuss\`"

echo "# a run that meets no work for another repository reads none of the stop's text"

# ticket.md and reply.md are read by every ticket run; the stop lives in elsewhere.md alone.
for file in "$ticket" "$reply"; do
  out="$(tr '\n' ' ' <"$file" | tr -s ' ')"
  name="$(basename "$file")"
  absent "$name carries no Work for another repository block" "**Work for another repository.**"
  absent "$name carries no spec-finding.sh call" "spec-finding.sh"
  absent "$name carries no reply-lines.sh elsewhere call" "reply-lines.sh elsewhere"
  absent "$name shapes no message for a run stopped on work for another repository" \
    "stopped on work for another repository"
done

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
