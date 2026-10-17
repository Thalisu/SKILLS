#!/usr/bin/env bash
# changeset-check.sh: whether an Implementer's changeset left every test file alone, read against
# the baseline main-untouched.sh took before the Implementer's dispatch. Run from anywhere.
#
#   changeset-check.sh <worktree> <state file> <digest> [<named path>...]
#
# <state file> is the one `main-untouched.sh snapshot <worktree> <state file>` wrote before the
# Implementer's first edit, and <digest> the digest= line that snapshot printed, which the caller
# kept in its own window: the state file sits where the Implementer can reach it, and a state file
# rewritten after the snapshot (re-snapshotted over a bent test) no longer matches it. The changeset is the file= set `main-untouched.sh check` prints against
# it: each path from the worktree's root, a hook or the git config as an absolute path. The named
# paths are the ones the test author's report named, its Test changeset and its Promotion
# changeset as one set, each relative to the worktree's root, ./-prefixed or absolute.
#
# Prints verdict=<pass|refused>, changed=<n> and one file=<path> line per changed path, sorted,
# then only on a refusal refused=<n> and one offending=<classes|named|test> <path> line per
# offending path, sorted: classes for the Testing Policy's skip-patterns.sh or
# skip-patterns.local.sh, git for the git config or a hook (the only paths main-untouched.sh
# prints as absolute: a hook runs inside the Builder's own commit and the config outlives the run
# in the checkout every worktree shares), named for a named path, test for any other path
# test-files.sh classifies as a test file of the worktree, under the policy's classes or the
# built-in list, either one, and index for an index-flag:<path> entry, a tracked path that now
# carries a skip-worktree or assume-unchanged flag the snapshot did not record, which hides an edit
# to it from git status. A refusal is whole: no part of a refused
# changeset passes.
#
# Exit codes: 0 pass · 1 refused · 2 usage, a worktree that is not a git working tree, or a state
# file main-untouched.sh cannot read or whose sha256 is not <digest>, which prints no verdict: a
# missing or rewritten baseline is never a pass.
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd -P)"

usage() {
  echo "usage: changeset-check.sh <worktree> <state file> <digest> [<named path>...]" >&2
  exit 2
}
[ "$#" -ge 3 ] || usage
worktree="$1" state="$2" digest="$3"
shift 3

[ -r "$state" ] && [ "$(sha256sum <"$state" | cut -d' ' -f1)" = "$digest" ] || {
  echo "$state does not match the digest the snapshot printed: the baseline was rewritten or is gone" >&2
  exit 2
}

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

offence() { # $1 a changed path: prints classes, named, test, or nothing
  # Rooted at "/" rather than at $root: a directory named spec or tests above the worktree must not
  # turn every production path into a test file.
  local abs="/$1"
  case "$1" in /*) abs="$1" ;; esac
  if [ -n "${classes_files[$1]:-}" ]; then
    echo classes
  elif [ "${1#index-flag:}" != "$1" ]; then
    echo index
  elif [ "$abs" = "$1" ]; then
    echo git
  elif [ -n "${named[$1]:-}" ]; then
    echo named
  elif is_test_file "$abs" || { classes=built-in; is_test_file "$abs"; }; then
    # The policy's classes are narrow (no snapshots, no fixtures), so a path is a test when either
    # the policy or the built-in list says so. offence() runs in a command substitution: setting
    # classes here does not leak into the caller.
    echo test
  fi
}

changed=()
while IFS= read -r line; do
  case "$line" in file=*) changed+=("${line#file=}") ;; esac
done <<<"$checked"

# A classes file the changeset touched is never sourced: it runs as code inside this check, so a
# rewritten one could classify nothing as a test, or print a pass and exit before the verdict.
declare -A classes_files=(
  [.claude/testing-policy/skip-patterns.sh]=1
  [.claude/testing-policy/skip-patterns.local.sh]=1
)
classes_touched=no
for path in "${changed[@]}"; do
  [ -n "${classes_files[$path]:-}" ] && classes_touched=yes
done

# shellcheck source=test-files.sh
. "$here/test-files.sh"
if [ "$classes_touched" = yes ]; then
  classes=built-in
else
  test_classes "$root"
fi

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
