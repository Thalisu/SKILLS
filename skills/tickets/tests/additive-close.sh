#!/usr/bin/env bash
# additive-close.sh: how a run that added Tickets to a feature with open ones closes. The close lists
# what was added and what was changed in the Tickets already published, and its last line is the
# `do` command for the first new Ticket, with the line before it naming that Ticket's Build
# repository when it is built elsewhere.
# The developer copies that last line to carry on: a line for an older Ticket of the frontier runs
# the wrong one, and a line with no repository named is pasted into a session that cannot build it.
# The session writes the close from the publish it just made, which no script carries, so the
# decision is proven over the passage of step 6 that carries it. The eval case
# auto-adds-the-missing-tickets grades it on a live run: its grader has to ask for that same close,
# and its fixture has to be a run whose first new Ticket is built outside the session's repository,
# or the hand-over line it asks for is not owed.
# Run: bash skills/tickets/tests/additive-close.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
skill="$here/../SKILL.md"
case_dir="$here/../evals/auto-adds-the-missing-tickets"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

mapfile -t moved_out < <(moved_out_phrasings)
mapfile -t edge_added < <(edge_added_phrasings)
mapfile -t changed < <(changed_phrasings)
last_line=("last line" "final line" "closing line" "ends on" "ends with" "end on" "end with")
line_before=(
  "line before" "line above" "lines above" "before the command" "above the command" "before it"
  "above it" "preceding line" "previous line" "second to last" "second-to-last"
)
# The section already describes the hand-over to another repository, so the passage may point at
# that rule instead of writing it out a second time.
same_hand_over=(
  "hand-over" "handover" "hand over" "another repository" "same rule" "rule above" "as above"
  "described above" "same way"
)

echo "# SKILL.md / ## 6: the close on a feature with open Tickets"
passage_of "$skill" "## 6. Close" "## Hard rules" >"$tmp/step6.md"
# shellcheck disable=SC2034 # the carries_* assertions read $flat
flat="$(passage_of "$tmp/step6.md" "**On a feature with open tickets.**" "## Hard rules" |
  tr '\n' ' ' | tr -s ' ')"
flat="${flat,,}"
expect "the close step has a passage on a feature with open tickets" test -n "${flat// /}"
carries_each "the close lists each new ticket with its identifier" \
  "new ticket" "added ticket" "ticket it adds" "tickets it adds" "ticket it added" \
  "tickets it added" "ticket added" "tickets added" "what was added" "each new" -- \
  "identifier" "number" "reference"
carries_each "and each existing ticket the publish changed" \
  "existing ticket" "open ticket" "published ticket" "ticket already" "tickets already" \
  "stopped ticket" "ticket the publish" "ticket it edited" "tickets it edited" "what was changed" -- \
  "${changed[@]}"
carries_each "with the criterion moved out of it" \
  "criteri" -- \
  "${moved_out[@]}"
carries_each "and the blocked by edge it gained" \
  "blocked by" -- \
  "${edge_added[@]}"
carries_each "the last line is the /do command for the first new ticket" \
  "${last_line[@]}" -- \
  "/do" -- \
  "first new ticket" "first of the new tickets" "first new one" "first added ticket" \
  "first ticket it added" "first ticket it adds" "first ticket added" "first of the added tickets" \
  "first of the tickets it added" "first of the tickets it adds" "first ticket this run added" \
  "first of the tickets this run added" "first of the new ones" "first ticket the run added"
carries_each "a first new ticket built elsewhere gets the line naming its build repository as the place to open a session in" \
  "build repository" -- \
  "session" "${same_hand_over[@]}"
carries_any "and the command then carries that ticket's absolute location" \
  "absolute" "${same_hand_over[@]}"

echo "# evals/auto-adds-the-missing-tickets: the run is one where the hand-over line is owed"
fixture="$tmp/laid/fixture"
mkdir -p "$fixture"
scaffold_rc=0
lay_scaffold "$case_dir/case.yaml" "$fixture" || scaffold_rc=$?
spec="$(find "$fixture/.scratch" -name spec.md 2>/dev/null | head -n 1)"
label="the scaffold lays a feature folder with a spec"
if [ "$scaffold_rc" = 0 ] && [ -n "$spec" ]; then ok "$label"; else
  fail "$label (scaffold exit $scaffold_rc)"
  echo "      extract: $(tail -1 "$tmp/extract.log")"
  echo "      scaffold: $(tail -1 "$tmp/scaffold.log")"
fi
repositories="$(passage_of "${spec:-/dev/null}" "## Repositories" "## ")"
session_root="$(cd "$fixture" && pwd -P)"
home_at="$(sed -nE 's/^- orders-service \(Home repository\): *//p' <<<"$repositories" | head -n 1)"
expect "the session runs in orders-service, the Home repository" test "$home_at" = "$session_root"
built_in="$(passage_of "${spec:-/dev/null}" "## Implementation Decisions" "## " |
  sed -nE 's/^- Moved by the run on Ticket [0-9]+.* at the Plan step: .+\. Belongs to: ([^.]+)\.$/\1/p' |
  head -n 1)"
expect "the finding line names notifications-service, where the new ticket is built" \
  test "$built_in" = "notifications-service"
built_at="$(sed -nE "s/^- ${built_in:-none}: *//p" <<<"$repositories" | head -n 1)"
expect "the spec's Repositories section gives that repository a location on disk" test -d "${built_at:-/nonexistent}"
label="that location is not the repository the session is in"
if [ -n "$built_at" ] && [ "$built_at" != "$session_root" ]; then ok "$label"; else fail "$label"; fi
expect "the prompt runs under --auto, so the command to hand over reads /do --auto" \
  grep -qE '(^| )--auto( |$)' "$case_dir/prompt.md"

echo "# evals/auto-adds-the-missing-tickets: a grader asks for that close"
grader="$case_dir/graders/close-lists-the-addition-and-hands-over.md"
expect "the case holds the close-lists-the-addition-and-hands-over grader" test -f "$grader"
# shellcheck disable=SC2034 # field reads the frontmatter the caller left in $out
out="$(frontmatter "$grader" 2>/dev/null)"
expect "that grader is judged by a model" test "$(field type)" = "llm"
flat="$(field criteria | tr '\n' ' ' | tr -s ' ')"
flat="${flat,,}"
expect "that grader carries its criteria" test -n "${flat// /}"
carries_any "it is judged on the run's final message" \
  "final message" "last message" "closing message" "final reply" "last reply" "final response" \
  "final answer"
carries_each "the message lists ticket 04 as added" \
  "04" -- \
  "added" "adds" "new ticket"
carries_each "and ticket 02 as changed" \
  "02" -- \
  "${changed[@]}"
carries_each "with the email criterion moved out of it to 04" \
  "email" -- \
  "criteri" -- \
  "${moved_out[@]}"
carries_each "and its blocked by now naming 04" \
  "blocked by" -- \
  "${edge_added[@]}" "now nam" "now list" "now read" "now carr"
carries_each "the last line is /do --auto with the absolute location of the ticket 04 file" \
  "${last_line[@]}" -- \
  "/do --auto" -- \
  "absolute"
carries_any "in the Home repository's feature folder" \
  "home repository" "orders-service"
carries_each "the line before it names notifications-service and its location as the place to open a session in" \
  "notifications-service" -- \
  "${line_before[@]}" -- \
  "location" "path" "where it is" "root" -- \
  "session"
carries_each "a last line naming ticket 02 or 03, a relative path or a cd fails" \
  "03" -- \
  "relative" -- \
  "cd " "cd\`" "cd'" "cd," "cd." "cd)" -- \
  "fail" "not pass" "no pass"

exit $((fails > 0))
