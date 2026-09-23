#!/usr/bin/env bash
# context-usage.sh: the context of this session's orchestrator, read from the harness transcript,
# so the ticket Playbook can write a measured figure into the Ticket's evidence and tickets can
# calibrate its estimates from it. Run from anywhere.
#
#   context-usage.sh            the current Claude Code session, found by $CLAUDE_CODE_SESSION_ID
#   context-usage.sh <file>     a transcript file, for tests and for a session read after the fact
#
# Prints key=value lines: current=<tokens>, the last assistant message's context (input plus cache
# creation plus cache read tokens); peak=<tokens>, the largest over the session; messages=<n>, the
# assistant messages counted; band=<small|medium|large>, where the peak falls (small under 150k,
# medium up to 200k, large beyond), the bands CONTEXT.md gives a Ticket. Lines flagged isSidechain,
# which older harness versions wrote into the same file for forked agents, are left out: only the
# orchestrator's context counts. Then forks=<n>, the forks the orchestrator made, and
# fork_kinds=<kind> <n>[, <kind> <n>]..., the kinds in C byte order and empty at zero: a fork is an
# Agent or Task call, its kind the subagent_type, general-purpose when none is named, or a Skill
# call whose installed $HOME/.claude/skills/<skill>/SKILL.md frontmatter says context: fork, its
# kind the skill's name. A Skill that runs inline is no fork.
# Exit codes: 0 · 2 no transcript: usage, the file missing, or no session id (a harness other than
# Claude Code) · 3 jq missing · 4 no assistant message with usage in the transcript.
set -euo pipefail
command -v jq >/dev/null || { echo "jq is required" >&2; exit 3; }
[ $# -le 1 ] || { echo "usage: context-usage.sh [<transcript.jsonl>]" >&2; exit 2; }
if [ $# -eq 1 ]; then
  file="$1"
else
  id="${CLAUDE_CODE_SESSION_ID:-}"
  [ -n "$id" ] || { echo "no session id: not a Claude Code session" >&2; exit 2; }
  file="$(ls -t "$HOME"/.claude/projects/*/"$id".jsonl 2>/dev/null | head -1 || true)"
fi
[ -n "$file" ] && [ -f "$file" ] || { echo "no transcript at ${file:-~/.claude/projects/*/<session id>.jsonl}" >&2; exit 2; }
read -r current peak messages < <(
  jq -r 'select(.type == "assistant" and .isSidechain != true) | .message.usage | select(. != null)
         | ((.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0))' "$file" 2>/dev/null \
  | awk '{ current = $1; if ($1 > peak) peak = $1; n++ } END { print current + 0, peak + 0, n + 0 }'
)
[ "$messages" -gt 0 ] || { echo "no assistant message with usage in $file" >&2; exit 4; }
if [ "$peak" -lt 150000 ]; then band=small; elif [ "$peak" -le 200000 ]; then band=medium; else band=large; fi
forked_skill() { # $1 skill name: its installed SKILL.md frontmatter says context: fork
  awk 'NR == 1 && $0 != "---" { exit 1 } NR > 1 && $0 == "---" { exit 1 } $0 == "context: fork" { found = 1; exit } END { exit !found }' \
    "$HOME/.claude/skills/$1/SKILL.md" 2>/dev/null
}
fork_kinds="$(
  jq -r 'select(.type == "assistant" and .isSidechain != true) | .message.content[]?
         | select(.type == "tool_use")
         | if .name == "Agent" or .name == "Task" then
             "\(.id)\tagent\t\(.input.subagent_type // "" | if . == "" then "general-purpose" else . end)"
           elif .name == "Skill" then "\(.id)\tskill\t\(.input.skill // "")"
           else empty end' "$file" 2>/dev/null \
  | awk -F'\t' '!seen[$1]++ { print $2 "\t" $3 }' \
  | while IFS=$'\t' read -r via kind; do
      if [ "$via" = agent ] || { [ -n "$kind" ] && forked_skill "$kind"; }; then printf '%s\n' "$kind"; fi
    done | LC_ALL=C sort | uniq -c \
  | awk '{ printf "%s%s %s", (NR > 1 ? ", " : ""), $2, $1; n += $1 } END { printf "\t%d", n + 0 }'
)"
forks="${fork_kinds##*$'\t'}"
fork_kinds="${fork_kinds%$'\t'*}"
printf 'current=%s\npeak=%s\nmessages=%s\nband=%s\nforks=%s\nfork_kinds=%s\n' "$current" "$peak" "$messages" "$band" "$forks" "$fork_kinds"
