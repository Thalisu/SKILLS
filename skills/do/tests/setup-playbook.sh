#!/usr/bin/env bash
# setup-playbook.sh: what `/do` has the session do on a Setup ticket. The router reads the Ticket's
# kind through ticket-kind.sh before its table, and a row above the `ticket` row sends a Ticket that
# reads kind=setup, with no ambiguous= line, to the `setup` Playbook; any other kind still routes to
# `ticket`. The `setup` Playbook's reply opens on `Playbook: setup`, its door runs setup-door.sh, it
# claims the Ticket in the main checkout on `start` (never committed, and never again on `resume`)
# and runs the setup check, with no worktree created, no Planner or Builder forked and no review
# called. Its reference links no other Playbook's, since a matched Playbook's links are all read.
# The route and the steps are prose a session follows, so they are proven over the passages that
# carry them.
# Run: bash skills/do/tests/setup-playbook.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
skill="$here/../SKILL.md"
setup="$here/../references/setup.md"
fails=0

echo "# SKILL.md / ## Router: a Ticket's kind is read by ticket-kind.sh before the table"
router="$(passage_of "$skill" "## Router" "## ")"
flat="$(tr '\n' ' ' <<<"$router" | tr -s ' ')"
carries "the router runs ticket-kind.sh on the Ticket's path" "bash <skill-dir>/scripts/ticket-kind.sh"
before "the kind is read before the table" "ticket-kind.sh" "| The argument | Match |"

# A row's Match is its last cell: the rows name other Playbooks in their prose, so only that cell
# says where a row routes.
rows="$(grep -E '^\| ' <<<"$router")"
match_of() { awk -F'|' '{ m = $(NF - 1); gsub(/^ +| +$/, "", m); print m }' <<<"$1"; }
setup_at=0
ticket_at=0
setup_row=""
n=0
while IFS= read -r line; do
  n=$((n + 1))
  case "$(match_of "$line")" in
    '`setup`') [ "$setup_at" = 0 ] && setup_at="$n" && setup_row="$line" ;;
    '`ticket`') [ "$ticket_at" = 0 ] && ticket_at="$n" ;;
  esac
done <<<"$rows"

echo "# SKILL.md / ## Router: a row routes a Ticket of kind setup to the setup Playbook, above the ticket row"
expect "the table has a row whose Match is \`setup\`" test "$setup_at" -gt 0
expect "the setup row sits above the ticket row" test "$setup_at" -gt 0 -a "$ticket_at" -gt "$setup_at"
flat="$setup_row"
carries "the row matches a Ticket whose ticket-kind.sh output is kind=setup" "kind=setup"
carries_any "and only with no ambiguous= line" \
  "no \`ambiguous=" "no ambiguous=" "No \`ambiguous=" "without an \`ambiguous=" "without \`ambiguous=" \
  "without an ambiguous=" "without ambiguous=" "no line \`ambiguous=" "no \`ambiguous\` line" \
  "not followed by an \`ambiguous=" "nor an \`ambiguous="
carries_each "an issue reference whose Kind reads setup matches it likewise" \
  "issue reference" "issue number" "an issue" -- \
  "Kind: setup" "Kind:** setup" "Kind:** \`setup\`" "Kind reads setup" "Kind reads \`setup\`" \
  "Kind\` reads \`setup\`" "Kind** reads \`setup\`" "kind reads setup" "kind reads \`setup\`" \
  "Kind is setup" "Kind is \`setup\`" "kind is setup" "kind is \`setup\`" "of kind setup" \
  "of kind \`setup\`" "Kind\` line reads \`setup\`" "Kind line reads setup" "Kind line reads \`setup\`"

echo "# SKILL.md / ## Router: a Ticket of any other kind still routes to ticket"
flat="$(tr '\n' ' ' <<<"$router" | tr -s ' ')"
carries_any "any other kind routes to ticket" \
  "any other kind" "Any other kind" "every other kind" "Every other kind" "other kinds" \
  "kind other than" "kind is not \`setup\`" "kind is not setup" "kind reads anything else" \
  "any other Ticket" "Any other Ticket" "every other Ticket" "Every other Ticket" "any other output" \
  "Any other output" "an \`ambiguous=\` line routes" "ambiguous kind routes"

echo "# SKILL.md / ## Links: setup.md is the setup Playbook"
flat="$(bullets_opening_on <(passage_of "$skill" "## Links" "## ") "references/setup.md")"
expect "Links carries an entry for references/setup.md" test -n "$flat"
carries "the entry names it the setup Playbook" "\`setup\`" "Playbook"

echo "# setup.md / ## Door: the reply opens on Playbook: setup and the door runs setup-door.sh"
expect "the setup Playbook's reference exists" test -f "$setup"
flat="$(passage_of "$setup" "## Door" "## " 2>/dev/null | tr '\n' ' ' | tr -s ' ')"
carries "the reply names the setup Playbook" "Playbook: setup"
carries_any "on its first line" \
  "first line" "First line" "opens with" "opens on" "opening line" "line one" "the reply opens"
carries "the door runs setup-door.sh on the Ticket" "bash <skill-dir>/scripts/setup-door.sh"

echo "# setup.md / ## The claim: start claims the Ticket in the main checkout, uncommitted; resume claims nothing"
flat="$(passage_of "$setup" "## The claim" "## " 2>/dev/null | tr '\n' ' ' | tr -s ' ')"
carries "the claim is made on verdict=start, setting the Status line to claimed" \
  "verdict=start" "**Status:**" "claimed"
carries_any "the edit lands in the main checkout the door's main= line names" \
  "\`main=\`" "main=" "main checkout"
carries_any "the claim is never committed" \
  "never committed" "not committed" "never commits" "commits nothing" "no commit" "uncommitted" \
  "without a commit" "without committing" "is not staged" "never staged"
flat="$(passage_of "$setup" "## The claim" "## " 2>/dev/null | tr '\n' ' ' | sed 's/\. /.\n/g' | grep -F "resume" | tr '\n' ' ')"
expect "the claim names the resume verdict" test -n "${flat// /}"
carries_any "on resume nothing is claimed again" \
  "nothing is claimed" "Nothing is claimed" "claims nothing" "not claimed again" "never claimed again" \
  "no claim" "No claim" "is not claimed" "already claimed" "skips the claim" "skip the claim" \
  "without claiming" "not claim it again" "never claims it again" "claim is not made" \
  "claim is never made" "not set again" "never set again" "left as it is" "left as is" "untouched"

echo "# setup.md / ## The check: the run runs the setup check"
flat="$(passage_of "$setup" "## The check" "## " 2>/dev/null | tr '\n' ' ' | tr -s ' ')"
carries "the step runs setup-check.sh" "bash <skill-dir>/../../.agents/scripts/setup-check.sh"

echo "# setup.md: no worktree, no Planner, no Builder, no review"
whole="$(tr '\n' ' ' 2>/dev/null <"$setup" | tr -s ' ')"
flat="$whole"
carries_any "the run creates no worktree" \
  "no worktree" "No worktree" "creates no worktree" "never creates a worktree" "not create a worktree" \
  "never opens a worktree" "opens no worktree" "without a worktree" "nor a worktree" \
  "never in a worktree" "not in a worktree" "never a worktree"
negations=("no " "No " "never" "Never" "not " "nor " "without" "none")
for agent in do-planner do-builder do-code-review; do
  flat="$(sed 's/\. /.\n/g' <<<"$whole" | grep -F "$agent" | tr '\n' ' ')"
  expect "setup.md names $agent" test -n "${flat// /}"
  carries_any "the run never calls $agent" "${negations[@]}"
done

echo "# setup.md: links no other Playbook's reference"
if [ -f "$setup" ]; then
  # shellcheck disable=SC2034 # absent() reads $out.
  out="$(cat "$setup")"
  absent "setup.md links no mechanics.md" "mechanics.md"
  absent "setup.md links no reply.md" "reply.md"
  absent "setup.md links no ticket.md" "ticket.md"
else
  fail "setup.md links no other Playbook's reference ($setup missing)"
fi

[ "$fails" -eq 0 ] && exit 0
exit 1
