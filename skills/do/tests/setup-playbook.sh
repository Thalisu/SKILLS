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
# After a step message, anything the developer writes makes the run run the check and read the skill
# listing again, taking nothing on their word, and with that step done the next missing one is
# written in the message's shape, the steps already done getting their done mark and no line more.
# With that step still missing, the message quotes the check's own missing line for it (and the
# uncommitted= line with its files at the commit step), shows the same command again, and the Ticket
# stays claimed with nothing else written to it.
# A message that is a question and not word that the step is done is answered first, the check runs
# anyway in that same turn, the question never reads as "done", and the current step is shown again
# in full, with its command, after the answer.
# A later `/do` on a Setup ticket left claimed, in the session that showed the step or in a new one,
# carries nothing over from the earlier turn: it writes no second claim, runs the check, and shows
# the first step that check reads missing, every step done since skipped.
# At the reload step the message tells the developer to reload the coding tool and then to type the
# plain `/do` line on the Ticket again, says why (a session lists the skills it loaded when it
# started, so waiting in this one proves nothing), and closes on that `/do` line in place of "Say
# when it is done.".
# The reload has no line in the check, so every run, a resumed one included, reads its own session's
# skill listing for it: a listing that names impeccable reads the reload done and the next missing
# step is shown, and one that does not reads it missing, a resumed run showing the reload step again
# with a line saying the skill is still not listed in this session.
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

echo "# setup.md / ## The re-check: any developer message re-runs the check, and the next missing step is shown in the same shape"
flat="$(passage_of "$setup" "## The re-check" "## " 2>/dev/null | tr '\n' ' ' | tr -s ' ')"
expect "setup.md says what the run does when the developer answers a step message" test -n "${flat// /}"
carries_any "anything the developer writes after a step message starts it, whatever the words" \
  "anything" "Anything" "any message" "Any message" "any reply" "Any reply" "any answer" "Any answer" \
  "whatever the developer" "Whatever the developer" "whatever they write" "whatever it says" \
  "every message" "Every message" "any word" "any developer message" "no matter what"
carries "the run runs setup-check.sh" "bash <skill-dir>/../../.agents/scripts/setup-check.sh"
carries_any "and it is a run of the check made again, not the earlier output read back" \
  "again" "Again" "re-run" "Re-run" "rerun" "re-runs" "reruns" "a second time" "once more" "anew" \
  "afresh" "a fresh run"
carries_each "the session's own skill listing is read again" \
  "skill listing" "skills listing" "listing of skills" "skill list" "skills list" "available skills" \
  "lists the skills" "lists \`impeccable\`" "lists impeccable" "listed skills" "skills it lists" -- \
  "again" "Again" "re-read" "Re-read" "reread" "re-reads" "rereads" "a second time" "once more" \
  "anew" "afresh"
carries_any "nothing is taken on the developer's word" \
  "on the developer's word" "on their word" "the developer's word" "their word" "word for it" \
  "on the developer's say" "on their say-so" "say-so" "never trusts" "does not trust" "not trusted" \
  "never trusted" "is no proof" "is not proof" "proves nothing" "never believes" "not believed" \
  "whatever the developer claims" "the claim that it is done"
carries_any "with the shown step now done, the next missing step is the one written" \
  "next missing" "next step still missing" "next one still missing" "next \`missing\`" \
  "first missing" "first step still missing" "first one still missing" "first \`missing\`" \
  "lowest row" "next row whose" "next step whose" "next step that" "first row whose" \
  "first step whose" "first step that"
carries_any "in the shape of the step message" \
  "## The message" "The message" "same shape" "same message" "same form" "same format" \
  "shape of the message" "shape of the step message" "the message's shape" "the step message's shape"
carries_any "a step already done gets its done mark and no line more" \
  "no other word" "nothing else" "nothing more" "only \`done\`" "just \`done\`" "no more than" \
  "no further word" "no further line" "no other line" "no line about" "no line more" "no line on" \
  "no detail" "no recap" "no summary" "never recaps" "never confirms" "no confirmation" \
  "not confirmed" "without a line about" "beyond its \`done\`" "beyond their \`done\`" \
  "beyond the \`done\`" "beyond its done mark" "beyond their done mark" "past its \`done\`" \
  "past their \`done\`"

echo "# setup.md / ## The re-check: a shown step still missing gets the check's own missing line and the same command again, the Ticket still claimed"
recheck="$(passage_of "$setup" "## The re-check" "## " 2>/dev/null)"
# The message quotes a `<name>=missing` line, so the paragraphs carrying one are where the section
# rules the step that did not take; the paragraph on a step now done names no such line.
flat="$(paragraph_with <(printf '%s\n' "$recheck") "=missing" all | tr '\n' ' ' | tr -s ' ')"
expect "the re-check rules the shown step that still reads missing, naming its <name>=missing line" \
  test -n "${flat// /}"
carries_any "the case is the step the run showed still reading missing after the re-check" \
  "still reads missing" "still reads \`missing\`" "still missing" "still \`missing\`" "reads missing again" \
  "reads \`missing\` again" "did not take" "has not taken" "does not read done" "does not read \`done\`" \
  "not reading done" "not reading \`done\`" "still does not read" "missing as before"
carries_any "the message says what is missing in the check's own line, quoted" \
  "quot" "verbatim" "word for word" "check's own line" "check's own \`" "check's line" "own line for" \
  "line the check printed" "as the check printed" "as the check prints" "the check printed" \
  "copies the" "copied from the check" "line of the check"
whole="$(tr '\n' ' ' <<<"$recheck" | tr -s ' ')"
flat="$(sed 's/\. /.\n/g' <<<"$whole" | grep -F "uncommitted=" | tr '\n' ' ')"
expect "the re-check names the check's uncommitted= line" test -n "${flat// /}"
carries_any "at the commit step" "ommit step" "ommit row" "step 6" "Step 6" "sixth step" "last step" "setup-committed"
carries_any "the uncommitted= line is quoted with the files it names" "file"
flat="$whole"
carries_any "then the same step is shown with the same command again" \
  "same command" "same \`Run:\`" "same Run:" "the command again" "its command again" "that command again" \
  "command once more" "command unchanged" "identical command" "command it showed" "command it already showed"
carries_any "the Ticket's Status line still reads claimed" \
  "stays \`claimed\`" "stays claimed" "remains \`claimed\`" "remains claimed" "left \`claimed\`" \
  "left claimed" "still reads \`claimed\`" "still reads claimed" "still \`claimed\`" "still claimed" \
  "keeps its claim" "keeps \`claimed\`" "keeps the claim" "claim stays" "claim is kept"
flat="$(sed 's/\. /.\n/g' <<<"$whole" | grep -F "Ticket" | tr '\n' ' ')"
carries_any "and nothing else is written to the Ticket file" \
  "nothing else" "Nothing else" "nothing more" "writes nothing" "nothing is written" "Nothing is written" \
  "nothing written" "no other edit" "no other change" "no other write" "not written" "never written" \
  "is not touched" "untouched" "otherwise unchanged" "without writing" "never writes" "no write"

echo "# setup.md / ## Door: a /do on a Setup ticket left claimed runs the check, writes no second claim and shows the first step that check reads missing"
# The verdict table is one paragraph whose lines open on a pipe, and its `resume` cell says only
# that the run goes on to the check: the prose outside it is what rules a resume.
flat="$(paragraph_with <(passage_of "$setup" "## Door" "## " 2>/dev/null) "resume" all | grep -v '^|' | tr '\n' ' ' | tr -s ' ')"
expect "the Door rules the resume verdict in prose outside its table" test -n "${flat// /}"
carries_each "a resume is any later /do on a Setup ticket left claimed" \
  "later \`/do\`" "later /do" "next \`/do\`" "next /do" "another \`/do\`" "another /do" "any \`/do\`" \
  "any /do" "every \`/do\`" "every /do" "\`/do\` again" "/do again" "second \`/do\`" "second /do" \
  "comes back" "returns to" -- \
  "left \`claimed\`" "left claimed" "reads \`claimed\`" "reads claimed" "still \`claimed\`" \
  "still claimed" "stays \`claimed\`" "stays claimed" "already \`claimed\`" "already claimed" \
  "status=claimed"
carries_each "in the session that showed the step or in a new one" \
  "same session" "this session" "session that showed" "session that claimed" "session it left" \
  "the earlier session" "one session" -- \
  "new session" "a new one" "another session" "fresh session" "later session" "different session" \
  "new agent session" "another one"
carries_any "the run carries nothing over from the earlier turn" \
  "carries nothing" "Nothing is carried" "nothing is carried" "nothing carried" "carried over" \
  "carries over nothing" "remembers nothing" "nothing is remembered" "no memory of" \
  "nothing from the earlier turn" "nothing from an earlier turn" "nothing of the earlier turn" \
  "not the step it showed" "neither the step it showed" "no step it showed" "starts from nothing" \
  "reads nothing back" "keeps nothing"
carries_any "it writes no second claim" \
  "no second claim" "No second claim" "claims nothing" "nothing is claimed" "Nothing is claimed" \
  "not claimed again" "never claimed again" "no claim" "No claim" "is not claimed" "skips the claim" \
  "without claiming" "not claim it again" "never claims it again" "claim is not made" \
  "claim is never made" "not set again" "never set again" "claim is not written again" \
  "claim is never written again"
carries_any "it runs the check" \
  "runs the check" "run the check" "the check runs" "the check is run" "goes on to the check" \
  "goes straight to the check" "straight to the check" "setup-check.sh" "## The check"
carries_any "the step it shows is the first one this check reads missing" \
  "first missing" "first step still missing" "first one still missing" "first \`missing\`" \
  "first one this check reads missing" "first step this check reads missing" \
  "first one that check reads missing" "first step that check reads missing" \
  "first one the check reads missing" "first step the check reads missing" \
  "first one it reads missing" "first step it reads missing" "lowest row" "first row whose" \
  "first step whose" "first step that" "first one that"
carries_any "so every step done since is skipped" \
  "skip" "Skip" "passed over" "passes over" "not shown again" "never shown again" "never the first step again" \
  "not the first step again" "is not repeated" "never repeated" "not asked again" "never asked again"

echo "# setup.md / ## The re-check: a question is answered, the check runs in the same turn, and the current step is shown again in full"
# Only the paragraphs naming a question rule this case: the section's other paragraphs say "again",
# "in full" and "command" for a step that did not take, and must not answer for it.
flat="$(paragraph_with <(passage_of "$setup" "## The re-check" "## " 2>/dev/null) "uestion" all | tr '\n' ' ' | tr -s ' ')"
expect "the re-check rules a developer message that is a question" test -n "${flat// /}"
carries_any "the case is a question in place of word that the step is done" \
  "not word that" "rather than word that" "instead of word that" "instead of saying" "rather than saying" \
  "not a claim" "not saying" "not that the step is done" "not that it is done" "and not \"done\"" \
  "instead of \"done\"" "rather than \"done\"" "without saying" "asks instead" "asks rather than" \
  "does not say it is done" "does not say the step is done" "says nothing of the step being done"
carries_any "the run answers the question" "answer" "Answer"
carries_each "the check runs anyway, in that same turn" \
  "anyway" "still runs" "runs all the same" "all the same" "regardless" "either way" "even so" \
  "runs as well" "runs too" "runs the check too" "still run" "nonetheless" "no less" \
  "like any other message" "as for any other message" "as with any other message" -- \
  "same turn" "that turn" "this turn" "the turn" "one turn" "single turn" "same reply" "same message" \
  "one message" "one reply"
carries_any "a question is never read as done" \
  "never read as" "not read as" "never reads as" "does not read as" "never taken as" "not taken as" \
  "never counts as" "does not count as" "never treated as" "not treated as" "never means" \
  "does not mean" "is not \"done\"" "is no \"done\"" "is never \"done\"" "is not word that" \
  "is no word that" "never stands for" "never passes for" "never mistaken for" "not mistaken for"
carries_each "the current step is shown again in full, with its command" \
  "again" "Again" "once more" "a second time" "anew" -- \
  "in full" "whole" "complete" "entire" "every line" "all its lines" "all of its lines" -- \
  "command" "Run:"
answer_at="$(first_at "answer" "Answer")"
full_at="$(first_at "in full" "whole" "complete" "entire" "every line" "all its lines" "all of its lines")"
said="$(first_at "after the answer" "below the answer" "under the answer" "following the answer" \
  "follows the answer" "after answering" "answer first" "answers first" "answers the question first" \
  "answers it first" "first answers" "answer comes first" "answer goes first" "answer opens" \
  "opens on the answer" "opens with the answer" "ahead of the step" "before the step" "above the step")"
expect "the step comes after the answer" test "$said" -gt 0 -o \( "$answer_at" -gt 0 -a "$full_at" -gt "$answer_at" \)

echo "# setup.md / ## The message: at the reload step the message says to reload the coding tool and type the plain /do line again"
# The sample message carries its own `2. Reload the coding tool: done` line inside a fence, so the
# fenced blocks are dropped, and each bullet is read as a paragraph of its own: only the prose that
# names the reload rules this step, and the bullets ruling every step alike must not answer for it.
flat="$(paragraph_with <(passage_of "$setup" "## The message" "## " 2>/dev/null | awk '
  /^ *```/ { fence = !fence; next }
  fence { next }
  /^ *- / { print "" }
  { print }
') "eload" all | tr '\n' ' ' | tr -s ' ')"
expect "the message section rules the reload step in prose outside its sample" test -n "${flat// /}"
carries_any "the message tells the developer to reload the coding tool" \
  "reload the coding tool" "reloads the coding tool" "reload it" "reload the tool" "reload the session" \
  "reload this session" "quit the coding tool" "restart the coding tool" "to reload"
carries_each "and to type the /do line on the Setup ticket again" \
  "/do <path>" "/do <the Ticket's path>" -- \
  "again" "Again" "once more" "a second time" "anew"
carries_any "the /do line is typed after the reload" \
  "then" "after the reload" "after reloading" "after it is reloaded" "once reloaded" \
  "once it is reloaded" "once the coding tool is reloaded" "after a reload" "following the reload"
carries_any "the /do line is plain" \
  "plain" "no flag" "without a flag" "without any flag" "with no flag" "flagless" "no \`--auto\`"
# shellcheck disable=SC2034 # absent() reads $out.
out="$flat"
absent "the /do it names carries no flag before the path" "/do --"
expect "the /do it names carries no flag after the path" \
  bash -c '! grep -qE "/do <[^>]*> --" <<<"$1"' _ "$flat"
carries_any "why: a session lists the skills it loaded when it started" \
  "when it started" "when it starts" "when the session started" "when it was started" "at its start" \
  "at startup" "at start-up" "on startup" "as it started" "the moment it started" "loaded at start"
carries_each "so this session cannot list impeccable until it is reloaded" \
  "impeccable" -- \
  "until it is reloaded" "until the reload" "until a reload" "until reloaded" "before the reload" \
  "before it is reloaded" "only after a reload" "only after the reload" "without a reload" \
  "unless it is reloaded" "until the coding tool is reloaded" "only once it is reloaded" \
  "only once reloaded"
carries_any "and waiting in it proves nothing" \
  "proves nothing" "prove nothing" "proves no step" "can prove nothing" "would prove nothing" \
  "never proves" "cannot prove" "can never prove" "no use waiting" "nothing to wait for" \
  "waiting changes nothing" "waiting is no use"
carries_each "the reload message closes on the /do line in place of the words that hand a step over" \
  "closes on" "closes with" "last line" "final line" "closing line" "ends on" "ends with" \
  "ends its message on" -- \
  "Say when it is done." -- \
  "in place of" "instead of" "rather than" "replaces" "replacing" "and not on" "and never on" \
  "not on \"Say" "never on \"Say" "takes the place of" "where the other steps"

echo "# setup.md / ## The check: a resumed run reads its own skill listing for the reload, done when it names impeccable and shown again when it does not"
# Only the paragraphs naming the listing rule the reload proof: the fenced blocks are dropped and
# each bullet is read as a paragraph of its own, so the exit-code bullet for 0, which names the
# reload and no listing, must not answer for it.
flat="$(paragraph_with <(passage_of "$setup" "## The check" "## " 2>/dev/null | awk '
  /^ *```/ { fence = !fence; next }
  fence { next }
  /^ *- / { print "" }
  { print }
') "list" all | tr '\n' ' ' | tr -s ' ')"
expect "the check section rules the reload proof in prose naming the skill listing" test -n "${flat// /}"
carries_any "the proof is the session's skill listing" \
  "skill listing" "skills listing" "listing of skills" "skill list" "skills list" "available skills" \
  "lists the skills" "lists \`impeccable\`" "lists impeccable" "listed skills" "skills it lists"
carries_each "the reload is the step the check has no line for" \
  "reload" "Reload" "step 2" "Step 2" -- \
  "no line" "No line" "none of its lines" "none of the lines" "no script reads" "no step line" \
  "not one of its lines" "not among its lines" "not a line of" "never prints" "does not print" \
  "nothing for the reload"
carries_each "every run, a resumed one included, reads the listing of its own session" \
  "every run" "Every run" "each run" "Each run" "any run" "every \`/do\`" "every /do" "each \`/do\`" \
  "whichever run" "a first run and a resumed" "a first run or a resumed" "the first run and a resumed" \
  "first or resumed" "start or resume" "\`start\` or \`resume\`" "\`start\` and \`resume\`" -- \
  "resum" "Resum" -- \
  "its own" "own session" "session's own" "this session" "the session it runs in" "the session it is in"
carries_each "a listing that names impeccable, or a skill under impeccable:, reads the reload step done" \
  "\`impeccable\`" -- \
  "\`impeccable:\`" "impeccable:" -- \
  "reads done" "reads \`done\`" "read done" "read \`done\`" "is done" "is \`done\`" "as done" \
  "as \`done\`" "step done" "marked done" "marked \`done\`" "counts done" "is proven" "is proved" \
  "proves the reload" "proves the step" "proves it"
carries_any "and the step shown is then the next missing one" \
  "next missing" "next step still missing" "next one still missing" "next \`missing\`" \
  "next step that" "next step whose" "next row whose" "next one that"
carries_each "a listing that does not name it reads the reload step missing" \
  "does not name" "does not list" "names neither" "lists neither" "names no" "lists no" "not listed" \
  "not named" "is not in the listing" "is absent" "no such skill" "without it" "unlisted" -- \
  "reads missing" "reads \`missing\`" "read missing" "read \`missing\`" "is missing" "is \`missing\`" \
  "as missing" "as \`missing\`" "step missing" "marked missing" "marked \`missing\`" "counts missing"
carries_each "and on a resumed run the reload step is shown again" \
  "resum" "Resum" -- \
  "shown again" "shows it again" "shows the reload step again" "shows the step again" \
  "shows the reload again" "shows that step again" "again in full" "is written again" \
  "writes it again" "shown once more" "shown a second time" "repeats the reload" "repeats the step"
carries_each "with a line saying the skill is still not listed in this session" \
  "still not listed" "still does not list" "still lists no" "still unlisted" "still not named" \
  "still does not name" "still names no" "still missing from" "still not in the listing" \
  "still absent" "is still not" -- \
  "this session" "the session" "its session" "that session"

[ "$fails" -eq 0 ] && exit 0
exit 1
