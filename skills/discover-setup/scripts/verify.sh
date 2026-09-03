#!/usr/bin/env bash
# verify.sh: report the discover install state of this machine and of one CLAUDE.md target.
#
# Usage: verify.sh [PROJECT_DIR]        project scope: PROJECT_DIR/CLAUDE.md (default: current directory)
#        verify.sh --user               user scope:    ~/.claude/CLAUDE.md
#
# Prints key=value lines. Exit 0 when the section is current, both link chains resolve into this
# repo and every dependency is present; 1 otherwise.
#   template_version=<n>
#   scope=project|user
#   claude_md=<path of the CLAUDE.md that was inspected>
#   section=none|stale|drifted|current    stale = other version · drifted = same version, body edited
#   installed_version=<n>                 only when a marked section exists
#   agent_link=ok|dangling|other|missing  ~/.claude/agents/discover.md (other = resolves outside this repo)
#   skill_links=ok|partial|missing        both hops for discover and discover-setup
#   agent_ref=<git describe --tags --always of the skills repo>
#   deps=rg:ok|missing,ast-grep:ok|missing,jq:ok|missing
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd -P)"
skills_root="$(cd "$here/../.." && pwd -P)"
template="$here/../CLAUDE-SECTION.md"
scope=project target=.
while [ $# -gt 0 ]; do
  case "$1" in
    --user) scope=user; shift ;;
    -h|--help) sed -n '2,17p' "$0"; exit 0 ;;
    -*) echo "unknown argument: $1" >&2; exit 2 ;;
    *) target="$1"; shift ;;
  esac
done
[ "$scope" = user ] && target="$HOME/.claude"
claude_md="$target/CLAUDE.md"
version="$(sed -nE '1s/^<!-- discover version: ([0-9]+(\.[0-9]+)*) -->$/\1/p' "$template")"
[ -n "$version" ] || { echo "no '<!-- discover version: N -->' line in $template" >&2; exit 2; }
echo "template_version=$version"
echo "scope=$scope"
echo "claude_md=$claude_md"
rc=0

section=none installed=""
if [ -f "$claude_md" ]; then
  start="$(grep -nE '^<!-- discover:start v=[0-9.]+ -->$' "$claude_md" | head -1 | cut -d: -f1)"
  if [ -n "$start" ]; then
    end="$(awk -v s="$start" 'NR > s && /^<!-- discover:end -->$/ { print NR; exit }' "$claude_md")"
    installed="$(sed -n "${start}p" "$claude_md" | sed -E 's/.*v=([0-9.]+).*/\1/')"
    if [ -z "$end" ]; then section=drifted
    elif [ "$installed" != "$version" ]; then section=stale
    elif [ "$(sed -n "$((start + 1)),$((end - 1))p" "$claude_md")" = "$(sed '1d' "$template")" ]; then section=current
    else section=drifted; fi
  fi
fi
echo "section=$section"
[ -n "$installed" ] && echo "installed_version=$installed"
[ "$section" = current ] || rc=1

resolves_to() { [ -L "$1" ] && [ -e "$1" ] && [ "$(readlink -f "$1")" = "$(readlink -f "$2")" ]; }
agent="$HOME/.claude/agents/discover.md"
if resolves_to "$agent" "$skills_root/discover/AGENT.md"; then agent_link=ok
elif [ -L "$agent" ] && [ ! -e "$agent" ]; then agent_link=dangling
elif [ -e "$agent" ]; then agent_link=other
else agent_link=missing; fi
echo "agent_link=$agent_link"
[ "$agent_link" = ok ] || rc=1

ok=0
for n in discover discover-setup; do
  resolves_to "$HOME/.agents/skills/$n" "$skills_root/$n" && ok=$((ok + 1))
  resolves_to "$HOME/.claude/skills/$n" "$skills_root/$n" && ok=$((ok + 1))
done
case "$ok" in 4) skill_links=ok ;; 0) skill_links=missing ;; *) skill_links=partial ;; esac
echo "skill_links=$skill_links"
[ "$skill_links" = ok ] || rc=1

echo "agent_ref=$(git -C "$skills_root" describe --tags --always 2>/dev/null || echo unknown)"

deps=""
for d in rg ast-grep jq; do
  if command -v "$d" >/dev/null 2>&1; then deps+="${deps:+,}$d:ok"; else deps+="${deps:+,}$d:missing"; rc=1; fi
done
echo "deps=$deps"
exit "$rc"
