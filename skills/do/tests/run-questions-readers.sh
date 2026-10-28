#!/usr/bin/env bash
# run-questions-readers.sh: run-questions.md is read only by a step of a `ticket` run under `--auto`
# that hands a run question to the `choice-taker`, so a run without the flag loads none of its text,
# and every step that rules or asks one under the flag is sent to it in the
# `Read <file> when <condition>` shape.
# Run: bash skills/do/tests/run-questions-readers.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
do_dir="$(cd "$here/.." && pwd -P)"
questions="$do_dir/references/run-questions.md"
forks="$do_dir/references/forks.md"
ticket="$do_dir/references/ticket.md"
mechanics="$do_dir/references/mechanics.md"
reply="$do_dir/references/reply.md"
fails=0
pointer="Read [run-questions.md](run-questions.md) when "

echo "# run-questions.md carries the run questions under --auto, and forks.md no longer does"
flat="$({ tr '\n' ' ' <"$questions"; } 2>/dev/null | tr -s ' ')"
expect "run-questions.md exists" test -n "$flat"
carries_each "its table names the two ruled questions, the resumed rebase's and the full suite's" \
  "continue or stop, on a resumed integration" -- "whether a full suite or a remote run runs"
carries "a ruled question's Ruling is written to no file" "Write the Ruling to no file"
expect "forks.md holds no run-question section" test -z "$(grep -E '^#+ A run question' "$forks")"
flat="$(paragraph_with "$forks" "It is read by" | tr -s ' ')"
expect "forks.md's opening names its readers" test -n "$flat"
out="$flat"
absent "forks.md's opening no longer names a step ruled under --auto among its readers" "--auto"

echo "# each step that rules or asks a run question under --auto is sent to run-questions.md"
at() { # $1 label, $2 file, $3 a fixed string the step's paragraph carries
  flat="$(paragraph_with "$2" "$3" | tr -s ' ')"
  carries "$1" "$pointer"
}
at "ticket.md's Resume, before discarding uncommitted work" "$ticket" \
  "restart the first behaviour without a commit"
at "ticket.md's Resume, on a rebase resolved with no conflicted file" "$ticket" \
  "continue: continue the rebase, committing what is staged"
at "ticket.md's Resume, on a rebase whose target moved" "$ticket" \
  "\`abort: drop this rebase and rebase once onto <tip>\`"
at "ticket.md's resumed integration, on its open rebase" "$ticket" \
  "on \`moved=ask\`, each question in the words of that bullet"
at "ticket.md's resumed integration, before a discard" "$ticket" \
  "yes discards it and the run goes on as \`verdict=restart\` with the tree present"
at "ticket.md's verification, before a full suite or a remote run" "$ticket" \
  "through \`scripts/flows.sh\`, its command line printed first"
at "ticket.md's close, before a write to a Ticket issue" "$ticket" "**9. Close.**"
at "mechanics.md's claim, before assigning an issue" "$mechanics" "issue is assigned on their yes alone"
at "mechanics.md's resume, on its open rebase and before a discard" "$mechanics" \
  "\`land\` at the fix call on the Review already written"
at "mechanics.md's verification, before a full suite or a remote run" "$mechanics" \
  "\`yes: run <the command line>\`"
at "mechanics.md's close, before a write to a remote tracker" "$mechanics" \
  "under the same \`Yours: outward:\` line, with the \`choice-taker\`'s return"
at "reply.md's Rulings, on a run question's Ruling" "$reply" "**A Ruling on a run question.**"
at "reply.md's handover, before a write to a remote tracker" "$reply" "**A write to a remote tracker.**"

echo "# every pointer to run-questions.md reads \`Read [run-questions.md](run-questions.md) when <condition>\`"
pointers_shaped "every pointer to run-questions.md has the \`Read <file> when <condition>\` shape" \
  "$do_dir" run-questions.md 12

[ "$fails" -eq 0 ]
