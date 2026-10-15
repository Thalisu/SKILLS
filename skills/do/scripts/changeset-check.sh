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
# changeset as one set, each relative to the worktree's root, ./-prefixed or absolute.
#
# Prints verdict=<pass|refused>, changed=<n> and one file=<path> line per changed path, sorted,
# then only on a refusal refused=<n> and one offending=named <path> line per changed path that is
# a named one. A refusal is whole: no part of a refused changeset passes.
#
# Exit codes: 0 pass · 1 refused · 2 usage, a worktree that is not a git working tree, or a state
# file main-untouched.sh cannot read, which prints no verdict: a missing baseline is never a pass.
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd -P)"

usage() {
  echo "usage: changeset-check.sh <worktree> <state file> [<named path>...]" >&2
  exit 2
}
[ "$#" -ge 2 ] || usage
worktree="$1" state="$2"
shift 2

checked="$(bash "$here/main-untouched.sh" check "$worktree" "$state")" || exit 2
root="$(git -C "$worktree" rev-parse --show-toplevel)"

named_key() { # $1 a reported path: the path from the worktree's root
  local path="$1"
  case "$path" in "$root"/*) path="${path#"$root"/}" ;; esac
  while [ "${path#./}" != "$path" ]; do path="${path#./}"; done
  printf '%s' "$path"
}

declare -A named=()
for reported in "$@"; do
  named["$(named_key "$reported")"]=1
done

offence() { # $1 a changed path: prints named, or nothing
  if [ -n "${named[$1]:-}" ]; then echo named; fi
}

changed=()
while IFS= read -r line; do
  case "$line" in file=*) changed+=("${line#file=}") ;; esac
done <<<"$checked"

offending=()
for path in "${changed[@]}"; do
  kind="$(offence "$path")"
  [ -n "$kind" ] && offending+=("$kind $path")
done

if [ "${#offending[@]}" = 0 ]; then
  echo "verdict=pass"
else
  echo "verdict=refused"
fi
echo "changed=${#changed[@]}"
for path in "${changed[@]}"; do
  echo "file=$path"
done
[ "${#offending[@]}" = 0 ] && exit 0
echo "refused=${#offending[@]}"
for line in "${offending[@]}"; do
  echo "offending=$line"
done
exit 1
