#!/usr/bin/env bash
# final-state.sh: the state a resumed Final integration picks itself up from, read off the Spec
# branch, its worktree and the files beside the Spec, and never from a run-state file. It only
# reads. Run from anywhere inside the project, the main checkout or a worktree of it.
#
#   final-state.sh <Ticket path>    any Ticket of the Spec, absolute or relative to the main checkout
#
# Prints key=value lines, in this order: spec, spec_branch, spec_upstream, tree (the worktree the
# Final integration runs in), ledger, token_slug (spec-<feature-slug>, the slug the review token of
# the Final integration is stored and revoked under), the lines `final-claim.sh show` prints, and
# worktree (present or absent, as git lists tree); then verdict.
#
# verdict: restart (add the tree when it is absent, then the rebase step).
#
# Exit codes: 0 restart · 2 usage, a Ticket outside a feature folder's issues/, no Spec branch, or
# not a git repository.
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd -P)"

usage() {
  echo "usage: final-state.sh <Ticket path>" >&2
  exit 2
}
[ "$#" = 1 ] || usage

top="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "not a git repository" >&2
  exit 2
}
# A bare main worktree has no working tree to anchor on, and git lists it first all the same.
main="$(git worktree list --porcelain 2>/dev/null |
  awk '/^$/ { exit } /^worktree /{ p = substr($0, 10) } /^bare$/ { p = "" } END { print p }')"
[ -n "$main" ] && [ -d "$main" ] || main="$top"

probe="$(bash "$here/spec-branch.sh" probe "$1")" || exit 2
spec_branch="$(sed -n 's/^spec_branch=//p' <<<"$probe")"
grep -qx 'spec_exists=yes' <<<"$probe" || {
  echo "no Spec branch for $1: no Final integration to resume" >&2
  exit 2
}
claim="$(bash "$here/final-claim.sh" show "$1")" || {
  echo "no feature folder holds $1" >&2
  exit 2
}
folder="$(dirname "$(sed -n 's/^file=//p' <<<"$claim")")"
token_slug="spec-${spec_branch#spec/}"
tree="$main/.claude/worktrees/$token_slug"

echo "spec=$folder/spec.md"
echo "spec_branch=$spec_branch"
echo "spec_upstream=$(sed -n 's/^spec_upstream=//p' <<<"$probe")"
echo "tree=$tree"
echo "ledger=$folder/spec.ledger.md"
echo "token_slug=$token_slug"
echo "$claim"
# grep -q would stop reading at the match and git would die of SIGPIPE on a long list, which
# pipefail turns into a missing worktree.
if git worktree list --porcelain | grep -xF -- "worktree $tree" >/dev/null; then
  echo "worktree=present"
else
  echo "worktree=absent"
fi
echo "verdict=restart"
