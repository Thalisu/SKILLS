#!/usr/bin/env bash
# setup-roundtrip.sh: the versioned-section machinery end to end, no LLM. Project scope: a
# project holding the previous section version must verify as stale, install.sh must replace it,
# and verify.sh must then exit 0 with section=current. User scope: install.sh --user must create
# ~/.claude/CLAUDE.md with the section and leave the project untouched. HOME is redirected to a
# temp dir so the machine-side links and the user-scope CLAUDE.md land there, never on the real machine.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
setup="$(cd "$here/../../discover-setup" && pwd -P)"
template="$setup/CLAUDE-SECTION.md"
fail() { echo "FAIL: $*" >&2; exit 1; }

version="$(sed -nE '1s/^<!-- discover version: ([0-9]+) -->$/\1/p' "$template")"
[ -n "$version" ] || fail "no version line in $template"
prev=$((version - 1))

tmp="$(mktemp -d -t discover-roundtrip.XXXXXX)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/home" "$tmp/project"
{
  echo "# fixture project"
  echo
  echo "<!-- discover:start v=$prev -->"
  sed '1d' "$template"
  echo "<!-- discover:end -->"
} > "$tmp/project/CLAUDE.md"

out="$(HOME="$tmp/home" bash "$setup/scripts/verify.sh" "$tmp/project" || true)"
grep -qx "scope=project" <<<"$out" || fail "pre-install: expected scope=project"
grep -qx "section=stale" <<<"$out" || fail "pre-install: expected section=stale, got: $(grep '^section=' <<<"$out")"
grep -qx "installed_version=$prev" <<<"$out" || fail "pre-install: expected installed_version=$prev"

HOME="$tmp/home" bash "$setup/scripts/install.sh" "$tmp/project" >/dev/null || fail "install.sh failed"

status=0
out="$(HOME="$tmp/home" bash "$setup/scripts/verify.sh" "$tmp/project")" || status=$?
[ "$status" -eq 0 ] || fail "post-install: verify.sh exited $status: $out"
grep -qx "section=current" <<<"$out" || fail "post-install: expected section=current"
grep -qx "installed_version=$version" <<<"$out" || fail "post-install: expected installed_version=$version"
head -1 "$tmp/project/CLAUDE.md" | grep -qx "# fixture project" || fail "install.sh touched content outside the markers"
[ -e "$tmp/home/.claude/CLAUDE.md" ] && fail "project-scope install wrote the user CLAUDE.md"

# user scope: nothing there yet, install creates the file, the project file is left alone
out="$(HOME="$tmp/home" bash "$setup/scripts/verify.sh" --user || true)"
grep -qx "scope=user" <<<"$out" || fail "user pre-install: expected scope=user"
grep -qx "claude_md=$tmp/home/.claude/CLAUDE.md" <<<"$out" || fail "user pre-install: wrong claude_md: $(grep '^claude_md=' <<<"$out")"
grep -qx "section=none" <<<"$out" || fail "user pre-install: expected section=none"

before="$(cat "$tmp/project/CLAUDE.md")"
HOME="$tmp/home" bash "$setup/scripts/install.sh" --user >/dev/null || fail "install.sh --user failed"
status=0
out="$(HOME="$tmp/home" bash "$setup/scripts/verify.sh" --user)" || status=$?
[ "$status" -eq 0 ] || fail "user post-install: verify.sh exited $status: $out"
grep -qx "section=current" <<<"$out" || fail "user post-install: expected section=current"
head -1 "$tmp/home/.claude/CLAUDE.md" | grep -qx "<!-- discover:start v=$version -->" || fail "user CLAUDE.md does not open with the section marker"
[ "$(cat "$tmp/project/CLAUDE.md")" = "$before" ] || fail "install.sh --user touched the project CLAUDE.md"

echo "setup-roundtrip: ok"
