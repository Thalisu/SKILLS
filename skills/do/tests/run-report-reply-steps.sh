#!/usr/bin/env bash
# run-report-reply-steps.sh: the Reply step of every Playbook that writes a Run report under --auto
# (ticket, bug-fix, refactoring, trivial, integrate, pr), and blocked-reply.md's blocked-run section, sends
# the run to read run-report.md when it is under --auto, before it writes the Run report. A step
# that never sends it there has the session write the report from no rules.
# Run: bash skills/do/tests/run-report-reply-steps.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
refs="$here/../references"
fails=0
pointer="Read [run-report.md](run-report.md) when"

# The sentence of a flattened passage that opens on the pointer, up to its full stop.
pointer_sentence() { # stdin: a flattened passage; stdout: the pointer's sentence
  awk -v p="$pointer" '{ i = index($0, p); if (i) { s = substr($0, i); j = index(s, ". "); print (j ? substr(s, 1, j) : s) } }'
}

# Each row: the Playbook, the marker line its Reply step opens with, the marker line past its end.
rows=(
  "ticket.md|**10. Reply.**|## "
  "bug-fix.md|**13. Reply.**|## "
  "refactoring.md|### 15. Reply|## "
  "trivial.md|### 7. Reply|## "
  "integrate.md|### 4. Reply|## "
  "pr.md|### 5. Reply|## "
)

echo "# each Playbook's Reply step sends an --auto run to run-report.md before it writes the Run report"

for row in "${rows[@]}"; do
  IFS='|' read -r book open past <<<"$row"
  step="$(passage_of "$refs/$book" "$open" "$past")"
  expect "$book carries its Reply step" test -n "$step"
  flat="$(pointer_sentence <<<"$(tr '\n' ' ' <<<"$step" | tr -s ' ')")"
  expect "$book's Reply step points at run-report.md in the Read-when shape" test -n "$flat"
  carries "$book's pointer sends a run under --auto" "\`--auto\`"
  carries_any "$book's pointer sends it there before it writes the Run report" \
    "before it writes the Run report" "before writing the Run report"
done

echo "# blocked-reply.md's blocked-run section sends an --auto run to run-report.md too"

section="$(passage_of "$refs/blocked-reply.md" "## A refusal or a blocked run" "## ")"
expect "blocked-reply.md carries its blocked-run section" test -n "$section"
flat="$(pointer_sentence <<<"$(tr '\n' ' ' <<<"$section" | tr -s ' ')")"
expect "the blocked-run section points at run-report.md in the Read-when shape" test -n "$flat"
carries "the blocked-run pointer sends a run under --auto" "\`--auto\`"
carries_any "the blocked-run pointer sends it there before it writes the Run report" \
  "before it writes the Run report" "before writing the Run report" "before it writes those lines"

[ "$fails" = 0 ]
