#!/usr/bin/env bash
# setup-check.sh: the contract of .agents/scripts/setup-check.sh, the check `tickets` reads a
# project's setup steps off, exercised in throwaway directories.
# Run: bash scripts/tests/setup-check.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/lib.sh"
script="$here/../../.agents/scripts/setup-check.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT
mkdir -p "$tmp/home"
export HOME="$tmp/home"

# Outside a repository there is no project to read: `tickets` ends its run on the error line, and a
# step line beside it would cut or skip a Setup ticket for a project nobody read.
mkdir "$tmp/plain" && cd "$tmp/plain" || exit 1
plain="$(pwd -P)"
cd "$plain" || exit 1
refuses "outside a git repository the check names the directory it could not read and exits 2" \
  opens "not a git repository: $plain"
same "outside a git repository the check prints nothing on stdout" ""

if [ "$fails" = 0 ]; then echo "PASS"; else
  echo "$fails failing"
  exit 1
fi
