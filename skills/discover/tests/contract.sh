#!/usr/bin/env bash
# contract.sh: the agent's one tool call must pin --root to the repo toplevel, otherwise a
# session started in a subdirectory reports paths that do not resolve from the repo root.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
agent="$here/../AGENT.md"
if ! grep -qF -- '--root "$(git rev-parse --show-toplevel' "$agent"; then
  echo 'FAIL: AGENT.md tool call does not pass --root "$(git rev-parse --show-toplevel …)"' >&2
  exit 1
fi
echo "contract: ok"
