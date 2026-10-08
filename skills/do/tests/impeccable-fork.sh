#!/usr/bin/env bash
# impeccable-fork.sh: what the `ticket` Playbook has the run do with a Front-end ticket of a Spec
# reading `Front-end: impeccable`. The decision turns on the session's own skill listing, which no
# script can read, so the cases read the Playbook's prose by passage and accept several phrasings.
# Run: bash skills/do/tests/impeccable-fork.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
ticket="$here/../references/ticket.md"
fails=0

# The Door's bullets are its stops, and the Door puts the first write after every one of them, so
# the stop is looked for among them and nowhere else: a sentence past the claim, or in another
# section, would tell the developer after the Ticket was claimed and the worktree cut.
echo "# ticket.md / ## Door: a session with no impeccable skill stops a Front-end: impeccable ticket"
flat="$(bullets_opening_on <(passage_of "$ticket" "## Door" "## Resume") "- " | grep -F "impeccable" |
  grep -F -e "lists no impeccable" -e "lists no \`impeccable\`" -e "no impeccable skill" \
    -e "no \`impeccable\` skill" -e "impeccable is not listed" -e "\`impeccable\` is not listed" \
    -e "impeccable not listed" -e "\`impeccable\` not listed" -e "names no impeccable" \
    -e "names no \`impeccable\`" -e "does not list impeccable" -e "does not list \`impeccable\`" \
    -e "does not name impeccable" -e "does not name \`impeccable\`" -e "names neither \`impeccable\`" \
    -e "lists neither \`impeccable\`" -e "impeccable skill is not listed" \
    -e "impeccable skill is missing" -e "without an impeccable skill" -e "impeccable skill listed" |
  head -n 1)"
expect "the Door has a stop for a session that lists no impeccable skill" test -n "$flat"
carries_each "the stop is for a Front-end ticket of a Spec reading Front-end: impeccable" \
  "\`kind=front-end\`" "Front-end ticket" -- \
  "\`front_end=impeccable\`" "\`Front-end: impeccable\`" "Front-end: impeccable"
carries_any "the Ticket is not claimed" \
  "before the claim" "not claimed" "nothing is claimed" "Nothing is claimed" "no claim" \
  "never claimed" "claims nothing"
carries_any "no worktree is cut" \
  "before any worktree" "before a worktree" "no worktree" "nothing is cut" "Nothing is cut" \
  "cuts no" "worktree is not cut" "never cuts"
carries "the stop is the developer's direction to give" "Yours: direction:"
carries_each "one choice is installing impeccable and reloading the session" \
  "install impeccable" "installing impeccable" "Install impeccable" "install the impeccable" \
  "installing the impeccable" "install \`impeccable\`" "installing \`impeccable\`" \
  "install the skill" "installing the skill" "install it" "installing it" -- \
  "reload" "Reload" "restart" "start it again"
carries_any "the other choice is changing the Spec's line to Front-end: builder" \
  "\`Front-end: builder\`" "Front-end: builder"

# A developer who wrote `Front-end: impeccable` chose who builds the screen. A run that built it with
# the Builder because the skill was missing would override that choice with nothing in the Reply
# saying so, so both places a reader could take the fallback from have to rule it out: the Door's
# stop, and the build step, where the Builder is the fork every other Ticket gets.
no_fallback=(
  "never falls back" "does not fall back" "never fall back" "not fall back" "no fallback"
  "no fall back" "without falling back" "never falling back" "not falling back"
  "is never a fallback" "is not a fallback" "never the fallback" "not the fallback"
)
the_builder=("the Builder" "the **Builder**" "\`do-builder\`" "do-builder")

echo "# ticket.md / ## Door: the stop never falls back to the Builder on its own"
carries_each "the Door's stop says the run does not fall back to the Builder" \
  "${no_fallback[@]}" -- "${the_builder[@]}"

echo "# ticket.md / step 3: a Front-end: impeccable ticket never falls back to the Builder on its own"
flat="$(paragraph_with <(passage_of "$ticket" "**3. Build.**" "**4. Diff.**") "impeccable" all |
  tr -s ' ' | grep -F "$(printf '%s\n' "${no_fallback[@]}")" | head -n 1)"
expect "step 3 has a paragraph on impeccable that rules a fallback out" test -n "$flat"
carries_each "step 3 says the run does not fall back to the Builder for that Ticket" \
  "${no_fallback[@]}" -- "${the_builder[@]}"

exit $((fails > 0))
