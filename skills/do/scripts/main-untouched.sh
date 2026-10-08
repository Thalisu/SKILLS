#!/usr/bin/env bash
# main-untouched.sh: whether a checkout's uncommitted state is what it was when a fork began. A
# snapshot records it before the fork, and a check compares it after the fork returned. Run from
# anywhere.
#
#   main-untouched.sh snapshot <main checkout> <state file>
#   main-untouched.sh check    <main checkout> <state file>
#
# snapshot writes the state file, one record per path git reports as not clean (modified, staged,
# deleted, or untracked and not ignored) with the hash of its working content, and prints
# state=<state file> and recorded=<n paths>. The state file sits outside the checkout or at a path
# git ignores in it, since a record git reported would be a change of its own. Nothing under
# .claude/worktrees/ is read, at the snapshot or at the check: the worktrees there are the runs' own.
#
# check prints verdict=untouched and changed=0 when the checkout reads as the state file recorded
# it, else verdict=changed, changed=<n> and one file=<path> line per changed file, sorted: a path
# whose working content differs from what the state file holds for it, or a path not clean now
# that the state file does not hold. A path it holds with the same content is never one, whatever
# git now says about it. It writes nothing and removes nothing, the state file included.
#
# Exit codes: 0 a snapshot written or a verdict printed · 2 usage, a checkout that is not a git
# working tree, or a state file inside the checkout that git does not ignore.
set -uo pipefail

usage() {
  echo "usage: main-untouched.sh snapshot|check <main checkout> <state file>" >&2
  exit 2
}
[ "$#" = 3 ] || usage
mode="$1" main="$2" state="$3"
case "$mode" in snapshot | check) ;; *) usage ;; esac

[ "$(git -C "$main" rev-parse --is-inside-work-tree 2>/dev/null)" = true ] || {
  echo "$main is not a git working tree" >&2
  exit 2
}
main="$(git -C "$main" rev-parse --show-toplevel)"

content() { # $1 a path relative to the checkout: what stands there now, as one word
  if [ -L "$main/$1" ]; then
    readlink -- "$main/$1" | git hash-object --stdin
  elif [ -f "$main/$1" ]; then
    git hash-object --no-filters -- "$main/$1"
  elif [ -d "$main/$1" ]; then
    echo directory
  else
    echo absent
  fi
}
records() { # one NUL-terminated `<content> <path>` record per path git reports as not clean
  local path
  # --no-renames keeps every entry to one path: a rename would print its source as a second field.
  # The run's own worktree and every other run's sit under .claude/worktrees/, which a project is
  # not obliged to ignore.
  git -C "$main" status --porcelain -z --no-renames --untracked-files=all \
    -- . ':(exclude,top).claude/worktrees' |
    while IFS= read -r -d '' path; do
      path="${path:3}"
      printf '%s %s\0' "$(content "$path")" "$path"
    done
}

if [ "$mode" = snapshot ]; then
  case "$state" in
    "$main"/*)
      git -C "$main" check-ignore -q -- "$state" || {
        echo "$state is inside $main at a path git does not ignore" >&2
        exit 2
      }
      ;;
  esac
  mkdir -p "$(dirname "$state")" && records >"$state" || {
    echo "cannot write $state" >&2
    exit 2
  }
  echo "state=$state"
  echo "recorded=$(tr -cd '\0' <"$state" | wc -c)"
  exit 0
fi

declare -A before=()
while IFS= read -r -d '' record; do
  before["${record#* }"]="${record%% *}"
done <"$state"

changed=()
for path in "${!before[@]}"; do
  [ "$(content "$path")" = "${before["$path"]}" ] || changed+=("$path")
done
while IFS= read -r -d '' record; do
  [ -n "${before["${record#* }"]+held}" ] || changed+=("${record#* }")
done < <(records)

if [ "${#changed[@]}" = 0 ]; then
  echo "verdict=untouched"
  echo "changed=0"
  exit 0
fi
echo "verdict=changed"
echo "changed=${#changed[@]}"
printf 'file=%s\n' "${changed[@]}" | LC_ALL=C sort
