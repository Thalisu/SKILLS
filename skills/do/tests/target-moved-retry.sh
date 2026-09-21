#!/usr/bin/env bash
# target-moved-retry.sh: what mechanics.md's `## The review` has the run do on a review return of
# `not landed: target moved`: the same run integrates again and lands through the fix call on the
# Review it already has, instead of stopping for the developer to type `/do` again, and it keeps doing
# so with no fixed count, per ADR 0044, which supersedes ADR 0034's stop on a second move. It stops as
# blocked only on a `not landed: target moved` right after an integration that ticked as a no-op,
# since that return means no other landing happened.
# Run: bash skills/do/tests/target-moved-retry.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
mech="$here/../references/mechanics.md"
fails=0

# The section opens with ADR 0033's "never a second review" and the fix call for a run committed
# after the review, so the checks read only the passage on what a not-landed return does, where a
# phrase about the moved target cannot be borrowed from elsewhere in the section.
flat="$(passage_of "$mech" "The run makes no commit for a Finding" "**What the run commits after the review.**" |
  tr '\n' ' ' | tr -s ' ')"

echo "# mechanics.md / ## The review: a moved target is integrated again in the same run"
expect "mechanics.md carries the passage on what the run does with a return that did not land" \
  test -n "$flat"
carries "the passage answers the not landed: target moved return" "not landed: target moved"

integrated=(
  "runs its integration once more" "runs the integration once more"
  "through its integration once more" "through the integration once more"
  "the integration runs once more" "integrates once more" "integrates again"
)
carries_any "the run answers the moved target by running its integration again" "${integrated[@]}"
carries_any "it does so in the same run, not in a run the developer types again" \
  "in the same run" "within the same run" "in this same run" "without a second \`/do\`"
carries_any "the retried integration judges the Loss ledger its rebase wrote" \
  "**The Loss ledger judged.**" "the Loss ledger judged" "judges the Loss ledger" "the ledger judged"
carries_any "the retried integration brings the reapplies back" \
  "**The reapplies brought back.**" "the reapplies brought back" "brings the reapplies back" \
  "brings its reapplies back" "its reapplies brought back"
# One tree is gated once: the retry's Gate and the fix call's Gate ran over the same tree, and the
# loop has no fixed count, so every lap paid for the suite twice. The run hands the branch over
# without gating it and the fix call below gates it.
mapfile -t skipped < <(no_gate_phrasings)
mapfile -t gated_by_the_call < <(fix_call_gates_phrasings)
carries_any "the retried integration hands its branch over with no Gate of the run's own" "${skipped[@]}"
carries_any "the Gate is dropped there because the fix call gates that same tree itself" \
  "${gated_by_the_call[@]}"
# shellcheck disable=SC2034  # lib.sh's check_absent reads $out
out="$flat"
check_absent "the passage no longer has the retried integration run a Gate before the fix call" \
  0 0 "the whole **Gate**" "the whole Gate" "the whole gate" \
  "green **Gate** hands" "green Gate hands" "green gate hands"

fixcall=(
  "fix call on the Review" "\`fix\` call on the Review" "\`fix\` on the Review"
  "fix call with the Review's location" "\`fix\` with the Review's location"
)
carries_any "the retried integration lands through the fix call on the Review the run already has" "${fixcall[@]}"
carries_any "the retry never calls a second review, which would fork every reviewer again" \
  "never a second review" "no second review" "not a second review" "never calls the review again" \
  "no reviewer is forked" "forks no reviewer"

i="$(first_at "${integrated[@]}")"
f="$(first_at "${fixcall[@]}")"
expect "the fix call comes after the integration run once more, never before it" \
  test "$i" -gt 0 -a "$f" -gt "$i"

carries_any "the retry has no fixed count: it repeats for as long as each return reads target moved" \
  "no fixed count" "no count" "without a count" "no cap" "without a cap" "no set number" \
  "for as long as each" "as long as each" "for as long as every" "as long as every"

# The one stop of the loop: a target moved right after an integration that replayed nothing, so no
# other landing moved the target in between and a retry would only meet the same tip again.
noop=(
  "ticked as a no-op" "ticks as a no-op" "ticked a no-op" "a no-op integration" "integration was a no-op"
  "replayed nothing" "replays nothing" "replayed no commit" "replays no commit"
  "tip the previous attempt already met" "tip the last attempt already met"
  "tip the attempt before it already met"
)
carries_any "the passage names the stop: a target moved right after an integration that ticked as a no-op" \
  "${noop[@]}"

# What the run does on that return is read from where the passage first names it on, so a stop or a
# recovery command the passage gives another return cannot answer for it.
whole="$flat"
n="$(first_at "${noop[@]}")"
flat="${whole:$((n > 0 ? n - 1 : ${#whole}))}"
carries_any "a target moved after a no-op integration stops the run as blocked, like every other not landed" \
  "stops the run as blocked" "the run stops as blocked" "stops as blocked" "stops the run, blocked" \
  "stops blocked"
retyped=(
  "the same run request typed again" "the same run request, typed again" "the run request typed again"
  "types the same run request again" "type the same run request again"
)
carries_any "the reply to a target moved after a no-op integration names the same run request typed again as its recovery" \
  "${retyped[@]}"
flat="$whole"

# The cap ADR 0044 supersedes: a count of retries beside the loop would still block the run one past it.
cap=(
  "once per run" "once a run" "once in a run" "a single retry"
  "a second \`not landed: target moved\`" "A second \`not landed: target moved\`"
  "the second \`not landed: target moved\`" "The second \`not landed: target moved\`"
)
# shellcheck disable=SC2034  # lib.sh's check_absent reads $out
out="$flat"
check_absent "the passage no longer caps the retry at once per run nor stops on a second target moved" \
  0 0 "${cap[@]}"

# shellcheck disable=SC2034  # lib.sh's check_absent reads $out
out="$flat"
check_absent "a first target moved return is no longer among the reasons that stop the run as blocked" \
  0 0 ", \`not landed: target moved\`, "
check_absent "the recovery command is no longer given for any target moved return, a first one being retried" \
  0 0 "On \`not landed: target moved\` the reply names" "On \`not landed: target moved\`, the reply names"

# The integration line of a run whose integration ran after the review, the retry above or a resumed
# run's: the review read the first integration's ledger only, so the reply is the one place a drop
# of the later integration is seen before it reaches the developer's branch.
# The `## Run` item is read from the marker of the item that names the state the integration
# reached to the next marker: the list is renumbered whenever an item is added above, so the item
# is found by the state it records and never by the number it happens to carry.
echo "# reply.md: the drops of an integration after the review reach the reply"
flat="$(item_holding "$here/../references/reply.md" '[0-9]+\.' "The state the integration reached" |
  tr '\n' ' ' | tr -s ' ')"
expect "reply.md carries the integration line" test -n "$flat"

after=(
  "integration that ran after the review" "integration ran after the review"
  "integration run after the review" "integration that came after the review"
  "integration came after the review" "integration after the review" "integrated after the review"
)
carries_any "the integration line answers an integration that ran after the review" "${after[@]}"
carries_any "a run that integrated twice carries both integrations' lines, never only the first one's" \
  "both integrations" "each integration's lines" "every integration's lines" \
  "the lines of both integrations" "the lines of each integration" "both of its integrations"

# What the line gives the later integration is read from where the item first names it on, so a
# drop the item lists for the first integration cannot answer for it.
whole="$flat"
a="$(first_at "${after[@]}")"
flat="${whole:$((a > 0 ? a - 1 : ${#whole}))}"
carries_any "every drop of the integration after the review is listed" \
  "every \`drop\`" "each \`drop\`" "every dropped entry" "each dropped entry"
carries_any "each drop of the integration after the review is marked as coming after the review" \
  "marked as coming after the review" "marked as after the review" "marked after the review" \
  "marked as set aside after the review" "marked as dropped after the review" \
  "flagged as coming after the review" "labelled as coming after the review"
flat="$whole"

# Story 22: the three worktree Playbooks integrate alike. A session follows its own Playbook's review
# and reply steps, so a step that stops on a moved target the loop answers, or hands the developer the
# request to type again for one, undoes the retry mechanics.md carries. A step may point at that
# review for the mechanics, as long as it names the retry or the no-op stop that ends it.
echo "# ticket.md, bug-fix.md, refactoring.md: each Playbook retries a moved target in the same run"
retry=("${integrated[@]}" "${noop[@]}")
# Each step is read from its own marker to the next one, and is found by a phrase of its own work:
# `ticket` absorbed its grounding steps into one and renumbered everything below them, and the next
# such change renumbers these again, so a step number, a step title and the order they sit in anchor
# nothing. The key is never a clause the checks below read, so a step that drops the retry is found
# red rather than found empty.
playbooks=(
  "ticket|\*\*[0-9]+\.|git merge-base refs/heads/|Written by [reply.md](reply.md)"
  "bug-fix|\*\*[0-9]+\.|git merge-base refs/heads/|Written by [reply.md](reply.md)"
  "refactoring|### [0-9]+\.|git merge-base refs/heads/|Written by [reply.md](reply.md)"
)
for row in "${playbooks[@]}"; do
  IFS='|' read -r name marker review_key reply_key <<<"$row"
  book="$here/../references/$name.md"

  flat="$(item_holding "$book" "$marker" "$review_key" | tr '\n' ' ' | tr -s ' ')"
  expect "$name.md carries its review step" test -n "$flat"
  carries_any "the $name review step integrates a target moved again, or names the no-op stop that ends the loop" \
    "${retry[@]}"
  # shellcheck disable=SC2034  # lib.sh's check_absent reads $out
  out="$flat"
  check_absent "the $name review step no longer stops the run as blocked on every not landed, a first target moved among them" \
    0 0 "for any reason the review gives. The run stops as blocked"
  check_absent "the $name review step no longer caps the retry at once per run nor stops on a second target moved" \
    0 0 "${cap[@]}"
  n="$(first_at "${noop[@]}")"
  r="$(first_at "${retyped[@]}")"
  expect "the $name review step names the run request typed again only for the no-op stop, never a target moved the loop answers" \
    test "$r" = 0 -o \( "$n" -gt 0 -a "$r" -gt "$n" \)

  flat="$(item_holding "$book" "$marker" "$reply_key" | tr '\n' ' ' | tr -s ' ')"
  expect "$name.md carries its reply step" test -n "$flat"
  # shellcheck disable=SC2034  # lib.sh's check_absent reads $out
  out="$flat"
  check_absent "the $name reply no longer gives a recovery for a second target moved" 0 0 "${cap[@]}"
  n="$(first_at "${noop[@]}")"
  r="$(first_at "${retyped[@]}")"
  expect "the $name reply names the run request typed again as the recovery for the no-op stop only" \
    test "$n" -gt 0 -a "$r" -gt "$n"
done

exit $((fails > 0))
