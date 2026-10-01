#!/usr/bin/env bash
# land-spec.sh: the landing of a Ticket's branch on its Spec branch, per ADR 0060. The Spec branch
# is checked out nowhere, so its ref is moved directly and no checkout is touched.
#
#   land-spec.sh <main checkout> <Spec branch> <branch>
#
# Prints one line: landed <sha> when the Spec branch's ref was moved to the tip of the branch ·
# failed <reason> when a ref does not resolve or git refused the update, nothing written.
#
# Exit codes: 0 landed · 2 usage · 3 failed.
set -uo pipefail

usage() {
  echo "usage: land-spec.sh <main checkout> <Spec branch> <branch>" >&2
  exit 2
}
[ "$#" -eq 3 ] || usage
main="$1" spec="$2" branch="$3"

tip="$(git -C "$main" rev-parse -q --verify "refs/heads/$spec^{commit}")" ||
  {
    echo "failed no Spec branch $spec"
    exit 3
  }
new="$(git -C "$main" rev-parse -q --verify "refs/heads/$branch^{commit}")" ||
  {
    echo "failed no branch $branch"
    exit 3
  }
# The tip read above is the old value, so a ref moved since that read fails the update.
said="$(git -C "$main" update-ref "refs/heads/$spec" "$new" "$tip" 2>&1)" ||
  {
    echo "failed $(grep -m1 -E '^(error|fatal):' <<<"$said" || head -n1 <<<"$said")"
    exit 3
  }
echo "landed $new"
