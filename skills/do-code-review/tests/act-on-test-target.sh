#!/usr/bin/env bash
# act-on-test-target.sh: an `Act on` Finding whose `Fix:` line names no test file as its target
# drops to `Consider` when the orchestrator groups the Review.
# The fix run verifies a Finding by re-running the check its `Fix:` line names, and a Fix aimed at a
# reference file names no check: its commit reads `fixed <sha>, not verified` forever, the Review
# never turns Green, and the run stops on the developer with no way forward but a hand edit.
# The grouping is prose the orchestrator follows, so it is proven over the paragraph of its body
# that carries it.
# Run: bash skills/do-code-review/tests/act-on-test-target.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
agent="$here/../AGENT.md"
fails=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

body="$tmp/body.md"
body_of "$agent" >"$body"

echo "# AGENT.md: an Act on Finding whose Fix: names no test file as its target drops to Consider"
para="$(paragraph_with "$body" "Group the Findings by Bucket" | tr -s ' ')"
expect "the agent body has the paragraph grouping the Findings by Bucket" test -n "$para"
mapfile -t demotion < <(printf '%s\n' "drops to \`Consider\`" "goes to \`Consider\`" "moves to \`Consider\`" \
  "falls to \`Consider\`" "sits in \`Consider\`" "lands in \`Consider\`" "is moved to \`Consider\`")
# The sentence that demotes a Finding is the scope: a test file named elsewhere in the paragraph
# never answers for the condition the demotion is taken on.
# shellcheck disable=SC2034  # lib.sh's carries_each reads $flat
flat="$(awk '{ n = split($0, s, /\. /); for (i = 1; i <= n; i++) print s[i] }' <<<"$para" |
  grep -F "Fix:" | grep -F -e "${demotion[0]}" -e "${demotion[1]}" -e "${demotion[2]}" \
  -e "${demotion[3]}" -e "${demotion[4]}" -e "${demotion[5]}" -e "${demotion[6]}")"
carries_each "the demotion to Consider is taken on a Fix: whose target is not a test file" \
  "Fix:" -- \
  "${demotion[@]}" -- \
  "test file" "no test" "not a test" "a test's path" "unit test" "new test" -- \
  "no test" "not a test" "names no" "anything else" "any other" "otherwise" "other than" "but a test" "without"

[ "$fails" -eq 0 ] && exit 0
exit 1
