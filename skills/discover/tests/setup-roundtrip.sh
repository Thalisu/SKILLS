#!/usr/bin/env bash
# setup-roundtrip.sh — the versioned-section machinery end to end, no LLM: a project holding
# the previous section version must verify as stale, install.sh must replace it, and verify.sh
# must then exit 0 with section=current. HOME is redirected to a temp dir so the machine-side
# links are created there, never on the real machine.
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
grep -qx "section=stale" <<<"$out" || fail "pre-install: expected section=stale, got: $(grep '^section=' <<<"$out")"
grep -qx "installed_version=$prev" <<<"$out" || fail "pre-install: expected installed_version=$prev"

HOME="$tmp/home" bash "$setup/scripts/install.sh" "$tmp/project" >/dev/null || fail "install.sh failed"

status=0
out="$(HOME="$tmp/home" bash "$setup/scripts/verify.sh" "$tmp/project")" || status=$?
[ "$status" -eq 0 ] || fail "post-install: verify.sh exited $status: $out"
grep -qx "section=current" <<<"$out" || fail "post-install: expected section=current"
grep -qx "installed_version=$version" <<<"$out" || fail "post-install: expected installed_version=$version"
head -1 "$tmp/project/CLAUDE.md" | grep -qx "# fixture project" || fail "install.sh touched content outside the markers"

echo "setup-roundtrip: ok"
