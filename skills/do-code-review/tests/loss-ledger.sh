#!/usr/bin/env bash
# loss-ledger.sh: what the orchestrator does with the Loss ledger a caller sends it, which of the
# two reviewers reads it (the technical one, whose brief carries its location beside the standards
# sources, and never the security one), and what that reviewer does with it: its Spec Axis reads
# every `drop` against the spec source, and one that set aside something the spec asks for is an
# ordinary Spec Finding.
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

# The Spec Axis's own text: its row of the Axis table, plus the `### Spec` subsection the contract
# grows when the row outgrows one cell, the way Standards, Principles and Blast radius each have
# one. Stopping at a heading of any depth is what `flat_section` does not do: from `### Spec` it
# would run on through `### Standards` and the rest of the Axes.
subsection() { # $1 file, $2 the heading line; its text flattened, stopping at the next heading of any depth
  awk -v h="$2" 'index($0, h) == 1 { on = 1; next } on && /^#+ / { exit } on' "$1" | tr '\n' ' ' | tr -s ' '
}
spec_axis_text() { # everything the contract says the Spec Axis does, flattened
  {
    grep -F '| Spec |' "$tech"
    subsection "$tech" "### Spec"
  } | tr '\n' ' ' | tr -s ' '
}
# What a table enumerates, apart from what it says about each one: the first cell of every row,
# backticks stripped. The separator row has no space after its first pipe and never matches.
table_first_cells() { # $1 file, $2 the opening of the line the table follows
  awk -v a="$2" 'index($0, a) == 1 { on = 1; next } on && /^#+ / { exit } on && /^\| /' "$1" |
    sed -e 's/^| *//' -e 's/ *|.*//' -e 's/`//g'
}
five_axes="$(printf 'Correctness\nSpec\nStandards\nPrinciples\nBlast radius')"

echo "# the technical reviewer / ## Reading: it opens the ledger the brief names"
flat="$(flat_section "$tech" "## Reading")"
expect "the technical reviewer lists what it opens" test -n "$flat"
carries "the Loss ledger is one of them" "Loss ledger"
carries_any "it opens it where the brief's line points, never a ledger it went looking for" \
  "the brief" "\`Loss ledger:\`" "the path the brief" "the location the brief"
# The brief's line is a closed choice, so a run that set nothing aside sends `none` and a run whose
# ledger has moved sends a path that opens nothing. Neither is the diff's fault: the review carries
# on with the four other Axes rather than charging the developer a Finding or refusing to review.
carries_any "a run that set nothing aside sends \`none\`, and there is nothing to open" \
  "\`none\`" "reads none" "none"
carries_any "a ledger path that opens nothing is read past" \
  "does not open" "cannot open" "cannot be read" "cannot read" "is not there" "no longer there" \
  "missing" "unreadable" "opens nothing"
carries_any "neither costs the review a Finding" \
  "no Finding" "not a Finding" "never a Finding" "costs no Finding" "raises no Finding" \
  "is no Finding"
carries_any "and neither is a reason to refuse the review" \
  "no refusal" "never refuse" "do not refuse" "never a refusal" "not a refusal" "refuse nothing" \
  "carry on" "review all the same" "the review goes on"

echo "# the technical reviewer / the Spec Axis: it reads every \`drop\` against the spec source"
flat="$(spec_axis_text)"
expect "the contract says what the Spec Axis does" test -n "$flat"
carries "the Spec Axis is the Axis that reads the ledger" "ledger"
# The two verdicts the judge writes are the ledger's own words, so the contract uses them as they
# are written there: a `reapply` is already back in the tree and nothing is lost by it, and only a
# `drop` left something out of the branch for good.
carries "it keeps the entries whose verdict is \`drop\`" "drop"
carries "it reads each one against the spec source" "spec source"
carries "and it reads past an entry judged \`reapply\`" "reapply"
carries_any "a \`reapply\` came back and is nothing for this Axis to answer" \
  "brought back" "came back" "is back" "already back" "no Finding" "not a Finding" "reads past" \
  "read past" "skip" "only the \`drop\`" "only entries" "only those"
carries_any "a \`drop\` that set aside something the Ticket or its Spec asks for is a Finding on this Axis" \
  "is a Finding" "a Spec Finding" "a Finding on this Axis" "a Finding here" "becomes a Finding" \
  "an ordinary Spec Finding"
# The Incoming side is a side of someone else's diff, quoted in the ledger. Pasting it into the
# Review hands the reader the set-aside text as if it were the reviewer's own claim, and a Review
# is read by a Fixer that edits code: the Finding points at the entry and lets the ledger hold it.
carries_any "the Finding points at the ledger entry" \
  "the entry" "its id" "the hunk id" "the entry's id" "by its id"
carries_any "and never copies the set-aside Incoming side into the Review" \
  "never the Incoming" "not the Incoming" "rather than the Incoming" "never pastes" \
  "never paste" "never copies" "never copy" "never quotes" "without pasting" "without copying"

echo "# the technical reviewer: a dropped requirement opens no sixth Axis and no fifth Bucket"
out="$(table_first_cells "$tech" "## The five Axes" | grep -vx 'Axis')"
same "the Axes stay the five the return has a line for" "$five_axes"
out="$(table_first_cells "$tech" "The Bucket follows the evidence" | grep -vx 'Bucket')"
same "the Buckets stay the four the Review format fixes" "$(printf 'Act on\nConsider\nNoted\nCleared')"

echo "# the technical reviewer / ## The return: the Spec Axis line says what it read from the ledger"
block="$(blocks_of "$tech" "## The return")"
expect "the section carries the return's template" test -n "$block"
out="$(sed -n 's/^- \([A-Z][^:]*\):.*/\1/p' <<<"$block")"
same "the template still has one line per Axis and no line for a sixth" "$five_axes"
flat="$(grep -F -- '- Spec:' <<<"$block")"
expect "the template has a line for the Spec Axis" test -n "$flat"
carries_any "that line says what the Axis read from the ledger" "ledger" "drop"
carries "and it still reads \`no spec\` when the run has no spec source" "no spec"

echo "# AGENT.md: a \`fix\` call forks no reviewer, so a ledger sent with it goes nowhere"
fix="$here/../references/fix.md"
# The paragraph that opens on the \`fix\` call, the only place the contract says what that call runs.
flat="$(awk -v RS= 'index($0, "A `fix` call") == 1' "$agent" | tr '\n' ' ' | tr -s ' ')"
expect "AGENT.md says what a \`fix\` call runs" test -n "$flat"
carries "the whole run is fix.md" "fix.md"
carries_any "it forks no reviewer" \
  "forks no reviewer" "no reviewer is forked" "never forks a reviewer" "reviews nothing"
flat="$(grep -E '^\| [^|]*Loss ledger' "$agent")"
expect "the ledger has its own row among the arguments" test -n "$flat"
carries_any "a \`fix\` call ignores the ledger sent with it" \
  "a \`fix\` call ignores it" "the \`fix\` call ignores it" "a \`fix\` call never reads it"
carries_any "and reads nothing at that path" \
  "reading nothing at that path" "reads nothing at that path" "nothing is read at that path" \
  "never opens that path"
# One home for the rule: were fix.md to say what it does with a ledger too, the two could part ways.
expect "fix.md is there to be read" test -s "$fix"
out="$(cat "$fix")"
absent "fix.md carries no ledger rule of its own" "Loss ledger"

exit $((fails > 0))
