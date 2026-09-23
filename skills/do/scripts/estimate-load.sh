#!/usr/bin/env bash
# estimate-load.sh: the context a `do` ticket run is projected to hold, from what the design says the
# run reads, so a maintainer sees what a change to the Playbook cost or saved, and what a Ticket just
# cut is projected to reach, without spending a session on it. Advisory: no skill reads it and it
# gates nothing; the `Context:` line a run writes into the resolved Ticket's evidence stays the ground
# truth that corrects it. Run from inside the project the run would build in.
#
#   estimate-load.sh                        the fixed load, broken down by term
#   estimate-load.sh <the Ticket's path>    the same, then the Ticket's criteria, the Builder's window
#                                           and the band the session's total falls in
#
# Prints key=value lines in tokens, in this order: baseline, reference_chain, door, total, planner,
# builder_base, per_criterion; with a Ticket, criteria, builder and band after them. A file is counted
# at four bytes a token. The lines before total are the session's and sum into it, and total is the
# session's peak, the one figure the band is read from (ADR 0016). The lines after total are the
# Planner's and the Builder's windows, which enter neither: the maintainer reads the planner figure
# against the same thresholds, as ADR 0047 has it, and the script prints no band of its own for it.
# baseline is the harness's own prompt and listings; reference_chain the skill file,
# the Playbook's reference, the shared mechanics, the forks and the conflict loop a step reads beside
# them, the Planner's and the Builder's briefs, the reply reference and the Ticket format. A reference
# a run reads that this array does not name is counted as nothing, and `need` cannot catch it: the
# term under-reports in silence, so a file split out of the mechanics is added here too. door the
# door script's output, the Digest's brief, the Ticket and its Digest. planner a fork's own baseline,
# its definition and brief, the Ticket, the Digest, and the grounding it reads: the project's
# CONTEXT.md, or its CONTEXT-MAP.md and the largest CONTEXT.md the map names, since which one it
# picks is not knowable here, and its ADR titles, then the map, the discover return and the ADR
# bodies, and the Sketch its shape fork returns. builder_base a fork's own baseline, its definition,
# its brief, the build loop and the Plan it builds from; per_criterion what each criterion adds to
# the Builder's window, and builder the two together for the Ticket's criteria. What is not a file
# is a stated allowance below.
# Exit codes: 0 a reading, whatever the band · 2 usage · 3 a term could not be read, named on stderr
set -uo pipefail
[ "$#" -le 1 ] || { echo "usage: estimate-load.sh [<the Ticket's path>]" >&2; exit 2; }
skill="$(cd "$(dirname "$0")/.." && pwd -P)"
root="$(git rev-parse --show-toplevel 2>/dev/null || pwd -P)"

# The Spec's measured figures: a session baseline of about 32k and 17k to 18k per criterion.
baseline=32000
per_criterion=18000
door_output=500
ticket_allowance=1000
# ADR 0024: a run used between 4.0KB and 9.7KB of its Spec and journey, the slice a Digest quotes.
digest_allowance=2500
# The map 5000, the discover return 500 and the bodies of the ADRs the Ticket touches 1000.
ground_allowance=6500
shape_allowance=1000
# The Plan the Builder opens: its map 5000, its Sketch 1000 and its behaviours 500.
plan_allowance=6500

bytes() { # the bytes of every file named
  local sum=0 f
  for f in "$@"; do sum=$((sum + $(wc -c < "$f"))); done
  echo "$sum"
}
tokens() { echo $((($1 + 3) / 4)); }
# Called in the main shell and never inside $(...), where the exit would leave only the subshell.
refuse() { echo "cannot read $1: $2" >&2; exit 3; }
need() { # $1 the term, $2.. the files it counts, each of which must be on disk
  local term="$1" f
  shift
  for f in "$@"; do [ -f "$f" ] || refuse "$term" "no file at $f"; done
}

chain=("$skill/SKILL.md" "$skill/references/ticket.md" "$skill/references/mechanics.md"
  "$skill/references/forks.md" "$skill/references/conflict-loop.md"
  "$skill/references/plan.md" "$skill/references/builder.md"
  "$skill/references/reply.md" "$skill/../../.agents/formats/ticket-format.md")
need reference_chain "${chain[@]}"
reference_chain="$(tokens "$(bytes "${chain[@]}")")"
need door "$skill/references/digest.md"
ticket="${1:-}"
ticket_tokens=$ticket_allowance
digest_tokens=$digest_allowance
if [ -n "$ticket" ]; then
  [ -f "$ticket" ] || refuse criteria "no Ticket at $ticket"
  grep -q '^\*\*Status:\*\*' "$ticket" || refuse criteria "$ticket is not a Ticket: no **Status:** line"
  criteria="$(grep -cE '^- \[[ xX]\] ' "$ticket")"
  [ "$criteria" -gt 0 ] || refuse criteria "$ticket carries no criterion line"
  ticket_tokens="$(tokens "$(bytes "$ticket")")"
  digest="${ticket%.md}.digest.md"
  [ -f "$digest" ] && digest_tokens="$(tokens "$(bytes "$digest")")"
fi
door=$((door_output + $(tokens "$(bytes "$skill/references/digest.md")") + ticket_tokens \
  + digest_tokens))
ground_bytes=0
map="$root/CONTEXT-MAP.md"
if [ -f "$map" ]; then
  mapfile -t contexts < <(grep -oE '\]\([^)]*CONTEXT\.md\)' "$map" | sed -E 's/^\]\(//; s/\)$//')
  [ "${#contexts[@]}" -gt 0 ] || refuse planner "$map names no CONTEXT.md"
  largest=0
  for context in "${contexts[@]}"; do
    need planner "$root/$context"
    size="$(bytes "$root/$context")"
    [ "$size" -gt "$largest" ] && largest=$size
  done
  ground_bytes=$(($(bytes "$map") + largest))
elif [ -f "$root/CONTEXT.md" ]; then
  ground_bytes="$(bytes "$root/CONTEXT.md")"
fi
for adr in "$root"/docs/adr/*; do
  name="${adr##*/}"
  [ -e "$adr" ] && ground_bytes=$((ground_bytes + ${#name} + 1))
done
ground=$(($(tokens "$ground_bytes") + ground_allowance))
total=$((baseline + reference_chain + door))
need planner "$skill/agents/do-planner.md" "$skill/references/plan.md"
planner=$((baseline + $(tokens "$(bytes "$skill/agents/do-planner.md" "$skill/references/plan.md")") \
  + ticket_tokens + digest_tokens + ground + shape_allowance))
need builder_base "$skill/agents/do-builder.md" "$skill/references/builder.md" \
  "$skill/references/build-loop.md"
builder_base=$((baseline + $(tokens "$(bytes "$skill/agents/do-builder.md" "$skill/references/builder.md" \
  "$skill/references/build-loop.md")") + plan_allowance))

printf 'baseline=%s\nreference_chain=%s\ndoor=%s\ntotal=%s\nplanner=%s\nbuilder_base=%s\nper_criterion=%s\n' \
  "$baseline" "$reference_chain" "$door" "$total" "$planner" "$builder_base" "$per_criterion"
[ -n "$ticket" ] || exit 0

builder=$((builder_base + criteria * per_criterion))
# context-usage.sh's band line with its thresholds copied verbatim, read on the session's total, so
# the estimate and the measured Context: line fall in the same bands. Nothing checks the copy.
if [ "$total" -lt 150000 ]; then band=small; elif [ "$total" -le 200000 ]; then band=medium; else band=large; fi
printf 'criteria=%s\nbuilder=%s\nband=%s\n' "$criteria" "$builder" "$band"
