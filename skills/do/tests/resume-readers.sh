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

exit $((fails > 0))
