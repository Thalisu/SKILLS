#!/usr/bin/env bash
# run-report-not-loaded.sh: a run without --auto writes no Run report, so the two files every run
# reads, SKILL.md and reply.md, carry none of the Run report's own rules: no Run section, none of
# the seven sections only the Run report carries, no location or append rule, no Run report example.
# Run: bash skills/do/tests/run-report-not-loaded.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
skill="$here/../SKILL.md"
reply="$here/../references/reply.md"
fails=0

echo "# a run without --auto loads no Run report rule from SKILL.md or reply.md"

out="$(cat "$reply")"
if grep -qx '## Run' "$reply"; then
  fail "reply.md carries no ## Run section"
else
  ok "reply.md carries no ## Run section"
fi
for item in '**Read-back.**' '**Checklist.**' '**Plan line.**' '**Build lines.**' \
  '**Integration line.**' '**Watch lines.**'; do
  absent "reply.md carries no Run section item $item" "$item"
done

sections="$(passage_of "$reply" "## Sections" "## ")"
expect "reply.md carries a ## Sections section" test -n "$sections"
out="$sections"
for item in '**Inherited.**' '**Commits.**' '**Evidence.**' '**Principles.**' '**Rulings.**' \
  '**Skipped.**' '**Left uncommitted.**'; do
  absent "reply.md's Sections carry no Run-report-only item $item" "$item"
done
for item in '**For whom.**' '**Pending debt.**' '**Next step.**'; do
  expect "reply.md's Sections keep the message part $item" grep -qF "$item" <<<"$sections"
done

out="$(tr '\n' ' ' <"$reply" | tr -s ' ')"
absent "reply.md carries no Run report location beside the Plan" "its stem with \`.report.md\` in place of"
absent "reply.md carries no Run report location under .scratch/do-reports/" ".scratch/do-reports/"
absent "reply.md carries no Run report append rule" "appends its own Run report below the earlier one"
if grep -qx '## Inherited' "$reply"; then
  fail "reply.md carries no Run report example"
else
  ok "reply.md carries no Run report example"
fi

out="$(tr '\n' ' ' <"$skill" | tr -s ' ')"
absent "SKILL.md carries no clause on the Run report's Run section and the checklist" \
  "the Run report's Run section carries it"
absent "SKILL.md carries no rule on naming a principle in the Run report" \
  "A principle is named in the Run report only with the decision it changed"

[ "$fails" = 0 ]
