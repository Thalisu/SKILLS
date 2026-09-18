#!/usr/bin/env bash
# write-blob.sh: one path in the worktree given the exact bytes of one blob, through the git index
# rather than a shell redirect into the path. A redirect follows whatever the path is: where the
# Target side of a rebase or merge left a symlink there, the redirect writes through it, landing
# outside the worktree while the symlink itself, and so the index, stay unchanged. This is the same
# trap `contested.sh`'s `stage_file` guards a hunk taken whole against, and the reapply step of
# mechanics.md's `## The integration` uses this script for the same reason on a whole-side blob.
#
#   write-blob.sh <path> <sha>
#
# The blob is staged at mode 100644 and checked out over whatever the path held, symlink or file:
# `git checkout-index` unlinks the destination before it writes, never opening it in place.
#
# Exit 0 once staged and checked out. Exit 1 on a git failure, with nothing written. Exit 2 usage.
set -euo pipefail
[ "$#" -eq 2 ] || { echo "usage: write-blob.sh <path> <sha>" >&2; exit 2; }
path="$1"
sha="$2"
git update-index --add --cacheinfo "100644,$sha,$path" || exit 1
git checkout-index -f -u -- "$path" || exit 1
