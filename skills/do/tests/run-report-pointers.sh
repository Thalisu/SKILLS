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

links=0
bad=""
while IFS= read -r file; do
  [ "$file" = "$skill_dir/SKILL.md" ] && continue
  flat="$(tr '\n' ' ' <"$file" | tr -s ' ')"
  n="$(grep -oF '](run-report.md' <<<"$flat" | wc -l)"
  shaped="$(grep -oF 'Read [run-report.md](run-report.md) when ' <<<"$flat" | wc -l)"
  links=$((links + n))
  [ "$n" = "$shaped" ] || bad="$bad ${file#"$skill_dir"/} ($n links, $shaped in the Read-when shape)"
done < <(grep -rlF 'run-report.md' "$skill_dir/references" "$skill_dir/agents" "$skill_dir/SKILL.md")
expect "the do skill links run-report.md from its steps" test "$links" -gt 0
if [ -z "$bad" ]; then
  ok "every link to run-report.md is in the Read-when shape"
else
  fail "every link to run-report.md is in the Read-when shape (not:$bad)"
fi

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

[ "$fails" = 0 ]
