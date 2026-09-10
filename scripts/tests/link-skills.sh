#!/usr/bin/env bash
# link-skills.sh: the contract of scripts/link-skills.sh, exercised against a fixture repo under a
# throwaway HOME, so no link lands on the real machine. Run: bash scripts/tests/link-skills.sh
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
script="$here/../link-skills.sh"
fails=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp/home"
repo="$tmp/repo"
agents_skills="$HOME/.agents/skills"
claude_skills="$HOME/.claude/skills"
claude_agents="$HOME/.claude/agents"

check() { # $1 label, $2 expected exit, $3 actual exit, $4.. lines that must appear (fixed strings); output in $out
  local label="$1" want="$2" rc="$3"; shift 3
  local ok=1 line
  [ "$rc" = "$want" ] || ok=0
  for line in "$@"; do grep -qF -- "$line" <<<"$out" || ok=0; done
  if [ "$ok" = 1 ]; then echo "ok    $label"; else
    echo "FAIL  $label (exit $rc, wanted $want)"; echo "      ${out//$'\n'/$'\n'      }"; fails=$((fails + 1)); fi
}
absent() { # $1 label, $2 line that must not appear
  if grep -qF -- "$2" <<<"$out"; then echo "FAIL  $1 (found: $2)"; fails=$((fails + 1)); else echo "ok    $1"; fi
}
expect() { # $1 label, $2.. a command that must succeed
  local label="$1"; shift
  if "$@"; then echo "ok    $label"; else echo "FAIL  $label"; fails=$((fails + 1)); fi
}
run() { rc=0; out="$(bash "$repo/scripts/link-skills.sh" 2>&1)" || rc=$?; }
links_to() { # $1 link path, $2 target
  [ -L "$1" ] && [ "$(readlink "$1")" = "$2" ]
}
snapshot() { find "$HOME" -mindepth 1 -printf '%p %y %l\n' | sort; }
skill() { # $1 skills|vendor, $2 name: a skill directory with its SKILL.md and Codex metadata
  mkdir -p "$repo/$1/$2/agents"
  printf -- '---\nname: %s\n---\n' "$2" > "$repo/$1/$2/SKILL.md"
  printf 'interface:\n  display_name: %s\n' "$2" > "$repo/$1/$2/agents/openai.yaml"
}

mkdir -p "$repo/scripts" && cp "$script" "$repo/scripts/link-skills.sh"
skill skills alpha
skill skills beta && printf -- '---\nname: beta-agent\ndescription: forked by beta\n---\n' > "$repo/skills/beta/AGENT.md"
skill vendor gamma && printf -- '---\ndescription: no name line\n---\n' > "$repo/vendor/gamma/AGENT.md"

# The first run links every skill into both harness folders and every AGENT.md under its name.
run
check "first run links every entry" 0 "$rc" \
  "linked  $agents_skills/alpha -> $repo/skills/alpha" \
  "linked  $claude_skills/alpha -> ../../.agents/skills/alpha" \
  "linked  $agents_skills/gamma -> $repo/vendor/gamma" \
  "linked  $claude_agents/beta-agent.md -> $repo/skills/beta/AGENT.md" \
  "linked  $claude_agents/gamma.md -> $repo/vendor/gamma/AGENT.md"
expect "the AGENT.md beside the skill file links under its frontmatter name" links_to "$claude_agents/beta-agent.md" "$repo/skills/beta/AGENT.md"
expect "an AGENT.md with no name line links under the skill's name" links_to "$claude_agents/gamma.md" "$repo/vendor/gamma/AGENT.md"
expect "a skill without an AGENT.md gets no agent link" test ! -e "$claude_agents/alpha.md"

# A second run confirms every entry and changes nothing.
before="$(snapshot)"
run
check "second run prints ok for every entry" 0 "$rc" \
  "ok      $agents_skills/beta" "ok      $claude_skills/beta" "ok      $claude_agents/beta-agent.md"
absent "second run links nothing" "linked "
absent "second run prunes nothing" "pruned "
expect "second run changes nothing under HOME" test "$before" = "$(snapshot)"

# A skill removed from the repo loses its links on the next run; the others keep theirs.
rm -r "$repo/vendor/gamma"
run
check "a removed skill is pruned" 0 "$rc" \
  "pruned  $agents_skills/gamma -> $repo/vendor/gamma" \
  "pruned  $claude_agents/gamma.md -> $repo/vendor/gamma/AGENT.md" \
  "pruned  $claude_skills/gamma -> ../../.agents/skills/gamma (dangling)"
expect "the removed skill's agent link is gone" test ! -e "$claude_agents/gamma.md"
expect "another skill's agent link is untouched" links_to "$claude_agents/beta-agent.md" "$repo/skills/beta/AGENT.md"
expect "another skill's directory link is untouched" links_to "$agents_skills/alpha" "$repo/skills/alpha"

# A real file where an agent link would go is left alone, reported, and fails the run.
rm "$claude_agents/beta-agent.md" && echo "the teammate's own agent" > "$claude_agents/beta-agent.md"
run
check "a real file in the way is skipped and fails the run" 1 "$rc" \
  "skipped $claude_agents/beta-agent.md (exists and is not a symlink)"
expect "the real file keeps its content" test "$(cat "$claude_agents/beta-agent.md")" = "the teammate's own agent"
expect "the other entries are still confirmed" grep -qF -- "ok      $agents_skills/alpha" <<<"$out"
rm "$claude_agents/beta-agent.md"

# Every markdown definition in a skill's agents folder links under its own file name; the Codex
# metadata beside them never does, and the prune pass leaves the new links in place.
printf -- '---\nname: beta-reviewer\ndescription: forked by beta\n---\n' > "$repo/skills/beta/agents/beta-reviewer.md"
printf -- '---\nname: beta-security\ndescription: forked by beta\n---\n' > "$repo/skills/beta/agents/beta-security.md"
run
check "definitions in the agents folder are linked under their file names" 0 "$rc" \
  "linked  $claude_agents/beta-reviewer.md -> $repo/skills/beta/agents/beta-reviewer.md" \
  "linked  $claude_agents/beta-security.md -> $repo/skills/beta/agents/beta-security.md"
expect "an agents-folder link is in place after the prune pass" links_to "$claude_agents/beta-reviewer.md" "$repo/skills/beta/agents/beta-reviewer.md"
absent "the prune pass does not undo an agents-folder link" "pruned  $claude_agents/beta-reviewer.md"
absent "the Codex metadata is never linked" "openai.yaml"
expect "no link points at the Codex metadata" test ! -e "$claude_agents/openai.yaml"
before="$(snapshot)"
run
check "a second run confirms the agents-folder links" 0 "$rc" \
  "ok      $claude_agents/beta-reviewer.md" "ok      $claude_agents/beta-security.md"
absent "a second run links no agents-folder entry" "linked "
expect "a second run changes nothing under HOME" test "$before" = "$(snapshot)"

# A definition removed from a current skill's agents folder loses its link; the skill's other
# links and the other skills' links stay. A removed skill loses every link it had.
rm "$repo/skills/beta/agents/beta-security.md"
run
check "a removed definition is pruned" 0 "$rc" \
  "pruned  $claude_agents/beta-security.md -> $repo/skills/beta/agents/beta-security.md"
expect "the removed definition's link is gone" test ! -e "$claude_agents/beta-security.md"
expect "the skill's other agents-folder link is untouched" links_to "$claude_agents/beta-reviewer.md" "$repo/skills/beta/agents/beta-reviewer.md"
expect "the skill's AGENT.md link is untouched" links_to "$claude_agents/beta-agent.md" "$repo/skills/beta/AGENT.md"
expect "another skill's directory link is untouched" links_to "$agents_skills/alpha" "$repo/skills/alpha"
absent "nothing else is pruned" "pruned  $claude_agents/beta-reviewer.md"
rm -r "$repo/skills/beta"
run
check "a removed skill loses its agents-folder links with the rest" 0 "$rc" \
  "pruned  $agents_skills/beta -> $repo/skills/beta" \
  "pruned  $claude_agents/beta-agent.md -> $repo/skills/beta/AGENT.md" \
  "pruned  $claude_agents/beta-reviewer.md -> $repo/skills/beta/agents/beta-reviewer.md" \
  "pruned  $claude_skills/beta -> ../../.agents/skills/beta (dangling)"
expect "the other skill keeps its links" links_to "$claude_skills/alpha" "../../.agents/skills/alpha"

# The real repo, installed into a HOME of its own: every skill and every agent definition on disk,
# searched at any depth rather than where the script looks, comes out linked and resolving.
real="$(cd "$here/../.." && pwd -P)"
export HOME="$tmp/real-home"
rc=0; out="$(bash "$real/scripts/link-skills.sh" 2>&1)" || rc=$?
check "the real repo installs cleanly" 0 "$rc"
while IFS= read -r skill_md; do
  dir="$(dirname "$skill_md")"; name="$(basename "$dir")"
  expect "skill $name is linked for Agent Skills harnesses" links_to "$HOME/.agents/skills/$name" "$dir"
  expect "skill $name resolves for Claude Code" test -f "$HOME/.claude/skills/$name/SKILL.md"
done < <(find "$real/skills" "$real/vendor" -name SKILL.md | sort)
while IFS= read -r definition; do
  if [ "$(basename "$definition")" = AGENT.md ]; then
    agent="$(sed -n 's/^name:[[:space:]]*//p' "$definition" | head -1 | tr -d "\"'")"
    agent="${agent:-$(basename "$(dirname "$definition")")}"
  else
    agent="$(basename "$definition" .md)"
  fi
  expect "agent $agent is linked" links_to "$HOME/.claude/agents/$agent.md" "$definition"
done < <(find "$real/skills" "$real/vendor" \( -name AGENT.md -o -path '*/agents/*.md' \) | sort)
expect "no installed link dangles" test -z "$(find "$HOME" -xtype l)"

if [ "$fails" = 0 ]; then echo "PASS"; else echo "$fails failing"; exit 1; fi
