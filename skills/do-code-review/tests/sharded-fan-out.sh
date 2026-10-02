#!/usr/bin/env bash
# sharded-fan-out.sh: what the orchestrator's fan-out does with the cut `scripts/shards.sh` prints.
# A diff the cut reports as one Shard is the run a developer already knows: one technical reviewer
# and one security reviewer, the same brief, the same two return files.
# The cases pin the script call, where it sits and the literal tokens a run acts on, never the
# contract's sentences.
# Run: bash skills/do-code-review/tests/sharded-fan-out.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
agent="$here/../AGENT.md"
fails=0

section="$(passage_of "$agent" "## 6. The fan-out" "## 7.")"
flat="$(flat_section "$agent" "## 6. The fan-out")"

echo "# AGENT.md / ## 6. The fan-out: the diff is cut before any reviewer is forked"
expect "AGENT.md carries the fan-out" test -n "$flat"
expect "the fan-out runs the cut script over the fixed point" \
  grep -qE 'do-code-review/scripts/shards\.sh <fixed[ _]point>' <<<"$flat"
before "the cut is taken before the reviewers are forked" \
  "scripts/shards.sh" "| \`subagent_type:"

echo "# AGENT.md / ## 6. The fan-out: a cut of one Shard is the unsharded run"
carries "the fan-out says what a cut of one Shard runs" "shards=1"

# The unsharded run's forks are the rows whose return file is the one a single reviewer of its kind
# writes: a sharded run's forks, when the table grows them, return into other files.
tech_rows="$(grep -F '| `subagent_type: do-code-review-technical-reviewer`' <<<"$section" | grep -F '/technical.md')"
sec_rows="$(grep -F '| `subagent_type: do-code-review-security-reviewer`' <<<"$section" | grep -F '/security.md')"
expect "one technical reviewer is forked, returning into technical.md" \
  test "$(grep -c . <<<"$tech_rows")" = 1
expect "one security reviewer is forked, returning into security.md" \
  test "$(grep -c . <<<"$sec_rows")" = 1
# shellcheck disable=SC2034 # lib.sh's absent reads $out
out="$tech_rows"$'\n'"$sec_rows"
absent "neither of the two prompts carries a Shard line" "Shard"
absent "and the manifest is named to neither of them" "manifest"

exit $((fails > 0))
