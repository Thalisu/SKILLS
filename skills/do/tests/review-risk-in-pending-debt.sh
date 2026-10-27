#!/usr/bin/env bash
# review-risk-in-pending-debt.sh: the Reply's Pending debt lists every `Risk:` line and every
# `Axis not run:` line of the review's return, and every drop of an integration that ran after the
# review, with or without `--auto`, and the Reply stays five parts.
#
# The developer who ran `do` without `--auto` gets no Run report (ADR 0091): a risk-class Consider
# Finding, an Axis the review never ran or a hunk a post-review integration let go that only the
# Run report carries reaches nobody, though mechanics.md promises a risk class is never dismissed
# silently. The debt skill reads the Debt file, which holds the Pending debt part alone.
#
# Everything is found by what it says, never by a line number, and read flattened, since the
# references hard-wrap.
# Run: bash skills/do/tests/review-risk-in-pending-debt.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
reply="$here/../references/reply.md"
mechanics="$here/../references/mechanics.md"
fails=0

# A sentence naming a line may put the flag that scopes it in the sentence right after it, so each
# hit carries its next sentence along.
sentences_with() { # $1 a fixed string; stdin: flattened text; stdout: each sentence carrying it, with the one after
  awk -v k="$1" '{
    n = split($0, s, /\. /)
    for (i = 1; i <= n; i++) if (index(s[i], k)) print s[i] ". " (i < n ? s[i + 1] : "")
  }'
}

pending_item="$(passage_of "$reply" "## Sections" "## " | numbered_items | grep -F '**Pending debt.**')"
expect "reply.md's Sections item for Pending debt is found" test -n "$pending_item"

with_or_without=("with or without \`--auto\`" "with \`--auto\` or without" "whether or not"
  "not only under \`--auto\`" "without \`--auto\` too" "also without \`--auto\`"
  "even without \`--auto\`" "on every run" "every run")
listed=("listed" "lists" "named" "names" "goes here" "go here" "carried here" "here")

echo "# every Risk: line of the review's return is Pending debt, with or without --auto"

flat="$pending_item"
affirms "the Pending debt item lists every Risk: line of the review's return" \
  "\`Risk" -- "${listed[@]}"
flat="$(sentences_with "\`Risk" <<<"$pending_item")"
carries_any "the Risk: lines reach Pending debt with or without --auto" "${with_or_without[@]}"

echo "# every Axis not run: line of the review's return is Pending debt, with or without --auto"

flat="$pending_item"
affirms "the Pending debt item lists every Axis not run: line of the review's return" \
  "\`Axis not run" -- "${listed[@]}"
flat="$(sentences_with "\`Axis not run" <<<"$pending_item")"
carries_any "the Axis not run: lines reach Pending debt with or without --auto" "${with_or_without[@]}"

echo "# every drop of an integration that ran after the review is Pending debt, with or without --auto"

flat="$(sentences_with "after the review" <<<"$pending_item")"
expect "the Pending debt item names an integration that ran after the review" test -n "$flat"
carries_any "the Pending debt item lists every drop of that integration" \
  "\`drop\`" "drop" "dropped" "let go" "set aside"
carries_any "the post-review drops reach Pending debt with or without --auto" "${with_or_without[@]}"

echo "# mechanics.md's Reading the return flags Risk: and Axis not run: through the Reply's Pending debt"

flat="$(bullets_opening_on <(passage_of "$mechanics" "### Reading the return" "### ") "\`Risk:\`")"
expect "mechanics.md's Risk: bullet is found" test -n "$flat"
carries_any "the Risk: bullet names the Reply's Pending debt" "Pending debt"
flat="$(bullets_opening_on <(passage_of "$mechanics" "### Reading the return" "### ") "\`Axis not run:\`")"
expect "mechanics.md's Axis not run: bullet is found" test -n "$flat"
carries_any "the Axis not run: bullet names the Reply's Pending debt" "Pending debt"

echo "# the Reply stays five parts, none of them a part of its own for the review's lines"

mapfile -t items < <(passage_of "$reply" "## The message" "## " | numbered_items)
expect "The message has five numbered parts" test "${#items[@]}" -eq 5
# shellcheck disable=SC2034 # lib.sh's check_absent reads $out
out="$(printf '%s\n' "${items[@]}")"
check_absent "no part of The message is given over to the review's lines" 0 0 \
  "Risk:" "Axis not run:" "## Risks" "## Review"

[ "$fails" -eq 0 ] && exit 0
exit 1
