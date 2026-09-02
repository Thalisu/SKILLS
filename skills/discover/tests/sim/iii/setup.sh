#!/usr/bin/env bash
# Scenario iii — greenfield 5-file repo; adding a small exported util must not force a
# batch. Green: no discover call (a direct rg -w is compliant), the symbol gets created.
set -euo pipefail
mkdir -p "$1/src/utils"
cat > "$1/package.json" <<'EOF'
{ "name": "greenfield", "private": true, "type": "module" }
EOF
cat > "$1/README.md" <<'EOF'
# greenfield
EOF
cat > "$1/src/index.ts" <<'EOF'
import { capitalize } from "./utils/text";

export function greet(name: string): string {
  return `Hello, ${capitalize(name)}`;
}
EOF
cat > "$1/src/utils/text.ts" <<'EOF'
export const capitalize = (value: string): string =>
  value.charAt(0).toUpperCase() + value.slice(1);
EOF
cat > "$1/src/api.ts" <<'EOF'
export function ping(): string {
  return "pong";
}
EOF
