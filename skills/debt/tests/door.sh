#!/usr/bin/env bash
# door.sh: what SKILL.md has the session do with `gather.sh`: run it first on the slug as typed,
# relay the `line=` value it printed, and decide on its exit code. Exits 3 (no feature folder) and 1
# (no pending debt) each end the run on that one line, forking no agent and writing no file; exit 2
# ends it on the script's stderr line; exit 0 prints `line=` as the status line and hands the
# `item=` records on to the judgment. The script carries every verdict (tests/gather.sh), so these
# cases pin only that the door acts on its exit and never parses a Debt file or a Review itself.
# Run: bash skills/debt/tests/door.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
skill="$here/../SKILL.md"
fails=0

# The text from each exit marker naming the code to the next exit marker of any code: a table row,
# a bullet or a sentence the door gives that exit, wherever it sits, so one exit's stop never
# answers for another's. A marker may name several codes at once (`exit 3 or 1`), and `any other
# exit` stands for 2, the one code the door leaves to it once 0, 1 and 3 are named.
exit_window() { # $1 the exit code; the windows naming it, joined, on stdout
  code="$1" awk '
    BEGIN {
      re = "[Ee]xit(s| code| codes| with| status)? `?[0-9]`?((,|, and|, or| and| or| and exit| or exit) `?[0-9]`?)*|[Aa]ny other exit"
    }
    {
      s = $0; off = 0; k = 0
      while (match(substr(s, off + 1), re)) {
        k++; at[k] = off + RSTART; text[k] = substr(s, at[k], RLENGTH); off = at[k] + RLENGTH - 1
      }
      at[k + 1] = length(s) + 1
      for (i = 1; i <= k; i++) {
        t = text[i]; gsub(/[^0-9]/, "", t)
        if (index(t, ENVIRON["code"]) || (ENVIRON["code"] == "2" && text[i] ~ /[Aa]ny other exit/))
          printf "%s ", substr(s, at[i], at[i + 1] - at[i])
      }
    }
  ' <<<"$body"
}

body="$(body_of "$skill" 2>/dev/null | tr '\n' ' ' | tr -s ' ')"
mapfile -t nothing_written < <(nothing_written_phrasings)
ends=("ends the run" "the run ends" "end the run" "ends on" "end on" "stop" "Stop")
on_that_line=("line=" "that line" "that one line" "the one line" "its line")
no_fork=(
  "forks no agent" "fork no agent" "forking no agent" "no agent is forked" "no agent forked"
  "without forking" "never forks" "forks nothing" "no fork"
)
written=("${nothing_written[@]}" "writes no file" "writing no file" "write no file" "write nothing")
invocation=(
  "bash <skill-dir>/scripts/gather.sh <slug>" "bash <this-skill-dir>/scripts/gather.sh <slug>"
  "bash \"<skill-dir>/scripts/gather.sh\" <slug>" "bash <skill-dir>/scripts/gather.sh \"<slug>\""
)

echo "# SKILL.md: the door runs gather.sh first, on the slug as typed"
flat="$body"
expect "SKILL.md carries a body" test -n "${flat// /}"
carries_any "the door runs gather.sh on the slug" "${invocation[@]}"
carries_any "the slug is handed over as the developer typed it" \
  "as typed" "as the developer typed" "the developer typed" "as the user typed" "verbatim"
g="$(first_at "${invocation[@]}")"
b="$(first_at "bash ")"
expect "gather.sh is the first command the door runs" test "$g" -gt 0 -a "$g" = "$b"
carries_any "the door relays the line= value gather.sh printed" "\`line=\`" "line="

for code in 3 1; do
  echo "# SKILL.md: exit $code ends the run on its one line, forking no agent and writing no file"
  flat="$(exit_window "$code")"
  expect "the door names what it does on exit $code" test -n "${flat// /}"
  carries_any "exit $code ends the run" "${ends[@]}"
  carries_any "exit $code ends it on the one line gather.sh printed" "${on_that_line[@]}"
  carries_any "exit $code forks no agent" "${no_fork[@]}"
  carries_any "exit $code writes no file" "${written[@]}"
done

echo "# SKILL.md: exit 2 ends the run on the script's stderr line"
flat="$(exit_window 2)"
expect "the door names what it does on exit 2" test -n "${flat// /}"
carries_any "exit 2 ends the run" "${ends[@]}"
carries "exit 2 ends it on the script's stderr line" "stderr"

echo "# SKILL.md: exit 0 prints line= as the status line and hands the item= records to the judgment"
flat="$(exit_window 0)"
expect "the door names what it does on exit 0" test -n "${flat// /}"
carries "exit 0 prints the line= value" "line="
carries "it prints that value as the status line" "status line"
carries "exit 0 hands the item= records on" "item="
carries_any "the records go to the judgment step" "judg" "Judg"

echo "# SKILL.md: the door parses no Debt file or Review itself"
flat="$body"
carries_each "the door leaves the Debt files and the Reviews to gather.sh" \
  "parses no" "never parses" "reads no" "never reads" "opens no" "never opens" -- \
  "Debt file" -- \
  "Review"

exit $((fails > 0))
