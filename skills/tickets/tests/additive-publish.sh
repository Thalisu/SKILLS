#!/usr/bin/env bash
# additive-publish.sh: what a yes publishes on a feature with open Tickets. The new Tickets are
# written under the same issues/ folder, numbered on after the feature's last one; the criterion the
# cut moves leaves the Ticket it was in and lands in the new one; that Ticket's Blocked by gains the
# new Ticket beside the blockers it had; and no existing Ticket is renumbered, renamed or deleted.
# The next `do` run on the stopped Ticket and every Blocked by already written rely on it: a
# renumbering points them at the wrong Ticket, and a criterion left behind is one that Ticket's
# repository cannot prove.
# The session writes these files from the breakdown it holds, which no script carries, so the
# decision is proven over the passage of step 5 that carries it. The eval case
# auto-adds-the-missing-tickets grades it on a live run: its code-read graders are run here through
# scripts/run-eval.sh's own grade() over the case's fixture, as laid and as a faithful run leaves it.
# Run: bash skills/tickets/tests/additive-publish.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
skill="$here/../SKILL.md"
case_dir="$here/../evals/auto-adds-the-missing-tickets"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

source_grade

mapfile -t moved_out < <(moved_out_phrasings)
mapfile -t edge_added < <(edge_added_phrasings)
mapfile -t kept < <(kept_phrasings)
mapfile -t never < <(never_phrasings)
deleted=("delet" "erase" "removed" "removes" "remove an" "remove a " "dropped" "discard")

echo "# SKILL.md / ## 5: the publish on a feature with open Tickets"
passage_of "$skill" "## 5. Publish" "## 6. Close" >"$tmp/step5.md"
# shellcheck disable=SC2034 # the carries_* assertions read $flat
flat="$(passage_of "$tmp/step5.md" "**On a feature with open tickets.**" "**A real tracker" |
  tr '\n' ' ' | tr -s ' ')"
flat="${flat,,}"
expect "the publish step has a passage on a feature with open tickets" test -n "${flat// /}"
carries_each "the new tickets are written as new files under the same issues/ folder" \
  "issues/" "same folder" "that folder" "feature folder" "feature's folder" "one folder" -- \
  "new file" "new ticket" "each new" "ticket it adds" "tickets it adds" "added ticket"
carries_each "they are numbered on after the feature's last one" \
  "number" -- \
  "after" "follow" "next" "continu" "onward" "above" "on from" -- \
  "last" "highest" "greatest" "largest"
carries_each "the criterion is moved out of the ticket the cut changes and into the new one" \
  "criteri" -- \
  "${moved_out[@]}" "deleted from" "cut from" "dropped from" "taken off" -- \
  "new ticket" "new one" "new file" "ticket that takes it" "ticket taking it" "added ticket"
carries_each "that ticket's blocked by gains the new ticket beside the blockers it had" \
  "blocked by" -- \
  "${edge_added[@]}" "append" -- \
  "beside" "alongside" "in addition to" "on top of" "already" "existing blocker" "it had" \
  "it has" "it named" "it names" "it lists" "it listed" "keeps" "kept" "remain" "stay"
carries_each "nothing else of an existing ticket is edited: its status and its other criteria stay" \
  "status" -- \
  "other criteri" "remaining criteri" "rest of its criteri" "every other criteri" "its other" \
  "nothing else" "no other" "every other line" "rest of the ticket" "rest of the file" -- \
  "${kept[@]}"
carries_each "no existing ticket is renumbered" \
  "renumber" -- \
  "${never[@]}"
carries_each "and none is deleted" \
  "${deleted[@]}" -- \
  "${never[@]}"

echo "# evals/auto-adds-the-missing-tickets: the prompt and the stand-in that rules to publish"
prompt="$(cat "$case_dir/prompt.md" 2>/dev/null)"
expect "the prompt types /tickets" grep -qE '^/tickets( |$)' <<<"$prompt"
expect "under --auto, so the choice-taker's ruling is the yes" grep -qE '(^| )--auto( |$)' <<<"$prompt"
expect "the case unlinks the real choice-taker" \
  grep -qx "choice-taker" <(yq -r '.context.unlinked_agents // [] | .[]' "$case_dir/case.yaml" 2>/dev/null)

echo "# evals/auto-adds-the-missing-tickets: the fixture is the open feature with the stopped Ticket 02"
as_laid="$tmp/as-laid"
mkdir -p "$as_laid/fixture"
scaffold_rc=0
lay_scaffold "$case_dir/case.yaml" "$as_laid/fixture" || scaffold_rc=$?
spec="$(find "$as_laid/fixture/.scratch" -name spec.md 2>/dev/null | head -n 1)"
feature="$(dirname "${spec:-$as_laid/fixture/none/spec.md}")"
slug="$(basename "$feature")"
mapfile -t tickets < <(find "$feature/issues" -maxdepth 1 -name '*.md' -printf '%f\n' 2>/dev/null | sort)
label="the scaffold lays a feature folder with a spec"
if [ "$scaffold_rc" = 0 ] && [ -n "$spec" ]; then ok "$label"; else
  fail "$label (scaffold exit $scaffold_rc)"
  echo "      extract: $(tail -1 "$tmp/extract.log")"
  echo "      scaffold: $(tail -1 "$tmp/scaffold.log")"
fi
expect "the prompt names that feature" grep -qF -- "$slug" <<<"$prompt"
expect "the fixture holds the choice-taker stand-in" test -f "$as_laid/fixture/.claude/agents/choice-taker.md"
numbers="$(printf '%s\n' "${tickets[@]}" | cut -d- -f1 | tr '\n' ' ')"
expect "the feature holds the three published tickets 01, 02 and 03, and no 04" test "$numbers" = "01 02 03 "
stopped="$(find "$feature/issues" -maxdepth 1 -name '02-*.md' 2>/dev/null | head -n 1)"
expect "ticket 02 still holds the customer email criterion, unticked" \
  grep -qiE '^- \[ \] .*email' "${stopped:-/dev/null}"
repositories="$(passage_of "${spec:-/dev/null}" "## Repositories" "## ")"
label="the spec lists orders-service as Home repository, billing-service and notifications-service"
if grep -qE '^- orders-service \(Home repository\)' <<<"$repositories" &&
  grep -qE '^- billing-service\b' <<<"$repositories" &&
  grep -qE '^- notifications-service\b' <<<"$repositories"; then ok "$label"; else fail "$label"; fi
finding="$(passage_of "${spec:-/dev/null}" "## Implementation Decisions" "## " |
  grep -E '^- Moved by the run on Ticket 02\b.* at the Plan step: .+\. Belongs to: notifications-service\.$' |
  head -n 1)"
expect "the finding line names Ticket 02 and notifications-service" test -n "$finding"

echo "# evals/auto-adds-the-missing-tickets: the code-read graders tell a faithful publish from the rest"
# A faithful run: ticket 04 written for notifications-service with the email criterion, ticket 02
# without that criterion and blocked by 04 beside 01.
faithful="$tmp/faithful"
cp -r "$as_laid" "$faithful" 2>/dev/null || mkdir -p "$faithful/fixture"
issues="$faithful/fixture/.scratch/$slug/issues"
mkdir -p "$issues"
cat >"$issues/04-tell-the-customer-the-invoice-is-on-hold.md" <<'MD'
# 04: Tell the customer the Invoice is on hold

**What to build:** Tell the customer the Invoice is on hold: the customer was told once.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

**Kind:** logic

**Build repository:** notifications-service

- [ ] Asked for a held Invoice, the mailer sends the customer the "invoice-on-hold" email, "Your Invoice is on hold", once

## Evidence
MD
for f in "$issues"/02-*.md; do
  [ -f "$f" ] || continue
  sed -i -E '/^- \[ \] .*[Ee]mail/d; s/^(\*\*Blocked by:\*\* .*)$/\1, 04: Tell the customer the Invoice is on hold/' "$f"
done
# A run that wrote a ticket 04 and got the rest wrong: built in the wrong repository, the email only
# in its prose and in a ticked criterion, and ticket 02 naming 04 in its prose alone.
wrong="$tmp/wrong"
cp -r "$as_laid" "$wrong" 2>/dev/null || mkdir -p "$wrong/fixture"
issues="$wrong/fixture/.scratch/$slug/issues"
mkdir -p "$issues"
cat >"$issues/04-tell-the-customer-the-invoice-is-on-hold.md" <<'MD'
# 04: Tell the customer the Invoice is on hold

**What to build:** The email to the customer, sent through notifications-service.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

**Kind:** logic

**Build repository:** billing-service

- [x] The customer receives the email "Your Invoice is on hold"
- [ ] The mailer knows the template

## Evidence
MD
for f in "$issues"/02-*.md; do
  [ -f "$f" ] || continue
  sed -i -E 's/^(\*\*What to build:\*\* .*)$/\1 See ticket 04./' "$f"
done

graders="$case_dir/graders"
# shellcheck disable=SC2034 # read by lib.sh's grade_passes and grade_fails
grader="$graders/ticket-04-written.md"
expect "the case holds the ticket-04-written grader" test -f "$grader"
grade_fails "the feature as laid, with no ticket 04, fails ticket-04-written" "$as_laid"
grade_passes "a 04 file under the feature's issues/ passes ticket-04-written" "$faithful"

grader="$graders/ticket-04-names-where-it-is-built.md"
expect "the case holds the ticket-04-names-where-it-is-built grader" test -f "$grader"
grade_passes "a ticket 04 whose Build repository line reads notifications-service passes it" "$faithful"
grade_fails "a ticket 04 built in billing-service that names notifications-service in its prose fails it" "$wrong"
grade_fails "the feature as laid fails it" "$as_laid"

grader="$graders/ticket-04-holds-the-moved-criterion.md"
expect "the case holds the ticket-04-holds-the-moved-criterion grader" test -f "$grader"
grade_passes "a ticket 04 with an unticked criterion about the email passes it" "$faithful"
grade_fails "a ticket 04 with the email in its prose and in a ticked criterion only fails it" "$wrong"
grade_fails "the feature as laid, where ticket 02 holds that criterion, fails it" "$as_laid"

grader="$graders/ticket-02-blocked-by-the-new-ticket.md"
expect "the case holds the ticket-02-blocked-by-the-new-ticket grader" test -f "$grader"
grade_passes "a ticket 02 whose Blocked by line names 04 beside 01 passes it" "$faithful"
grade_fails "a ticket 02 naming 04 in its prose and not in its Blocked by line fails it" "$wrong"
grade_fails "the feature as laid, where ticket 02 waits on 01 alone, fails it" "$as_laid"

echo "# evals/auto-adds-the-missing-tickets: a grader asks that the criterion moved and nothing was renumbered"
grader="$graders/criterion-moved-and-nothing-renumbered.md"
expect "the case holds the criterion-moved-and-nothing-renumbered grader" test -f "$grader"
# shellcheck disable=SC2034 # field reads the frontmatter the caller left in $out
out="$(frontmatter "$grader" 2>/dev/null)"
expect "that grader is judged by a model" test "$(field type)" = "llm"
flat="$(field criteria | tr '\n' ' ' | tr -s ' ')"
flat="${flat,,}"
expect "that grader carries its criteria" test -n "${flat// /}"
carries_each "ticket 02 no longer holds the email criterion" \
  "02" -- \
  "email" -- \
  "criteri" -- \
  "no longer" "not hold" "does not carry" "not carry" "gone" "absent" "lacks" "without" \
  "${moved_out[@]}"
carries_each "ticket 02 keeps its other criteria, its status and its blocker 01" \
  "other criteri" "remaining criteri" "rest of its criteri" "every other criteri" "its other" \
  "four criteri" "other four" "four other" -- \
  "status" -- \
  "01" -- \
  "${kept[@]}"
carries_each "tickets 01 and 03 are unedited" \
  "01" -- \
  "03" -- \
  "${kept[@]}"
carries_each "no existing file was renumbered" \
  "renumber" -- \
  "${never[@]}"
carries_each "and none was deleted" \
  "${deleted[@]}" -- \
  "${never[@]}"
carries_each "exactly one new ticket file was written" \
  "exactly one" "only one" "one new" "a single" "one and only one" "one ticket file" -- \
  "new ticket" "new file" "ticket file" "04"

exit $((fails > 0))
