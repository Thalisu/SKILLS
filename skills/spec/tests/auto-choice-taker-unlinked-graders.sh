#!/usr/bin/env bash
# auto-choice-taker-unlinked-graders.sh: the contract of the tool_used graders of
# skills/spec/evals/auto-choice-taker-unlinked-asks-the-seams and of its sibling
# auto-choice-taker-unlinked-asks-the-builder, which share it, exercised by calling
# scripts/run-eval.sh's own grade() against a throwaway work folder, so no claude session ever
# starts. The fixture unlinks choice-taker, so a run learns it is out of reach from the Agent
# tool's list or from one refused call: that one call is allowed, a second one or any other agent
# forked in its place is not. Run: bash skills/spec/tests/auto-choice-taker-unlinked-graders.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
fails=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

source_grade

case_passes() { # $1 label, $2 work folder: every tool_used grader of the case passes the run, and the case has one
  local g out seen=0 reasons=""
  for g in "$graders"/*.md; do
    out="$(frontmatter "$g")"
    [ "$(field type)" = "tool_used" ] || continue
    seen=$((seen + 1))
    out="$(grade "$g" "$2")"
    [ -z "$out" ] || reasons="$reasons ${g##*/}: $out;"
  done
  if [ "$seen" -gt 0 ] && [ -z "$reasons" ]; then ok "$1"; else
    fail "$1 ($seen tool_used graders, failing:${reasons:- none})"
  fi
}

for name in auto-choice-taker-unlinked-asks-the-seams auto-choice-taker-unlinked-asks-the-builder; do
  graders="$here/../evals/$name/graders"
  not_twice="$graders/choice-taker-not-tried-twice.md"
  no_other="$graders/no-other-agent-forked-in-its-place.md"

  expect "$name: the case holds a choice-taker-not-tried-twice grader" test -f "$not_twice"
  expect "$name: the case holds a no-other-agent-forked-in-its-place grader" test -f "$no_other"

  silent="$(mktemp -d "$tmp/w.XXXXXX")"
  : >"$silent/transcript.jsonl"
  case_passes "$name: a run with no Agent call passes every tool_used grader of the case" "$silent"
  case_passes "$name: a run whose one Agent call is the refused choice-taker call passes every tool_used grader of the case" \
    "$(run_of choice-taker "" "" y)"

  # shellcheck disable=SC2034 # read by lib.sh's grade_passes and grade_fails
  grader="$not_twice"
  grade_passes "$name: a run with no Agent call passes choice-taker-not-tried-twice" "$silent"
  agent_call_passes "$name: one refused choice-taker call passes choice-taker-not-tried-twice" "choice-taker"
  grade_fails "$name: two choice-taker calls fail choice-taker-not-tried-twice" \
    "$(run_of choice-taker "" "" y -- choice-taker "" "" y)"

  # shellcheck disable=SC2034 # read by lib.sh's grade_passes and grade_fails
  grader="$no_other"
  grade_passes "$name: a run with no Agent call passes no-other-agent-forked-in-its-place" "$silent"
  agent_call_passes "$name: one refused choice-taker call passes no-other-agent-forked-in-its-place" "choice-taker"
  grade_fails "$name: a choice-taker call plus a general-purpose call fails no-other-agent-forked-in-its-place" \
    "$(run_of choice-taker "" "" y -- general-purpose "" "" y)"
  agent_call_fails "$name: an Agent call with no subagent_type at all fails no-other-agent-forked-in-its-place" ""
  agent_call_fails "$name: one general-purpose call alone fails no-other-agent-forked-in-its-place" "general-purpose"
done

[ "$fails" -eq 0 ] && exit 0
exit 1
