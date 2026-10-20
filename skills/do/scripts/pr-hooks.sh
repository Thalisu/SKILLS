#!/usr/bin/env bash
# pr-hooks.sh: whether the hooks and the config of the git directory a pr run tree shares with its
# fixer worktrees are what they were before the fixers were forked. A fixer can write into that
# directory from its own worktree, and the session's push runs with the developer's credentials.
#
#   pr-hooks.sh snapshot <run tree>
#   pr-hooks.sh verify   <run tree> <hooks digest> <config digest>
#
# snapshot prints `hooks=<digest>` and `config=<digest>`, which the caller keeps in its own memory,
# out of any fixer's reach. hooks covers every file and symlink of the common git directory's hooks
# directory: its path, its executable bit and its content or link target. config covers the common
# directory's config file as its settings, less the upstream of a branch (`git worktree add --track`
# and `git branch -d` write it for the run's own branches), and the run tree's own config.worktree
# when it has one. Unlike main-untouched.sh, it reads no working tree file, since the developer
# edits their checkout while a run goes on.
#
# verify prints `unchanged` when both digests still match, else one line per digest that differs,
# `changed hooks` then `changed config`. It writes nothing.
#
# Exit codes: 0 a snapshot printed or both digests match · 1 verify found a change · 2 usage, or a
# run tree that is not a git work tree, with nothing on stdout.
set -uo pipefail

usage() {
  echo "usage: pr-hooks.sh snapshot <run tree> | verify <run tree> <hooks digest> <config digest>" >&2
  exit 2
}
[ "$#" -ge 2 ] || usage
mode="$1" tree="$2"
case "$mode" in
  snapshot) [ "$#" = 2 ] || usage ;;
  verify) [ "$#" = 4 ] || usage ;;
  *) usage ;;
esac
[ "$(git -C "$tree" rev-parse --is-inside-work-tree 2>/dev/null)" = true ] || usage

common="$(git -C "$tree" rev-parse --path-format=absolute --git-common-dir)"
own="$(git -C "$tree" rev-parse --path-format=absolute --git-dir)"

hooks_digest() {
  local path kind
  find "$common/hooks" -mindepth 1 ! -type d -print0 2>/dev/null | LC_ALL=C sort -z |
    while IFS= read -r -d '' path; do
      if [ -L "$path" ]; then
        kind="link $(readlink -- "$path")"
      else
        kind="file $([ -x "$path" ] && echo x || echo -) $(git hash-object --no-filters -- "$path")"
      fi
      printf '%s\0%s\0' "${path#"$common/hooks/"}" "$kind"
    done | git hash-object --stdin
}

settings_digest() { # $1 a config file: its settings as git reads them, hashed; absent for none
  local entry
  [ -f "$1" ] || {
    echo absent
    return
  }
  git config --file "$1" --null --list 2>/dev/null |
    while IFS= read -r -d '' entry; do
      case "${entry%%$'\n'*}" in
        branch.*.remote | branch.*.merge) ;;
        *) printf '%s\0' "$entry" ;;
      esac
    done | git hash-object --stdin
}

config_digest() {
  printf '%s\0%s\0' "$(settings_digest "$common/config")" "$(settings_digest "$own/config.worktree")" |
    git hash-object --stdin
}

if [ "$mode" = snapshot ]; then
  echo "hooks=$(hooks_digest)"
  echo "config=$(config_digest)"
  exit 0
fi

rc=0
[ "$(hooks_digest)" = "$3" ] || {
  echo "changed hooks"
  rc=1
}
[ "$(config_digest)" = "$4" ] || {
  echo "changed config"
  rc=1
}
[ "$rc" = 0 ] && echo unchanged
exit "$rc"
