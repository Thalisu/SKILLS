#!/usr/bin/env bash
# run-report-pointers.sh: every pointer to run-report.md under skills/do/ reads
# `Read [run-report.md](run-report.md) when <condition>`, SKILL.md's references-list entry being the
# list and no pointer, and no step sends a Run report line to reply.md for a rule that moved out of
# it. A maintainer finds a conditional pointer by its shape, and a step that still cites reply.md for
# a Run report rule sends the session to a file that no longer holds it.
# Run: bash skills/do/tests/run-report-pointers.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
skill_dir="$here/.."
fails=0

echo "# every link to run-report.md reads Read [run-report.md](run-report.md) when <condition>"

pointers_shaped "every link to run-report.md is in the Read-when shape" "$skill_dir" run-report.md 10

echo "# no step cites reply.md for a Run report rule that moved to run-report.md"

# Every sentence outside reply.md and run-report.md that names the Run report and cites reply.md as
# where its rule lives.
cited="$(for file in "$skill_dir"/references/*.md "$skill_dir"/agents/*.md; do
  case "${file##*/}" in reply.md | run-report.md) continue ;; esac
  awk -v f="${file##*/}" 'BEGIN { RS = "" } {
    g = $0; gsub(/\n/, " ", g); gsub(/  +/, " ", g); n = split(g, s, /\. /)
    for (i = 1; i <= n; i++) if (index(s[i], "Run report") &&
      (index(s[i], "per [reply.md](reply.md)") || index(s[i], "[reply.md](reply.md) fixes") ||
       index(s[i], "[reply.md](reply.md) gives") || index(s[i], "[reply.md](reply.md) puts") ||
       index(s[i], "the Run report it names"))) print f ": " s[i]
  }' "$file"
done)"
if [ -z "$cited" ]; then
  ok "no step cites reply.md for a Run report rule"
else
  fail "no step cites reply.md for a Run report rule (found: $(head -3 <<<"$cited" | cut -c1-160) ... $(wc -l <<<"$cited") in all)"
fi

echo "# ticket.md: no pointer names an item reply.md lacks, and the Final integration lines' message rules sit in reply.md"

ticket="$skill_dir/references/ticket.md"
reply="$skill_dir/references/reply.md"
flat_ticket="$(tr '\n' ' ' <"$ticket" | tr -s ' ')"
stale="$(grep -oE 'item [0-9]+ of \[reply\.md\]' <<<"$flat_ticket" | sort -u | tr '\n' ',')"
if [ -z "$stale" ]; then
  ok "ticket.md names no item of reply.md by number for a rule that moved to run-report.md"
else
  fail "ticket.md names no item of reply.md by number for a rule that moved to run-report.md (found: $stale)"
fi
stale="$(grep -oE 'Integration line of item [0-9]+|Review return of item [0-9]+' <<<"$flat_ticket" | sort -u | tr '\n' ',')"
if [ -z "$stale" ]; then
  ok "ticket.md cites no Run section item number of run-report.md for the review file"
else
  fail "ticket.md cites no Run section item number of run-report.md for the review file (found: $stale)"
fi
expect "reply.md has a Final integration lines section a run without --auto reads" \
  grep -qx '## Final integration lines' "$reply"
expect "ticket.md sends the Final integration lines to that section of reply.md" \
  grep -qF 'reply.md#final-integration-lines' <<<"$flat_ticket"
section="$(tr '\n' ' ' <<<"$(passage_of "$reply" '## Final integration lines' '## ')" | tr -s ' ')"
expect "that section is found" grep -q "[a-z]" <<<"$section"
flat="$section"
carries "the section places the lines in the message: a run that built no Ticket, the Push: line and the repositories lines under Next step" \
  "built no Ticket and took no claim" "\`Push:\`" "\`repositories\`" "## Next step" "Yours:"

[ "$fails" = 0 ]
