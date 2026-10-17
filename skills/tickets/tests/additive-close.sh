#!/usr/bin/env bash
# additive-close.sh: how a run that added Tickets to a feature with open ones closes. The close lists
# what was added and what was changed in the Tickets already published, and its last line is the
# `do` command for the first new Ticket, with the line before it naming that Ticket's Build
# repository when it is built elsewhere.
# The developer copies that last line to carry on: a line for an older Ticket of the frontier runs
# the wrong one, and a line with no repository named is pasted into a session that cannot build it.
# The session writes the close from the publish it just made, which no script carries, so the
# decision is proven over the passage of step 6 that carries it. The eval case
# auto-adds-the-missing-tickets grades it on a live run: its fixture has to be a run whose first
# new Ticket is built outside the session's repository, or the hand-over line is not owed.
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
  sed -nE 's/^- Moved by the run on Ticket [0-9]+.* at the [^ ]+ step: .+\. Belongs to: ([^.]+)\.$/\1/p' |
  head -n 1)"
expect "the finding line names notifications-service, where the new ticket is built" \
  test "$built_in" = "notifications-service"
built_at="$(sed -nE "s/^- ${built_in:-none}: *//p" <<<"$repositories" | head -n 1)"
expect "the spec's Repositories section gives that repository a location on disk" test -d "${built_at:-/nonexistent}"
label="that location is not the repository the session is in"
if [ -n "$built_at" ] && [ "$built_at" != "$session_root" ]; then ok "$label"; else fail "$label"; fi

exit $((fails > 0))
