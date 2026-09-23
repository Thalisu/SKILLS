#!/usr/bin/env bash
# review-token.sh: the token that ties a Review beside a Ticket to the review step that wrote it.
# Everything else a Review file carries, the commit its `Commit:` header names included, is a fact
# the branch itself carries and anything holding the worktree can copy, so a marker holding one of
# those proves the file's age and not its author. This mints a value nothing else can guess, and
# revokes it again.
#
#   review-token.sh new <slug>      mints a token, stores it, prints it on stdout
#   review-token.sh revoke <slug>   removes the stored token
#
# The store is <the clone's git common dir>/do/review-token/<slug>, shared by the main checkout and
# every worktree of it, so the session writes it and `resume-state.sh` reads it back from the
# worktree. It sits under the git dir rather than in the tree: no worktree checks it out and the
# project never commits it.
#
# The window it exists in is the guarantee, not the path. It is minted at the review step, after
# the Builder has returned, and the build step revokes it before forking another, so at the one
# moment a fork holds a shell in the worktree there is no token on disk to copy into a marker of
# its own. A revoke that quietly missed would hand a fork a live value, so a slug it cannot reduce
# to one name inside the store is refused rather than resolved.
#
# Exit 0 on a mint or a revoke, a revoke with no token on disk included, since the build step runs
# it on every run and a first run has none. Exit 2 on usage: a mode that is neither, the wrong
# number of arguments, a slug that is empty or holds a / or a .., or being run outside a git
# repository. Nothing is written or removed on a refusal.
set -uo pipefail

usage() {
  echo "usage: review-token.sh <new | revoke> <slug>" >&2
  exit 2
}
[ "$#" = 2 ] || usage
mode="$1"
slug="$2"
case "$mode" in new | revoke) ;; *) usage ;; esac

# A slug reaches this script from a Ticket's file name, so it is checked as a name and never
# resolved as a path: `..` climbing back onto a live token, or onto the clone's own HEAD, is a
# write this script would otherwise make on somebody else's behalf.
case "$slug" in
  '' | */* | *..*) usage ;;
  [A-Za-z0-9]*) ;;
  *) usage ;;
esac

common="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || usage
[ -n "$common" ] || usage
store="$common/do/review-token"
token_file="$store/$slug"

if [ "$mode" = revoke ]; then
  rm -f -- "$token_file" || exit 2
  exit 0
fi

mkdir -p -- "$store" || exit 2
# 32 bytes of urandom as hex. od is POSIX where xxd is not, and the value is never derived from the
# branch, the commit or the clock: a token a fork could compute is a token it never has to read.
token="$(head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n')" || exit 2
[ -n "$token" ] || exit 2
umask 077
printf '%s\n' "$token" >"$token_file" || exit 2
printf '%s\n' "$token"
