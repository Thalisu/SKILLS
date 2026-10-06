#!/usr/bin/env bash
# setup-playbook.sh: what `/do` has the session do on a Setup ticket. The router reads the Ticket's
# kind through ticket-kind.sh before its table, and a row above the `ticket` row sends a Ticket that
# reads kind=setup, with no ambiguous= line, to the `setup` Playbook; any other kind still routes to
# `ticket`. The `setup` Playbook's reply opens on `Playbook: setup`; under `--auto` it refuses in
# one line naming the plain `/do` on the Ticket, before the door and the claim, so nothing is claimed
# or written; otherwise its door runs setup-door.sh, it
# claims the Ticket in the main checkout on `start` (never committed, and never again on `resume`)
# and runs the setup check, with no worktree created, no Planner or Builder forked and no review
# called. A check that cannot run (exit 2, or no script at its path) ends the run on one message,
# `Playbook: setup` then the check's own error line, with no step shown and the Ticket left claimed
# for a later `/do` to resume.
# Its reference links no other Playbook's, since a matched Playbook's links are all read.
# Its steps are a table of six rows in the order the developer runs them, each naming the line that
# proves it, where it runs and its command; with a step missing, the message marks every step done
# or missing, shows the first missing one with a `Run:` and a `Where:` line and "Say when it is
# done.", and the turn ends there, which SKILL.md's `## Where a turn ends` names as a place a turn
# ends. With the check exiting 0 and the reload done, no step is shown: the close ticks the criteria,
# appends the Context, Forks and check lines with reload=done under the Ticket's Evidence, sets it
# resolved uncommitted, and the Reply's last line is read off completion-check.sh's next= line.
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

echo "# setup.md / ## Door: under --auto the run refuses in one line naming the plain /do, before the door and the claim"
before "the --auto refusal comes before the door script runs" "--auto" "bash <skill-dir>/scripts/setup-door.sh"
flat="$(paragraph_with <(passage_of "$setup" "## Door" "## " 2>/dev/null) "--auto" all | tr '\n' ' ' | tr -s ' ')"
expect "the Door states what --auto does on a Setup ticket" test -n "${flat// /}"
carries_any "the refusal is one line" "one line" "One line" "a single line" "one-line" "a line of its own"
carries_any "and the run stops on it" "stops" "Stop" "stop" "ends the run" "ends the turn"
carries_any "the line names the plain /do command on the Ticket's path" "/do <the Ticket's path>" "/do <path>"
# shellcheck disable=SC2034 # absent() reads $out.
out="$flat"
absent "the command it names carries no --auto after the path" "path> --auto"
absent "the command it names carries no --auto before the path" "/do --auto"
carries_each "nothing is claimed and nothing is written" \
  "claims nothing" "nothing is claimed" "Nothing is claimed" "no claim" "No claim" "without claiming" \
  "before any claim" "before the claim" "never claims" "not claimed" "status unchanged" \
  "status is unchanged" "status stays" "**Status:** unchanged" -- \
  "writes nothing" "nothing is written" "Nothing is written" "without writing" "never writes" \
  "no write" "No write" "nothing written"

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

echo "# setup.md / ## The check: a check that cannot run ends the run on one message with its own error line, the Ticket still claimed"
carries_each "exit 2, and no script at its path, mean the check could not run" \
  "exit 2" "exits 2" "exit code 2" "exit status 2" "exits with 2" "\`2\`" -- \
  "not found" "no script at" "no file at" "does not exist" "missing script" \
  "script is absent" "cannot be found" "can't be found" "is not there"
carries_any "the run ends there" \
  "ends the run" "the run ends" "run stops" "the run stops" "ends the turn" "turn ends" "stop there" \
  "stops there" "Stop there" "Stop:"
carries_any "on one message" \
  "one message" "a single message" "one reply" "a single reply" "the only message" "only that message"
at="$(awk -v s="$flat" -v k="Playbook: setup" 'BEGIN { print index(s, k) }')"
expect "the message opens on Playbook: setup" test "$at" -gt 0
whole="$flat"
flat="${whole:$at}"
carries_each "then carries the check's own error line: its stderr line, or the path the script was not found at" \
  "stderr" "standard error" "error line" "error output" -- \
  "the path" "its path" "<path" "script's path" "path it was not found" "path the script"
flat="$whole"
carries_any "no step is shown" \
  "no step is shown" "No step is shown" "shows no step" "no step shown" "without showing a step" \
  "never shows a step" "no step message" "not shown" "is shown no step" "no step line"
carries_any "the Ticket stays claimed" \
  "stays \`claimed\`" "stays claimed" "remains \`claimed\`" "remains claimed" "left \`claimed\`" \
  "left claimed" "still reads \`claimed\`" "still reads claimed" "still \`claimed\`" "still claimed" \
  "keeps its claim" "keeps \`claimed\`" "keeps the claim" "claim stays" "claim is kept"
carries_any "so a later /do resumes it" "resume" "Resume"

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

# The six steps, each as a fixed string its row and its line in the message carry, in the order the
# developer runs them, then the line that proves each row done.
step_names=("nstall" "eload" "context" "design system" "build path" "ommit")
step_proofs=("impeccable-skill=done" "impeccable" "product-context=done" "design-system=done" "build-path=done" "setup-committed=done")

echo "# setup.md / ## The steps: six rows in order, each with its proof, its place and its command"
steps="$(passage_of "$setup" "## The steps" "## " 2>/dev/null)"
# The header is the first `| ` row; the separator row has no space after its first pipe.
mapfile -t step_rows < <(grep -E '^\| ' <<<"$steps" | tail -n +2)
expect "the table has six step rows" test "${#step_rows[@]}" -eq 6
for i in 0 1 2 3 4 5; do
  flat="${step_rows[$i]:-}"
  carries "row $((i + 1)) is the step named for '${step_names[$i]}', proven by ${step_proofs[$i]}" \
    "${step_names[$i]}" "${step_proofs[$i]}"
  carries_any "row $((i + 1)) says where the step runs" "terminal" "this session" "new agent session"
done
flat="${step_rows[1]:-}"
carries_any "the reload is proven by the session's own skill listing naming impeccable" \
  "skill listing" "skills listing" "listing of skills" "skill list" "skills list" "available skills" \
  "lists the skills" "lists \`impeccable\`" "lists impeccable" "listed skills" "skills it lists"
flat="${step_rows[5]:-}"
carries "the commit row's command adds and commits the files the check's uncommitted= line names" \
  "uncommitted=" "git -C <main> add --" "git -C <main> commit"

echo "# setup.md / ## The message: every step done or missing, then the first missing one, and the turn ends"
message="$(passage_of "$setup" "## The message" "## " 2>/dev/null)"
flat="$(tr '\n' ' ' <<<"$message" | tr -s ' ')"
carries "each step is marked done or missing" "done" "missing"
# The six steps in order: either the message's own lines name them in that order, or its prose says
# they follow the table's order.
listed=1
at=0
for name in "${step_names[@]}"; do
  rest="${flat:$at}"
  pos="$(awk -v s="$rest" -v k="$name" 'BEGIN { print index(s, k) }')"
  if [ "$pos" -eq 0 ]; then
    listed=0
    break
  fi
  at=$((at + pos))
done
said="$(first_at "in order" "in the table's order" "in the order of the table" "table's order" \
  "in their order" "in row order" "in the order they" "in the order of the rows" "the rows' order")"
expect "the six steps are listed in order" test "$listed" = 1 -o "$said" -gt 0
carries_any "a step that reads done gets no other word" \
  "no other word" "nothing else" "nothing more" "only \`done\`" "just \`done\`" "no more than" \
  "no further word" "no detail" "no command"
carries_any "then the first step still missing, the lowest row whose proof does not read done" \
  "first missing" "first step still missing" "first one still missing" "first \`missing\`" \
  "lowest row" "first row whose" "first step whose" "first step that"
carries_any "the missing step is shown with what it is" \
  "what it is" "what the step is" "what it does" "what the step does" "what it sets up" "says what"
carries "with its exact command on a Run: line and where to run it on a Where: line" "Run:" "Where:"
carries "the message closes on the words that hand the step over" "Say when it is done."
before "the command comes before the closing words" "Run:" "Say when it is done."
before "the place comes before the closing words" "Where:" "Say when it is done."
carries_any "the turn ends on that message" \
  "ends the turn" "turn ends" "ends its turn" "end the turn" "ending the turn" "the turn stops"

echo "# SKILL.md / ## Where a turn ends: the setup Playbook's step message is a place a turn ends"
whole="$(passage_of "$skill" "## Where a turn ends" "## " | tr '\n' ' ' | tr -s ' ')"
flat="$(sed 's/\. /.\n/g' <<<"$whole" | grep -iF "setup" | tr '\n' ' ')"
expect "the section names the setup Playbook" test -n "${flat// /}"
carries_any "as the step message that ends a turn" \
  "step message" "missing step" "setup step" "first missing" "a step to run" "the step it shows" \
  "shows the developer" "step the developer"

echo "# setup.md / ## The close: every step done on the first check resolves the Ticket and hands over the next /do"
# The close may show the Ticket's evidence in a fenced block, whose own `## Evidence` line is no
# heading of setup.md, so the section is read up to the next heading outside a fence.
close="$(awk '
  $0 == "## The close" { on = 1; print; next }
  on && /^ *```/ { fence = !fence }
  on && !fence && /^## / { exit }
  on
' "$setup" 2>/dev/null)"
flat="$(tr '\n' ' ' <<<"$close" | tr -s ' ')"
expect "setup.md carries a close section" test -n "${flat// /}"
carries_any "the close runs when the check exits 0, every step line reading done" \
  "exits 0" "exit 0" "exits zero" "exit code 0" "exit status 0" "exits with 0"
carries_each "and the reload step reads done, the session's own skill listing naming impeccable" \
  "reload" "Reload" "step 2" "Step 2" -- \
  "skill listing" "skills listing" "listing of skills" "skill list" "skills list" "available skills" \
  "lists the skills" "lists \`impeccable\`" "lists impeccable" "listed skills" "skills it lists"
carries_any "then no step is shown" \
  "no step is shown" "No step is shown" "shows no step" "no step shown" "without showing a step" \
  "never shows a step" "no step message" "no message" "skips the message" "not shown"
carries_any "the Ticket is written in the main checkout" "main checkout" "\`main=\`" "main=" "<main>"
carries_any "its criteria are ticked" "tick" "Tick" "[x]"
carries "the check's lines and reload=done go under the Ticket's Evidence" "## Evidence" "reload=done"
carries_any "the evidence is the check's own lines" \
  "the check's lines" "check's five lines" "check's step lines" "check's five step lines" \
  "lines the check printed" "the check printed" "check's output" "setup-check.sh's lines" \
  "impeccable-skill=done"
carries "the Status line is set to resolved" "**Status:**" "resolved"
carries_any "nothing is committed" \
  "never committed" "not committed" "never commits" "commits nothing" "no commit" "uncommitted" \
  "without a commit" "without committing" "is not staged" "never staged" "Nothing is committed" \
  "nothing is committed"
carries "the Evidence opens on a Context line that reads not measured, and a Forks line reading 0" \
  "Context: not measured," "Forks: 0"
flat="$(paragraph_with <(printf '%s\n' "$close") "Forks: 0" | tr -s ' ')"
before "the Context line comes first" "Context:" "Forks: 0"
before "the Forks line comes ahead of the check's lines" "Forks: 0" "reload=done"
flat="$(tr '\n' ' ' <<<"$close" | tr -s ' ')"
carries "after the close the run reads the frontier with completion-check.sh and takes its next= line" \
  "bash <skill-dir>/scripts/completion-check.sh" "next="
before "the frontier is read after the Ticket reads resolved" \
  "resolved" "bash <skill-dir>/scripts/completion-check.sh"
carries "the Reply names the setup Playbook" "Playbook: setup"
carries_any "it says every step read done on the first check" "first check" "first run of the check"
carries_any "its last line is the plain /do on the path next= names" \
  "/do <path>" "/do <that path>" "/do <the path" "/do <next"
carries_any "as the Reply's last line" \
  "last line" "Last line" "final line" "closes on" "ends on" "closing line"
# shellcheck disable=SC2034 # absent() reads $out.
out="$flat"
absent "the /do it names carries no flag before the path" "/do --"
expect "the /do it names carries no flag after the path" \
  bash -c '! grep -qE "/do <[^>]*> --" <<<"$1"' _ "$flat"
whole="$flat"
for value in wait none ambiguous; do
  flat="$(sed 's/\. /.\n/g' <<<"$whole" | grep -F -e "next=$value" -e "\`$value\`" | tr '\n' ' ')"
  expect "the close names next=$value" test -n "${flat// /}"
  case "$value" in
    wait) carries_any "next=wait: every open Ticket is held by another run" \
      "another run" "other runs" "held" "claimed" ;;
    none) carries_any "next=none: nothing else in the Spec is open" \
      "nothing else" "Nothing else" "no other" "No other" "nothing is open" "nothing open" \
      "none open" "nothing left" ;;
    ambiguous) carries_any "next=ambiguous: an open Ticket's status cannot be read" \
      "cannot be read" "can't be read" "unreadable" "could not be read" "not be read" ;;
  esac
done

[ "$fails" -eq 0 ] && exit 0
exit 1
