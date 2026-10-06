#!/usr/bin/env bash
# setup-ticket.sh: what SKILL.md has the session do on a spec that reads `Front-end: impeccable`:
# it runs the setup check, and when a step reads missing the breakdown opens with a Setup ticket
# numbered 00, of kind setup, blocked by nothing, whose acceptance criteria are the six setup steps
# in their order, every one listed whether the check reads it done or not.
# The ticket is drafted by the session from the check's verdict, which no script and no eval
# carries, so the decision is proven over the passages that carry it.
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
carries_any "a step the check reads missing is what calls for the ticket" \
  "missing" "exits 1" "exits \`1\`" "exit 1" "exit \`1\`" "exit code 1" "exit status 1"
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

exit $((fails > 0))
