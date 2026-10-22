#!/usr/bin/env bash
# impeccable-waits.sh: the do-impeccable fork waits on what its next step needs in the foreground.
# The Agent tool runs an agent in the background unless the call sets `run_in_background: false`,
# so an end-to-end author or an impeccable helper dispatched without it comes back as a launch with
# no verdict, and the fork improvises a poll on a side effect (`until ...; do sleep; done`,
# `tail -f`). The poll outlives the Bash tool's timeout, the harness moves it to the background,
# and it runs stale long after the fork returned to the do session waiting on it.
# The dispatches and the ban are prose the fork follows, so they are proven over the paragraphs of
# its agent body that carry them, wherever they sit.
# Run: bash skills/do/tests/impeccable-waits.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
agent="$here/../agents/do-impeccable.md"
fails=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# The body alone: the frontmatter's Agent hook names every agent the fork may dispatch, and a
# paragraph of the hook never answers for the prose the fork follows.
body="$tmp/body.md"
body_of "$agent" >"$body"

mapfile -t foreground_flag < <(foreground_phrasings)

mapfile -t every_agent < <(every_dispatch_phrasings)

echo "# do-impeccable.md: every agent whose verdict the fork's next step waits on is dispatched in the foreground"
flat="$(paragraphs_naming "e2e-test-author" "end-to-end author" "end-to-end test author" "${every_agent[@]}")"
expect "the agent body has a passage on dispatching the end-to-end authors" test -n "$flat"
carries_any "the end-to-end authors' dispatch sets the Agent tool's run_in_background: false" "${foreground_flag[@]}"
flat="$(paragraphs_naming "impeccable-<role>" "helper" "${every_agent[@]}")"
expect "the agent body has a passage on dispatching the impeccable helpers" test -n "$flat"
carries_any "the impeccable helpers' dispatch sets the Agent tool's run_in_background: false" "${foreground_flag[@]}"

# The agent body speaks to the fork as "you", so the ban's subject is the fork in the second person.
echo "# do-impeccable.md: the fork never waits with a loop of its own, since the Bash timeout moves the call to the background"
mapfile -t loop_terms < <(own_loop_phrasings)
paras="$(paragraphs_naming "${loop_terms[@]}")"
flat="$(grep -E 'timeout|time out|times out' <<<"$paras" | head -n1)"
[ -n "$flat" ] || flat="$(head -n1 <<<"$paras")"
expect "the fork's contract has a passage on waiting with a loop of its own" test -n "$flat"
subject_denies "it forbids the fork a wait loop or a poll of its own" "You|you|fork" "${loop_terms[@]}"
carries_each "the ban covers a dispatch and a slow command alike" \
  "dispatch" "agent" "Agent" -- \
  "command" "shell call" "Bash call"
carries_each "it ties the ban to the Bash tool's timeout moving the call to the background" \
  "Bash" -- \
  "timeout" "time out" "times out" -- \
  "to the background" "into the background" "backgrounds it" "backgrounded"

echo "# do-impeccable.md: the fallback wait for a backgrounded agent is bounded and has a next step"
wait_para="$(paragraph_with "$body" "timeout 540 tail -f /dev/null" | tr -s ' ')"
flat="$wait_para"
expect "the agent body has a paragraph giving the fallback wait \`timeout 540 tail -f /dev/null\`" test -n "$flat"
flat="$(awk '{ n = split($0, s, /\. /); for (i = 1; i <= n; i++) if (index(s[i], "600000")) print s[i] }' <<<"$wait_para")"
carries_each "the wait call runs with the Bash tool's timeout set to 600000 ms, above the wait's own timeout 540" \
  "timeout 540" "tail -f /dev/null" "wait call" "the wait" "wait with" "waits with" "wait itself" -- \
  "timeout"
flat="$wait_para"
# `stopped` is the only verdict of `## What you return` that ends a stretch short of `built` over
# anything but a Design fork: any other first line is a return the session cannot route.
carries_each "a wait that ends with no notification is repeated at most twice more, then the fork returns stopped naming the dispatch" \
  "no verdict" "without a verdict" "no notification" "without a notification" -- \
  "twice" "two more" -- \
  "return \`stopped\`" "returns \`stopped\`" "as \`stopped\`" -- \
  "naming the dispatch" "names the dispatch" "naming that dispatch" "names that dispatch" \
  "naming the agent" "names the agent" "naming the dispatched" "names the dispatched"

[ "$fails" -eq 0 ] && exit 0
exit 1
