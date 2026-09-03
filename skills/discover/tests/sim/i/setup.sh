#!/usr/bin/env bash
# Scenario i: the user pastes a failing function with its path and asks for the one-line
# fix. Green: no discover call, at most one direct search, the fix lands in the file.
set -euo pipefail
fixture="$(cd "$(dirname "$0")/../../fixture" && pwd -P)"
cp -R "$fixture/." "$1/"
cat > "$1/src/utils/format.ts" <<'EOF'
export const formatCpf = (value: string): string =>
  value.replace(/\D/g, "").replace(/(\d{3})(\d{3})(\d{3})(\d{2})/, "$1.$2.$3-$4");

export const onlyDigits = (value: string): string => value.replace(/\d/g, "");
EOF
