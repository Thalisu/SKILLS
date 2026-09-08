#!/usr/bin/env bash
set -euo pipefail

# Dev-only, for maintainers of this repo; not a supported installer (the README says how to install).
# Links every skill under skills/ and vendor/ into the local harness skill directories, links every
# agent definition a skill ships into ~/.claude/agents, then prunes links into this repo whose skill
# or definition is gone:
#   ~/.agents/skills/<name>     -> <repo>/<skills|vendor>/<name>            absolute; Codex and
#                                                                          other Agent Skills
#                                                                          harnesses
#   ~/.claude/skills/<name>     -> ../../.agents/skills/<name>              relative hop; Claude Code
#   ~/.claude/agents/<agent>.md -> <repo>/<skills|vendor>/<name>/AGENT.md   absolute; <agent> is the
#                                                                          `name` in its frontmatter
#   ~/.claude/agents/<file>.md  -> <repo>/<skills|vendor>/<name>/agents/<file>.md
#                                                                          absolute; every markdown
#                                                                          file in the agents folder,
#                                                                          under its own file name
# Same layout as skills/discover-setup/scripts/install.sh, so the two never rewrite each other's
# links. Every entry is a symlink into this repo, so a `git pull` keeps the installed skills current.

REPO="$(cd "$(dirname "$0")/.." && pwd -P)"
AGENTS_SKILLS="$HOME/.agents/skills"
CLAUDE_SKILLS="$HOME/.claude/skills"
CLAUDE_AGENTS="$HOME/.claude/agents"
status=0
declare -A owned=() # every link path this run wrote or confirmed; a link into this repo outside it is pruned

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
  owned["$1"]=1
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

for skill_md in "$REPO"/skills/*/SKILL.md "$REPO"/vendor/*/SKILL.md; do
  [ -f "$skill_md" ] || continue
  dir="$(dirname "$skill_md")"
  name="$(basename "$dir")"
  if [ -e "$REPO/skills/$name/SKILL.md" ] && [ -e "$REPO/vendor/$name/SKILL.md" ]; then
    echo "error: $name exists under both skills/ and vendor/; rename one" >&2
    exit 1
  fi
  link "$AGENTS_SKILLS/$name" "$dir"
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

for entry in "$AGENTS_SKILLS"/* "$CLAUDE_AGENTS"/*.md; do
  [ -L "$entry" ] || continue
  target="$(readlink "$entry")"
  case "$target" in "$REPO"/skills/* | "$REPO"/vendor/*) ;; *) continue ;; esac
  owns "$entry" && continue
  rm "$entry"
  echo "pruned  $entry -> $target"
done
for entry in "$CLAUDE_SKILLS"/*; do
  [ -L "$entry" ] || continue
  name="$(basename "$entry")"
  [ "$(readlink "$entry")" = "../../.agents/skills/$name" ] || continue
  owns "$entry" && continue
  [ -e "$entry" ] && continue
  rm "$entry"
  echo "pruned  $entry -> ../../.agents/skills/$name (dangling)"
done

exit "$status"
