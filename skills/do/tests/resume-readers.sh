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
door="$(passage_of "$ticket" "## Door" "## Checklist")"
expect "the Door reads Read [resume.md](resume.md) when the door prints verdict=resume" \
  grep -qF "Read [resume.md](resume.md) when the door prints verdict=resume" <<<"$door"

echo "# ticket.md: a verdict=resume-final run still reaches the stopped Final integration, in final-stopped.md"
senders="$(paragraph_with "$ticket" "verdict=resume-final" all | grep -vF -- "- [ ]" | tr -s ' ')"
expect "ticket.md sends a verdict=resume-final run somewhere" test -n "$senders"
expect "every passage sending a verdict=resume-final run names final-stopped.md" \
  test "$(grep -c "final-stopped.md" <<<"$senders")" -ge 3
expect "no passage sending a verdict=resume-final run names a Resume section" \
  bash -c '! grep -qE "Resume section|the Resume above|Resume of" <<<"$1"' _ "$senders"

readers=("the Door" "The Door" -- "the review step" "The review step" -- "the build step" "The build step"
  -- "the stopped Final integration" "A stopped Final integration" "The stopped Final integration")
conditions=("verdict=resume" -- "route=resume" -- "fails its checks" "fails either check" "fails a check"
  -- "verdict=integration" -- "verdict=ask")
# The opening that counts its readers goes stale the day ticket.md adds one, as the stopped Final
# integration did; a reader trusting the count changes resume.md without checking the one it misses.
reader_count='the three|three (places|readers)|one of three'

echo "# resume.md: its opening names every reader that reaches it and the condition that sends each"
flat="$(awk '/^## /{exit} !/^# / {print}' "$resume" | tr '\n' ' ' | tr -s ' ')"
expect "resume.md has an opening before its first section" grep -q '[a-z]' <<<"$flat"
carries_each "the opening names the Door, the review step, the build step and the stopped Final integration" \
  "${readers[@]}"
carries_each "the opening names each condition: verdict=resume, route=resume, a Builder return failing its checks, verdict=integration, verdict=ask" \
  "${conditions[@]}"
expect "the opening no longer counts its readers as three" bash -c '! grep -qiE "$1" <<<"$2"' _ "$reader_count" "$flat"

echo "# SKILL.md: the references-list entry for resume.md names the same readers and conditions"
skill="$do_dir/SKILL.md"
flat="$(bullets_opening_on "$skill" "[resume.md](references/resume.md)" | tr -s ' ')"
expect "SKILL.md's references list has an entry for resume.md" test -n "$flat"
carries_each "the entry names the Door, the review step, the build step and the stopped Final integration" \
  "${readers[@]}"
carries_each "the entry names each condition: verdict=resume, route=resume, a Builder return failing its checks, verdict=integration, verdict=ask" \
  "${conditions[@]}"
expect "the entry no longer counts its readers as three" bash -c '! grep -qiE "$1" <<<"$2"' _ "$reader_count" "$flat"
skill_links="$(grep -cE '\]\(([^)]*/)?resume\.md\)' "$skill")"
expect "SKILL.md links resume.md in its references-list entry alone" test "$skill_links" = 1

echo "# skills/do: every pointer to resume.md reads Read [resume.md](resume.md) when <condition>"
# A link to the file, under any relative path, is a pointer, except SKILL.md's references-list entry
# and the links resume.md makes to itself. bug-fix.md and refactoring.md keep Resume sections of
# their own, which no pointer here is about.
pointers="$(pointers_to "$do_dir" resume.md)"
expect "the do skill carries at least one pointer to resume.md outside ticket.md" \
  test -n "$(grep -v '^ticket\.md: ' <<<"$pointers")"
pointers_shaped "no pointer to resume.md has another shape" "$do_dir" resume.md 1
stale="$(grep -rnE 'Resume (step |section |line )?(of|in|there)|the Resume (section|above|step)|Resume section' \
  "$do_dir/references" "$do_dir/scripts" "$do_dir/SKILL.md" |
  grep -vF -e "$do_dir/references/bug-fix.md:" -e "$do_dir/references/refactoring.md:" \
    -e "$do_dir/references/resume.md:" | grep -vE "$pointer_shape" | grep -vE "bug-fix's Resume|refactoring's Resume|Resume of \\[bug-fix\\.md\\]|Resume of resume\\.md")"
expect "no file of the do skill still sends a reader to the Resume of ticket.md" test -z "$stale"
[ -z "$stale" ] || echo "      ${stale//$'\n'/$'\n'      }"

exit $((fails > 0))
