#!/usr/bin/env bash
# judgment-step.sh: what SKILL.md has the session do after the door's `Judging <n> debt items of
# <folder>` line: fork one debt-evaluator per item in one message, wait on every return file with the
# shared returns.sh, then write the Debt review through debt-review.sh and show its text followed by
# `Written to <location>`. The script carries every verdict (tests/debt-review.sh), so these cases
# pin only the calls the step makes, their order, and that the session leaves the Buckets to it.
# Run: bash skills/debt/tests/judgment-step.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
skill="$here/../SKILL.md"
fails=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# The mirror of lib.sh's affirms: one clause of $flat carries a match of every group and a negator
# word, so "never ends the turn" answers and "ends the turn" alone does not. Clauses are cut at a
# sentence end or a semicolon only, since a brief key (`Item:`) carries a colon of its own.
denies() { # $1 label, $2.. groups of fixed strings separated by `--`: one clause of $flat carries a match of every group and a negator word
  local label="$1" groups
  shift
  groups="$(printf '%s\n' "$@")"
  if groups="$groups" awk '
    BEGIN {
      n = split(ENVIRON["groups"], line, "\n"); g = 1
      for (i = 1; i <= n; i++) {
        if (line[i] == "--") { g++; continue }
        c[g]++; phrase[g, c[g]] = line[i]
      }
      ng = g
    }
    {
      m = split($0, clause, /\. |; /)
      for (j = 1; j <= m; j++) {
        text = clause[j]; good = 1
        for (g = 1; g <= ng && good; g++) {
          hit = 0
          for (k = 1; k <= c[g]; k++) if (index(text, phrase[g, k])) hit = 1
          if (!hit) good = 0
        }
        if (good && (" " text " ") ~ /[^a-z](never|not|no|nothing|none|neither|nor|cannot|without)[^a-z]|n'"'"'t[^a-z]/) found = 1
      }
    }
    END { exit !found }
  ' <<<"$flat"; then ok "$label"; else fail "$label (no clause denies: $*)"; fi
}

no_fork=(
  "forks no agent" "fork no agent" "forking no agent" "no agent is forked" "no agent forked"
  "without forking" "never forks" "forks nothing" "fork nothing" "forking nothing" "no fork"
)
fork_call="subagent_type: debt-evaluator"
wait_call="bash <skill-dir>/../../.agents/scripts/returns.sh 240"
compose_call="bash <skill-dir>/scripts/debt-review.sh <slug> <dir>"

echo "# SKILL.md: the judgment step follows the door"
flat="$(flat_section "$skill" "## 2.")"
expect "SKILL.md carries a second step after the door" test -n "${flat// /}"

echo "# the run's directory, and one debt-evaluator per item, all in one message"
carries "the run's returns directory is made with mktemp -d" "mktemp -d"
carries "each fork is the debt-evaluator agent, named as the Agent tool's subagent_type" "$fork_call"
carries_any "one Agent tool call is made per item= record" \
  "per \`item=\` record" "each \`item=\` record" "every \`item=\` record" \
  "per item= record" "each item= record" "every item= record"
carries_any "every fork goes out in one message" \
  "in one message" "in a single message" "all in one message" "one message"
denies "the step never forks a general-purpose agent in the evaluator's place" "general-purpose"
before "the directory is made before the evaluators are forked" "mktemp -d" "$fork_call"

echo "# each brief carries the six keys, and its own return file"
carries "the brief carries the six keys" \
  "Item:" "Source:" "Text:" "Folder:" "Spec:" "Return file:"
carries "each item's return file is item-<k>.md in the run's directory" "<dir>/item-<k>.md"

echo "# the wait: the turn is not ended on the Agent tool's handback"
denies "the session does not end the turn when the Agent tool hands back" \
  "end the turn" "ends the turn" "ending the turn" "end its turn" "ends its turn"
carries "the wait runs the shared returns.sh on the return files, a 240-second window" "$wait_call"
carries "the Bash tool's timeout is set to 600000" "timeout" "600000"
carries "the wait is called again on what it reports missing" "missing="
carries_any "the next window waits on the missing= files only" \
  "the \`missing=\` files only" "only the \`missing=\` files" "only over the \`missing=\`" \
  "the missing= files only" "only the missing= files" "only over the missing="
carries_any "the wait runs three windows and no more" "three windows"
before "the evaluators are forked before the wait" "$fork_call" "$wait_call"

echo "# the Agent tool withheld, or listing no debt-evaluator: nothing forked, straight to compose"
passage_of "$skill" "## 2." "<arguments>" >"$tmp/step.md"
fallback=""
for key in "withheld" "lists no \`debt-evaluator\`" "not listing \`debt-evaluator\`" \
  "does not list \`debt-evaluator\`"; do
  fallback="$(paragraph_with "$tmp/step.md" "$key")"
  [ -n "$fallback" ] && break
done
flat="$fallback"
expect "the step names the run where the Agent tool is withheld or lists no debt-evaluator" \
  test -n "${flat// /}"
carries "that branch names debt-evaluator as the agent it cannot fork" "debt-evaluator"
carries_any "that branch forks nothing" "${no_fork[@]}"
carries_any "that branch goes on to the compose call" "debt-review.sh" "compose"

echo "# the compose call writes the Debt review, and the run ends on its text and Written to"
flat="$(flat_section "$skill" "## 2.")"
carries "the Debt review is written through debt-review.sh on the slug and the run's directory" \
  "$compose_call"
before "the wait comes before the compose call" "$wait_call" "$compose_call"
carries "the run shows the line= value, Written to <location>" "line=" "Written to <location>"
text_at="$(first_at "file's text" "review's text" "text of the Debt review" "text of the review")"
written_at="$(first_at "Written to <location>")"
expect "the run shows the Debt review file's text" test "$text_at" -gt 0
expect "the review's text comes before Written to <location>" test "$text_at" -lt "$written_at"
carries_any "those are the run's last lines" "last lines" "last line" "ends on"

echo "# the session leaves the returns and the Buckets to the script"
denies "the session never reads a return file itself" \
  "read" "open" "parse" -- "return file"
denies "the session never places an item in a Bucket itself" \
  "place" "put" "sort" "assign" -- "Bucket"

echo "# the composer's exit 5: no line= to print, straight to the fix with its review="
flat="$(exit_window 5 "$(flat_section "$skill" "## 2.")")"
expect "the step names what it does on debt-review.sh's exit 5" test -n "${flat// /}"
carries_any "exit 5 prints no line= value" \
  "no \`line=\`" "no line=" "prints nothing" "print nothing" "printing nothing" \
  "nothing is printed" "nothing to print" "without printing"
carries_any "exit 5 goes on to the fix step" "step 3" "Step 3" "the fix" "The fix"
carries "exit 5 hands on the review= value debt-review.sh printed" "review="

echo "# the shared wait the step reaches through <skill-dir>/../../.agents/scripts/"
expect "returns.sh sits at .agents/scripts/ from the repo root, where the step calls it" \
  test -f "$here/../../../.agents/scripts/returns.sh"

exit $((fails > 0))
