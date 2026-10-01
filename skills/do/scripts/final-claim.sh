#!/usr/bin/env bash
# final-claim.sh: the claim one run takes on a Spec's Final integration, a file created beside the
# Spec in the main checkout's scratch. Its presence is the claim: it is made by creating it, never a
# lock a run waits on, per ../../../.agents/scratch.md. Run from anywhere inside the project.
#
#   final-claim.sh claim <Ticket path>    claim the Final integration of the Ticket's Spec
#   final-claim.sh yield <Ticket path>    mark the Spec's one claim yielded, from any Ticket of
#                                         the Spec: its holder stopped and a resume may take it over
#   final-claim.sh show <Ticket path>     the claim's state, read-only
#   final-claim.sh release <Ticket path>  remove the Spec branch through `spec-branch.sh remove`
#                                         and, only when that removed it or found none, delete
#                                         the claim file
#
# <Ticket path> is absolute, or relative to the main checkout. The Spec is the spec.md of the
# feature folder that holds the Ticket's issues/ folder.
#
# claim prints key=value lines: claim (claimed, taken or failed), file (the claim file,
# <feature folder>/spec.integration.claim), then on claimed: spec, spec_branch, spec_upstream, tree
# (the worktree the Final integration runs in, <main checkout>/.claude/worktrees/spec-<slug>) and
# ledger (the Loss ledger of the Spec's rebase, <feature folder>/spec.ledger.md); on taken, the
# file was already there and stays as its claimant wrote it: holder_ticket and claimed_at, that
# file's ticket and claimed_at, then yield_command, the shell-quoted command that yields that
# claim by hand when its holder died without yielding; on failed: reason (no-feature-folder, no-spec-branch or
# not-writable). claimed ends in takeover (yes or no): a claim file already there and yielded is
# taken over, the file then naming this Ticket, and takeover=yes is followed by previous_ticket and
# previous_claimed_at, the holder it replaced, and yielded_at.
#
# The claim file holds key=value lines a reader takes the keys it knows from: ticket (the absolute
# path of the Ticket whose run claimed), spec_branch, tree, claimed_at (UTC, ISO 8601).
#
# The yielded mark is a file beside the claim, <feature folder>/spec.integration.yielded, holding
# yielded_at (UTC, ISO 8601) and yielded_by (the absolute path of the Ticket the yield was called
# with). It is created exclusively, so a claim already yielded keeps its first mark, and the claim
# file is never rewritten by a yield.
#
# yield prints key=value lines: claim (yielded, none when there is no claim file to yield, or
# failed), file, then on yielded: holder_ticket, claimed_at, yielded_at and yielded_by.
#
# show prints key=value lines and writes nothing: claim (none, held or yielded), file, then on held
# and yielded: holder_ticket and claimed_at, and on yielded: yielded_at and yielded_by.
#
# release prints key=value lines: claim (released or held), spec_branch, removed (yes, absent when
# there was no Spec branch left to remove, or no), and on held: reason, the removal's own (unlanded,
# checked-out or no-upstream). A claim file already gone is still released. held deletes nothing: a
# Final integration that stopped keeps its Spec branch and its claim for the run that resumes it.
#
# Exit codes: 0 claimed, released, yielded or shown · 1 taken, held or nothing to yield · 3 failed ·
# 2 usage or not a git repository.
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd -P)"
resolver="$here/../../../.agents/scripts/resolve-feature-folder.sh"

usage() {
  echo "usage: final-claim.sh claim|yield|show|release <Ticket path>" >&2
  exit 2
}

failed() { # $1 reason
  echo "claim=failed"
  echo "file=${file:-}"
  echo "reason=$1"
  exit 3
}

# Sets path, root, folder, file, mark, spec_branch, spec_exists and spec_upstream from the Ticket's path.
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
  mark="$folder/spec.integration.yielded"
}

holder() { # the claim file's holder lines
  echo "holder_ticket=$(sed -n 's/^ticket=//p' "$file")"
  echo "claimed_at=$(sed -n 's/^claimed_at=//p' "$file")"
}

now() { date -u +%Y-%m-%dT%H:%M:%SZ; }

claim_lines() { # $1 tree: what a claim file holds
  printf 'ticket=%s\nspec_branch=%s\ntree=%s\nclaimed_at=%s\n' "$path" "$spec_branch" "$1" "$(now)"
}

cmd_claim() {
  local tree won previous="" takeover=no
  resolve "$1"
  [ "$spec_exists" = yes ] || failed no-spec-branch
  tree="$root/.claude/worktrees/spec-${spec_branch#spec/}"
  # noclobber makes the creation exclusive: of two claims at once, one creates the file.
  if ! (
    set -C
    claim_lines "$tree" >"$file"
  ) 2>/dev/null; then
    [ -f "$file" ] || failed not-writable
    # A yielded claim is taken over by the one claim that renames its mark away. The claim file is
    # then replaced in one rename, so it exists throughout and no first claim slips in.
    won="$mark.$$"
    if ! mv "$mark" "$won" 2>/dev/null; then
      echo "claim=taken"
      echo "file=$file"
      holder
      printf 'yield_command=bash %q yield %q\n' "$here/final-claim.sh" "$(sed -n 's/^ticket=//p' "$file")"
      exit 1
    fi
    takeover=yes
    previous="$(holder | sed 's/^holder_ticket=/previous_ticket=/; s/^claimed_at=/previous_claimed_at=/')
$(grep '^yielded_at=' "$won")"
    if ! { claim_lines "$tree" >"$file.$$" && mv -f "$file.$$" "$file"; } 2>/dev/null; then
      rm -f "$file.$$"
      mv "$won" "$mark"
      failed not-writable
    fi
    rm -f "$won"
  fi
  echo "claim=claimed"
  echo "file=$file"
  echo "spec=$folder/spec.md"
  echo "spec_branch=$spec_branch"
  echo "spec_upstream=$spec_upstream"
  echo "tree=$tree"
  echo "ledger=$folder/spec.ledger.md"
  echo "takeover=$takeover"
  [ -z "$previous" ] || echo "$previous"
}

cmd_show() {
  resolve "$1"
  if [ ! -f "$file" ]; then
    echo "claim=none"
    echo "file=$file"
    return 0
  fi
  if [ -f "$mark" ]; then echo "claim=yielded"; else echo "claim=held"; fi
  echo "file=$file"
  holder
  [ ! -f "$mark" ] || grep -E '^(yielded_at|yielded_by)=' "$mark"
}

cmd_yield() {
  resolve "$1"
  if [ ! -f "$file" ]; then
    echo "claim=none"
    echo "file=$file"
    exit 1
  fi
  # noclobber keeps the first mark: a second yield of the same claim changes nothing.
  (
    set -C
    printf 'yielded_at=%s\nyielded_by=%s\n' "$(now)" "$path" >"$mark"
  ) 2>/dev/null
  [ -f "$mark" ] || failed not-writable
  cmd_show "$1"
}

cmd_release() {
  local removal action removed=yes
  resolve "$1"
  removal="$(bash "$here/spec-branch.sh" remove "$path")"
  action="$(sed -n 's/^action=//p' <<<"$removal")"
  case "$action" in
    removed) ;;
    absent) removed=absent ;;
    *)
      echo "claim=held"
      echo "spec_branch=$spec_branch"
      echo "removed=no"
      echo "reason=$(sed -n 's/^reason=//p' <<<"$removal")"
      exit 1
      ;;
  esac
  rm -f "$file"
  echo "claim=released"
  echo "spec_branch=$spec_branch"
  echo "removed=$removed"
}

[ "$#" = 2 ] || usage
case "$1" in
  claim) cmd_claim "$2" ;;
  yield) cmd_yield "$2" ;;
  show) cmd_show "$2" ;;
  release) cmd_release "$2" ;;
  *) usage ;;
esac
