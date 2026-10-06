#!/usr/bin/env bash
# rerun-front-end-graders.sh: the contract of the code-read graders of the spec eval cases that rerun
# the skill on a feature whose Spec already carries a Front-end: line, exercised by calling
# scripts/run-eval.sh's own grade() against a throwaway work folder, so no claude session ever starts.
# In rerun-keeps-the-front-end-line the earlier Spec reads Front-end: impeccable, the answer the
# developer gave and never the recommended builder, and the rerun adds one decision, an Order total
# column in the exported CSV: the rerun rewrites the Spec with that decision and keeps the line.
# In rerun-lost-screen-rewrites-none the earlier Spec reads Front-end: builder and the rerun replaces
# its export button with a nightly job, so no story has a screen: the rerun rewrites the Spec around
# the job and rewrites the line to Front-end: none.
# In rerun-gained-screen-rewrites-in-place the earlier Spec reads Front-end: none over a nightly export
# job and the rerun adds an export button on the orders list, with the developer answering impeccable
# to the builder question: the rerun rewrites the Spec with the button and rewrites the line to
# Front-end: impeccable, never the recommended builder.
# Run: bash skills/spec/tests/rerun-front-end-graders.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
fails=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

source_grade

keeps="$here/../evals/rerun-keeps-the-front-end-line/graders"
impeccable_kept="$keeps/front-end-impeccable-kept.md"
decision_written="$keeps/rerun-decision-written.md"

rerun_decision='- The exported CSV carries an Order total column.'

expect "the case holds a front-end-impeccable-kept grader" test -f "$impeccable_kept"
expect "the case holds a rerun-decision-written grader" test -f "$decision_written"

# shellcheck disable=SC2034 # read by lib.sh's grade_passes and grade_fails
grader="$impeccable_kept"
grade_passes "a rewritten Spec whose line still reads Front-end: impeccable passes front-end-impeccable-kept" \
  "$(run_with_spec "Front-end: impeccable" "$rerun_decision")"
grade_fails "a rewritten Spec whose line was reset to Front-end: builder fails front-end-impeccable-kept" \
  "$(run_with_spec "Front-end: builder" "$rerun_decision")"
grade_fails "a rewritten Spec whose line was reset to Front-end: none fails front-end-impeccable-kept" \
  "$(run_with_spec "Front-end: none" "$rerun_decision")"
grade_fails "a rewritten Spec that dropped its Front-end: line fails front-end-impeccable-kept" \
  "$(run_with_spec "" "$rerun_decision")"

# shellcheck disable=SC2034 # read by lib.sh's grade_passes and grade_fails
grader="$decision_written"
grade_passes "a Spec naming the Order total column passes rerun-decision-written" \
  "$(run_with_spec "Front-end: impeccable" "$rerun_decision")"
grade_passes "a Spec naming the order total column in lower case passes rerun-decision-written" \
  "$(run_with_spec "Front-end: impeccable" '- The exported CSV gains a column with the order total.')"
grade_fails "the earlier Spec left as it was fails rerun-decision-written" \
  "$(run_with_spec "Front-end: impeccable" "")"

lost="$here/../evals/rerun-lost-screen-rewrites-none/graders"
none_written="$lost/front-end-none-written.md"
lost_decision_written="$lost/rerun-decision-written.md"

nightly_decision='- A nightly job writes the CSV to storage, and the orders list has no export button.'

expect "the lost-screen case holds a front-end-none-written grader" test -f "$none_written"
expect "the lost-screen case holds a rerun-decision-written grader" test -f "$lost_decision_written"

# shellcheck disable=SC2034 # read by lib.sh's grade_passes and grade_fails
grader="$none_written"
grade_passes "a rewritten Spec whose line now reads Front-end: none passes front-end-none-written" \
  "$(run_with_spec "Front-end: none" "$nightly_decision")"
grade_fails "a rewritten Spec whose only line still reads Front-end: builder fails front-end-none-written" \
  "$(run_with_spec "Front-end: builder" "$nightly_decision")"
grade_fails "a rewritten Spec whose only line reads Front-end: impeccable fails front-end-none-written" \
  "$(run_with_spec "Front-end: impeccable" "$nightly_decision")"
grade_fails "a rewritten Spec that dropped its Front-end: line fails front-end-none-written" \
  "$(run_with_spec "" "$nightly_decision")"

# shellcheck disable=SC2034 # read by lib.sh's grade_passes and grade_fails
grader="$lost_decision_written"
grade_passes "a Spec naming the nightly job passes the lost-screen rerun-decision-written" \
  "$(run_with_spec "Front-end: none" "$nightly_decision")"
grade_passes "a Spec naming the Nightly job with a capital passes the lost-screen rerun-decision-written" \
  "$(run_with_spec "Front-end: none" '- Nightly, a job writes the CSV to storage.')"
grade_fails "the earlier Spec left as it was fails the lost-screen rerun-decision-written" \
  "$(run_with_spec "Front-end: builder" "")"

gained="$here/../evals/rerun-gained-screen-rewrites-in-place/graders"
impeccable_written="$gained/front-end-impeccable-written.md"
gained_decision_written="$gained/rerun-decision-written.md"

button_decision='- The orders list carries an export button that downloads the CSV.'

expect "the gained-screen case holds a front-end-impeccable-written grader" test -f "$impeccable_written"
expect "the gained-screen case holds a rerun-decision-written grader" test -f "$gained_decision_written"

# shellcheck disable=SC2034 # read by lib.sh's grade_passes and grade_fails
grader="$impeccable_written"
grade_passes "a rewritten Spec whose line now reads Front-end: impeccable passes front-end-impeccable-written" \
  "$(run_with_spec "Front-end: impeccable" "$button_decision")"
grade_fails "a rewritten Spec whose only line still reads Front-end: none fails front-end-impeccable-written" \
  "$(run_with_spec "Front-end: none" "$button_decision")"
grade_fails "a rewritten Spec whose only line reads the unanswered Front-end: builder fails front-end-impeccable-written" \
  "$(run_with_spec "Front-end: builder" "$button_decision")"
grade_fails "a rewritten Spec that dropped its Front-end: line fails front-end-impeccable-written" \
  "$(run_with_spec "" "$button_decision")"

# shellcheck disable=SC2034 # read by lib.sh's grade_passes and grade_fails
grader="$gained_decision_written"
grade_passes "a Spec naming the export button passes the gained-screen rerun-decision-written" \
  "$(run_with_spec "Front-end: impeccable" "$button_decision")"
grade_passes "a Spec naming the Button with a capital passes the gained-screen rerun-decision-written" \
  "$(run_with_spec "Front-end: impeccable" '- Button on the orders list: Export orders.')"
grade_fails "the earlier Spec left as it was fails the gained-screen rerun-decision-written" \
  "$(run_with_spec "Front-end: none" "")"

[ "$fails" -eq 0 ] && exit 0
exit 1
