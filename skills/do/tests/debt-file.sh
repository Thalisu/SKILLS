#!/usr/bin/env bash
# debt-file.sh: a run on a Ticket leaves the Reply's Pending debt part in the Debt file beside the
# Ticket (its file name with `.debt` before the extension), with or without `--auto`, one section
# per run headed by the run's date and time and holding that part verbatim.
#
# The developer and the debt skill that judges a feature's debt read the items a run named there:
# a run without `--auto` writes no Run report, so without the Debt file every item it named is gone
# once its session closes.
#
# Everything is found by what it says, never by a line number, and read flattened, since the
# references hard-wrap.
# Run: bash skills/do/tests/debt-file.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
reply="$here/../references/reply.md"
ticket="$here/../references/ticket.md"
fails=0

# Every paragraph of a passage that names the Debt file, flattened onto one line.
debt_file_paragraphs() { # stdin: a passage; stdout: its paragraphs naming the Debt file, on one line
  awk 'BEGIN { RS = "" } { gsub(/\n/, " ") } index(tolower($0), "debt file") { print }' |
    tr '\n' ' ' | tr -s ' '
}

echo "# every run on a Ticket writes its Pending debt to the Debt file beside the Ticket"

flat="$(passage_of "$reply" "## The message" "## " | debt_file_paragraphs)"
expect "reply.md's The message names the Debt file" test -n "$flat"
carries_any "the Debt file is written on every run, not only under --auto" \
  "every run" "each run" "with or without \`--auto\`" "whether or not" "not only under \`--auto\`" \
  "with \`--auto\` or without" "without \`--auto\` too" "also without \`--auto\`"
carries_each "the Debt file sits beside the Ticket, its file name with .debt before the extension" \
  "beside the Ticket" "next to the Ticket" "beside a Ticket" "Ticket's own folder" -- \
  ".debt"
carries_each "the Debt file holds the Pending debt part and nothing else of the Reply" \
  "Pending debt" -- \
  "nothing else" "no other part" "only the Pending debt" "and no other" "alone"
carries_each "each run's section is headed by the run's date and time" \
  "date and time" "timestamp" "date-time" "datetime" -- \
  "headed" "heading" "under a" "opens on" "opens with"
carries_any "each run's section holds the Pending debt part verbatim" \
  "verbatim" "word for word" "as written" "exactly as" "unchanged"

echo "# the Reply stays five parts and carries no line naming the Debt file"

# ADR 0091 promised the developer a five-part Reply: a Debt: line beside Report:, or a Next step
# that points at the file, hands them a longer message than that.
flat="$(passage_of "$reply" "## The message" "## " | debt_file_paragraphs)"
carries_any "the Plan block carries no Debt: line beside the Report: line" \
  "no \`Debt:\` line" "never a \`Debt:\` line" "without a \`Debt:\` line" "nor a \`Debt:\` line" \
  "no line \`Debt:" "no \`Debt: <"
carries_each "the Next step says nothing about the Debt file" \
  "Next step" -- \
  "nothing about" "says nothing" "names no" "never names" "does not name" "no mention" \
  "no word" "no line" "nor the Next step" "nor in the Next step" "neither in the"
carries_any "the message stays the five parts" \
  "five parts" "five-part" "stays five" "still five"

mapfile -t items < <(passage_of "$reply" "## The message" "## " | numbered_items)
expect "The message's numbered parts are found" test "${#items[@]}" -gt 0
# shellcheck disable=SC2034 # lib.sh's check_absent reads $out
out="$(printf '%s\n' "${items[@]}")"
check_absent "no numbered part of The message names the Debt file" 0 0 \
  "Debt file" "debt file" ".debt" "Debt:"

echo "# a run under --auto writes the same section to the Debt file as well as the Run report"

# The debt skill reads the Debt file whatever flag the run had: an --auto run whose Run report held
# the Debt file's place would leave its debt where that skill never reads it.
flat="$(passage_of "$reply" "## The message" "## " | debt_file_paragraphs)"
carries_each "under --auto the Debt file section is written as well as the Run report" \
  "under \`--auto\`" "with \`--auto\`" "an \`--auto\` run" "\`--auto\` runs" -- \
  "as well as the Run report" "besides the Run report" "in addition to the Run report" \
  "alongside the Run report" "on top of the Run report" "the Run report too"
carries_any "the Run report does not stand in for the Debt file" \
  "not stand in for" "never stands in for" "not replace" "never replaces" "no substitute for" \
  "not a substitute" "not take the Debt file's place" "never takes the Debt file's place" \
  "not hold the Debt file's place" "never holds the Debt file's place" "not instead of" \
  "not in place of"
affirms "the Run report itself stays written under --auto alone" \
  "Run report" -- \
  "under \`--auto\` alone" "only under \`--auto\`" "only with \`--auto\`" "\`--auto\` alone" \
  "\`--auto\` only" "only an \`--auto\` run" "only \`--auto\` runs"

echo "# ticket.md's Reply step names the Debt file write on every run"

flat="$(item_holding "$ticket" '\*\*[0-9]+\.' 'Reply.**' | debt_file_paragraphs)"
expect "ticket.md's Reply step names the Debt file" test -n "$flat"
carries_any "the Reply step writes the Debt file on every run, not only under --auto" \
  "every run" "each run" "with or without \`--auto\`" "whether or not" "not only under \`--auto\`" \
  "with \`--auto\` or without" "without \`--auto\` too" "also without \`--auto\`"

[ "$fails" -eq 0 ] && exit 0
exit 1
