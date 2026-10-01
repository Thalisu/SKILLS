#!/usr/bin/env bash
# final-claim.sh: the claim one run takes on a Spec's Final integration, a file created beside the
# Spec in the main checkout's scratch. Its presence is the claim: it is made by creating it, never a
# lock a run waits on, per ../../../.agents/scratch.md. Run from anywhere inside the project.
#
#   final-claim.sh claim <Ticket path>    claim the Final integration of the Ticket's Spec
#   final-claim.sh release <Ticket path>  remove the Spec branch through `spec-branch.sh remove`
#                                         and delete the claim file
#
# <Ticket path> is absolute, or relative to the main checkout. The Spec is the spec.md of the
# feature folder that holds the Ticket's issues/ folder.
#
# claim prints key=value lines: claim (claimed, taken or failed), file (the claim file,
# <feature folder>/spec.integration.claim), then on claimed: spec, spec_branch, spec_upstream, tree
# (the worktree the Final integration runs in, <main checkout>/.claude/worktrees/spec-<slug>) and
# ledger (the Loss ledger of the Spec's rebase, <feature folder>/spec.ledger.md); on taken, the
# file was already there and stays as its claimant wrote it: holder_ticket and claimed_at, that
# file's ticket and claimed_at; on failed: reason (no-feature-folder, no-spec-branch or
# not-writable).
#
# The claim file holds key=value lines a reader takes the keys it knows from: ticket (the absolute
# path of the Ticket whose run claimed), spec_branch, tree, claimed_at (UTC, ISO 8601).
#
# release prints key=value lines: claim (released), spec_branch, removed (yes, or absent when there
# was no Spec branch left to remove). A claim file already gone is still released.
#
# Exit codes: 0 claimed or released · 1 taken · 3 failed · 2 usage or not a git repository.
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd -P)"
resolver="$here/../../../.agents/scripts/resolve-feature-folder.sh"

usage() {
  echo "usage: final-claim.sh claim|release <Ticket path>" >&2
  exit 2
}

failed() { # $1 reason
  echo "claim=failed"
  echo "file=${file:-}"
  echo "reason=$1"
  exit 3
}

# Sets path, root, folder, file, spec_branch, spec_exists and spec_upstream from the Ticket's path.
resolve() { # $1 Ticket path
  local probe resolved issues
  probe="$(bash "$here/spec-branch.sh" probe "$1")" || exit 2
  spec_branch="$(sed -n 's/^spec_branch=//p' <<<"$probe")"
  spec_exists="$(sed -n 's/^spec_exists=//p' <<<"$probe")"
  spec_upstream="$(sed -n 's/^spec_upstream=//p' <<<"$probe")"
  [ "$spec_branch" != none ] || failed no-feature-folder
  resolved="$(bash "$resolver" "${spec_branch#spec/}" 2>/dev/null)" || failed no-feature-folder
  root="$(sed -n 's/^root=//p' <<<"$resolved")"
  folder="$(sed -n 's/^folder=//p' <<<"$resolved")"
  [ "$folder" != none ] || failed no-feature-folder
  case "$folder" in /*) ;; *) folder="$root/$folder" ;; esac
  case "$1" in /*) path="$1" ;; *) path="$root/${1#./}" ;; esac
  issues="$(dirname "$path")"
  [ "$(dirname "$issues")" -ef "$folder" ] || failed no-feature-folder
  file="$folder/spec.integration.claim"
}

cmd_claim() {
  local tree
  resolve "$1"
  [ "$spec_exists" = yes ] || failed no-spec-branch
  tree="$root/.claude/worktrees/spec-${spec_branch#spec/}"
  # noclobber makes the creation exclusive: of two claims at once, one creates the file.
  if ! (
    set -C
    printf 'ticket=%s\nspec_branch=%s\ntree=%s\nclaimed_at=%s\n' \
      "$path" "$spec_branch" "$tree" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >"$file"
  ) 2>/dev/null; then
    [ -f "$file" ] || failed not-writable
    echo "claim=taken"
    echo "file=$file"
    echo "holder_ticket=$(sed -n 's/^ticket=//p' "$file")"
    echo "claimed_at=$(sed -n 's/^claimed_at=//p' "$file")"
    exit 1
  fi
  echo "claim=claimed"
  echo "file=$file"
  echo "spec=$folder/spec.md"
  echo "spec_branch=$spec_branch"
  echo "spec_upstream=$spec_upstream"
  echo "tree=$tree"
  echo "ledger=$folder/spec.ledger.md"
}

cmd_release() {
  local removal removed=yes
  resolve "$1"
  removal="$(bash "$here/spec-branch.sh" remove "$path")"
  grep -qx 'action=removed' <<<"$removal" || removed=absent
  rm -f "$file"
  echo "claim=released"
  echo "spec_branch=$spec_branch"
  echo "removed=$removed"
}

[ "$#" = 2 ] || usage
case "$1" in
  claim) cmd_claim "$2" ;;
  release) cmd_release "$2" ;;
  *) usage ;;
esac
