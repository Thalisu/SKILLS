#!/usr/bin/env bash
# run-report-lines.sh: run-report.md carries every line the Run report carried before it moved out
# of reply.md and SKILL.md: every Run section item, the ten sections in their order, the file's
# location beside the Plan or under .scratch/do-reports/, the append below an earlier report under a
# `---` rule, the checklist and principle rules, and the Run report example. A line dropped in the
# move is a Ruling or a skipped step an unattended run's developer reads nowhere else.
# Run: bash skills/do/tests/run-report-lines.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
report="$here/../references/run-report.md"
fails=0

echo "# run-report.md: every Run section item"

run="$(passage_of "$report" "## Run" "## Sections")"
expect "run-report.md carries a ## Run section" test -n "$run"
mapfile -t run_items < <(numbered_items <<<"$run")
labels=('Read-back' 'Surface' 'Predicate' 'Loop line' 'Defect line' 'Claim line' 'Resume line'
  'Protected-branch warning' 'Checklist' 'Plan line' 'Audit line' 'Map line' 'Hand-over'
  'Shaped-by line' 'Sketch line' 'Reproduction' 'Diagnosis' 'Target files' 'Worktree line'
  'Structure line' 'Fix line' 'Behaviours list' 'Build lines' 'Answer lines' 'Gate line'
  'Door verdict' 'Integration line' 'Review return' 'Spec landing lines'
  'Final integration lines' 'Watch lines')
expect "the Run section holds one item per line it can carry" test "${#run_items[@]}" -eq "${#labels[@]}"
for i in "${!labels[@]}"; do
  n=$((i + 1))
  expect "Run item $n is ${labels[$i]}" grep -qF -- "$n. **${labels[$i]}.**" <<<"${run_items[$i]:-}"
done

echo "# run-report.md: the ten sections in their order"

sections="$(passage_of "$report" "## Sections" "## ")"
mapfile -t section_items < <(numbered_items <<<"$sections")
names=('For whom' 'Inherited' 'Commits' 'Evidence' 'Principles' 'Rulings' 'Skipped'
  'Left uncommitted' 'Pending debt' 'Next step')
expect "the Sections list holds ten items" test "${#section_items[@]}" -eq 10
for i in "${!names[@]}"; do
  n=$((i + 1))
  expect "section $n is ${names[$i]}" grep -qF -- "$n. **${names[$i]}.**" <<<"${section_items[$i]:-}"
done

echo "# run-report.md: where the file is written, and what a later run does with it"

flat="$(passage_of "$report" "## The file" "## " | tr '\n' ' ' | tr -s ' ')"
carries "the Run report sits beside the Plan in a ticket run" "beside the Plan" \
  "its stem with \`.report.md\` in place of \`.plan.md\`"
carries "the Run report sits under .scratch/do-reports/ in every other Playbook" \
  ".scratch/do-reports/<YYYYMMDD>-<the branch's slug>.md" "appending the \`.scratch/\` line first"
carries "the file holds the Run section then the ten sections, an empty one reading none" \
  "the Run section, then the ten sections in their order" "reading \`none\`"
carries "a later --auto run appends below the earlier report under a --- rule, never replacing it" \
  "appends its own Run report below the earlier one, under a \`---\` rule, and never replaces it"
carries "the Run report is written under --auto alone" "only under \`--auto\`" \
  "Without \`--auto\` the Run report is not written at all"
carries "the Run report does not stand in for the Debt file" "does not stand in for the Debt file"
carries "the Run section carries the checklist, every step ticked done: or visible as skip:" \
  "the Run section carries the matched Playbook's checklist" "visible as \`skip: <reason>\`"
carries "a principle is named only with the decision it changed" \
  "A principle is named in the Run report only with the decision it changed"

echo "# run-report.md: the Run report example"

example="$(passage_of "$report" "## Example" "## Example")"
expect "run-report.md carries an example" grep -q '^<example>' <<<"$example"
headings="$(grep -E '^## ' <<<"$(sed -n '/^```md/,/^```$/p' <<<"$example")" | tr '\n' '|')"
expect "the example holds the Run section then the ten sections in their order" \
  test "$headings" = "## Run|## For whom|## Inherited|## Commits|## Evidence|## Principles|## Rulings|## Skipped|## Left uncommitted|## Pending debt|## Next step|"

[ "$fails" = 0 ]
