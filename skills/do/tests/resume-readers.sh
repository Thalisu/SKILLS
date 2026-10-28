#!/usr/bin/env bash
# resume-readers.sh: resume.md is read only on a ticket run the door finds resumed, by the readers
# its opening names. ticket.md, which every ticket run loads whole, carries no rule for a resume
# and sends a resumed run to resume.md in the one pointer shape, so a fresh run loads no resume text.
# Run: bash skills/do/tests/resume-readers.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
do_dir="$(cd "$here/.." && pwd -P)"
ticket="$do_dir/references/ticket.md"
resume="$do_dir/references/resume.md"
fails=0

pointer_shape='Read \[resume\.md\]\(resume\.md\) when [^ ]'

echo "# ticket.md: a ticket run that is not resumed loads no rule for a resume"
expect "ticket.md has no Resume section" bash -c '! grep -qx "## Resume" "$1"' _ "$ticket"
expect "ticket.md names no resume-tick.sh" bash -c '! grep -qF "resume-tick.sh" "$1"' _ "$ticket"
bare_resume="$(grep -nE 'verdict=resume([^-]|$)' "$ticket" | grep -vE "$pointer_shape")"
expect "ticket.md names verdict=resume only in a pointer to resume.md" test -z "$bare_resume"
misshaped="$(grep -nF 'resume.md' "$ticket" | grep -vE "$pointer_shape")"
expect "every line of ticket.md naming resume.md reads Read [resume.md](resume.md) when <condition>" \
  test -z "$misshaped"

echo "# ticket.md / ## Door: a resumed run is sent to resume.md where the door prints verdict=resume"
door="$(passage_of "$ticket" "## Door" "## A stopped Final integration")"
expect "the Door reads Read [resume.md](resume.md) when the door prints verdict=resume" \
  grep -qF "Read [resume.md](resume.md) when the door prints verdict=resume" <<<"$door"

echo "# ticket.md: a verdict=resume-final run still reaches the stopped Final integration it keeps"
expect "ticket.md carries the stopped Final integration as a section of its own" \
  grep -qx "## A stopped Final integration" "$ticket"
senders="$(paragraph_with "$ticket" "verdict=resume-final" all | grep -vF -- "- [ ]" | tr -s ' ')"
expect "ticket.md sends a verdict=resume-final run somewhere" test -n "$senders"
expect "every passage sending a verdict=resume-final run names the stopped Final integration" \
  test "$(grep -c "A stopped Final integration" <<<"$senders")" -ge 3
expect "no passage sending a verdict=resume-final run names a Resume section" \
  bash -c '! grep -qE "Resume section|the Resume above|Resume of" <<<"$1"' _ "$senders"

readers=("the Door" "The Door" -- "the review step" "The review step" -- "the build step" "The build step")
conditions=("verdict=resume" -- "route=resume" -- "fails its checks" "fails either check" "fails a check")

echo "# resume.md: its opening names every reader that reaches it and the condition that sends each"
flat="$(awk '/^## /{exit} !/^# / {print}' "$resume" | tr '\n' ' ' | tr -s ' ')"
expect "resume.md has an opening before its first section" grep -q '[a-z]' <<<"$flat"
carries_each "the opening names the Door, the review step and the build step" "${readers[@]}"
carries_each "the opening names each condition: verdict=resume, route=resume, a Builder return failing its checks" \
  "${conditions[@]}"

exit $((fails > 0))
