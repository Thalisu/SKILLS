#!/usr/bin/env bash
# claude-md-rules.sh: the rules the repository's own root CLAUDE.md states for every change made
# here, read where a maintainer or an agent finds them: a level-2 section outside the
# testing-policy managed block, which verify-policy.sh compares with its template.
# Run: bash scripts/tests/claude-md-rules.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/lib.sh"
claude_md="$here/../../CLAUDE.md"
fails=0

heading="## A prompt holds instructions only"

# The line number of the heading, and of each managed-block marker, so the section is read only
# when it sits outside the block.
heading_at="$(grep -nxF -- "$heading" "$claude_md" | head -n 1 | cut -d: -f1)"
start_at="$(grep -n '^<!-- testing-policy:start' "$claude_md" | head -n 1 | cut -d: -f1)"
end_at="$(grep -n '^<!-- testing-policy:end -->' "$claude_md" | head -n 1 | cut -d: -f1)"
outside() { [ -n "$heading_at" ] && { [ "$heading_at" -lt "${start_at:-0}" ] || [ "$heading_at" -gt "${end_at:-0}" ]; }; }
flat="$(flat_section "$claude_md" "$heading")"

echo "# CLAUDE.md / $heading"
expect "CLAUDE.md carries the section outside the testing-policy managed block" outside
carries_each "a skill, a reference and an agent definition hold instructions only, the reason a rule is shaped as it is lives in the ADRs alone" \
  "skill" -- \
  "reference" -- \
  "agent definition" -- \
  "instructions only" "only instructions" -- \
  "docs/adr/" -- \
  "ADRs alone" "ADRs and nowhere else" "\`docs/adr/\` alone" "only in the ADRs" "only in \`docs/adr/\`"
carries_each "the rule names the Goal clause as its one exception: one clause naming what the instruction protects, only where the instruction is not a closed list of cases" \
  "Goal clause" -- \
  "one exception" "only exception" "sole exception" -- \
  "one clause" -- \
  "what the instruction protects" -- \
  "not a closed list of cases"

exit "$fails"
