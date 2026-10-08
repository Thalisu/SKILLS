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

# The do-impeccable fork is briefed with its worktree and nothing holds it there: one that wrote in
# the developer's Main checkout instead would leave stray files behind a screen the Reply calls
# landed. Only a snapshot taken before the fork tells its writes from the work the developer already
# had uncommitted, and the run cannot know which of the changed files are the fork's to keep, so it
# removes nothing and hands the choice over before the Gate runs on a branch missing them.
removes_nothing=(
  "removes nothing" "remove nothing" "removed nothing" "deletes nothing" "delete nothing"
  "deleted nothing" "restores nothing" "restore nothing" "restored nothing" "never removes"
  "never deletes" "never restores" "nothing is removed" "nothing was removed"
  "nothing is deleted" "nothing was deleted" "does not remove" "did not remove"
)
left_in_place=(
  "left in place" "stay in place" "stays in place" "stay for" "stays for" "stay as" "stays as"
  "are kept" "is kept" "keeps the worktree" "keeps its worktree" "keep the worktree" "remain"
  "are left" "is left" "stay where" "stays where" "both stay" "still there" "left standing"
)

echo "# ticket.md / step 3: the Main checkout is snapshotted before the do-impeccable fork and checked after it"
flat="$(paragraph_with <(passage_of "$ticket" "**3. Build.**" "**4. Diff.**") "main-untouched.sh" all |
  tr '\n' ' ' | tr -s ' ')"
expect "step 3 has a passage on main-untouched.sh" test -n "$flat"
carries_any "the passage is for the run that forks do-impeccable" "${this_flow[@]}"
before "the snapshot comes before the check" "main-untouched.sh snapshot" "main-untouched.sh check"
carries_each "the snapshot is taken before the fork and the check runs after the fork returns" \
  "before the fork" "Before the fork" "before forking" "Before forking" "before it forks" \
  "before the run forks" "before that fork" "Before that fork" -- \
  "after the fork returns" "After the fork returns" "after it returns" "After it returns" \
  "once the fork returns" "Once the fork returns" "when the fork returns" "When the fork returns" \
  "once it returns" "Once it returns" "after the fork's return" "after its return" \
  "fork has returned" "after the return" "after the fork" "After the fork" "its return read" \
  "return is read"
carries "the state file lives under .scratch/main-state/ in the main checkout" ".scratch/main-state/"
carries_any "the check runs before the Gate" \
  "before the Gate" "before the **Gate**" "before step 5" "before step 4" "before the diff" \
  "before the Diff" "ahead of the Gate" "ahead of the **Gate**" "ahead of step 5" \
  "ahead of step 4" "never reaches the Gate" "never reaches the **Gate**"

echo "# ticket.md / step 3: a Main checkout the fork changed stops the run before the Gate"
carries "the stop is keyed on verdict=changed" "verdict=changed"
carries_any "the run stops as blocked" "blocked"
carries_any "the stop's class is direction" "Yours: direction:" "\`direction\`"
carries "the Reply lists the check's file= lines" "file="
carries_each "one choice is moving the files into the worktree by hand and running /do on the Ticket again" \
  "move the files" "moving the files" "moves the files" "move them" "moving them" \
  "move those files" "moving those files" -- \
  "into the worktree" "into <worktree>" "into that worktree" "into its worktree" \
  "into the run's worktree" "to the worktree" -- \
  "by hand" -- \
  "/do" -- \
  "again"
carries_each "the other choice is discarding them and running /do again" \
  "discard" "Discard" -- "/do" -- "again"
carries_any "the run removes nothing" "${removes_nothing[@]}"
carries_each "the worktree and its commits stay for the resume" \
  "worktree" -- "commits" "commit" "branch" -- "${left_in_place[@]}"

echo "# ticket.md / step 3: an untouched Main checkout lets the run go on, and a resume that forks again snapshots again"
carries_each "on verdict=untouched the run goes on with nothing added" \
  "verdict=untouched" -- \
  "goes on" "go on" "continues" "continue" "proceeds" "proceed" "carries on" "moves on" \
  "move on" -- \
  "nothing added" "nothing is added" "adds nothing" "add nothing" "nothing more" \
  "nothing to the Reply" "nothing in the Reply" "no line" "says nothing" "nothing else"
carries_each "a run resumed that forks again snapshots again first" \
  "resume" "Resume" -- \
  "snapshots again" "snapshot again" "snapshotted again" "new snapshot" "fresh snapshot" \
  "takes the snapshot again" "snapshot is taken again" "\`snapshot\` again" "snapshot anew" \
  "snapshots anew" "snapshots first" "snapshot first" "again first" "snapshots it again" \
  "snapshot it again" "own snapshot"

# The blocked shape runs from the paragraph that names the fork to the fenced example that closes
# it, so the facts may sit in any paragraph between the two and the shapes written for other stops,
# which also say "left in place" and `claimed`, never answer for this one.
blocked_section="## A refusal or a blocked run"
yours_line="Yours: direction: move the files above into <worktree> by hand and run /do <ticket> again, or discard them and run /do <ticket> again"

echo "# reply.md / $blocked_section: a Main checkout that changed during the do-impeccable fork"
flat="$(passage_of "$reply" "$blocked_section" "## Whole replies" | awk '
  BEGIN { RS = "" }
  !on && index($0, "impeccable") { on = 1 }
  on { gsub(/\n/, " "); print }
  on && index($0, "move the files above") { exit }
' | tr '\n' ' ' | tr -s ' ')"
expect "the section has a blocked shape that names the do-impeccable fork" test -n "$flat"
carries_each "the shape is for a Main checkout that changed during the do-impeccable fork" \
  "Main checkout" "main checkout" "**Main checkout**" -- \
  "changed" "changes" "wrote" "written" "touched" -- \
  "do-impeccable"
carries_each "it carries the files that changed since the fork began, one per line, off the check's file= lines" \
  "one per line" "one a line" "one to a line" "each on its own line" "each on a line of its own" \
  "a line each" "a line per file" "one line per file" "one file per line" -- \
  "file="
carries_each "it never carries the work that was already uncommitted before the fork" \
  "already uncommitted" "uncommitted before" "was uncommitted" "already there" "already dirty" \
  "dirty before" "there before the fork" "before the fork began" "before the snapshot" \
  "predates the fork" "predated the fork" "developer already had" "developer had already" -- \
  "never" "not " "leaves out" "left out" "omits" "excludes" "excluding" "without"
out="$(blocks_of "$reply" "$blocked_section")"
expect "a fenced example's Yours: direction: line carries both choices" grep -qxF -- "$yours_line" <<<"$out"
carries_any "the shape says the run removed nothing" "${removes_nothing[@]}"
carries_each "the worktree and its branch are left in place" \
  "worktree" -- "branch" "commits" -- "${left_in_place[@]}"
carries "the Ticket still reads claimed" "\`claimed\`"

# A project with no end-to-end command gets a screen no flow ran over, and the fork says so on a
# `fallback:` line of its return. Evidence is where the developer reads what proved the screen: with
# no line there, the unit suite and the Gate quoted above it read as the same proof a flow gives.
echo "# reply.md / ## Sections, Evidence: a do-impeccable return carrying fallback: gets one line on a screen no flow covered"
flat="$(item_holding <(passage_of "$reply" "## Sections" "$blocked_section") '[0-9]+\.' "**Evidence.**" |
  tr '\n' ' ' | tr -s ' ')"
expect "the Sections have an Evidence item" test -n "$flat"
carries_any "the item names the run that forks do-impeccable" "${this_flow[@]}"
carries "the item names the return's fallback: line" "\`fallback:\`"
mapfile -t no_flow_proof < <(no_flow_proof_groups)
carries_each "that run's Evidence says in one line that no flow covered the screen and that the detector scan and the Gate are its proof" \
  "${no_flow_proof[@]}"

# The detector scan runs inside the fork and the session never runs it again, so the fork's `scan:`
# line is the only place the developer reads which command judged the screen and how many findings
# it left. A count with nothing naming the findings is debt the developer cannot act on, so each
# `finding:` line is listed under Pending debt; and a finding is debt, never a stop, so the screen
# lands with it listed instead of being held back by it.
beside_the_flows=(
  "beside the flows" "next to the flows" "with the flows" "under the flows" "below the flows"
  "after the flows" "beside the \`flow:\` line" "next to the \`flow:\` line"
  "with the \`flow:\` line" "under the \`flow:\` line" "below the \`flow:\` line"
  "after the \`flow:\` line" "\`flow:\` lines and the \`scan:\` line"
  "\`flow:\` lines, and the \`scan:\` line" "\`flow:\` lines and its \`scan:\` line"
  "\`flow:\` lines, then the \`scan:\` line" "\`flow:\` lines, the \`scan:\` line"
  "beside them" "next to them" "under them" "below them" "after them"
)
each_finding_listed=(
  "each \`finding:\` line" "Each \`finding:\` line" "every \`finding:\` line"
  "Every \`finding:\` line" "one line per finding" "One line per finding" "a line per finding"
  "one per finding" "one \`finding:\` line per finding" "each finding" "Each finding"
  "every finding" "Every finding" "each one" "every one"
)
findings_stop_nothing=(
  "still lands" "still landed" "lands all the same" "landed all the same" "lands anyway"
  "landed anyway" "lands regardless" "landed regardless" "do not block" "does not block"
  "never block" "block nothing" "blocks nothing" "blocked nothing" "without blocking"
  "stop nothing" "stops nothing" "stopped nothing" "never stop" "do not stop" "does not stop"
  "not stop the landing" "never hold" "do not hold" "hold nothing back" "holds nothing back"
)

echo "# reply.md / ## Sections, Evidence: a do-impeccable return's scan: line stands beside the flows"
flat="$(item_holding <(passage_of "$reply" "## Sections" "$blocked_section") '[0-9]+\.' "**Evidence.**" |
  tr '\n' ' ' | tr -s ' ')"
expect "the Sections have an Evidence item" test -n "$flat"
# The item already says "unchanged" of the `flow:` lines and "command lines" of the integration's,
# so the facts are read off the lead or the bullet that names `scan:` and never off a neighbour.
flat="$(item_holding <(passage_of "$reply" "## Sections" "$blocked_section") '[0-9]+\.' "**Evidence.**" | awk '
  function flush() { if (index(part, "`scan:`")) print part; part = "" }
  /^ +- / { flush() }
  { part = part " " $0 }
  END { flush() }
' | tr '\n' ' ' | tr -s ' ')"
carries_each "the item carries the scan: line the do-impeccable fork returned" \
  "${this_flow[@]}" -- "\`scan:\`"
carries_each "that line is the detector scan's command line and the count of findings that remain" \
  "\`scan:\`" -- \
  "command line" "command" -- \
  "count of findings" "count of the findings" "findings that remain" "findings remain" \
  "findings left" "findings it left" "how many findings" "number of findings"
carries_each "that line sits beside the flows" "\`scan:\`" -- "${beside_the_flows[@]}"
carries_each "that line is copied as the fork returned it, never composed by the session" \
  "\`scan:\`" -- \
  "unchanged" "verbatim" "unedited" "as returned" "as it came back" "as they came back" \
  "as the fork returned" "word for word" "never composed" "never reworded"

echo "# reply.md / ## Sections, Pending debt: each finding the do-impeccable fork returned is listed, and the Ticket still lands"
flat="$(item_holding <(passage_of "$reply" "## Sections" "$blocked_section") '[0-9]+\.' "**Pending debt.**" |
  tr '\n' ' ' | tr -s ' ')"
expect "the Sections have a Pending debt item" test -n "$flat"
carries_each "the item lists each finding: line the do-impeccable fork returned, one line per finding" \
  "${this_flow[@]}" -- "\`finding:\`" -- "${each_finding_listed[@]}"
carries_each "findings that remain never stop the landing" \
  "\`finding:\`" -- "${findings_stop_nothing[@]}"

# Step 10 is one paragraph on every kind of run, so the sentences read are the ones from the first
# naming of the fork on: Evidence, pending debt and a landing said of another run never answer.
echo "# ticket.md / step 10: a do-impeccable run's Reply carries the scan: line under Evidence and each finding: line under Pending debt"
flat="$(passage_of "$ticket" "**10. Reply.**" "## " | tr '\n' ' ' | tr -s ' ')"
case "$flat" in
  *do-impeccable*) flat="${flat#*do-impeccable}" ;;
  *) flat="" ;;
esac
expect "step 10 has sentences on the run that forked do-impeccable" test -n "$flat"
carries_each "step 10 puts the scan: line under Evidence beside the flow: lines" \
  "\`scan:\`" -- "Evidence" -- "${beside_the_flows[@]}"
carries_each "step 10 puts each finding: line under Pending debt" \
  "\`finding:\`" -- "Pending debt" "pending debt" -- "${each_finding_listed[@]}"
carries_each "step 10 says findings that remain stop nothing: the Ticket landed and reads resolved all the same" \
  "\`finding:\`" "findings" -- \
  "\`resolved\`" -- \
  "all the same" "still" "anyway" "regardless" "nonetheless" "even so" "${findings_stop_nothing[@]}"

# The next Ticket of the Spec is refused as blocked until this one reads `resolved`, so a `built`
# return that the Playbook carried no further than step 3 would leave the developer with a screen
# built in a worktree and a Spec that cannot move. The paragraphs read are the ones that name the
# fork and hold both ends of the path, the `built` return and the `resolved` Ticket, each from its
# first naming of the fork on: the Gate, a landing or a last line said of another run never answer.
echo "# ticket.md / steps 4 to 10: a built do-impeccable return after an untouched check runs the Builder's path to resolved"
flat="$(paragraph_with <(passage_of "$ticket" "**3. Build.**" "## ") "do-impeccable" all |
  awk '{ print substr($0, index($0, "do-impeccable")) }' |
  grep -F -- "\`built\`" | grep -F -- "\`resolved\`" | tr '\n' ' ' | tr -s ' ')"
expect "a passage on do-impeccable takes its built return to a resolved Ticket" test -n "$flat"
carries_each "the passage is for a built return after an untouched main checkout" \
  "\`built\`" -- \
  "verdict=untouched" "untouched main checkout" "untouched Main checkout" \
  "untouched **Main checkout**" "main checkout untouched" "Main checkout untouched" \
  "main checkout is untouched" "Main checkout is untouched" "checkout was untouched" \
  "checkout read untouched" "untouched check"
carries_each "from there the run goes through the Gate, the integration, the landing and the close" \
  "the Gate" "the **Gate**" "step 5" -- \
  "the integration" "the Integration" "the **Integration**" "step 6" -- \
  "the landing" "the Landing" "the **Landing**" "lands on the Spec branch" "step 7" -- \
  "the close" "the Close" "the **Close**" "step 9"
carries_any "those steps run as after a Builder, with none added, skipped or changed" \
  "as after a Builder" "as after the Builder" "as they do after a Builder" \
  "as they do after the Builder" "as it does after a Builder" "as it does after the Builder" \
  "as they run after a Builder" "as they run after the Builder" "as for a Builder" \
  "as for the Builder" "as a Builder's" "as the Builder's" "the way a Builder" \
  "the way the Builder" "exactly as" "the same as" "the same steps" "same steps as" "unchanged" \
  "no step of its own" "no step added" "no step is added" "nothing is added, skipped or changed" \
  "nothing added, skipped or changed" "none added, skipped or changed"
carries_each "the run ends with the Ticket reading resolved" \
  "Ticket" -- "\`resolved\`"
carries_each "the Reply's last line is the next /do the Completion check names" \
  "last line" "final line" "closing line" -- \
  "next \`/do\`" "next /do" "\`next=\`" "\`/do\` the Completion check" "/do the Completion check"

exit $((fails > 0))
