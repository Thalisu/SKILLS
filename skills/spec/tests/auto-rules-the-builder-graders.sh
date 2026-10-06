#!/usr/bin/env bash
# auto-rules-the-builder-graders.sh: the contract of the code-read graders of
# skills/spec/evals/auto-rules-the-builder, exercised by calling scripts/run-eval.sh's own grade()
# against a throwaway work folder, so no claude session ever starts. Under --auto a feature with a
# screen has its builder ruled by the choice-taker: forked once, the Spec's Front-end: line carrying
# one of the two builders, and the Ruling written with its norm. The fixture's summary names the
# seams, so the builder is the only question handed over and a seam's Ruling never stands in for it.
# Run: bash skills/spec/tests/auto-rules-the-builder-graders.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
fails=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

source_grade

graders="$here/../evals/auto-rules-the-builder/graders"
forked_once="$graders/choice-taker-forked-once.md"
line_ruled="$graders/front-end-line-ruled.md"
carries_norm="$graders/ruled-builder-carries-its-norm.md"

run_with_spec() { # $1 the Spec's Front-end: line or empty for none, $2 the lines closing its Implementation Decisions or empty for none: a new work folder whose fixture holds that Spec, its path on stdout
  local w
  w="$(mktemp -d "$tmp/w.XXXXXX")"
  mkdir -p "$w/fixture/.scratch/20260905-suppliers"
  {
    printf '# Supplier export\n\nJourney: required\n'
    [ -z "$1" ] || printf '%s\n' "$1"
    printf 'Status: ready-for-agent\n\n## Problem Statement\n\nA buyer cannot export the suppliers of an order.\n\n'
    printf '## Solution\n\nAn export screen on the order page.\n\n'
    printf '## User Stories\n\n1. As a buyer, I want to export the suppliers from the order screen, so that I can share them.\n\n'
    printf '## Implementation Decisions\n\n- The export is a CSV file.\n'
    [ -z "$2" ] || printf '%s\n' "$2"
    printf '\n## Testing Decisions\n\n- The export handler of the order module, taken from the conversation.\n'
  } >"$w/fixture/.scratch/20260905-suppliers/spec.md"
  echo "$w"
}

builder_ruling='- Ruled by the choice-taker under --auto: the front-end is built by builder. Norm: the repository ships no impeccable setup.'
seam_ruling='- Ruled by the choice-taker under --auto: the export handler of the order module. Norm: no norm: the side easiest to undo.'

expect "the case holds a choice-taker-forked-once grader" test -f "$forked_once"
expect "the case holds a front-end-line-ruled grader" test -f "$line_ruled"
expect "the case holds a ruled-builder-carries-its-norm grader" test -f "$carries_norm"

silent="$(mktemp -d "$tmp/w.XXXXXX")"
: >"$silent/transcript.jsonl"

# shellcheck disable=SC2034 # read by lib.sh's grade_passes and grade_fails
grader="$forked_once"
agent_call_passes "one choice-taker call passes choice-taker-forked-once" "choice-taker"
grade_fails "a run with no Agent call fails choice-taker-forked-once" "$silent"
agent_call_fails "one general-purpose call and no choice-taker call fails choice-taker-forked-once" "general-purpose"
grade_fails "two choice-taker calls fail choice-taker-forked-once" \
  "$(run_of choice-taker "" "" y -- choice-taker "" "" y)"

# shellcheck disable=SC2034 # read by lib.sh's grade_passes and grade_fails
grader="$line_ruled"
grade_passes "a Spec whose line reads Front-end: builder passes front-end-line-ruled" \
  "$(run_with_spec "Front-end: builder" "$builder_ruling")"
grade_passes "a Spec whose line reads Front-end: impeccable passes front-end-line-ruled" \
  "$(run_with_spec "Front-end: impeccable" "")"
grade_fails "a Spec whose only Front-end: line reads none fails front-end-line-ruled" \
  "$(run_with_spec "Front-end: none" "$builder_ruling")"
grade_fails "a Spec with no Front-end: line fails front-end-line-ruled" \
  "$(run_with_spec "" "$builder_ruling")"

# shellcheck disable=SC2034 # read by lib.sh's grade_passes and grade_fails
grader="$carries_norm"
grade_passes "a builder Ruling with its norm passes ruled-builder-carries-its-norm" \
  "$(run_with_spec "Front-end: builder" "$builder_ruling")"
grade_passes "an impeccable Ruling whose value sits in backticks passes ruled-builder-carries-its-norm" \
  "$(run_with_spec "Front-end: impeccable" \
    '- Ruled by the choice-taker under --auto: the front-end is built by `impeccable`. Norm: the project already carries an impeccable design context.')"
grade_passes "a builder Ruling backed by no norm but the side easiest to undo passes ruled-builder-carries-its-norm" \
  "$(run_with_spec "Front-end: builder" \
    '- Ruled by the choice-taker under --auto: the front-end is built by `builder`. Norm: no norm: the side easiest to undo.')"
grade_passes "a builder Ruling written beside a seam's passes ruled-builder-carries-its-norm" \
  "$(run_with_spec "Front-end: builder" "$seam_ruling"$'\n'"$builder_ruling")"
grade_fails "a Spec with no Ruling line fails ruled-builder-carries-its-norm" \
  "$(run_with_spec "Front-end: builder" "")"
grade_fails "a Spec whose only Ruling line is a seam's fails ruled-builder-carries-its-norm" \
  "$(run_with_spec "Front-end: builder" "$seam_ruling")"
grade_fails "a builder Ruling with no Norm: fails ruled-builder-carries-its-norm" \
  "$(run_with_spec "Front-end: builder" \
    '- Ruled by the choice-taker under --auto: the front-end is built by builder.')"

[ "$fails" -eq 0 ] && exit 0
exit 1
