#!/usr/bin/env bash
# no-general-agent-in-its-place.sh: the contract of the grader at
# skills/do/evals/unlisted-choice-taker/graders/no-general-agent-in-its-place.md, exercised by
# calling scripts/run-eval.sh's own grade() against a throwaway work folder, so no claude session
# ever starts. Run: bash skills/do/tests/no-general-agent-in-its-place.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
# shellcheck disable=SC2034 # read by lib.sh's agent_call_passes and agent_call_fails
grader="$here/../evals/unlisted-choice-taker/graders/no-general-agent-in-its-place.md"
fails=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

source_grade

agent_call_fails "an Agent call with no subagent_type at all fails the grader" ""
agent_call_fails "an Agent call to unit-test-author fails the grader" "unit-test-author"
agent_call_passes "an Agent call to do-reader, the door step's legitimate pre-fork fork, passes" "do-reader"
agent_call_passes "an Agent call to sketch, the shape step's legitimate pre-fork fork, passes" "sketch"
agent_call_passes "an Agent call to ledger-judge, the integration step's legitimate fork, passes" "ledger-judge"
agent_call_passes "an Agent call to do-planner, the Plan step's legitimate fork, passes" "do-planner"
agent_call_fails "an Agent call to general-purpose still fails the grader" "general-purpose"

[ "$fails" -eq 0 ] && exit 0
exit 1
