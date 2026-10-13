#!/usr/bin/env bash
# additive-decline.sh: what a no does on a feature with open Tickets. Nothing is published, no
# existing Ticket is edited, one line says nothing was published, no next command follows, and the
# finding line stays in the Spec, so a later `tickets` run on the same Spec cuts from it.
# The developer who said no relies on it: a finding cleared on the way out is missing work lost for
# good, and a `/do` line after a no names an issue that does not exist.
# The session takes the no from the answer it was given, which no script carries, so the decision is
# proven over the passages of step 4 that carry it. The eval case
# auto-declined-addition-publishes-nothing grades it on a live run, and its code-read graders have to
# pass a faithful no and fail each outcome a no must not break.
# Run: bash skills/tickets/tests/additive-decline.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
skill="$here/../SKILL.md"
case_dir="$here/../evals/auto-declined-addition-publishes-nothing"
reference_dir="$here/../evals/auto-adds-the-missing-tickets"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

source_grade

mapfile -t changed < <(changed_phrasings)
mapfile -t never < <(never_phrasings)
mapfile -t declined < <(declined_phrasings)
mapfile -t on_open_tickets < <(on_open_tickets_phrasings)
mapfile -t nothing_published < <(nothing_published_phrasings)
mapfile -t finding_kept < <(finding_kept_phrasings)
mapfile -t later_run < <(later_run_phrasings)

# The finding line of a Spec, as `do` leaves it under Implementation Decisions for Ticket 02.
finding_of() { # $1 spec: the first such line, whole, on stdout
  passage_of "${1:-/dev/null}" "## Implementation Decisions" "## " |
    grep -E '^- Moved by the run on Ticket 02\b.* at the Plan step: .+\. Belongs to: notifications-service\.$' |
    head -n 1
}
caught() { # $1 label, $2 a work folder where the outcome is broken
  local label="$1" work="$2" g
  for g in "${code_graders[@]}"; do
    [ -z "$(grade "$g" "$work")" ] || {
      ok "$label"
      return
    }
  done
  fail "$label"
}

echo "# SKILL.md / ## 4: a no on a feature with open Tickets"
passage_of "$skill" "## 4. Put the breakdown to the user" "## 5. Publish" |
  tr '[:upper:]' '[:lower:]' >"$tmp/step4.md"
for word in "${declined[@]}"; do paragraph_with "$tmp/step4.md" "$word" all; done |
  sort -u >"$tmp/declines.txt"
flat="$(tr '\n' ' ' <"$tmp/declines.txt" | tr -s ' ')"
expect "step 4 says what a no does" test -n "${flat// /}"
carries_each "a no publishes nothing, and one line says so" \
  "${nothing_published[@]}" -- \
  "one line" "a line" "single line"
carries_each "no next command follows it, neither a /do line nor a /tickets line" \
  "/do" -- \
  "/tickets" -- \
  "no next command" "no command" "neither" "nor "

# The no on an addition: the passages of step 4 that speak of a no and of the open tickets at once.
grep -F -f <(printf '%s\n' "${on_open_tickets[@]}") "$tmp/declines.txt" >"$tmp/addition-declined.txt"
flat="$(tr '\n' ' ' <"$tmp/addition-declined.txt" | tr -s ' ')"
expect "step 4 says what a no does on a feature with open tickets" test -n "${flat// /}"
carries_each "a declined addition edits no existing ticket" \
  "ticket" -- \
  "${changed[@]}" -- \
  "${never[@]}"
# The finding may be given a paragraph of its own beside the no.
flat="$flat $(paragraph_with "$tmp/step4.md" "finding" all | tr '\n' ' ' | tr -s ' ')"
carries_each "the finding line stays in the spec" \
  "finding" -- \
  "spec" -- \
  "${finding_kept[@]}"
carries_each "so a later tickets run on the same spec cuts from it" \
  "finding" -- \
  "${later_run[@]}" -- \
  "tickets" -- \
  "cut"

echo "# evals/auto-declined-addition-publishes-nothing: the case unlinks the real choice-taker"
expect "the case unlinks the real choice-taker" \
  grep -qx "choice-taker" <(yq -r '.context.unlinked_agents // [] | .[]' "$case_dir/case.yaml" 2>/dev/null)

echo "# evals/auto-declined-addition-publishes-nothing: the fixture is one a later run would cut from"
reference="$tmp/reference/fixture"
mkdir -p "$reference"
lay_scaffold "$reference_dir/case.yaml" "$reference"
wanted="$(finding_of "$(find "$reference/.scratch" -name spec.md 2>/dev/null | head -n 1)")"
expect "auto-adds-the-missing-tickets, the additive fixture, carries the finding line" test -n "$wanted"

as_laid="$tmp/as-laid"
mkdir -p "$as_laid/fixture"
scaffold_rc=0
lay_scaffold "$case_dir/case.yaml" "$as_laid/fixture" || scaffold_rc=$?
spec="$(find "$as_laid/fixture/.scratch" -name spec.md 2>/dev/null | head -n 1)"
feature="$(dirname "${spec:-$as_laid/fixture/none/spec.md}")"
# shellcheck disable=SC2034 # read by lib.sh's mutated
slug="$(basename "$feature")"
mapfile -t tickets < <(find "$feature/issues" -maxdepth 1 -name '*.md' 2>/dev/null | sort)
label="the scaffold lays a feature folder with a spec"
if [ "$scaffold_rc" = 0 ] && [ -n "$spec" ]; then ok "$label"; else
  fail "$label (scaffold exit $scaffold_rc)"
  echo "      extract: $(tail -1 "$tmp/extract.log")"
  echo "      scaffold: $(tail -1 "$tmp/scaffold.log")"
fi
expect "the tracker is local markdown, where the ruling is the answer" \
  grep -qisF "local markdown" "$as_laid/fixture/docs/agents/issue-tracker.md"
flat="$(cat "$as_laid/fixture/.claude/agents/choice-taker.md" 2>/dev/null | tr '\n' ' ' | tr -s ' ')"
flat="${flat,,}"
carries_any "the fixture's choice-taker stand-in rules to leave the breakdown unpublished" \
  "unpublished" "not published" "not publish" "publishes nothing" "publish nothing" \
  "against publishing" "without publishing"
numbers="$(for t in "${tickets[@]}"; do basename "$t" | cut -d- -f1; done | tr '\n' ' ')"
expect "the feature holds the three published tickets 01, 02 and 03, and no 04" test "$numbers" = "01 02 03 "
stopped="$(find "$feature/issues" -maxdepth 1 -name '02-*.md' 2>/dev/null | head -n 1)"
expect "ticket 02 holds the customer email criterion, unticked" \
  grep -qiE '^- \[ \] .*email' "${stopped:-/dev/null}"
expect "and waits on ticket 01 alone" \
  grep -qE '^\*\*Blocked by:\*\* 01: [^,]+$' "${stopped:-/dev/null}"
label="the spec holds the additive fixture's finding line, word for word"
if [ -n "$wanted" ] && grep -qxF -- "$wanted" "${spec:-/dev/null}"; then ok "$label"; else fail "$label"; fi
label="no ticket under issues/ covers it: none is built in notifications-service"
if [ "${#tickets[@]}" -gt 0 ] &&
  ! grep -qE '^\*\*Build repository:\*\* notifications-service' "${tickets[@]}"; then ok "$label"; else fail "$label"; fi

echo "# evals/auto-declined-addition-publishes-nothing: the graders pass a faithful no and catch the rest"
code_graders=()
for g in "$case_dir"/graders/*.md; do
  [ -f "$g" ] || continue
  case "$(key "$g" type)" in
    file_exists | file_contains) code_graders+=("$g") ;;
  esac
done
# A faithful no leaves the fixture as it was laid.
# shellcheck disable=SC2034 # read by lib.sh's grade_passes
for grader in "${code_graders[@]}"; do
  grade_passes "the feature as laid, which a faithful no leaves as it is, passes $(basename "$grader" .md)" "$as_laid"
done

# Each tree below breaks one outcome of a no and nothing else.
at="$(mutated criterion-moved)"
for f in "$at"/issues/02-*.md; do [ ! -f "$f" ] || sed -i -E '/^- \[ \] .*[Ee]mail/d' "$f"; done
at="$(mutated edge-added)"
for f in "$at"/issues/02-*.md; do
  [ ! -f "$f" ] || sed -i -E 's/^(\*\*Blocked by:\*\* .*)$/\1, 04: Tell the customer the Invoice is on hold/' "$f"
done
at="$(mutated finding-cleared)"
[ ! -f "$at/spec.md" ] || sed -i -E '/^- Moved by the run on Ticket 02\b/d' "$at/spec.md"

caught "a ticket 02 that lost its email criterion is caught" "$tmp/criterion-moved"
caught "a ticket 02 whose blocked by gained 04 is caught" "$tmp/edge-added"
caught "a spec whose finding line was cleared is caught" "$tmp/finding-cleared"

exit $((fails > 0))
