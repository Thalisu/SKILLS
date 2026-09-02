#!/usr/bin/env bash
# run.sh — compliance simulation for the Discovery section (the acceptance gate of PLAN.md).
#
# Usage: run.sh [all|i|ii|iii|iv ...] [--reps N] [--section FILE] [--model NAME] [--keep]
#   --section FILE  section template whose first line is "<!-- discover version: N -->"
#                   (default: skills/discover-setup/CLAUDE-SECTION.md — the current text)
#   --reps N        repetitions per scenario; a scenario is green only at N/N (default 1,
#                   the final gate runs 3)
#   --model NAME    orchestrator model for the headless sessions (default sonnet)
#   --keep          keep green work dirs too (red ones are always kept)
#
# A scenario dir holds setup.sh (lays files into $1), prompt.txt, assert.sh (runs with
# TRANSCRIPT, REPO and SIM_LIB exported; exit 0 = green) and an optional cwd file naming
# the subdirectory the session starts in. The runner turns the laid files into a throwaway
# git repo, renders the section between discover markers in its CLAUDE.md, and runs
# `claude -p` under a sandboxed CLAUDE_CONFIG_DIR: the real ~/.claude (memory, hooks,
# settings, plugins) never loads; credentials are symlinked; only the discover agent and
# skill are wired in. A discover call in the transcript = a tool_use of
# Skill{skill:discover} or Agent/Task{subagent_type:discover}.
# Exit 0 all green · 1 any red · 2 usage or missing dependency.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd -P)"
skills_root="$(cd "$here/../../.." && pwd -P)"
section="$skills_root/discover-setup/CLAUDE-SECTION.md"
reps=1 model=sonnet keep=0 scenarios=()
while [ $# -gt 0 ]; do
  case "$1" in
    --reps) reps="${2:?--reps needs a number}"; shift 2 ;;
    --section) section="${2:?--section needs a file}"; shift 2 ;;
    --model) model="${2:?--model needs a name}"; shift 2 ;;
    --keep) keep=1; shift ;;
    -h|--help) sed -n '2,22p' "$0"; exit 0 ;;
    all) scenarios=(i ii iii iv); shift ;;
    i|ii|iii|iv) scenarios+=("$1"); shift ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done
[ ${#scenarios[@]} -gt 0 ] || scenarios=(i ii iii iv)
[ -f "$section" ] || { echo "no such section file: $section" >&2; exit 2; }
for dep in claude jq rg git; do
  command -v "$dep" >/dev/null 2>&1 || { echo "missing dependency: $dep" >&2; exit 2; }
done
version="$(sed -nE '1s/^<!-- discover version: ([0-9]+(\.[0-9]+)*) -->$/\1/p' "$section")"
[ -n "$version" ] || { echo "no '<!-- discover version: N -->' line in $section" >&2; exit 2; }

sandbox="$(mktemp -d -t discover-sim-config.XXXXXX)"
trap 'rm -rf "$sandbox"' EXIT
mkdir -p "$sandbox/agents" "$sandbox/skills"
if [ -f "$HOME/.claude/.credentials.json" ]; then
  ln -s "$HOME/.claude/.credentials.json" "$sandbox/.credentials.json"
fi
printf '{"hasCompletedOnboarding":true,"bypassPermissionsModeAccepted":true}\n' > "$sandbox/.claude.json"
printf '{}\n' > "$sandbox/settings.json"
ln -s "$skills_root/discover/AGENT.md" "$sandbox/agents/discover.md"
ln -s "$skills_root/discover" "$sandbox/skills/discover"

overall=0 summary=""
for sc in "${scenarios[@]}"; do
  green=0
  for rep in $(seq 1 "$reps"); do
    work="$(mktemp -d -t "discover-sim-$sc.XXXXXX")"
    repo="$work/repo"
    mkdir "$repo"
    bash "$here/$sc/setup.sh" "$repo"
    { echo "<!-- discover:start v=$version -->"; sed '1d' "$section"; echo "<!-- discover:end -->"; } >> "$repo/CLAUDE.md"
    git -C "$repo" init -q
    git -C "$repo" add -A
    git -C "$repo" -c user.email=sim@discover -c user.name=discover-sim commit -qm fixture
    cwdrel="."
    if [ -f "$here/$sc/cwd" ]; then cwdrel="$(cat "$here/$sc/cwd")"; fi

    status=0
    (
      cd "$repo/$cwdrel"
      env -u CLAUDECODE -u CLAUDE_CODE_ENTRYPOINT CLAUDE_CONFIG_DIR="$sandbox" \
        timeout 600 claude -p "$(cat "$here/$sc/prompt.txt")" \
        --output-format stream-json --verbose --max-turns 15 \
        --dangerously-skip-permissions --model "$model"
    ) > "$work/transcript.jsonl" 2> "$work/claude-stderr.log" || status=$?

    reason=""
    if [ "$status" -ne 0 ] && ! grep -q '"type":"result"' "$work/transcript.jsonl"; then
      reason="claude exited $status: $(head -1 "$work/claude-stderr.log")"
    elif out="$(TRANSCRIPT="$work/transcript.jsonl" REPO="$repo" SIM_LIB="$here/lib.sh" \
                bash "$here/$sc/assert.sh" 2>&1)"; then
      green=$((green + 1))
    else
      reason="${out:-assert.sh failed without a reason}"
    fi
    if [ -n "$reason" ]; then
      echo "$sc rep $rep: RED — $reason (kept: $work)"
    else
      echo "$sc rep $rep: green"
      if [ "$keep" = 0 ]; then rm -rf "$work"; else echo "  kept: $work"; fi
    fi
  done
  summary+="$sc $green/$reps"$'\n'
  [ "$green" -eq "$reps" ] || overall=1
done

echo
echo "section v$version · model $model"
printf '%s' "$summary"
exit "$overall"
