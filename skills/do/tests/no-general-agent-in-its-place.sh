#!/usr/bin/env bash
# no-general-agent-in-its-place.sh: the contract of the grader at
# skills/do/evals/unlisted-choice-taker/graders/no-general-agent-in-its-place.md, exercised by
# calling scripts/run-eval.sh's own grade() against a throwaway work folder, so no claude session
# ever starts. Run: bash skills/do/tests/no-general-agent-in-its-place.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
runner="$here/../../../scripts/run-eval.sh"
grader="$here/../evals/unlisted-choice-taker/graders/no-general-agent-in-its-place.md"
fails=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

start="$(grep -n '^front()' "$runner" | head -1 | cut -d: -f1)"
end="$(($(grep -n '^restore_agents()' "$runner" | head -1 | cut -d: -f1) - 1))"
source <(sed -n "${start},${end}p" "$runner")

# $1 subagent_type or empty to omit the key, $2 work folder: writes one Agent tool_use transcript line
agent_call_transcript() {
  local sub="$1" w="$2" input
  if [ -n "$sub" ]; then
    input="{\"description\":\"x\",\"prompt\":\"y\",\"subagent_type\":\"$sub\"}"
  else
    input='{"description":"x","prompt":"y"}'
  fi
  printf '{"type":"assistant","parent_tool_use_id":null,"message":{"content":[{"type":"tool_use","id":"t1","name":"Agent","input":%s}]}}\n' \
    "$input" >"$w/transcript.jsonl"
}

case_pass() { # $1 label, $2 subagent_type or empty
  local w out
  w="$(mktemp -d "$tmp/w.XXXXXX")"
  agent_call_transcript "$2" "$w"
  out="$(grade "$grader" "$w")"
  if [ -z "$out" ]; then ok "$1"; else
    fail "$1 (wanted empty, got: $out)"
  fi
}

case_fail() { # $1 label, $2 subagent_type or empty
  local w out
  w="$(mktemp -d "$tmp/w.XXXXXX")"
  agent_call_transcript "$2" "$w"
  out="$(grade "$grader" "$w")"
  if [ -n "$out" ]; then ok "$1"; else
    fail "$1 (wanted a non-empty failure reason, grader passed instead)"
  fi
}

case_fail "an Agent call with no subagent_type at all fails the grader" ""
case_fail "an Agent call to unit-test-author fails the grader" "unit-test-author"
case_pass "an Agent call to do-reader, the door step's legitimate pre-fork fork, passes" "do-reader"
case_pass "an Agent call to sketch, the shape step's legitimate pre-fork fork, passes" "sketch"
case_pass "an Agent call to ledger-judge, the integration step's legitimate fork, passes" "ledger-judge"
case_pass "an Agent call to do-planner, the Plan step's legitimate fork, passes" "do-planner"
case_fail "an Agent call to general-purpose still fails the grader" "general-purpose"

[ "$fails" -eq 0 ] && exit 0
exit 1
