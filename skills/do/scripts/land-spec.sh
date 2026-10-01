#!/usr/bin/env bash
# land-spec.sh: the landing of a Ticket's branch on its Spec branch, per ADR 0060. The Spec branch
# is checked out nowhere, so its ref is moved directly and no checkout is touched.
#
#   land-spec.sh <main checkout> <Spec branch> <branch>
#
# Prints one line: landed <sha> when the Spec branch's ref was moved to the tip of the branch ·
# moved <sha> when the Spec branch holds a commit the branch lacks, <sha> the tip it met ·
# failed <reason> when a ref does not resolve or git refused the update. Only landed writes.
#
# Exit codes: 0 landed · 1 moved · 2 usage · 3 failed.
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
echo "landed $new"
