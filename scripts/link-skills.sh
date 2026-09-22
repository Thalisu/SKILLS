#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd -P)"
AGENTS_SKILLS="$HOME/.agents/skills"
CLAUDE_SKILLS="$HOME/.claude/skills"
CLAUDE_AGENTS="$HOME/.claude/agents"
if [ "$#" -gt 1 ]; then
  echo "error: choose one destination; usage: $0 [claude|codex]" >&2
  exit 2
fi
harness="${1:-}"
if [ "$#" -eq 0 ]; then
  printf 'Install skills for Claude or Codex? [claude/codex]: ' >&2
  read -r harness || harness=""
fi
case "$harness" in
  claude | codex) ;;
  *)
    echo "error: choose claude or codex; usage: $0 [claude|codex]" >&2
    exit 2
    ;;
esac

status=0
declare -A owned=() # every link path this run wrote or confirmed; a link into this repo outside it is pruned

# A destination that is itself a symlink into this repo would receive the per-skill links inside
# the repo's own skills/ tree; a ~/.claude/skills that is a symlink anywhere breaks the relative hop,
# which is resolved from the directory the link physically sits in.
destinations=("$AGENTS_SKILLS")
if [ "$harness" = claude ]; then
  destinations+=("$CLAUDE_SKILLS" "$CLAUDE_AGENTS")
fi
for dest in "${destinations[@]}"; do
  [ -L "$dest" ] || continue
  resolved="$(readlink -f "$dest")"
  case "$resolved" in
    "$REPO" | "$REPO"/*)
      echo "error: $dest is a symlink into this repo ($resolved); remove it and re-run" >&2
      exit 1
      ;;
  esac
  if [ "$dest" = "$CLAUDE_SKILLS" ]; then
    echo "error: $CLAUDE_SKILLS is a symlink ($resolved); the ../../.agents/skills hop needs a real directory" >&2
    exit 1
  fi
done
mkdir -p "${destinations[@]}"

link() { # $1 link path, $2 target
  owned["$1"]=1
  if [ -L "$1" ]; then
    [ "$(readlink "$1")" = "$2" ] && {
      echo "ok      $1"
      return
    }
    rm "$1"
  elif [ -e "$1" ]; then
    echo "skipped $1 (exists and is not a symlink)" >&2
    status=1
    return
  fi
  ln -s "$2" "$1"
  echo "linked  $1 -> $2"
}

for skill_md in "$REPO"/skills/*/SKILL.md "$REPO"/vendor/*/SKILL.md; do
  [ -f "$skill_md" ] || continue
  dir="$(dirname "$skill_md")"
  name="$(basename "$dir")"
  if [ -e "$REPO/skills/$name/SKILL.md" ] && [ -e "$REPO/vendor/$name/SKILL.md" ]; then
    echo "error: $name exists under both skills/ and vendor/; rename one" >&2
    exit 1
  fi
  link "$AGENTS_SKILLS/$name" "$dir"
  [ "$harness" = claude ] || continue
  link "$CLAUDE_SKILLS/$name" "../../.agents/skills/$name"
  if [ -f "$dir/AGENT.md" ]; then
    agent="$(sed -n 's/^name:[[:space:]]*//p' "$dir/AGENT.md" | head -1 | tr -d "\"'")"
    agent="${agent:-$name}"
    link "$CLAUDE_AGENTS/$agent.md" "$dir/AGENT.md"
  fi
  for definition in "$dir"/agents/*.md; do
    [ -f "$definition" ] || continue
    link "$CLAUDE_AGENTS/$(basename "$definition")" "$definition"
  done
done

owns() { [ -n "${owned[$1]+x}" ]; } # $1 link path

for dest in "${destinations[@]}"; do
  [ "$dest" = "$CLAUDE_SKILLS" ] && continue
  for entry in "$dest"/*; do
    if [ "$dest" = "$CLAUDE_AGENTS" ] && [[ "$entry" != *.md ]]; then
      continue
    fi
    [ -L "$entry" ] || continue
    target="$(readlink "$entry")"
    case "$target" in "$REPO"/skills/* | "$REPO"/vendor/*) ;; *) continue ;; esac
    owns "$entry" && continue
    rm "$entry"
    echo "pruned  $entry -> $target"
  done
done
if [ "$harness" = claude ]; then
  for entry in "$CLAUDE_SKILLS"/*; do
    [ -L "$entry" ] || continue
    name="$(basename "$entry")"
    [ "$(readlink "$entry")" = "../../.agents/skills/$name" ] || continue
    owns "$entry" && continue
    [ -e "$entry" ] && continue
    rm "$entry"
    echo "pruned  $entry -> ../../.agents/skills/$name (dangling)"
  done
fi

exit "$status"
