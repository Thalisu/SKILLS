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

echo "# SKILL.md: the references-list entry for not-landed.md names the same readers and condition"
skill="$here/../SKILL.md"
flat="$(bullets_opening_on "$skill" "[not-landed.md](references/not-landed.md)" | tr -s ' ')"
expect "SKILL.md's references list has an entry for not-landed.md" test -n "$flat"
carries_each "the entry names each review step, the Final integration's review, stop and resume, the Resume paths and the verification's red flow" \
  "${readers[@]}"
carries_each "the entry names the condition, a route= line other than route=verify" "${condition[@]}"
expect "SKILL.md links not-landed.md in its references-list entry alone" \
  test "$(grep -cE '\]\(([^)]*/)?not-landed\.md\)' "$skill")" = 1

echo "# each review step sends a return other than route=verify to not-landed.md at that point"
# $1 the review step, $2 its text; the step carries the pointer followed by a condition.
# Optional: $3 what sends the run there, for the case's label, a return other than route=verify when
# left out.
points_at_not_landed() {
  expect "$1 is found" test -n "$2"
  expect "$1 reads not-landed.md when ${3:-a return is other than route=verify}" \
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

# A resume on a Review that already counts has no review return of its own to send it there: the
# fix call's lines (`Caller: do`, its arguments, no `command=` line on a resume) live in
# not-landed.md alone, so a path without the pointer calls the review with no `Caller: do` line.
echo "# each Resume path that lands through the fix call on a Review the run has reads not-landed.md there"
via_fix="it lands through the fix call on a Review the run already has"
points_at_not_landed "ticket.md's verdict=land resume bullet" \
  "$(bullets_opening_on "$refs/ticket.md" "On \`verdict=land\`, the review already read this branch")" "$via_fix"
points_at_not_landed "ticket.md's mid-rebase resume, a review= line naming a Review" \
  "$(passage_of "$refs/ticket.md" "  A \`review=\` line that names a Review means the rebase came after the review" "- " |
    tr '\n' ' ' | tr -s ' ')" "$via_fix"
points_at_not_landed "ticket.md's stopped Final integration, step 3's verdict=land" \
  "$(passage_of "$refs/ticket.md" "### A stopped Final integration" "## " |
    bullets_opening_on /dev/stdin "\`verdict=land\`, exit 4: the Review beside the Spec counts")" "$via_fix"
points_at_not_landed "bug-fix.md's resume on a Review that counts" \
  "$(bullets_opening_on "$refs/bug-fix.md" "A Review of the branch" |
    grep -F "A Review that counts means the review already read the branch")" "$via_fix"
points_at_not_landed "refactoring.md's resume on a Review that counts" \
  "$(paragraph_with "$refs/refactoring.md" "a Review that counts decides" | tr -s ' ')" "$via_fix"
points_at_not_landed "mechanics.md's integration on a run the review already read" \
  "$(paragraph_with "$refs/mechanics.md" "A run the review already read, a" | tr -s ' ')" "$via_fix"

echo "# skills/do: every pointer to not-landed.md reads Read [not-landed.md](not-landed.md) when <condition>"
# A link to the file, under any relative path, is a pointer, except SKILL.md's references-list entry
# and the links not-landed.md makes to itself. Files are flattened, since a pointer may wrap.
pointers=0
misshapen=""
for file in "$refs"/*.md "$here"/../agents/*.md; do
  [ "$(basename "$file")" = not-landed.md ] && continue
  while IFS= read -r hit; do
    [ -n "$hit" ] || continue
    pointers=$((pointers + 1))
    grep -qE '^Read \[not-landed\.md\]\(not-landed\.md\) when ' <<<"$hit" ||
      misshapen="$misshapen${misshapen:+; }$(basename "$file"): $hit"
  done < <(tr '\n' ' ' <"$file" | tr -s ' ' | grep -oE '(Read )?\[[^]]*\]\(([^)]*/)?not-landed\.md\)( when )?')
done
expect "the do skill points at not-landed.md from the steps that read it" test "$pointers" -ge 5
if [ -z "$misshapen" ]; then
  ok "every pointer to not-landed.md has the \`Read <file> when <condition>\` shape"
else
  fail "every pointer to not-landed.md has the \`Read <file> when <condition>\` shape (misshapen: $misshapen)"
fi

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
