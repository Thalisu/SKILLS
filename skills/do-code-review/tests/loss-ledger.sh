#!/usr/bin/env bash
# loss-ledger.sh: what the orchestrator does with the Loss ledger a caller sends it, and which of
# the two reviewers reads it: the technical one, whose brief carries its location beside the
# standards sources, and never the security one.
# Run: bash skills/do-code-review/tests/loss-ledger.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
agent="$here/../AGENT.md"
tech="$here/../agents/do-code-review-technical-reviewer.md"
sec="$here/../agents/do-code-review-security-reviewer.md"
fails=0

# Which block of a section a line sits in is the contract here, since the first block is what both
# reviewers get and the second is the technical reviewer's alone. Which one comes first is shape,
# so a block is asked for by a line it carries rather than by its number.
block_holding() { # $1 file, $2 the section's heading line, $3 a fixed string one of its lines carries
  local n=1 block
  while block="$(blocks_of "$1" "$2" "" "$n")" && [ -n "$block" ]; do
    if grep -qF -- "$3" <<<"$block"; then
      printf '%s\n' "$block"
      return 0
    fi
    n=$((n + 1))
  done
  return 1
}

echo "# AGENT.md / ## The arguments: the ledger is an argument, and the technical reviewer's alone"
flat="$(flat_section "$agent" "## The arguments")"
expect "AGENT.md carries the arguments a caller may send" test -n "$flat"
carries "a caller may send the run's Loss ledger among them" "Loss ledger"
carries_any "the ledger argument is the technical reviewer's alone" \
  "technical reviewer only" "only the technical reviewer" "technical reviewer alone" \
  "only to the technical reviewer" "the technical reviewer's alone" \
  "never reaches the security reviewer" "never the security reviewer" "not the security reviewer"

echo "# AGENT.md / ## 5. The brief: the ledger line goes in the block the technical reviewer alone gets"
flat="$(block_holding "$agent" "## 5. The brief" "Standards sources:")"
expect "the brief has a block the technical reviewer alone receives" test -n "$flat"
carries "that block carries the ledger's location beside the standards sources" "Loss ledger:"
# A closed choice, a path or `none`: a reviewer reads the line the same way whatever the run set
# aside, and never has to tell an absent line from an empty one.
ledger_line="$(grep -F 'Loss ledger:' <<<"$flat")"
expect "a run that set nothing aside still sends the line, reading none" \
  grep -qF -- "none" <<<"$ledger_line"

out="$(block_holding "$agent" "## 5. The brief" "Fixed point:")"
expect "the brief has the block both reviewers receive" test -n "$out"
absent "the lines both reviewers receive carry no ledger" "Loss ledger"

echo "# AGENT.md / ## 6. The fan-out: only one of the two prompts carries the line"
tech_row="$(grep -F '| `subagent_type: do-code-review-technical-reviewer`' "$agent")"
expect "the fan-out says what the technical reviewer's prompt carries" test -n "$tech_row"
expect "the technical reviewer's prompt carries the ledger line" \
  grep -qF -- "Loss ledger" <<<"$tech_row"
out="$(grep -F '| `subagent_type: do-code-review-security-reviewer`' "$agent")"
expect "the fan-out says what the security reviewer's prompt carries" test -n "$out"
absent "the security reviewer's prompt carries no ledger line" "Loss ledger"

echo "# the reviewers' own briefs: the technical one reads the line, the security one is told it never comes"
flat="$(flat_section "$tech" "## The brief")"
expect "the technical reviewer's brief lists the lines it receives" test -n "$flat"
carries "its brief carries a row for the ledger line" "| \`Loss ledger:\` |"

flat="$(flat_section "$sec" "## The brief")"
out="$flat" # `absent` reads $out and the carries family reads $flat: both the same brief here
expect "the security reviewer's brief lists the lines it receives" test -n "$flat"
absent "its brief carries no row for the ledger line" "| \`Loss ledger"
carries "it is told of the ledger all the same" "Loss ledger"
before "the ledger is named among what never reaches it" "Loss ledger" "never reach"

exit $((fails > 0))
