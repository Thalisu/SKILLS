#!/usr/bin/env bash
# selftest.sh — run discover.sh on tests/fixture and diff the report against tests/expected.txt.
#
# Usage: selftest.sh [--update]
#   --update  rewrite tests/expected.txt from the current output (review the diff before committing)
# Exit 0 when identical, 1 on drift (the diff is printed).
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
skill="$(cd "$here/.." && pwd)"
out="$(bash "$here/discover.sh" --root "$skill/tests/fixture" < "$skill/tests/spec.txt")"
if [ "${1:-}" = --update ]; then
  printf '%s\n' "$out" > "$skill/tests/expected.txt"
  echo "selftest: expected.txt updated ($(wc -l < "$skill/tests/expected.txt") lines)"
  exit 0
fi
if diff -u "$skill/tests/expected.txt" <(printf '%s\n' "$out"); then
  echo "selftest: ok"
else
  echo "selftest: drift" >&2
  exit 1
fi
