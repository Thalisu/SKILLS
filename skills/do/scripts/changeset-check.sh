#!/usr/bin/env bash
# changeset-check.sh: whether an Implementer's changeset left every test file alone, read against
# the baseline main-untouched.sh took before the Implementer's dispatch. Run from anywhere.
#
#   changeset-check.sh <worktree> <state file> [<named path>...]
#
# <state file> is the one `main-untouched.sh snapshot <worktree> <state file>` wrote before the
# Implementer's first edit. The changeset is the file= set `main-untouched.sh check` prints against
# it: each path from the worktree's root, a hook or the git config as an absolute path. The named
# paths are the ones the test author's report named, its Test changeset and its Promotion
# changeset as one set.
#
# Prints verdict=pass, changed=<n> and one file=<path> line per changed path, sorted.
#
# Exit codes: 0 pass · 2 usage, a worktree that is not a git working tree, or a state file
# main-untouched.sh cannot read, which prints no verdict: a missing baseline is never a pass.
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd -P)"

usage() {
  echo "usage: changeset-check.sh <worktree> <state file> [<named path>...]" >&2
  exit 2
}
[ "$#" -ge 2 ] || usage
worktree="$1" state="$2"

checked="$(bash "$here/main-untouched.sh" check "$worktree" "$state")" || exit 2

changed=()
while IFS= read -r line; do
  case "$line" in file=*) changed+=("${line#file=}") ;; esac
done <<<"$checked"

echo "verdict=pass"
echo "changed=${#changed[@]}"
for path in "${changed[@]}"; do
  echo "file=$path"
done
exit 0
