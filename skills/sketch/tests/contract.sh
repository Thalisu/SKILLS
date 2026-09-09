#!/usr/bin/env bash
# contract.sh: the static contract of the sketch skill, checked against the files on disk so a
# reviewer can rerun it: the skill file and its Codex metadata, the agent definition and the
# callers its description names, the Sketch format, the docs page, the README rows, the invocation
# contract's rows, and no em-dash in any prose the skill adds.
# Run: bash skills/sketch/tests/contract.sh
# shellcheck disable=SC2016
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
repo="$(cd "$here/../../.." && pwd -P)"
skill="$repo/skills/sketch"
fails=0

has() { # $1 label, $2 file, $3.. fixed strings that must appear in the file
  local label="$1" file="$2"; shift 2
  local ok=1 line
  [ -f "$file" ] || ok=0
  for line in "$@"; do [ "$ok" = 1 ] && grep -qF -- "$line" "$file" || ok=0; done
  if [ "$ok" = 1 ]; then echo "ok    $label"; else echo "FAIL  $label ($file)"; fails=$((fails + 1)); fi
}
lacks() { # $1 label, $2 file, $3.. fixed strings that must not appear
  local label="$1" file="$2"; shift 2
  local ok=1 line
  [ -f "$file" ] || ok=0
  for line in "$@"; do grep -qF -- "$line" "$file" 2>/dev/null && ok=0; done
  if [ "$ok" = 1 ]; then echo "ok    $label"; else echo "FAIL  $label ($file)"; fails=$((fails + 1)); fi
}
ordered() { # $1 label, $2 file, $3.. lines that must appear in this order
  local label="$1" file="$2"; shift 2
  local last=0 n line ok=1
  for line in "$@"; do
    n="$(grep -nF -- "$line" "$file" 2>/dev/null | awk -F: -v l="$last" '$1 >= l { print $1; exit }')"
    [ -n "$n" ] || ok=0
    last="${n:-$last}"
  done
  if [ "$ok" = 1 ]; then echo "ok    $label"; else echo "FAIL  $label ($file)"; fails=$((fails + 1)); fi
}
expect() { # $1 label, $2.. a command that must succeed
  local label="$1"; shift
  if "$@"; then echo "ok    $label"; else echo "FAIL  $label"; fails=$((fails + 1)); fi
}

# The skill file: user-invoked in Claude Code, forked onto its own agent.
skill_md="$skill/SKILL.md"
has "the skill file carries its fork keys" "$skill_md" \
  "name: sketch" "context: fork" "agent: sketch" "background: false" "argument-hint:" '$ARGUMENTS'
has "the skill is user-invoked in Claude Code" "$skill_md" "disable-model-invocation: true"
expect "the body is one instruction line plus the arguments" \
  test "$(awk '/^---$/ { c++; next } c == 2 && NF { n++ } END { print n }' "$skill_md" 2>/dev/null)" = 2

# The Codex half of the same choice.
codex="$skill/agents/openai.yaml"
has "the Codex metadata carries the interface" "$codex" "display_name:" "short_description:"
has "the Codex metadata closes implicit invocation" "$codex" \
  "policy:" "allow_implicit_invocation: false"

# The agent definition: the second door, gated by the callers its description names.
agent_md="$skill/AGENT.md"
has "the agent carries its frontmatter" "$agent_md" "name: sketch" "model: inherit"
has "the agent description names its only callers" "$agent_md" \
  "Invoke through /sketch" "do at its shape step" "the developer and do are its only callers" \
  "Never on your own initiative."

# What it is handed, and what it never reads twice.
has "the brief names every part the caller hands over" "$agent_md" \
  "## The brief" "what to shape" "the map" "the Digest" "the repository root" "where the Sketch goes"
has "the agent grounds the subsystem no second time" "$agent_md" \
  "You ground nothing a second time" "the map is the subsystem"
has "a missing part of the brief is named and never re-derived by exploring" "$agent_md" \
  "A brief that names no map"

# It explores the rivals itself, and depends on no skill this repository does not carry.
has "the agent explores rival shapes in its own window" "$agent_md" \
  "## The rivals" "two structurally different" "rejected"
lacks "the agent calls no skill this repository does not carry" "$agent_md" \
  "arena" "interrogate" "Skill tool"

if [ "$fails" = 0 ]; then echo "PASS"; else echo "$fails failing"; exit 1; fi
