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

# impeccable builds from the Ticket and never opens a Plan, so a Planner forked for that Ticket is
# a window the developer pays for and nobody reads. The skip is that Ticket's alone: a Builder run
# builds from the Plan, so step 1 also has to say which Tickets keep the Planner, or the skip reads
# as covering every Front-end ticket.
echo "# ticket.md / step 1: a Front-end: impeccable ticket forks no Planner and gets no Plan"
flat="$(paragraph_with <(passage_of "$ticket" "**1. Plan.**" "**2. Claim and worktree.**") "impeccable" all |
  tr '\n' ' ' | tr -s ' ')"
expect "step 1 has a passage on impeccable" test -n "$flat"
carries_each "the passage is for a Front-end ticket of a Spec reading Front-end: impeccable" \
  "\`kind=front-end\`" "Front-end ticket" -- \
  "\`front_end=impeccable\`" "\`Front-end: impeccable\`" "Front-end: impeccable"
carries_any "that Ticket forks no Planner" \
  "forks no Planner" "forks no **Planner**" "forks no \`do-planner\`" "fork no Planner" \
  "fork no \`do-planner\`" "no Planner is forked" "no **Planner** is forked" \
  "no \`do-planner\` is forked" "Planner is not forked" "Planner is never forked" \
  "\`do-planner\` is not forked" "\`do-planner\` is never forked" "does not fork the Planner" \
  "does not fork \`do-planner\`" "never forks the Planner" "never forks \`do-planner\`" \
  "skips the Planner" "skips the **Planner**" "skips \`do-planner\`" "without a Planner" \
  "forks nobody" "no Planner fork"
carries_any "that Ticket gets no Plan written" \
  "writes no Plan" "write no Plan" "no Plan is written" "no **Plan** is written" \
  "Plan is not written" "Plan is never written" "no Plan written" "gets no Plan" "has no Plan" \
  "carries no Plan" "without a Plan" "no Plan at all" "nobody writes a Plan" \
  "nothing writes a Plan" "does not write a Plan" "does not write the Plan" \
  "never writes a Plan" "never writes the Plan" "and no Plan"
every_other=(
  "every other Ticket" "Every other Ticket" "any other Ticket" "Any other Ticket"
  "all other Tickets" "All other Tickets" "every other kind" "Every other kind"
)
carries_each "a Logic ticket and a Front-end: builder ticket still fork the Planner" \
  "Logic ticket" "\`kind=logic\`" "${every_other[@]}" -- \
  "\`Front-end: builder\`" "Front-end: builder" "\`front_end=builder\`" "${every_other[@]}" -- \
  "still fork" "keeps the Planner" "keep the Planner" "keeps the **Planner**" \
  "keep the **Planner**" "keeps its Planner" "keep their Planner" "forks the Planner" \
  "fork the Planner" "forks the **Planner**" "fork the **Planner**" "forks \`do-planner\`" \
  "fork \`do-planner\`" "Planner is forked" "\`do-planner\` is forked" "gets the Planner" \
  "get the Planner" "goes to the Planner" "go to the Planner" "is forked as below" \
  "forks as below" "fork as below"

# The session reads the fork's final message as the return. A brief that named a place for the
# return would have the fork write a file the session never opens, and one named outside the
# worktree would touch the developer's Main checkout, so the brief has to be said to carry no such
# key, next to the two things it does carry.
echo "# ticket.md / step 3: a Front-end: impeccable ticket is built by a do-impeccable fork"
flat="$(paragraph_with <(passage_of "$ticket" "**3. Build.**" "**4. Diff.**") "impeccable" all |
  tr '\n' ' ' | tr -s ' ')"
expect "step 3 has a passage on impeccable" test -n "$flat"
carries_each "the passage is for a Front-end ticket of a Spec reading Front-end: impeccable" \
  "\`kind=front-end\`" "Front-end ticket" -- \
  "\`front_end=impeccable\`" "\`Front-end: impeccable\`" "Front-end: impeccable"
carries "that Ticket is built by a fork of subagent_type: do-impeccable" \
  "subagent_type: do-impeccable"
carries_any "the fork works in the worktree step 2 cut, as for any Ticket" \
  "worktree step 2" "worktree that step 2" "worktree and the branch step 2" \
  "worktree and branch step 2" "step 2's worktree" "worktree of step 2" "worktree from step 2" \
  "worktree cut in step 2" "worktree cut at step 2" "worktree made in step 2" \
  "worktree created in step 2" "worktree cut by step 2" "worktree made by step 2" \
  "worktree created by step 2"
carries_each "the brief carries the Ticket and the worktree root" \
  "brief" -- \
  "the Ticket" "the **Ticket**" "Ticket's path" "\`Ticket:\`" -- \
  "worktree root" "worktree's root" "root of the worktree" "root of that worktree" \
  "\`Worktree:\`"
carries_any "the brief has no key for where the return goes" \
  "no key for where the return" "no key for the return" "no key naming where the return" \
  "no key that names where the return" "no key saying where the return" \
  "no key for a return" "no return key" "no \`Return:\` key" "no \`Return\` key" \
  "no key for its return" "no key for where its return" "names no place for the return" \
  "names no destination for the return" "no return path" "no return file" \
  "no return destination" "never names where the return"
carries_any "the return is the fork's final message" \
  "final message" "last message"

# The session routes on the return's first line alone. A `do-impeccable` return the step checked
# less than a Builder's would let a `behaviour:` line with no commit behind it reach the Reply and
# the Gate run over a half-built screen, and a return it had no route for would leave the run with
# nowhere to go on `fork` or `stopped`. The paragraphs read are still the ones carrying
# `impeccable`: the checks and the routes written for the Builder answer for this fork only where
# the step says they do.
echo "# ticket.md / step 3: the do-impeccable fork's verdict is checked and routed as a Builder's"
carries_each "the checks of the return against the branch apply to the do-impeccable fork" \
  "same checks" "same check" "checks below" "check below" "checks above" "check above" \
  "checked the same way" "checked as the Builder's" "checked as a Builder's" \
  "checked against the branch" "checks of the return" "check of the return" \
  "checks its return" "checks the return" "Check the return" "\`resume-state.sh\`" \
  "resume-state.sh"
carries_each "the three routes, built, fork and stopped, apply to the do-impeccable fork" \
  "same three routes" "same routes" "same route" "three routes" "routes below" "route below" \
  "routes above" "routed as" "routed the same" "routed the way" "routes it as" \
  "routes its verdict" "routes the verdict" "routes that verdict" "routes its return" \
  "Route on the first line" "routes on the first line" "route on the first line" \
  "routes on its first line" "route on its first line" \
  -- \
  "\`built\`" "three routes" "three verdicts" \
  -- \
  "\`fork\`" "three routes" "three verdicts" \
  -- \
  "\`stopped\`" "three routes" "three verdicts"

# No Planner ran and no Plan was written, so a Reply that kept a Plan line would send the developer
# looking for a file that does not exist, and a behaviours list read off a Plan's section would have
# nothing to read. The list is the Ticket's acceptance criteria instead, each with its commit, which
# is what lets the developer check the screen against the Ticket. reply.md fixes the Reply's lines
# and step 10 says what this Playbook puts in them, so a reader of either has to meet the exception.
# The `## Run` items are renumbered whenever one is added, so each is found by its own title.
this_flow=("\`Front-end: impeccable\`" "\`front_end=impeccable\`" "do-impeccable")
no_plan_line=(
  "no Plan line" "no **Plan line**" "no Planner line" "no **Planner** line" "no line for the Plan"
  "no line for a Plan" "omits the Plan line" "omit the Plan line" "Plan line is omitted"
  "Plan line is left out" "leaves the Plan line out" "leave the Plan line out"
  "Plan line is not written" "Plan line is never written" "without a Plan line"
  "without the Plan line" "skips the Plan line" "drops the Plan line" "the line is omitted"
  "the line is left out" "the line is not written" "no line is written" "writes no line"
  "this line is omitted" "this line is left out" "this line is not written" "has no such line"
  "carries no such line" "no line at all"
)
criteria_list=("acceptance criteria" "acceptance criterion")
commit_beside=(
  "commit beside" "commit next to" "with its commit" "with the commit" "with a commit"
  "the commit that built" "commit that built it"
)
reply="$here/../references/reply.md"

echo "# reply.md / ## Run, Plan line: a Front-end: impeccable ticket's Reply carries no Planner line"
flat="$(paragraph_with <(item_holding <(passage_of "$reply" "## Run" "## Sections") '[0-9]+\.' "**Plan line.**") \
  "impeccable" all | tr '\n' ' ' | tr -s ' ')"
expect "the Plan line item has a passage on impeccable" test -n "$flat"
carries_any "the passage is for the run that forks do-impeccable on a Front-end: impeccable ticket" \
  "${this_flow[@]}"
carries_any "that run's Reply carries no Plan line" "${no_plan_line[@]}"

echo "# reply.md / ## Run, Behaviours list: a Front-end: impeccable ticket lists the Ticket's acceptance criteria"
flat="$(item_holding <(passage_of "$reply" "## Run" "## Sections") '[0-9]+\.' "**Behaviours list.**" |
  tr '\n' ' ' | tr -s ' ')"
expect "the Run section has a Behaviours list item" test -n "$flat"
carries_any "the item names the run that forks do-impeccable on a Front-end: impeccable ticket" \
  "${this_flow[@]}"
carries_any "that run's list is the Ticket's acceptance criteria" "${criteria_list[@]}"
carries_any "each criterion has its commit beside it" "${commit_beside[@]}"
carries_any "that run's list is never a Plan's Behaviours section" \
  "never the Plan" "not the Plan" "never a Plan" "not a Plan" "in place of the Plan" \
  "instead of the Plan" "rather than the Plan" "in place of a Plan" "instead of a Plan" \
  "rather than a Plan" "no Plan" "no \`## Behaviours\`" "every other \`ticket\` run" \
  "any other \`ticket\` run" "every other Ticket" "any other Ticket" "every other run" \
  "any other run"

echo "# ticket.md / step 10: a Front-end: impeccable ticket's Reply has no Planner line and lists the criteria"
flat="$(passage_of "$ticket" "**10. Reply.**" "## " | tr '\n' ' ' | tr -s ' ')"
expect "the Playbook has a Reply step" test -n "$flat"
carries_any "step 10 names the run that forks do-impeccable on a Front-end: impeccable ticket" \
  "${this_flow[@]}"
carries_any "step 10 says that run's Reply carries no Plan line" "${no_plan_line[@]}"
carries_any "step 10 says that run's behaviours list is the Ticket's acceptance criteria" \
  "${criteria_list[@]}"
carries_any "step 10 says each criterion has its commit beside it" "${commit_beside[@]}"

exit $((fails > 0))
