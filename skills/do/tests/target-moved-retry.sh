#!/usr/bin/env bash
# target-moved-retry.sh: what mechanics.md's `## The review` has the run do on a first review return
# of `not landed: target moved`: the same run integrates once more and lands through the fix call on
# the Review it already has, per ADR 0034, instead of stopping for the developer to type `/do` again,
# and it does so once per run: a second `not landed: target moved` stops the run as blocked.
# Run: bash skills/do/tests/target-moved-retry.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
mech="$here/../references/mechanics.md"
fails=0

# Where in $flat the earliest of the fixed strings sits, 0 when none does: an order check that keeps
# the same phrasings carries_any accepts.
first_at() { # $1.. fixed strings; the smallest positive index of any of them in $flat, on stdout
  local key at best=0
  for key in "$@"; do
    at="$(awk -v s="$flat" -v k="$key" 'BEGIN { print index(s, k) }')"
    if [ "$at" -gt 0 ] && { [ "$best" = 0 ] || [ "$at" -lt "$best" ]; }; then best="$at"; fi
  done
  echo "$best"
}

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
  "the integration runs once more" "integrates once more"
)
carries_any "the run answers the moved target by running its integration once more" "${integrated[@]}"
carries_any "it does so in the same run, not in a run the developer types again" \
  "in the same run" "within the same run" "in this same run" "without a second \`/do\`"
carries_any "the retried integration judges the Loss ledger its rebase wrote" \
  "**The Loss ledger judged.**" "the Loss ledger judged" "judges the Loss ledger" "the ledger judged"
carries_any "the retried integration brings the reapplies back" \
  "**The reapplies brought back.**" "the reapplies brought back" "brings the reapplies back" \
  "brings its reapplies back" "its reapplies brought back"
carries_any "the retried integration runs the whole Gate" \
  "the whole **Gate**" "the whole gate" "the whole Gate"

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

second=(
  "a second \`not landed: target moved\`" "A second \`not landed: target moved\`"
  "the second \`not landed: target moved\`" "The second \`not landed: target moved\`"
  "\`not landed: target moved\` again" "\`not landed: target moved\` a second time"
  "\`not landed: target moved\` once more"
)
carries_any "the passage answers a second not landed: target moved, the fix call after the retry returning it again" \
  "${second[@]}"
carries_any "the retry happens once per run, so a branch that keeps moving never loops the run" \
  "once per run" "once a run" "once in a run" "at most once" "only once" "a single retry" \
  "one retry" "never a second retry" "no second retry" "never retries twice"

# What the run does on that second return is read from where the passage first names it on, so a
# stop or a recovery command the passage gives another return cannot answer for it.
whole="$flat"
s="$(first_at "${second[@]}")"
flat="${whole:$((s > 0 ? s - 1 : ${#whole}))}"
carries_any "a second target moved return stops the run as blocked, like every other not landed" \
  "stops the run as blocked" "the run stops as blocked" "stops as blocked" "stops the run, blocked" \
  "stops blocked"
retyped=(
  "the same run request typed again" "the same run request, typed again" "the run request typed again"
  "types the same run request again" "type the same run request again"
)
carries_any "the reply to a second target moved names the same run request typed again as its recovery" \
  "${retyped[@]}"
flat="$whole"

# shellcheck disable=SC2034  # lib.sh's check_absent reads $out
out="$flat"
check_absent "a first target moved return is no longer among the reasons that stop the run as blocked" \
  0 0 ", \`not landed: target moved\`, "
check_absent "the recovery command is no longer given for any target moved return, a first one being retried" \
  0 0 "On \`not landed: target moved\` the reply names" "On \`not landed: target moved\`, the reply names"

# The integration line of a run whose integration ran after the review, the retry above or a resumed
# run's: the review read the first integration's ledger only, so the reply is the one place a drop
# of the later integration is seen before it reaches the developer's branch.
echo "# reply.md / item 26: the drops of an integration after the review reach the reply"
flat="$(passage_of "$here/../references/reply.md" "26. **Integration line.**" "27." | tr '\n' ' ' | tr -s ' ')"
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
# and reply steps, so a step that stops on any moved target, or hands the developer the request to
# type again for a first one, undoes the retry mechanics.md carries. A step may point at that review
# for the mechanics, as long as it names the retry or the second move that ends it.
echo "# ticket.md, bug-fix.md, refactoring.md: each Playbook retries a first moved target in the same run"
retry=("${integrated[@]}" "${second[@]}")
playbooks=(
  "ticket|**9. Review and landing.**|**10. Verification.**|**12. Reply.**"
  "bug-fix|**10. Review and landing.**|**11. Verification.**|**13. Reply.**"
  "refactoring|### 12. Review|### 13. Verification|### 15. Reply"
)
for row in "${playbooks[@]}"; do
  IFS='|' read -r name review_at verify_at reply_at <<<"$row"
  book="$here/../references/$name.md"

  flat="$(passage_of "$book" "$review_at" "$verify_at" | tr '\n' ' ' | tr -s ' ')"
  expect "$name.md carries its review step" test -n "$flat"
  carries_any "the $name review step integrates a first target moved once more, or names the second one that stops the run" \
    "${retry[@]}"
  # shellcheck disable=SC2034  # lib.sh's check_absent reads $out
  out="$flat"
  check_absent "the $name review step no longer stops the run as blocked on every not landed, a first target moved among them" \
    0 0 "for any reason the review gives. The run stops as blocked"
  s="$(first_at "${second[@]}")"
  r="$(first_at "${retyped[@]}")"
  expect "the $name review step names the run request typed again only for a second target moved, never a first" \
    test "$r" = 0 -o \( "$s" -gt 0 -a "$r" -gt "$s" \)

  flat="$(passage_of "$book" "$reply_at" "## " | tr '\n' ' ' | tr -s ' ')"
  expect "$name.md carries its reply step" test -n "$flat"
  s="$(first_at "${second[@]}")"
  r="$(first_at "${retyped[@]}")"
  expect "the $name reply names the run request typed again as the recovery for a second target moved, never a first" \
    test "$s" -gt 0 -a "$r" -gt "$s"
done

exit $((fails > 0))
