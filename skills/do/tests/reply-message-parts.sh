#!/usr/bin/env bash
# reply-message-parts.sh: reply.md's `## The message` builds the do Reply from five parts and
# nothing else, in this order: the Plan block (the `Playbook: <name>` line, then a `Plan:` line),
# `## For whom`, `## Pending debt`, the `Yours:` line only when the run hands the developer
# something, and `## Next step` last. The Run section and the other sections (Inherited, Commits,
# Evidence, Principles, Rulings, Skipped, Left uncommitted) belong to the Run report, which is
# written to a file only under `--auto` and never into the message.
#
# A developer who comes back to an unattended run reads only the Reply: one still carrying the Run
# section and ten sections is the long output they asked to be rid of, and an `--auto` Reply that
# drops the Rulings with no file loses the one record of what was decided for them.
#
# Everything is found by what it says, never by a line number, and read flattened, since the
# references hard-wrap.
# Run: bash skills/do/tests/reply-message-parts.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
reply="$here/../references/reply.md"
fails=0

section="$(passage_of "$reply" "## The message" "## ")"

# The section's first numbered list, one item per line, flattened: an item runs from its marker to
# the line before the next marker, and the list ends at the first line that is neither a marker
# nor indented under one.
message_items() {
  awk '
    /^[0-9]+\. / { if (item != "") print item; item = $0; on = 1; next }
    on && /^ +[^ ]/ { item = item " " $0; next }
    on && /^ *$/ { next }
    on { exit }
    END { if (item != "") print item }
  ' <<<"$section" | tr -s ' '
}

echo "# reply.md's The message: the five parts the Reply is built from, in order"

expect "reply.md carries its The message section" test -n "$section"
mapfile -t items < <(message_items)
expect "The message builds the Reply from exactly five parts (found ${#items[@]})" \
  test "${#items[@]}" -eq 5

flat="${items[0]:-}"
carries "the first part is the Plan block, the Playbook line then a Plan: line" \
  "Playbook: <name>" "Plan:"
before "the Playbook line comes before the Plan: line" "Playbook: <name>" "Plan:"

flat="${items[1]:-}"
carries_any "the second part is For whom" "## For whom" "[For whom]("

flat="${items[2]:-}"
carries_any "the third part is Pending debt" "## Pending debt" "[Pending debt]("

flat="${items[3]:-}"
carries "the fourth part is the Yours: line" "Yours:"
carries_any "the Yours: line is written only when the run hands the developer something" \
  "only when" "only if" "only on a run" "only a run that"

flat="${items[4]:-}"
carries_any "the fifth and last part is Next step" "## Next step" "[Next step]("

echo "# the Run section and the other sections are no part of the message"

flat="$(printf '%s ' "${items[@]}")"
for heading in "## Run" "[Run](#run)" "[Sections](#sections)" "## Inherited" "## Commits" "## Evidence" \
  "## Principles" "## Rulings" "## Skipped" "## Left uncommitted"; do
  if grep -qF -- "$heading" <<<"$flat"; then
    fail "no part of the message is $heading"
  else
    ok "no part of the message is $heading"
  fi
done

echo "# they are named as the Run report's, written to a file only under --auto"

flat="$(awk 'BEGIN { RS = "" } index($0, "Run report") { gsub(/\n/, " "); print }' <<<"$section" | tr -s ' ')"
expect "The message names the Run report" test -n "$flat"
carries_any "the Run report holds the Run section" "Run section" "[Run](" "## Run"
carries "the Run report holds the seven other sections" \
  "Inherited" "Commits" "Evidence" "Principles" "Rulings" "Skipped" "Left uncommitted"
carries "the Run report is written to a file under --auto" "file" "--auto"
carries_any "the Run report file is written only under --auto" \
  "only under \`--auto\`" "under \`--auto\` only" "only with \`--auto\`" "only on \`--auto\`" \
  "only when \`--auto\`" "only an \`--auto\`" "only in an \`--auto\`" "only on an \`--auto\`"
carries_any "the Run report never goes into the message" \
  "never into the message" "never in the message" "not part of the message" \
  "no part of the message" "never part of the message" "not in the message" \
  "stays out of the message" "never goes into the message" "outside the message"
carries_any "a second --auto run keeps the earlier run's Run report readable" \
  "appends" "below the earlier" "never replace" "never overwrite" "unique to each run" \
  "unique to the run" "one file per run" "a file of its own"

echo "# a weakened guard reaches the message through Pending debt, with or without --auto"

# A committed `disableAllHooks` makes the probe print guard=header-only: when that Guard: line rides
# only the Run report, a run without --auto never tells the developer the pattern guard was off.
flat="$(item_holding <(passage_of "$reply" "## Sections" "## ") '[0-9]+\.' '**Pending debt.**' |
  tr '\n' ' ' | tr -s ' ')"
carries_each "Pending debt lists the Guard: line of a header-only or verdict-less probe, its disabled_by= file, with or without --auto" \
  "Guard:" -- "header-only" -- "disabled_by=" -- \
  "printed no verdict" "no verdict" "failed and printed" "probe failed" "probe that failed" -- \
  "with or without \`--auto\`"

[ "$fails" -eq 0 ] && exit 0
exit 1
