#!/usr/bin/env bash
# install.sh: wire the discover agent and skills on this machine and render the Discovery section
# into one CLAUDE.md: the project's, or the user's global one. Idempotent.
#
# Usage: install.sh [PROJECT_DIR] [--force]   project scope: PROJECT_DIR/CLAUDE.md (default: current directory)
#        install.sh --user [--force]          user scope:    ~/.claude/CLAUDE.md
#   --force  replace a drifted section (same version, body edited by hand) instead of stopping
#
# Machine side (every scope): only these entries are created or repaired, nothing else is touched:
#   ~/.claude/agents/discover.md                -> <repo>/skills/discover/AGENT.md
#   ~/.agents/skills/{discover,discover-setup}  -> <repo>/skills/<name>            (absolute)
#   ~/.claude/skills/{discover,discover-setup}  -> ../../.agents/skills/<name>      (relative)
# Target side: the installed version is read first (verify.sh), then CLAUDE-SECTION.md is rendered
# between "<!-- discover:start v=N -->" and "<!-- discover:end -->": appended when absent, replaced
# when an older version is there. Nothing else in that CLAUDE.md is read or written.
# Exit 0 done or nothing to do · 2 usage or template error · 5 drifted section without --force.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd -P)"
skills_root="$(cd "$here/../.." && pwd -P)"
template="$here/../CLAUDE-SECTION.md"
scope=project target=. force=0
while [ $# -gt 0 ]; do
  case "$1" in
    --user) scope=user; shift ;;
    --force) force=1; shift ;;
    -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
    -*) echo "unknown argument: $1" >&2; exit 2 ;;
    *) target="$1"; shift ;;
  esac
done
if [ "$scope" = user ]; then target="$HOME/.claude"; mkdir -p "$target"; fi
[ -d "$target" ] || { echo "not a directory: $target" >&2; exit 2; }
version="$(sed -nE '1s/^<!-- discover version: ([0-9]+(\.[0-9]+)*) -->$/\1/p' "$template")"
[ -n "$version" ] || { echo "no '<!-- discover version: N -->' line in $template" >&2; exit 2; }

link() { # $1 link path, $2 target
  if [ -L "$1" ]; then
    [ "$(readlink "$1")" = "$2" ] && { echo "link: ok $1"; return; }
    rm "$1"
  elif [ -e "$1" ]; then
    echo "link: skipped $1 (exists and is not a symlink)"; return
  fi
  mkdir -p "$(dirname "$1")"
  ln -s "$2" "$1"
  echo "link: created $1 -> $2"
}
link "$HOME/.claude/agents/discover.md" "$skills_root/discover/AGENT.md"
for n in discover discover-setup; do
  link "$HOME/.agents/skills/$n" "$skills_root/$n"
  link "$HOME/.claude/skills/$n" "../../.agents/skills/$n"
done

claude_md="$target/CLAUDE.md"
echo "scope: $scope ($claude_md)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
{ echo "<!-- discover:start v=$version -->"; sed '1d' "$template"; echo "<!-- discover:end -->"; } > "$tmp/section"
if [ "$scope" = user ]; then verify="$(bash "$here/verify.sh" --user || true)"
else verify="$(bash "$here/verify.sh" "$target" || true)"; fi
state="$(sed -n 's/^section=//p' <<<"$verify")"
installed="$(sed -n 's/^installed_version=//p' <<<"$verify")"

case "$state" in
  current)
    echo "section: current v=$version (no change)" ;;
  none)
    [ -f "$claude_md" ] || : > "$claude_md"
    { if [ -s "$claude_md" ]; then [ -z "$(tail -c1 "$claude_md")" ] || echo; echo; fi; cat "$tmp/section"; } >> "$claude_md"
    echo "section: none -> current v=$version" ;;
  stale|drifted)
    if [ "$state" = drifted ] && [ "$force" = 0 ]; then
      awk '/^<!-- discover:start v=/ { p = 1 } p { print } /^<!-- discover:end -->$/ { exit }' "$claude_md" | diff -u - "$tmp/section" || true
      echo "section: drifted v=$installed, hand edits inside the markers; re-run with --force to replace them" >&2
      exit 5
    fi
    awk -v section="$tmp/section" '
      /^<!-- discover:start v=/ && !done { skip = 1; while ((getline l < section) > 0) print l; next }
      skip && /^<!-- discover:end -->$/ { skip = 0; done = 1; next }
      !skip { print }' "$claude_md" > "$tmp/claude.md"
    cat "$tmp/claude.md" > "$claude_md"
    echo "section: $state v=$installed -> current v=$version" ;;
  *)
    echo "verify.sh did not report a section state" >&2; exit 2 ;;
esac
