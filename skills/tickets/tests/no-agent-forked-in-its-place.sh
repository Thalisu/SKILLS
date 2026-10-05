#!/usr/bin/env bash
# no-agent-forked-in-its-place.sh: the contract of the grader at
# skills/tickets/evals/auto-agent-tool-withheld-asks-the-developer/graders/no-agent-forked-in-its-place.md,
# exercised by calling scripts/run-eval.sh's own grade() against a throwaway work folder, so no
# claude session ever starts. Run: bash skills/tickets/tests/no-agent-forked-in-its-place.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
# shellcheck disable=SC2034 # read by lib.sh's agent_call_passes and agent_call_fails
grader="$here/../evals/auto-agent-tool-withheld-asks-the-developer/graders/no-agent-forked-in-its-place.md"
fails=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

source_grade

agent_call_fails "an Agent call with no subagent_type at all, the general agent forked in the choice-taker's place, fails the grader" ""
agent_call_passes "an Agent call naming choice-taker itself, which forks nothing when the tool is withheld, passes" "choice-taker"
agent_call_fails "an Agent call to general-purpose fails the grader" "general-purpose"
agent_call_fails "an Agent call to unit-test-author fails the grader" "unit-test-author"

[ "$fails" -eq 0 ] && exit 0
exit 1
