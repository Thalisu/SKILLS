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
# feature folder that holds the Ticket's issues/ folder, in the Home repository when the session
# runs in another repository of the feature.
#
# The four names beside the Spec are spec.integration.claim, spec.integration.yielded,
# spec.ledger.md and spec.review.md for a Ticket with no **Build repository:** line. A Ticket that
# carries one gets spec.<key>.integration.claim, spec.<key>.integration.yielded,
# spec.<key>.ledger.md and spec.<key>.review.md, <key> being ticket-read.sh's repository_key_of,
# so each repository of a feature holds a claim of its own. The Spec branch and the worktree are
# always the session's repository's.
#
# claim prints key=value lines: claim (claimed, taken or failed), file (the claim file), then on
# claimed: spec, spec_branch, spec_upstream, tree (the worktree the Final integration runs in,
# <main checkout>/.claude/worktrees/spec-<slug>), ledger (the Loss ledger of the Spec's rebase) and
# review_file (the Review beside the Spec); on taken, the file was already there and stays as its
# claimant wrote it: holder_ticket and claimed_at, that file's ticket and claimed_at, then
# yield_command, the shell-quoted command that yields that claim by hand when its holder died
# without yielding; on failed: reason (no-feature-folder,
# no-spec-branch, no-upstream, a Spec branch whose upstream is empty or names no local branch,
# ambiguous-repository, a Ticket with two **Build repository:** lines, or not-writable). claimed
# ends in takeover (yes or no): a claim file already there and yielded is
# taken over, the file then naming this Ticket, and takeover=yes is followed by previous_ticket and
# previous_claimed_at, the holder it replaced, and yielded_at.
#
# The claim file holds key=value lines a reader takes the keys it knows from: ticket (the absolute
# path of the Ticket whose run claimed), spec_branch, tree, claimed_at (UTC, ISO 8601).
#
# The yielded mark is a file beside the claim, holding
# yielded_at (UTC, ISO 8601) and yielded_by (the absolute path of the Ticket the yield was called
# with). It is created exclusively, so a claim already yielded keeps its first mark, and the claim
# file is never rewritten by a yield.
#
# yield prints key=value lines: claim (yielded, none when there is no claim file to yield, or
# failed), file, then on yielded: the lines show prints after them.
#
# show prints key=value lines and writes nothing: claim (none, held or yielded), file, ledger and
# review_file, then on held and yielded: holder_ticket and claimed_at, and on yielded: yielded_at
# and yielded_by.
#
# release prints key=value lines: claim (released or held), spec_branch, removed (yes, absent when
# there was no Spec branch left to remove, or no), and on held: reason, the removal's own (unlanded,
# checked-out or no-upstream). A released claim's yielded mark is deleted with it. A claim file
# already gone is still released. held deletes nothing: a Final integration that stopped keeps its
# Spec branch and its claim for the run that resumes it.
#
# Exit codes: 0 claimed, released, yielded or shown · 1 taken, held or nothing to yield · 3 failed ·
# 2 usage or not a git repository.
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd -P)"
resolver="$here/../../../.agents/scripts/resolve-feature-folder.sh"
# shellcheck source=skills/do/scripts/ticket-read.sh
. "$here/ticket-read.sh"

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

# The one place the names beside the Spec are composed: a feature of one repository keeps the
# unkeyed names, and each Build repository of a feature gets its own under its key, so one
# repository's claim, ledger and Review are never read as another's.
# shellcheck disable=SC2154 # repository_key_of sets word.
final_names() { # $1 the feature folder, $2 the Ticket's absolute path: sets file, mark, ledger and review_file
  repository_key_of "$2"
  [ "$word" != ambiguous ] || failed ambiguous-repository
  local stem="$1/spec${word:+.$word}"
  file="$stem.integration.claim"
  mark="$stem.integration.yielded"
  ledger="$stem.ledger.md"
  review_file="$stem.review.md"
}

# Sets path, main, folder, file, mark, ledger, review_file, spec_branch, spec_exists and
# spec_upstream from the Ticket's path. The folder is the Home repository's, where the Ticket sits;
# the Spec branch and main are the session's repository's.
resolve() { # $1 Ticket path
  local probe resolved issues
  probe="$(bash "$here/spec-branch.sh" probe "$1")" || exit 2
  spec_branch="$(sed -n 's/^spec_branch=//p' <<<"$probe")"
  spec_exists="$(sed -n 's/^spec_exists=//p' <<<"$probe")"
  spec_upstream="$(sed -n 's/^spec_upstream=//p' <<<"$probe")"
  [ "$spec_branch" != none ] || failed no-feature-folder
  main="$(main_of .)"
  case "$1" in /*) path="$1" ;; *) path="$main/${1#./}" ;; esac
  resolved="$(cd "$(home_root "$path" "$main")" 2>/dev/null && bash "$resolver" "${spec_branch#spec/}" 2>/dev/null)" || failed no-feature-folder
  folder="$(sed -n 's/^folder=//p' <<<"$resolved")"
  [ "$folder" != none ] || failed no-feature-folder
  case "$folder" in /*) ;; *) folder="$(sed -n 's/^root=//p' <<<"$resolved")/$folder" ;; esac
  issues="$(dirname "$path")"
  [ "$(dirname "$issues")" -ef "$folder" ] || failed no-feature-folder
  final_names "$folder" "$path"
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
  # Nothing to integrate into: the claim is refused before it creates the file.
  [ -n "$spec_upstream" ] && git -C "$main" show-ref --verify --quiet "refs/heads/$spec_upstream" || failed no-upstream
  tree="$main/.claude/worktrees/spec-${spec_branch#spec/}"
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
  echo "ledger=$ledger"
  echo "review_file=$review_file"
  echo "takeover=$takeover"
  [ -z "$previous" ] || echo "$previous"
}

cmd_show() {
  resolve "$1"
  if [ ! -f "$file" ]; then echo "claim=none"; elif [ -f "$mark" ]; then echo "claim=yielded"; else echo "claim=held"; fi
  echo "file=$file"
  echo "ledger=$ledger"
  echo "review_file=$review_file"
  [ -f "$file" ] || return 0
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
  rm -f "$file" "$mark"
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
