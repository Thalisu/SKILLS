#!/usr/bin/env bash
# setup-ticket.sh: what SKILL.md has the session do on a spec that reads `Front-end: impeccable`:
# it runs the setup check, and when a step reads missing the breakdown opens with a Setup ticket
# numbered 00, of kind setup, blocked by nothing, whose acceptance criteria are the six setup steps
# in their order, every one listed whether the check reads it done or not. With every step done no
# Setup ticket is cut, and one line under the breakdown list says the setup was found. On a spec
# that reads `Front-end: builder` the check is never run and no Setup ticket is cut, whatever the
# project carries. A check that cannot run (exit 2, or no script at its path) ends the run on one
# message carrying the check's own error line: no breakdown shown, no approval asked, nothing
# published, and the turn-end list names that point. At the publish step the Setup ticket goes out
# as the ticket numbered 00, of kind setup, and the other tickets still count from 01. The closing
# summary shows each published ticket with its kind beside its blocking edges, and its last line is
# `/do` on the Setup ticket when one was cut. Under `--auto` that last line is the plain `/do`
# command with no flag, one line says this one ticket needs the developer and that the flag returns
# from the next ticket on, and the `--auto` section says the same exception.
# The ticket is drafted by the session from the check's verdict, which no script carries. The eval
# case impeccable-setup-missing-cuts-setup-ticket grades the cut itself on a live run, a Setup ticket
# published as 00. Every rule around the cut is proven here, over the passages that carry it.
# Run: bash skills/tickets/tests/setup-ticket.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
skill="$here/../SKILL.md"
fails=0

echo "# SKILL.md / ## 3: a missing setup step opens the breakdown with the Setup ticket"
whole="$(passage_of "$skill" "**The Setup ticket.**" "**Blocking edges.**" | tr '\n' ' ' | tr -s ' ')"
flat="$whole"
expect "SKILL.md carries the Setup ticket rule of the draft step" test -n "$flat"

carries "the setup check is run on a spec that reads Front-end: impeccable" \
  "Front-end: impeccable" "setup-check.sh"
# Scoped to the sentence that opens the breakdown with the ticket: the passage already says
# "missing" of the lines the check prints, and that sentence cannot answer for what calls for it.
flat="$(grep -oE '[^.]*the breakdown opens with[^.]*' <<<"$whole")"
carries_each "a step the check reads missing is what calls for the ticket" \
  "Exit 1" "Exit \`1\`" "exits 1" "exits \`1\`" "exit 1" "exit \`1\`" "exit code 1" "exit status 1" -- \
  "reads missing" "reads \`missing\`" "read missing" "read \`missing\`" "is missing"
flat="$whole"
carries_any "the ticket opens the breakdown" \
  "opens with" "opens the breakdown" "open the breakdown" "opens on" "first ticket" "comes first" \
  "is the first" "goes first" "leads the breakdown" "heads the breakdown" "at the head of" \
  "before every other" "ahead of every other" "before any other" "ahead of any other" \
  "before the other tickets" "ahead of the other tickets"
carries "the ticket is numbered 00" "00"
carries_any "the ticket is of kind setup" \
  "\`setup\`" "Kind: setup" "kind setup" "Kind setup" "a setup kind"
carries_any "the ticket is blocked by nothing" \
  "blocked by nothing" "Blocked by nothing" "blocked by none" "Blocked by none" \
  "Blocked by: none" "**Blocked by:** none" "Blocked by\` is none" "Blocked by\` reads none" \
  "no blocker" "no blocking edge" "nothing blocks it" "blocked by no ticket" "blocked by no other"

install=(
  "install impeccable" "Install impeccable" "installs impeccable" "installing impeccable"
  "Installing impeccable" "impeccable is installed" "impeccable installed"
)
reload=("reload" "Reload" "restart" "Restart")
initialise=("initialis" "Initialis" "initializ" "Initializ")
design_system=("design system" "Design system" "DESIGN.md")
build_path=("code-led" "Code-led")
commit_setup=(
  "commit the setup" "Commit the setup" "commits the setup" "committing the setup"
  "Committing the setup" "setup files are committed" "setup files committed"
)

carries_each "the criteria are the six steps, each one named with what the developer does" \
  "acceptance criteria" "Acceptance criteria" "criteria" -- \
  "${install[@]}" -- "terminal" -- \
  "${reload[@]}" -- "coding tool" -- \
  "${initialise[@]}" -- "project context" -- \
  "agent session" "in a session" "inside a session" "session of the agent" -- \
  "${design_system[@]}" -- \
  "when one exists" "if one exists" "where one exists" "when there is one" "if there is one" \
  "when the project has one" "if the project has one" "when it has one" "if it has one" -- \
  "${build_path[@]}" -- "build path" -- \
  "${commit_setup[@]}" -- \
  "developer's branch" "developer's own branch" "developer's current branch" \
  "branch the developer is on"

# The order is read from where the first step is named on, so a sentence above the list that
# speaks of the setup being committed cannot stand for the last step.
s1="$(first_at "${install[@]}")"
flat="${whole:$((s1 > 0 ? s1 - 1 : ${#whole}))}"
s2="$(first_at "${reload[@]}")"
s3="$(first_at "${initialise[@]}")"
s4="$(first_at "${design_system[@]}")"
s5="$(first_at "${build_path[@]}")"
s6="$(first_at "${commit_setup[@]}")"
expect "the six steps come in order: install, reload, initialise, design system, build path, commit" \
  test "$s1" -gt 0 -a "$s2" -gt 1 -a "$s3" -gt "$s2" -a "$s4" -gt "$s3" -a "$s5" -gt "$s4" -a "$s6" -gt "$s5"

flat="$whole"
carries_each "every one of the six is listed, whether the check reads it done or not" \
  "six" "Six" -- \
  "every one" "Every one" "every step" "Every step" "each step" "Each step" "all six" "All six" \
  "each of the six" "all of the six" "each one" -- \
  "done or not" "done or missing" "missing or done" "whether or not" "whether the check reads" \
  "whether it reads" "regardless of" "whatever the check reads" "even one the check reads done" \
  "even when the check reads" "reads done or" "already done"

echo "# SKILL.md / ## 3: with a Setup ticket cut, every other ticket is blocked by it"
flat="$whole"
# The passage already says the Setup ticket itself is blocked by nothing, so every phrasing here
# names the other tickets as the blocked side: a bare "blocked by" would answer for the wrong edge.
carries_any "every other ticket is blocked by the Setup ticket" \
  "very other ticket is blocked by" "very other ticket of the breakdown is blocked by" \
  "ach other ticket is blocked by" "ll other tickets are blocked by" \
  "ll the other tickets are blocked by" "very ticket after it is blocked by" \
  "very ticket but it is blocked by" "very ticket other than it is blocked by" \
  "very other ticket names it" "very other ticket names the Setup ticket" \
  "very other ticket lists it" "very other ticket lists the Setup ticket" \
  "very other ticket carries it in" "very other ticket carries the Setup ticket in" \
  "very other ticket's \`Blocked by\` names" "very other ticket's **Blocked by** names" \
  "very other ticket's Blocked by names" "Blocked by\` of every other ticket names" \
  "Blocked by** of every other ticket names" "Blocked by of every other ticket names" \
  "blocks every other ticket" "blocks each other ticket" "blocks all other tickets" \
  "blocks all the other tickets" "blocks every ticket after it" "blocks every ticket but itself"
carries_each "and that holds on a spec where no path has a screen and every other ticket is a Logic ticket" \
  "no path has a screen" "no Path has a screen" "not one path has a screen" \
  "none of the paths has a screen" "none of its paths has a screen" \
  "no path of the spec has a screen" "no path with a screen" "no path carries a screen" \
  "no path touches a screen" "no screen" "without a screen" "without any screen" -- \
  "Logic ticket" "logic ticket" "\`logic\` ticket" "of kind \`logic\`" "Kind: logic"

echo "# SKILL.md / ## 4: the Kind field of the breakdown list admits setup"
flat="$(bullets_opening_on <(passage_of "$skill" "## 4. Put the breakdown to the user" "After the list:") "**Kind**")"
expect "SKILL.md carries the Kind field of the breakdown list" test -n "$flat"
carries "the field admits setup beside logic and front-end" "\`setup\`" "\`logic\`" "\`front-end\`"

echo "# SKILL.md / ## 3: with every step of the setup done, no Setup ticket is cut"
flat="$whole"
carries_each "the check exiting 0, every step done, cuts no Setup ticket" \
  "Exit 0" "exit 0" "exits 0" "Exit \`0\`" "exit \`0\`" "exits \`0\`" "exit code 0" "exit code \`0\`" \
  "exit status 0" "exit status \`0\`" "every step done" "every step is done" "every step reads done" \
  "every step reads \`done\`" "each step reads done" "each step reads \`done\`" "all six done" \
  "all six are done" "all six read done" "all six read \`done\`" "no step missing" \
  "no step reads missing" "no step is missing" "nothing missing" "nothing is missing" -- \
  "no Setup ticket" "no **Setup ticket**" "No Setup ticket" "No **Setup ticket**" \
  "without a Setup ticket" "without the Setup ticket" "Setup ticket is not cut" \
  "Setup ticket is never cut" "Setup ticket is left out" "Setup ticket is not listed" \
  "Setup ticket is not drafted" "cuts no ticket for the setup" "no ticket is cut for the setup" \
  "no ticket for the setup" "the ticket is not cut" "the ticket is left out" "none is cut"

echo "# SKILL.md / ## 4: with the setup whole, one line under the list says it was found"
# The key leaves the first letter out: the item may open its sentence on "Setup" or name "the setup".
flat="$(item_holding <(passage_of "$skill" "After the list:" "One shape the message can take") \
  '[0-9]+\.' "etup" | tr '\n' ' ' | tr -s ' ')"
expect "SKILL.md carries a setup item in the breakdown's closing parts" test -n "$flat"
carries "the item is for a spec that reads Front-end: impeccable" "Front-end: impeccable"
carries_any "the item is for the setup being whole, no step missing" \
  "Exit 0" "exit 0" "exits 0" "exited 0" "Exit \`0\`" "exit \`0\`" "exits \`0\`" "exited \`0\`" \
  "exit code 0" "exit status 0" \
  "every step done" "every step is done" "every step reads done" "every step reads \`done\`" \
  "each step reads done" "all six done" "all six are done" "all six read done" "no step missing" \
  "no step reads missing" "no step is missing" "nothing missing" "nothing is missing" \
  "setup whole" "setup is whole" "setup complete" "setup is complete" "whole setup" \
  "complete setup" "already set up" "set up already"
carries_any "it is one line of the message" \
  "one line" "One line" "a line" "A line" "one more line" "a single line" "the line"
carries_any "the line says the setup was found" \
  "was found" "is found" "were found" "setup found" "found whole" "found complete" \
  "found in place" "found in the project" "already there" "already in place" "is in place" \
  "already set up" "set up already" "already done"

echo "# SKILL.md / ## 3: on a spec that reads Front-end: builder the check is never run and no Setup ticket is cut"
# The passage says "no Setup ticket is cut" of the check exiting 0, so the scope is the paragraph
# that names builder, read from the sentence that names it: the exit-0 sentence cannot answer here.
para="$(paragraph_with <(passage_of "$skill" "**The Setup ticket.**" "**Blocking edges.**") "builder")"
lead="${para%%builder*}"
flat=""
if [ "$lead" != "$para" ]; then
  tail="${lead##*. }"
  flat="${para:$((${#lead} - ${#tail}))}"
fi
expect "the Setup ticket rule names builder" test -n "$flat"
carries_any "the rule is for a spec that reads Front-end: builder" \
  "Front-end: builder" "\`builder\`"
carries_any "the setup check is never run there" \
  "never run" "not run" "never runs" "does not run" "runs no" "never read" "not read" \
  "never called" "not called" "is skipped" "skips the check" "skip the check" \
  "without running" "no setup check" "no check is run" "no check runs"
carries_any "no Setup ticket is cut there" \
  "no Setup ticket" "no **Setup ticket**" "No Setup ticket" "No **Setup ticket**" \
  "without a Setup ticket" "without the Setup ticket" "Setup ticket is not cut" \
  "Setup ticket is never cut" "Setup ticket is left out" "Setup ticket is not listed" \
  "Setup ticket is not drafted" "cuts no ticket for the setup" "no ticket is cut for the setup" \
  "no ticket for the setup" "the ticket is not cut" "the ticket is left out" "none is cut" \
  "never a Setup ticket" "nor is a Setup ticket"
carries_any "and that holds whatever the project carries" \
  "whatever the project" "Whatever the project" "whatever is in the project" \
  "whether or not the project" "whether the project carries" "whether the project has" \
  "even in a project without" "even in a project that" "even when the project" \
  "even if the project" "regardless of what the project" "regardless of the project" \
  "with or without the setup" "setup or not" "whatever the check would read"

echo "# SKILL.md / ## 1: the setup is read on Front-end: impeccable alone"
# Scoped to the sentences that name the setup: the paragraph already says "the only trace of the
# line" of none, and an "only" there says nothing about who has the setup read.
flat="$(paragraph_with "$skill" "**The front-end.**" | sed 's/\. /.\n/g' | grep -F "etup" | tr '\n' ' ')"
expect "the front-end paragraph of the ground step names the setup" test -n "$flat"
carries_each "the setup is read or checked on impeccable and on no other value" \
  "impeccable" -- \
  "read" "check" "run" -- \
  "\`impeccable\` alone" "impeccable alone" "impeccable\` alone" "\`impeccable\` only" \
  "impeccable\` only" "only on \`impeccable\`" "only on impeccable" "only \`impeccable\`" \
  "only for \`impeccable\`" "only under \`impeccable\`" "only when it reads \`impeccable\`" \
  "only when the line reads \`impeccable\`" "only on a spec that reads \`Front-end: impeccable\`" \
  "only when the spec reads \`Front-end: impeccable\`" "no other value" "on no other" \
  "never on \`none\` or \`builder\`" "never on \`builder\` or \`none\`"

echo "# SKILL.md / ## 3: a setup check that cannot run ends the run on its own error line, nothing asked or published"
cannot_run=(
  "Exit 2" "exit 2" "exits 2" "Exit \`2\`" "exit \`2\`" "exits \`2\`" "exit code 2" "exit code \`2\`"
  "exit status 2" "exit status \`2\`" "any other exit" "Any other exit" "cannot run" "could not run"
  "cannot be run" "could not be run" "could not be read" "cannot be read" "cannot read"
  "could not read" "not found" "is not there" "does not exist"
)
# The passage already speaks of a line under the breakdown and of no Setup ticket being cut, said
# of the check exiting 0 and of builder, so the scope is the paragraphs that name the check failing
# to run: a sentence about another verdict cannot answer for this one.
flat=""
for key in "${cannot_run[@]}"; do
  flat="$flat $(paragraph_with <(passage_of "$skill" "**The Setup ticket.**" "**Blocking edges.**") "$key" all | tr '\n' ' ')"
done
flat="$(tr -s ' ' <<<"$flat")"
expect "the Setup ticket rule names a check that cannot run" test -n "${flat// /}"
carries_any "the run ends there" \
  "ends there" "end there" "run ends" "turn ends" "ends the run" "ends the turn" "end the run" \
  "end the turn" "stops there" "stop there" "run stops" "stops the run" "stop the run" "ends on" \
  "end on" "stops on" "stop on"
carries_any "on one message" \
  "one message" "single message" "a message" "one short message"
carries_any "the message carries the check's own error line" \
  "stderr" "error line" "error message" "own error" "own line" "line it printed" \
  "line the check printed" "line the check prints" "line it prints" "what the check printed" \
  "what the check prints" "the check's message" "the check's line"
carries_any "no breakdown is shown and no approval is asked" \
  "no approval" "No approval" "approval question is not" "approval question is never" \
  "approval is not asked" "approval is never asked" "no question" "No question" "not shown" \
  "never shown" "no breakdown" "No breakdown" "without a breakdown" "without the breakdown" \
  "nothing is asked" "Nothing is asked" "asks nothing" "without asking" "never asked" "not asked" \
  "before any breakdown" "nothing is shown" "Nothing is shown"
carries_any "nothing is published" \
  "nothing is published" "Nothing is published" "nothing published" "publishes nothing" \
  "no ticket is published" "No ticket is published" "no ticket published" "never published" \
  "not published" "or published" "nor published" "without publishing" "nothing is written" \
  "Nothing is written" "nothing written" "writes nothing" "no ticket is written" \
  "No ticket is written" "nothing is cut" "Nothing is cut" "cuts nothing" "no ticket is cut" \
  "No ticket is cut"

echo "# SKILL.md / How a turn ends: the setup check that cannot run is one of the points a turn ends at"
# Every bullet of the list, one per line: the two-character key sits in each bullet's own marker.
flat="$(bullets_opening_on <(passage_of "$skill" "## How a turn ends" "## 1. Ground") "- " | grep -F "etup" | tr '\n' ' ')"
expect "a bullet of the list names the setup" test -n "$flat"
carries_each "the bullet is the setup check that cannot run" \
  "check" -- \
  "${cannot_run[@]}" "refus" "fail" "error" "cannot be reached" "unreadable"

echo "# SKILL.md / ## 5: the Setup ticket is published as the ticket numbered 00, of kind setup"
publish="$(passage_of "$skill" "## 5. Publish" "## 6. Close")"
flat="$(paragraph_with <(printf '%s\n' "$publish") "**The kind.**" | tr -s ' ')"
expect "the publish step carries the kind paragraph" test -n "$flat"
carries_each "the Setup ticket is published with the kind setup" \
  "Setup ticket" "setup ticket" -- \
  "\`setup\`" "Kind: setup" "**Kind:** setup" "kind setup" "Kind setup" "a setup kind"

# `do` resolves a blocker by its number, so the bullet has to keep both halves: the Setup ticket
# takes 00, and the count of the other tickets still opens on 01.
flat="$(bullets_opening_on <(printf '%s\n' "$publish") "**Numbering**")"
expect "the publish step carries the numbering bullet of the local shape" test -n "$flat"
carries_each "the Setup ticket takes the number 00 and the other tickets still count from 01" \
  "Setup ticket" "setup ticket" -- \
  "00" -- \
  "01"

echo "# SKILL.md / ## 6: the closing summary shows each ticket's kind, and its last line is /do on the Setup ticket"
close_bullets="$(bullets_opening_on <(passage_of "$skill" "## 6. Close" "## Hard rules") "- ")"
# The next-step bullet may speak of a published Setup ticket and of its blocker too, so the bullet
# that lists the tickets is the one that does not fix the last line.
flat="$(grep -E 'published|every ticket|each ticket' <<<"$close_bullets" | grep -vF "last line")"
expect "the close step carries the bullet that lists every published ticket" test -n "$flat"
carries_each "each published ticket is shown with its kind beside its blocking edges" \
  "kind" "Kind" -- \
  "blocking edge" "Blocked by" "blocker" "what blocks it"

# Scoped to the sentences that name the Setup ticket and leave out those that name `--auto`: the
# bullet already says the last line is `/do` on the first ticket of the frontier, and the
# `--auto` exception also says `/do` and "the first ticket", so neither can answer for the rule
# outside `--auto`.
flat="$(grep -F "last line" <<<"$close_bullets" | sed 's/\. /.\n/g' | grep -F "etup ticket" | grep -vF -- "--auto" | tr '\n' ' ')"
expect "the next-step bullet of the close step names the Setup ticket" test -n "${flat// /}"
carries_any "with a Setup ticket cut, the last line is /do on the Setup ticket" \
  "/do" "last line" "next command" "the command" "frontier" "no blocker" "blocked by nothing" \
  "nothing blocks it" "comes first" "goes first" "is the first" "the first ticket"

echo "# SKILL.md / ## 6: under --auto the Setup ticket's last line is the plain /do command, and one line says why"
# `do` refuses `--auto` on a Setup ticket at its door, so a pasted `/do --auto` line would stop the
# chain on its first step. Every phrasing is matched in lower case, since the prose may write Ticket.
no_flag=(
  "plain" "no flag" "without the flag" "without that flag" "without \`--auto\`" "without --auto"
  "no \`--auto\`" "drops the flag" "drops \`--auto\`" "flag is dropped" "leaves the flag"
  "leaves \`--auto\`" "flag is left" "flag off" "never \`/do --auto"
)
# Scoped to the sentences of the next-step bullet that name both the flag and the Setup ticket: the
# bullet already says the Setup ticket's last line is `/do` and that under `--auto` the line reads
# `/do --auto <ticket>`, in two sentences that never meet, and neither can answer for the exception.
flat="$(grep -F "last line" <<<"$close_bullets" | sed 's/\. /.\n/g' | grep -iF "etup ticket" | grep -F -- "--auto" | tr '\n' ' ')"
flat="${flat,,}"
expect "a sentence of the next-step bullet names both --auto and the Setup ticket" test -n "${flat// /}"
carries_each "under --auto the Setup ticket's last line is the plain /do command, with no flag" \
  "/do" -- \
  "${no_flag[@]}"

# The line may sit in a bullet of its own, so the scope is every bullet of the close that names the
# Setup ticket: none of them speaks of the developer or of a next ticket today.
flat="$(grep -iF "etup ticket" <<<"$close_bullets" | tr '\n' ' ')"
flat="${flat,,}"
carries_each "one line says this one ticket needs the developer" \
  "one line" "a line" "one more line" "single line" "line says" "line saying" "line tells" \
  "line telling" -- \
  "needs the developer" "need the developer" "developer's to run" "developer's own to run" \
  "the developer runs" "run by the developer" "takes the developer" "developer has to run" \
  "developer must run"
carries_each "and that the flag returns from the next ticket on" \
  "flag" "\`--auto\`" -- \
  "returns from the next ticket" "from the next ticket on" "comes back on the next ticket" \
  "returns on the next ticket" "comes back from the next ticket" "back from the next ticket" \
  "returns with the next ticket" "back with the next ticket" "from the ticket after it on" \
  "again from the next ticket" "again on the next ticket"

echo "# SKILL.md / ## 4: the --auto section says the same exception for the Setup ticket"
# Scoped to the sentences that name the Setup ticket: the section already speaks of a `/do` line,
# said of a run that publishes nothing.
flat="$(passage_of "$skill" "### Under \`--auto\`" "## 5. Publish" | tr '\n' ' ' | tr -s ' ' | sed 's/\. /.\n/g' | grep -iF "etup ticket" | tr '\n' ' ')"
flat="${flat,,}"
expect "the --auto section names the Setup ticket" test -n "${flat// /}"
carries_each "its /do line is the plain command there too, with no flag" \
  "/do" -- \
  "${no_flag[@]}"

echo "# ticket-format.md / ## Header: the Setup ticket takes 00, and every other ticket counts from 01 with or without it"
# `tickets` numbers from this section and `do` resolves a ticket by its `<NN>` file name, so the
# section has to carry both halves. Every phrasing is matched in lower case, since the prose may
# write Ticket.
format="$here/../../../.agents/formats/ticket-format.md"
header="$(passage_of "$format" "## Header" "## Spec" | tr '\n' ' ' | tr -s ' ')"
header="${header,,}"
expect "ticket-format.md carries the Header section" test -n "${header// /}"
# Scoped to the sentences that name the Setup ticket: the section already says `<NN>` counts from
# `01`, and that sentence cannot answer for the number the Setup ticket takes.
flat="$(sed 's/\. /.\n/g' <<<"$header" | grep -F "etup ticket" | tr '\n' ' ')"
carries "the Setup ticket takes 00" "\`00\`"
carries_any "00 is the one number below 01" \
  "the one number below \`01\`" "the only number below \`01\`" "the single number below \`01\`" \
  "the one number under \`01\`" "the only number under \`01\`" "the one number before \`01\`" \
  "the only number before \`01\`"
# The other half may sit in a sentence of its own that says "it" of the Setup ticket, so the scope
# is the section from the Setup ticket's first naming on.
lead="${header%%etup ticket*}"
flat=""
[ "$lead" != "$header" ] && flat="${header:${#lead}}"
carries_each "every other ticket counts from 01 whether or not the Setup ticket is there" \
  "every other ticket" "each other ticket" "all other tickets" "all the other tickets" \
  "the other tickets" "every ticket but it" "every ticket after it" -- \
  "from \`01\`" "at \`01\`" "on \`01\`" -- \
  "whether or not it is there" "whether or not the setup ticket is there" \
  "whether or not one is there" "whether or not one is cut" "whether or not it is cut" \
  "whether or not the setup ticket is cut" "whether or not there is one" \
  "whether or not there is a setup ticket" "whether it is there or not" \
  "whether the setup ticket is there or not" "whether one is cut or not" \
  "with or without it" "with or without one" "with or without a setup ticket" \
  "with or without the setup ticket" "setup ticket or not"

exit $((fails > 0))
