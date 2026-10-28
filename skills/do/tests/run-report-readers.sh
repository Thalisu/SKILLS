#!/usr/bin/env bash
# run-report-readers.sh: run-report.md opens on every reader that reaches it, the Reply step of the
# ticket, bug-fix, refactoring, trivial, integrate and pr Playbooks and a refused or blocked run's
# reply, and on the condition that sends them, a run under --auto before it writes the Run report.
# SKILL.md's references-list entry names the same readers and condition. A maintainer changing the
# file reads there, in one place, who reads it and when, and misses no reader.
# Run: bash skills/do/tests/run-report-readers.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
report="$here/../references/run-report.md"
skill="$here/../SKILL.md"
fails=0

readers=(ticket bug-fix refactoring trivial integrate pr)

echo "# run-report.md's opening paragraph names its readers and the condition that sends them"

# The first paragraph after the title, flattened.
flat="$(awk 'NR > 1 && /^#/ { exit } NR > 1' "$report" | awk 'BEGIN { RS = "" } NR == 1 { gsub(/\n/, " "); print }' | tr -s ' ')"
expect "run-report.md opens on a paragraph before its first section" test -n "$flat"
for book in "${readers[@]}"; do
  carries "the opening names the $book Playbook's Reply step" "\`$book\`"
done
carries "the opening names the Reply step as where those Playbooks read it" "Reply step"
carries_any "the opening names a refused or blocked run's reply" \
  "refused or blocked run" "blocked or refused run" "refusal or a blocked run"
carries "the opening's condition is a run under --auto" "under \`--auto\`"
carries_any "the opening sends them before the Run report is written" \
  "before it writes the Run report" "before writing the Run report"

echo "# SKILL.md's references-list entry for run-report.md names the same readers and condition"

flat="$(grep -F '[run-report.md](references/run-report.md):' "$skill")"
expect "SKILL.md carries a references-list entry for run-report.md" test -n "$flat"
for book in "${readers[@]}"; do
  carries "the entry names the $book Playbook's Reply step" "\`$book\`"
done
carries_any "the entry names a refused or blocked run's reply" \
  "refused or blocked run" "blocked or refused run" "refusal or a blocked run"
carries "the entry's condition is a run under --auto" "under \`--auto\`"
carries_any "the entry sends them before the Run report is written" \
  "before it writes the Run report" "before writing the Run report"

[ "$fails" = 0 ]
