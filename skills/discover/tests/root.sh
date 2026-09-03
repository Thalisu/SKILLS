#!/usr/bin/env bash
# root.sh: the report must open with the resolved absolute root, so every relative path
# line in it is unambiguous no matter where the caller sat.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
skill="$(cd "$here/.." && pwd -P)"
fixture="$here/fixture"
expected="ROOT $(cd "$fixture" && pwd -P)"

out="$(cd / && bash "$skill/scripts/discover.sh" --root "$fixture" <<'SPEC'
1 | formatCpf | - | - | no
SPEC
)"
first_line="$(printf '%s\n' "$out" | sed -n 1p)"
if [ "$first_line" != "$expected" ]; then
  echo "FAIL: first line is '$first_line', expected '$expected'" >&2
  exit 1
fi
echo "root: ok"
