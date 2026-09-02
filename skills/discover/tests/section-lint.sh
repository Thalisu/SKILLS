#!/usr/bin/env bash
# section-lint.sh — text invariants of the Discovery section (findings 3, 4, 7, 8, 9 of the
# 2026-09-01 review). Guards the v2 rewrite and keeps later edits from regressing it.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
section="$(cd "$here/../../discover-setup" && pwd -P)/CLAUDE-SECTION.md"
fail() { echo "FAIL: $*" >&2; exit 1; }

grep -q 'from any source' "$section" \
  || fail "exception must accept a name already held 'from any source' (finding 4)"
grep -qiE 'if .?/discover.? errors' "$section" \
  || fail "no fallback line for machines where /discover errors (finding 9)"
grep -qi 'planning reconnaissance' "$section" \
  && fail "'planning reconnaissance' must not be a mandate trigger (finding 3)"
n="$(grep -c 'Discovery:' "$section")"
[ "$n" -eq 1 ] || fail "expected exactly one 'Discovery:' audit format, found $n (finding 8)"
grep -q '~50 files' "$section" \
  || fail "no small-repo carve-out (~50 files) (finding 7)"

echo "section-lint: ok"
