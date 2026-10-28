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
blocked="$here/../references/blocked-reply.md"
ticket="$here/../references/ticket.md"
do_doc="$here/../../../docs/do.md"
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

mapfile -t items < <(passage_of "$reply" "## The message" "## " | numbered_items)
expect "The message's numbered parts are found" test "${#items[@]}" -gt 0
expect "The message stays five numbered parts" test "${#items[@]}" = 5
# shellcheck disable=SC2034 # lib.sh's check_absent reads $out
out="$(printf '%s\n' "${items[@]}")"
check_absent "no numbered part of The message names the Debt file" 0 0 \
  "Debt file" "debt file" ".debt" "Debt:"

echo "# a run under --auto writes the same section to the Debt file as well as the Run report"

# The debt skill reads the Debt file whatever flag the run had: an --auto run whose Run report held
# the Debt file's place would leave its debt where that skill never reads it. The sentence moved to
# run-report.md with the Run report's other rules, read under `--auto` alone.
flat="$(passage_of "$here/../references/run-report.md" "## The file" "## " | debt_file_paragraphs)"
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

echo "# a run that owes nothing writes a section reading none"

# The debt skill and the developer read a Ticket with no Debt file as a run that never wrote its
# debt down: a run that owed nothing and wrote nothing would look the same to them.
flat="$(passage_of "$reply" "## The message" "## " | debt_file_paragraphs)"
carries_each "a run with nothing owed still writes its section, which reads none" \
  "owes nothing" "owed nothing" "nothing owed" "nothing to owe" "no debt" "nothing pending" -- \
  "still writes" "writes it all the same" "writes its section" "still adds" "adds its section" \
  "writes one all the same" -- \
  "\`none\`"
carries_any "the section of a run that owes nothing reads plain \`none\`, never a \`- none\` bullet" \
  "plain \`none\`" "bare \`none\`" "not a \`- none\`" "never a \`- none\`" "no \`- none\`" \
  "not \`- none\`" "never \`- none\`"

echo "# a run refused before any edit writes no section to the Debt file"

# The debt skill reads every section as a run that built something: a refused run that wrote one,
# even reading none, would pass there for a run that built and owed nothing.
flat="$(bullets_opening_on <(passage_of "$blocked" "## A refusal or a blocked run" "## ") \
  "**Refused before any edit.**" | head -n 1)"
expect "blocked-reply.md's Refused before any edit bullet is found" test -n "$flat"
carries_each "a run refused before any edit writes no section to the Debt file" \
  "Debt file" -- \
  "no section" "writes nothing" "adds nothing to the Debt file" "nothing to the Debt file" \
  "leaves the Debt file untouched" "not write" "never writes" "no Debt file section"

echo "# a later run on the same Ticket appends its section and never replaces one"

# The developer resuming a stopped run reads the stopped run's items in the Debt file: a later run
# that overwrote or edited an earlier section would lose them.
flat="$(passage_of "$reply" "## The message" "## " | debt_file_paragraphs)"
carries_any "a later run on the same Ticket is named, a resume or a run again" \
  "later run" "a resume" "resumed run" "run again" "runs again" "next run" "second run" \
  "a rerun" "a re-run"
affirms "a later run appends its section below the earlier ones" \
  "appends" "adds its section" "adds its own section" "writes its section" -- \
  "below the earlier" "under the earlier" "after the earlier" "beneath the earlier" \
  "below those" "below the sections"
carries_each "a later run never replaces or edits an earlier section" \
  "never replaces" "does not replace" "not replace" "never overwrites" "not overwrite" \
  "never rewrites" -- \
  "or edits" "nor edits" "never edits" "not edit" "or changes" "nor changes" "or rewrites" \
  "nor rewrites" "or touches" "nor touches"

flat="$(bullets_opening_on <(passage_of "$blocked" "## A refusal or a blocked run" "## ") \
  "**Stopped after work exists.**" | head -n 1)"
expect "blocked-reply.md's Stopped after work exists bullet is found" test -n "$flat"
affirms "a run stopped after work exists writes its section to the Debt file" \
  "Debt file" -- \
  "writes" "adds" "appends" "written" -- \
  "section"

echo "# ticket.md's Reply step names the Debt file write on every run"

flat="$(item_holding "$ticket" '\*\*[0-9]+\.' 'Reply.**' | debt_file_paragraphs)"
expect "ticket.md's Reply step names the Debt file" test -n "$flat"
carries_any "the Reply step writes the Debt file on every run, not only under --auto" \
  "every run" "each run" "with or without \`--auto\`" "whether or not" "not only under \`--auto\`" \
  "with \`--auto\` or without" "without \`--auto\` too" "also without \`--auto\`"

echo "# docs/do.md names the Debt file beside the Ticket among what every run leaves, with or without --auto"

# The page tells the developer the Run report is written only under --auto: one that never names
# the Debt file leaves them believing a run without the flag kept nothing of the debt it named.
reply_paragraphs="$(passage_of "$do_doc" "## What it does" "## " |
  awk 'BEGIN { RS = "" } index($0, "The reply is kept short") { at = NR } at && NR <= at + 1 { print; print "" }')"
expect "docs/do.md's What it does paragraph on the reply is found" test -n "$reply_paragraphs"
flat="$(debt_file_paragraphs <<<"$reply_paragraphs")"
expect "What it does names the Debt file in or right after the paragraph on the reply" test -n "$flat"
carries_any "What it does puts the Debt file beside the Ticket" \
  "beside the Ticket" "next to the Ticket" "beside a Ticket" "beside its Ticket" "Ticket's own folder"
carries_any "What it does says every run on a Ticket writes it, with or without --auto" \
  "every run" "each run" "with or without \`--auto\`" "whether or not" "not only under \`--auto\`" \
  "with \`--auto\` or without" "without \`--auto\` too" "also without \`--auto\`" \
  "even without \`--auto\`" "without \`--auto\` as well"
carries_any "What it does says the Debt file holds the debt the reply named" \
  "Pending debt" "debt the reply named" "debt the reply names" "debt it named" \
  "debt the run left" "the reply's debt"

flat="$(bullets_opening_on <(passage_of "$do_doc" "## It's working if" "## ") "- " |
  grep -i -F "debt file" | tr '\n' ' ')"
expect "It's working if names the Debt file" test -n "$flat"
carries_each "It's working if lists the Debt file beside the Ticket among the files the run leaves you" \
  "beside the Ticket" "next to the Ticket" "beside a Ticket" "beside its Ticket" -- \
  "files the run leaves" "leaves for you" "left for you" "leaves you" "\`git status\`"

echo "# each run's section is one ## heading over one - bullet per Pending debt line, so the debt skill splits it per run"

# The debt skill's gather.sh reads a Debt file by its `## ` headings and `- ` bullets alone: a
# `## Pending debt` heading under each run's heading gives every run's first item the same source,
# so the Debt review that holds one drops the first item of every later run, and a `- none` bullet
# is counted as an item owed.
flat="$(passage_of "$reply" "## The message" "## " | debt_file_paragraphs)"
carries_each "each run's section opens on one \`## <date and time>\` heading" \
  "\`## <date and time>\`" "\`## <date-time>\`" "\`## <timestamp>\`" "\`## <the run's date and time>\`" \
  "\`## <run's date and time>\`" "\`## <date> <time>\`" "\`## YYYY-" "\`## <YYYY-" "\`## \` heading" -- \
  "one \`## " "a single \`## " "its own \`## " "one heading" "a single heading" "its one heading" \
  "only heading" "one such heading"
carries_each "each Pending debt line becomes one \`- \` bullet under that heading, its text verbatim" \
  "\`- \`" "bullet" -- \
  "per Pending debt line" "per line" "each line" "each Pending debt line" "every Pending debt line" \
  "every line" "per item" "each item" "every item" "one per" -- \
  "verbatim" "word for word" "as written" "exactly as" "unchanged"
carries_any "the section carries no \`## Pending debt\` heading of its own" \
  "no \`## Pending debt\`" "never a \`## Pending debt\`" "never \`## Pending debt\`" \
  "not a \`## Pending debt\`" "not under a \`## Pending debt\`" "nor a \`## Pending debt\`" \
  "without a \`## Pending debt\`" "without the \`## Pending debt\`" "without its \`## Pending debt\`" \
  "drops the \`## Pending debt\`" "drops its \`## Pending debt\`" "leaves out the \`## Pending debt\`" \
  "no Pending debt heading" "never a Pending debt heading" "without the Pending debt heading" \
  "drops the Pending debt heading"
carries_any "a run that owes nothing reads plain \`none\`, never a \`- none\` bullet" \
  "plain \`none\`" "bare \`none\`" "not a \`- none\`" "never a \`- none\`" "no \`- none\`" \
  "not \`- none\`" "never \`- none\`" "not as a bullet" "not a bullet" "never a bullet" "no bullet"

[ "$fails" -eq 0 ] && exit 0
exit 1
