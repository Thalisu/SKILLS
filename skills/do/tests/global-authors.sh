#!/usr/bin/env bash
# global-authors.sh: the contract of the global unit and end-to-end authors do ships for a project
# with no Testing Policy installed: each agent carries the policy's agent core byte for byte, the
# Project map the run derives with scripts/project-map.sh, and the sentences of the Playbook that
# dispatch them. Run: bash skills/do/tests/global-authors.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
skill="$here/.."
repo="$(cd "$skill/../.." && pwd -P)"
policy="$repo/skills/testing-policy"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

ok() { echo "ok    $1"; }
fail() { echo "FAIL  $1"; fails=$((fails + 1)); }
has() { # $1 label, $2 file, $3.. fixed strings that must each appear in it
  local label="$1" file="$2"; shift 2
  local s
  for s in "$@"; do grep -qF -- "$s" "$file" 2>/dev/null || { fail "$label (missing: $s)"; return; }; done
  ok "$label"
}

echo "# the agents carry the policy's core unchanged"
version="$(bash "$policy/scripts/render-policy.sh" --version)"
for kind in unit e2e; do
  agent="$skill/agents/global-$kind-test-author.md"
  if [ ! -f "$agent" ]; then fail "global-$kind-test-author ships in do's agents folder"; continue; fi
  ok "global-$kind-test-author ships in do's agents folder"
  core="$(bash "$policy/scripts/render-agent.sh" --core-only "$kind")"
  body="$(cat "$agent")"
  if [ -n "$core" ] && [[ "$body" == *"$core"* ]]; then ok "global-$kind-test-author carries the $kind core byte for byte"
  else fail "global-$kind-test-author carries the $kind core byte for byte"; fi
  has "global-$kind-test-author records the policy version its core came from" "$agent" \
    "<!-- testing-policy:agent v=$version -->"
  has "global-$kind-test-author is named for the Agent tool" "$agent" "name: global-$kind-test-author"
  template="$policy/AGENT-$(tr '[:lower:]' '[:upper:]' <<<"$kind").md"
  has "global-$kind-test-author holds the template's tools" "$agent" "$(grep -m1 '^tools:' "$template")"
  has "global-$kind-test-author names do as its only caller" "$agent" \
    "Dispatched only by the do skill" "Never on your own initiative."
  has "global-$kind-test-author reads its Project map from the file the dispatch names" "$agent" \
    "## Project map" "The Project map is not in this file."
  if grep -q '—' "$agent"; then fail "global-$kind-test-author carries no em-dash"; else ok "global-$kind-test-author carries no em-dash"; fi
done
has "the README links both global authors by name" "$repo/README.md" \
  "ln -s ~/SKILLS/skills/do/agents/global-unit-test-author.md ~/.claude/agents/global-unit-test-author.md" \
  "ln -s ~/SKILLS/skills/do/agents/global-e2e-test-author.md ~/.claude/agents/global-e2e-test-author.md"
has "the invocation contract names both global authors and their caller" "$repo/.agents/invocation.md" \
  '| `global-unit-test-author` | `do`, user-invoked |' '| `global-e2e-test-author` | `do`, user-invoked |'

echo
if [ "$fails" = 0 ]; then echo "all passed"; else echo "$fails failed"; exit 1; fi
