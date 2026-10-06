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

# The `setup` Playbook proves each manual step by one whole line (`grep -qx 'product-context=done'`):
# a renamed key, a missing line or a third state leaves a step it can never prove. Which state a
# line carries is each step's own case, so the states are folded before the comparison.
fresh readable
echo "a project" >README.md
commit "first commit"
out="$(bash "$script" 2>"$tmp/readable.err")" || true
err="$(cat "$tmp/readable.err")"
label="in a readable project the check prints the four step lines in their fixed order, each done or missing"
if [ "$(sed -E 's/=(done|missing)$/=<done|missing>/' <<<"$out")" = "impeccable-skill=<done|missing>
product-context=<done|missing>
design-system=<done|missing>
build-path=<done|missing>" ] && [ -z "$err" ]; then ok "$label"; else
  fail "$label"
  dump_out
  echo "      stderr: ${err//$'\n'/$'\n'      }"
fi

if [ "$fails" = 0 ]; then echo "PASS"; else
  echo "$fails failing"
  exit 1
fi
