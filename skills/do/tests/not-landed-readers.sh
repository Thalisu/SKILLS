#!/usr/bin/env bash
# not-landed-readers.sh: not-landed.md is read only when a review return, or a fix call's, prints a
# `route=` line other than `route=verify`. Each review step points the run at it through one
# `Read [not-landed.md](not-landed.md) when <condition>` line, so a run whose review lands never
# loads the handling of a return that did not.
# Run: bash skills/do/tests/not-landed-readers.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
refs="$here/../references"
fails=0

readers=(
  "review step" "review steps" -- "Final integration" -- "its stop" "a stop" "stops" --
  "Resume" "resume" -- "verification" -- "red flow"
)
condition=("route=verify" -- "anything but" "other than" "not \`route=verify\`")

echo "# not-landed.md: its opening names every reader that reaches it and the condition that sends them"
flat="$(awk '/^## /{exit} {print}' "$refs/not-landed.md" | tr '\n' ' ' | tr -s ' ')"
expect "not-landed.md has an opening before its first section" grep -qE '[a-z]' <<<"${flat#\# Not landed}"
carries_each "the opening names each review step, the Final integration's review, stop and resume, the Resume paths and the verification's red flow" \
  "${readers[@]}"
carries_each "the opening names the condition, a route= line other than route=verify" "${condition[@]}"

echo "# each review step sends a return other than route=verify to not-landed.md at that point"
# $1 the review step, $2 its text; the step carries the pointer followed by a condition.
points_at_not_landed() {
  expect "$1 is found" test -n "$2"
  expect "$1 reads not-landed.md when a return is other than route=verify" \
    grep -qE 'Read \[not-landed\.md\]\(not-landed\.md\) when [^ ]' <<<"$2"
}
key="integration.sh settle <the worktree>"
points_at_not_landed "mechanics.md's ### Reading the return" \
  "$(passage_of "$refs/mechanics.md" "### Reading the return" "### " | tr '\n' ' ' | tr -s ' ')"
points_at_not_landed "mechanics.md's Final integration review, step 5" \
  "$(passage_of "$refs/mechanics.md" "**5. The review.**" "**6. The release.**" | tr '\n' ' ' | tr -s ' ')"
points_at_not_landed "ticket.md's review step" \
  "$(item_holding "$refs/ticket.md" '\*\*[0-9]+\.' "$key" | tr '\n' ' ' | tr -s ' ')"
points_at_not_landed "bug-fix.md's review step" \
  "$(item_holding "$refs/bug-fix.md" '\*\*[0-9]+\.' "$key" | tr '\n' ' ' | tr -s ' ')"
points_at_not_landed "refactoring.md's review step" \
  "$(item_holding "$refs/refactoring.md" '### [0-9]+\.' "$key" | tr '\n' ' ' | tr -s ' ')"

# A run whose review lands reads mechanics.md and its Playbook and never not-landed.md, so the
# handling of a return that did not land, left in either, is text every landed run loads for
# nothing. A line carrying the pointer may name the condition it sends the run on.
echo "# mechanics.md and the three Playbooks: a run whose review lands loads no not-landed handling"
not_landed_text='not landed: target moved|route=(fix|resume|blocked)([^a-z-]|$)|Caller: do|`(fix|gate|caller)=|fix <review>'
for name in mechanics ticket bug-fix refactoring; do
  left="$(grep -nE "$not_landed_text" "$refs/$name.md" | grep -vF '](not-landed.md)')"
  if [ -z "$left" ]; then
    ok "$name.md carries no not-landed route, fix call line or target moved handling outside its pointers"
  else
    fail "$name.md carries no not-landed route, fix call line or target moved handling outside its pointers (left: ${left//$'\n'/; })"
  fi
done

exit $((fails > 0))
