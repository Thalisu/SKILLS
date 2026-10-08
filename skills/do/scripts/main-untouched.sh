#!/usr/bin/env bash
# main-untouched.sh: whether a checkout's uncommitted state is what it was when a fork began. A
# snapshot records it before the fork, and a check compares it after the fork returned. Run from
# anywhere.
#
#   main-untouched.sh snapshot <main checkout> <state file>
#   main-untouched.sh check    <main checkout> <state file>
#
# snapshot writes the state file, one record per path git reports as not clean (modified, staged,
# deleted, or untracked and not ignored) with the hash of its working content, then one per file of
# the checkout's git hooks directory and one for its git config, which every worktree of the
# checkout shares and git status never reports, and prints state=<state file> and
# recorded=<n records>. The hooks directory is the git directory's own: one that core.hooksPath
# names is read as any other path, and the setting moving there is a change of the config. A file
# git ignores is outside what the script reads, so a write to one is never reported. The config is
# read as its settings, less the upstream of a branch. The state file sits outside the checkout or
# at a path git ignores in it, since a record git reported would be a change of its own. The state
# path is resolved before that match: a relative path, or one through a symlink, counts where it
# lands. Nothing under .claude/worktrees/ is read, at the snapshot or at the check: the worktrees
# there are the runs' own.
#
# check prints verdict=untouched and changed=0 when the checkout reads as the state file recorded
# it, else verdict=changed, changed=<n> and one file=<path> line per changed file, sorted: a path
# whose working content differs from what the state file holds for it, or a path not clean now
# that the state file does not hold. A path it holds with the same content is never one, whatever
# git now says about it. A hook or the config is printed as an absolute path, a file of the working
# tree as a path from the checkout's root. It writes nothing and removes nothing, the state file
# included.
#
# Exit codes: 0 a snapshot written or a verdict printed · 2 usage, a checkout that is not a git
# working tree, a state file inside the checkout that git does not ignore, or a check with no
# readable state file, which prints no verdict: a missing record is never an untouched checkout.
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

# git reports no path under its own directory, so what the script reads there is keyed by absolute
# path, which no path relative to the checkout can spell. A linked worktree shares both with its
# main checkout, and a checkout made with --separate-git-dir keeps them outside itself.
common="$(git -C "$main" rev-parse --path-format=absolute --git-common-dir)"

# Every run of the feature shares this config, and one that cuts or closes its worktree while a
# fork is out writes or drops the upstream of its own branch there (`git worktree add --track`,
# `git branch -d`). Those two keys are left out, so a sibling run is never read as this fork's write.
settings() {
  local entry
  git config --file "$common/config" --null --list 2>/dev/null |
    while IFS= read -r -d '' entry; do
      case "${entry%%$'\n'*}" in
        branch.*.remote | branch.*.merge) ;;
        *) printf '%s\0' "$entry" ;;
      esac
    done | git hash-object --stdin
}

content() { # $1 a path relative to the checkout, or an absolute one: what stands there now, as one word
  local at="$main/$1"
  case "$1" in /*) at="$1" ;; esac
  if [ "$at" = "$common/config" ] && [ -f "$at" ]; then
    settings
  elif [ -L "$at" ]; then
    readlink -- "$at" | git hash-object --stdin
  elif [ -f "$at" ]; then
    git hash-object --no-filters -- "$at"
  elif [ -d "$at" ]; then
    echo directory
  else
    echo absent
  fi
}
records() { # one NUL-terminated `<content> <path>` record per path git reports as not clean, then per git hook
  local path
  # --no-renames keeps every entry to one path: a rename would print its source as a second field.
  # The run's own worktree and every other run's sit under .claude/worktrees/, which a project is
  # not obliged to ignore.
  # --no-optional-locks: a plain status refreshes the index and rewrites it, which is a write in
  # the checkout this script only reads, and a lock the developer's own git would wait on.
  git -C "$main" --no-optional-locks status --porcelain -z --no-renames --untracked-files=all \
    -- . ':(exclude,top).claude/worktrees' |
    while IFS= read -r -d '' path; do
      path="${path:3}"
      printf '%s %s\0' "$(content "$path")" "$path"
    done
  find "$common/hooks" -mindepth 1 ! -type d -print0 2>/dev/null |
    while IFS= read -r -d '' path; do
      printf '%s %s\0' "$(content "$path")" "$path"
    done
  printf '%s %s\0' "$(content "$common/config")" "$common/config"
}

if [ "$mode" = snapshot ]; then
  # The match runs on the path as it lands: a relative path, or one through a symlink, would
  # otherwise skip the ignore check and sit in the checkout as a change of its own.
  landing="$(realpath -m -- "$state")"
  case "$landing" in
    "$main"/*)
      git -C "$main" check-ignore -q -- "$landing" || {
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

[ -r "$state" ] || {
  echo "no snapshot at $state: nothing to check the checkout against" >&2
  exit 2
}
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
