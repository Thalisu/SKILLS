#!/usr/bin/env bash
set -euo pipefail

# Dev-only, for maintainers of this repo; not a supported installer (the README says how to install).
# Links every skill under skills/ into the local harness skill directories, links every AGENT.md a
# skill ships into ~/.claude/agents, then prunes links into this repo whose skill is gone:
#   ~/.agents/skills/<name>     -> <repo>/skills/<name>            absolute; Codex and other
#                                                                  Agent Skills harnesses
#   ~/.claude/skills/<name>     -> ../../.agents/skills/<name>     relative hop; Claude Code
#   ~/.claude/agents/<name>.md  -> <repo>/skills/<name>/AGENT.md   absolute
# Same layout as skills/discover-setup/scripts/install.sh, so the two never rewrite each other's
# links. Every entry is a symlink into this repo, so a `git pull` keeps the installed skills current.

REPO="$(cd "$(dirname "$0")/.." && pwd -P)"
AGENTS_SKILLS="$HOME/.agents/skills"
CLAUDE_SKILLS="$HOME/.claude/skills"
CLAUDE_AGENTS="$HOME/.claude/agents"
status=0

# A destination that is itself a symlink into this repo would receive the per-skill links inside
# the repo's own skills/ tree; a ~/.claude/skills that is a symlink anywhere breaks the relative hop,
# which is resolved from the directory the link physically sits in.
for dest in "$AGENTS_SKILLS" "$CLAUDE_SKILLS" "$CLAUDE_AGENTS"; do
  [ -L "$dest" ] || continue
  resolved="$(readlink -f "$dest")"
  case "$resolved" in
    "$REPO" | "$REPO"/*)
      echo "error: $dest is a symlink into this repo ($resolved); remove it and re-run" >&2
      exit 1 ;;
  esac
  if [ "$dest" = "$CLAUDE_SKILLS" ]; then
    echo "error: $CLAUDE_SKILLS is a symlink ($resolved); the ../../.agents/skills hop needs a real directory" >&2
    exit 1
  fi
done
mkdir -p "$AGENTS_SKILLS" "$CLAUDE_SKILLS" "$CLAUDE_AGENTS"

link() { # $1 link path, $2 target
  if [ -L "$1" ]; then
    [ "$(readlink "$1")" = "$2" ] && { echo "ok      $1"; return; }
    rm "$1"
  elif [ -e "$1" ]; then
    echo "skipped $1 (exists and is not a symlink)" >&2
    status=1
    return
  fi
  ln -s "$2" "$1"
  echo "linked  $1 -> $2"
}

names=()
for skill_md in "$REPO"/skills/*/SKILL.md; do
  dir="$(dirname "$skill_md")"
  name="$(basename "$dir")"
  names+=("$name")
  link "$AGENTS_SKILLS/$name" "$dir"
  link "$CLAUDE_SKILLS/$name" "../../.agents/skills/$name"
  if [ -f "$dir/AGENT.md" ]; then
    link "$CLAUDE_AGENTS/$name.md" "$dir/AGENT.md"
  fi
done

current() {
  local n
  for n in ${names[@]+"${names[@]}"}; do [ "$n" = "$1" ] && return 0; done
  return 1
}

for entry in "$AGENTS_SKILLS"/* "$CLAUDE_AGENTS"/*.md; do
  [ -L "$entry" ] || continue
  target="$(readlink "$entry")"
  case "$target" in "$REPO"/skills/*) ;; *) continue ;; esac
  current "$(basename "$entry" .md)" && continue
  rm "$entry"
  echo "pruned  $entry -> $target"
done
for entry in "$CLAUDE_SKILLS"/*; do
  [ -L "$entry" ] || continue
  name="$(basename "$entry")"
  [ "$(readlink "$entry")" = "../../.agents/skills/$name" ] || continue
  current "$name" && continue
  [ -e "$entry" ] && continue
  rm "$entry"
  echo "pruned  $entry -> ../../.agents/skills/$name (dangling)"
done

exit "$status"
