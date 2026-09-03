#!/usr/bin/env bash
# ensure-local-ignored.sh — guarantee `.claude/testing-policy/local/` is ignored by git.
#
# Usage: ensure-local-ignored.sh [PROJECT_DIR]      (default: current directory)
#
# `local/` is the ONLY place an install may write material captured from the project itself — a
# filled example map, a scan report kept for calibration, any note quoting real paths, service
# names or debt. That material names internals, so it never enters history; the generated scripts
# sitting next to it stay tracked, because agent worktrees, CI and the PreToolUse hook only see
# tracked files.
#
# A .gitignore pattern with an inner slash is anchored to its own directory, so the line is always
# written to the repository-root .gitignore, spelled relative to that root. The ignore probe uses
# a phantom path inside the folder: it holds whatever pattern form already covers the directory,
# and works before the folder exists.
#
# Prints one state line — `gitignored: yes`, `gitignore: added <line>` or `not a git repository` —
# preceded by a `warning:` line when tracked files already exist under the folder (reported, never
# `git rm`ed: the user decides). Exit 0 when the folder ends up ignored or the project is not a
# git repo; 1 when the .gitignore cannot be written.
set -uo pipefail

project="${1:-.}"
cd "$project" 2>/dev/null || { echo "no such directory: $project" >&2; exit 1; }
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "not a git repository"; exit 0; }

root="$(git rev-parse --show-toplevel)"
abs="$(pwd -P)/.claude/testing-policy/local"
rel="${abs#"$root"/}"
[ "$rel" = "$abs" ] && rel=".claude/testing-policy/local"

tracked="$(git ls-files -- "$abs" 2>/dev/null | grep -c . || true)"
[ "$tracked" -gt 0 ] && echo "warning: $tracked tracked file(s) under $rel/ — .gitignore does not untrack them"

if git check-ignore -q -- "$abs/x" 2>/dev/null; then
  echo "gitignored: yes"
  exit 0
fi

[ -s "$root/.gitignore" ] && [ -n "$(tail -c1 "$root/.gitignore")" ] && echo >> "$root/.gitignore"
printf '%s/\n' "$rel" >> "$root/.gitignore" || { echo "cannot write $root/.gitignore" >&2; exit 1; }
echo "gitignore: added $rel/"
