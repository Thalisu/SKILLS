#!/usr/bin/env bash
# land-spec.sh: the landing of a Ticket's branch on its Spec branch, per ADR 0060. The Spec branch
# is meant to be checked out nowhere, so its ref is moved directly and no checkout is touched.
#
#   land-spec.sh <main checkout> <Spec branch> <branch>
#
# Holds the landing lock of ADR 0043 in the git common directory from the checked-out read to the
# end of the ref update, so two runs landing at once never both pass the ancestry check: the loser
# reads moved. The operating system frees the lock when the process ends.
#
# Prints one line: landed <sha> when the Spec branch's ref was moved to the tip of the branch ·
# moved <sha> when the Spec branch holds a commit the branch lacks, <sha> the tip it met ·
# checked-out <worktree> when a worktree, the main checkout included, has the Spec branch checked
# out or is rebasing it, since a ref moved under a checkout leaves its index showing the landing as a reversal ·
# failed <reason> when a ref does not resolve or git refused the update. Only landed writes.
#
# A landing also revokes the review token the Spec's Final integration stored under
# `spec-<feature-slug>`: the Review it vouched for read the Spec branch before this commit, so it
# no longer counts for a resume, which would otherwise land the Ticket's commits on the developer's
# branch with no reviewer having read them.
#
# Exit codes: 0 landed · 1 moved · 2 usage · 3 failed · 4 checked-out.
set -uo pipefail

usage() {
  echo "usage: land-spec.sh <main checkout> <Spec branch> <branch>" >&2
  exit 2
}
failed() {
  echo "failed $1"
  exit 3
}
[ "$#" -eq 3 ] || usage
main="$1" spec="$2" branch="$3"

# The lock file land.sh opens, so a landing here and one on the developer's branch serialize too.
lock="$(git -C "$main" rev-parse --path-format=absolute --git-common-dir)/do-landing.lock"
exec 9>"$lock"
flock 9

# A worktree mid-rebase has a detached HEAD, so only its rebase state's head-name still names the
# branch it is rebasing.
holder=""
while IFS= read -r path; do
  gitdir="$(git -C "$path" rev-parse --absolute-git-dir 2>/dev/null)" || continue
  if [ "$(git -C "$path" symbolic-ref -q HEAD)" = "refs/heads/$spec" ] ||
    [ "$(cat "$gitdir/rebase-merge/head-name" "$gitdir/rebase-apply/head-name" 2>/dev/null | head -n1)" = "refs/heads/$spec" ]; then
    holder="$path"
    break
  fi
done < <(git -C "$main" worktree list --porcelain | awk '/^worktree /{ print substr($0, 10) }')
if [ -n "$holder" ]; then
  echo "checked-out $holder"
  exit 4
fi
tip="$(git -C "$main" rev-parse -q --verify "refs/heads/$spec^{commit}")" ||
  failed "no Spec branch $spec"
new="$(git -C "$main" rev-parse -q --verify "refs/heads/$branch^{commit}")" ||
  failed "no branch $branch"
if ! git -C "$main" merge-base --is-ancestor "$tip" "$new"; then
  echo "moved $tip"
  exit 1
fi
# The tip read above is the old value, so a ref moved since that read fails the update.
said="$(git -C "$main" update-ref "refs/heads/$spec" "$new" "$tip" 2>&1)" ||
  failed "$(grep -m1 -E '^(error|fatal):' <<<"$said" || head -n1 <<<"$said")"
rm -f -- "$(git -C "$main" rev-parse --path-format=absolute --git-common-dir)/do/review-token/spec-${spec#spec/}"
echo "landed $new"
