#!/usr/bin/env bash
# fixed-point.sh: the door of do-code-review, the facts of the diff that a script can observe, so the
# orchestrator reads them off one run and a reviewer can rerun them. Run from anywhere inside the
# project.
#
#   fixed-point.sh            the fixed point is the merge-base with the base branch: the remote's
#                             HEAD branch (the local branch of that name when it holds every commit
#                             the remote-tracking ref has, so unpushed commits on it are never part
#                             of the diff, and the remote-tracking ref when that local branch is
#                             behind, so commits the branch never wrote stay out), else main, else
#                             master
#   fixed-point.sh <ref>      the fixed point is the merge-base of <ref> and HEAD, which is <ref>
#                             itself when it sits on the branch
#   --ticket <location>       the Ticket a caller hands over, a path or an issue reference (all
#                             digits, or an http(s) URL); it is the spec source, and a path is also
#                             the Review's home. A path is resolved from the directory the script
#                             was invoked from first, then from the repository top; one that names
#                             no file is a refusal, so a Ticket handed over is never lost quietly
#
# Which paths a slug can name under the scratch is not this door's rule to hold: before it answers
# it asks ../../../.agents/scripts/resolve-feature-folder.sh, the one executable form of that rule,
# and passes on every refusal it makes, so a .scratch, a feature folder, or a spec.md or issues
# folder in it that is a symlink never puts the Review, or a spec read beside it, at a path the
# repository does not control. It asks for the branch's slug, and for the slug of the feature folder
# a Ticket found or handed sits in, whose folder, spec.md and issues folder the door checks itself
# as well, since the resolver names only the newest folder of a slug. A Review beside the Ticket
# that is a symlink is refused the same way. Its answer for the branch's slug is also the exact
# .scratch arm of spec=, so the door names the spec the allocator would have named, from any tree.
# The other lookups stay this door's own: a Ticket is named after its own slug and not after its
# feature's, and the containing scan matches a branch name no resolver knows, though it reads the
# scratch the resolver read, so the two arms never name folders from different trees. A checkout
# that has no resolver refuses nothing and names no spec in the scratch, since a machine may have
# linked skills/ on its own.
#
# Prints key=value lines: branch, slug (the branch with every slash turned into a dash), head,
# dirty (yes when the working tree has uncommitted or untracked changes; the two files this run
# itself would write, the Review at review= and the .review.md beside the Ticket at ticket=, never
# count, here or in the empty-diff check, and nothing else is spared: a project's own
# docs/api.review.md is a change like any other), ref (the ref given, or none), fixed_point (the
# full sha), base (only when inferred), diff (the command that shows the working tree against the
# fixed point), status (the command that shows the working tree's short status with those two
# files left out, the one a caller passes on), commits (the commits between the fixed point and
# HEAD), review (the Review's path: beside a handed-over local Ticket, taking its name with .review
# before the extension, else in the scratch reviews folder of the main checkout, relative when this
# tree is the main checkout and absolute from a linked worktree, which has no scratch of its own
# and is removed with everything in it), issue (a number in the branch name,
# else one written as #<n> in a commit subject since the fixed point, else none), ticket (the
# location handed over, a path resolved to where the run reads it, else a Ticket file under
# .scratch/*/issues/ named after the branch's slug, else none), ticket_handed (yes when a caller
# handed the Ticket over, so it names the run's Ticket;
# no when the door found it by slug, which makes it a spec source and nothing more), spec (the spec
# beside that Ticket, else the spec of the feature folder the resolver names for the branch's slug,
# absolute from a linked worktree the way review= is, else docs/specs/<x>.md or specs/<x>.md whose
# <x> is the slug, else the one spec in the usual spec homes, .scratch/<x>/spec.md in the scratch
# the resolver read, docs/specs/<x>.md, specs/<x>.md, whose <x> contains the slug and never counts
# the date a feature folder is prefixed with, else none when there is none or more than one),
# tracker (yes when docs/agents/issue-tracker.md exists) and
# review_in_status (yes when the file at review= would show up in git status, in this tree or in the
# main checkout when it sits there, no when git ignores that path or it sits outside the
# repository).
# Exit codes: 0 the door holds · 1 a refusal, with refusal=<the one line to print> · 2 usage, not a
# git repository, a refusal the resolver makes over the scratch, reported in this door's words, or a
# Ticket's feature folder, spec.md, issues folder or the Review beside it that is a symlink, or the
# file at review= or the folder it sits in that is one.
# main_checkout, printed last, is the path of the main worktree, the first entry of git worktree
# list, so a caller in a linked worktree reaches the developer's checkout, and the tree the run sits
# in when that entry is a bare repository: see .agents/worktrees.md.
set -uo pipefail

usage() { echo "usage: fixed-point.sh [<ref>] [--ticket <location>]" >&2; exit 2; }
ref=""; handed=""; handed_given=no
while [ "$#" -gt 0 ]; do
  case "$1" in
    --ticket) [ "$#" -ge 2 ] || usage; handed="$2"; handed_given=yes; shift 2 ;;
    *) [ -z "$ref" ] || usage; ref="$1"; shift ;;
  esac
done
here="$(cd "$(dirname "$0")" && pwd -P)"
resolver="$here/../../../.agents/scripts/resolve-feature-folder.sh"
top="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "not a git repository" >&2; exit 2; }
invoked="$(pwd -P)"
cd "$top" || exit 2
# A bare main worktree has no working tree to anchor on, and git lists it first all the same, so a
# run in a linked worktree would resolve every path under it inside the bare repository.
main_checkout="$(git worktree list --porcelain 2>/dev/null |
  awk '/^$/ { exit } /^worktree /{ p = substr($0, 10) } /^bare$/ { p = "" } END { print p }')"
[ -n "$main_checkout" ] && [ -d "$main_checkout" ] || main_checkout="$top"

refuse() { echo "refusal=$1"; exit 1; }
refuse_link() { [ -L "$1" ] || return 0; echo "$1 is a symlink; nothing reviewed" >&2; exit 2; }
short() { git rev-parse --short "$1"; }
reference() { # a handed location that is an issue reference: all digits, or an http(s) URL
  case "$1" in
    http://*|https://*) return 0 ;;
    ''|*[!0-9]*) return 1 ;;
    *) return 0 ;;
  esac
}
locate() { # the file resolve finds, named the way the caller named it, so a symlink on the way stays
           # visible to the gate
  case "$1" in
    /*) [ -f "$1" ] && printf '%s\n' "$1" ;;
    *) if [ -f "$invoked/$1" ]; then printf '%s\n' "$invoked/$1"; elif [ -f "$top/$1" ]; then printf '%s\n' "$top/$1"; else return 1; fi ;;
  esac
}
resolve() { # a handed path, from the directory the script was invoked from first and the
            # repository top second, printed the way the rest of the run names it: relative to the
            # top when it sits under it, absolute anywhere else
  local abs
  abs="$(locate "$1")" || return 1
  abs="$(cd "$(dirname "$abs")" && pwd -P)/$(basename "$abs")"
  case "$abs" in "$top"/*) printf '%s\n' "${abs#"$top"/}" ;; *) printf '%s\n' "$abs" ;; esac
}

branch="$(git symbolic-ref -q --short HEAD || echo HEAD)"
slug="${branch//\//-}"
head="$(short HEAD)"
review=".scratch/reviews/$slug.md"
# A linked worktree has no scratch of its own and git worktree remove deletes an ignored one without
# a word, so the default home is the main checkout's folder, by its absolute path.
[ "$top" -ef "$main_checkout" ] || review="$main_checkout/.scratch/reviews/$slug.md"
core="${branch##*/}"
core="$(sed -E 's/^[0-9]+-//' <<<"$core")"
gate() { # leaves the resolver's answer in resolved, empty when it has none to give
  resolved=""
  [ -f "$resolver" ] || return 0
  resolved="$(bash "$resolver" "$1" 2>&1)" && return 0
  case "$resolved" in
    # Only the escapes: a branch whose name normalises to no slug names no feature folder, which is
    # an answer of none here and never a refusal.
    *"nothing resolved")
      # The reason is the resolver's; the verb is this door's, which reviews where it only reads.
      echo "${resolved/%nothing resolved/nothing reviewed}" >&2; exit 2 ;;
  esac
  resolved=""
}
gate "$core"
scratch_spec="$(sed -n 's/^spec=//p' <<<"$resolved")"
scratch_root="$(sed -n 's/^root=//p' <<<"$resolved")"
ticket=none
# One slug can carry more than one dated feature folder, and the newest of them wins: the glob is
# sorted, so the last match is the one .agents/scratch.md names, and an undated folder, whose name
# sorts after every date, wins the way the allocator prefers it.
for f in .scratch/*/issues/[0-9][0-9]-"$core".md; do [ -f "$f" ] && ticket="$f"; done
located="$ticket"
ticket_handed=no
if [ "$handed_given" = yes ]; then
  ticket_handed=yes
  if reference "$handed"; then
    ticket="$handed"; located=none
  else
    ticket="$(resolve "$handed")" || refuse "$handed is not a Ticket file; nothing reviewed"
    review="${ticket%.md}.review.md"
    located="$(locate "$handed")"; located="${located#"$top"/}"
  fi
fi
# do names its branch after the Ticket's slug and not after its feature's, so the gate above never
# reached the folder the spec is read from and a handed Ticket's Review is written into.
if [ "$located" != none ]; then
  folder="$(dirname "$(dirname "$located")")"
  if [ -f "$resolver" ] && [ "$(basename "$(dirname "$folder")")" = .scratch ]; then
    gate "$(basename "$folder")"
    for p in "$folder" "$folder/spec.md" "$folder/issues"; do refuse_link "$p"; done
  fi
  refuse_link "${ticket%.md}.review.md"
fi
# The Review is written with a tool that follows a link, wherever review= puts it.
refuse_link "$(dirname "$review")"
refuse_link "$review"
own=(":!$review")
case "$ticket" in
  none) ;;
  *.md) [ "${ticket%.md}.review.md" = "$review" ] || own+=(":!${ticket%.md}.review.md") ;;
esac
status="git status --short -- ."
for p in "${own[@]}"; do status="$status '$p'"; done
if [ -n "$(git status --porcelain -- . "${own[@]}")" ]; then dirty=yes; else dirty=no; fi

base=""
if [ -n "$ref" ]; then
  commit="$(git rev-parse --verify -q "${ref}^{commit}")" || refuse "$ref does not resolve; nothing reviewed"
  fixed="$(git merge-base "$commit" HEAD 2>/dev/null || echo "$commit")"
  label="$ref ($(short "$fixed"))"
else
  remote="$(git remote | grep -x origin || git remote | head -1)"
  if [ -n "$remote" ]; then base="$(git symbolic-ref -q --short "refs/remotes/$remote/HEAD" || true)"; fi
  local_base="${base#"$remote/"}"
  if [ -n "$base" ] && git rev-parse --verify -q "refs/heads/$local_base" >/dev/null &&
    git merge-base --is-ancestor "$base" "refs/heads/$local_base"; then base="$local_base"; fi
  if [ -z "$base" ]; then
    for candidate in main master; do
      if git rev-parse --verify -q "refs/heads/$candidate" >/dev/null; then base="$candidate"; break; fi
      if [ -n "$remote" ] && git rev-parse --verify -q "refs/remotes/$remote/$candidate" >/dev/null; then base="$remote/$candidate"; break; fi
    done
  fi
  [ -n "$base" ] || refuse "no base branch found; pass a ref"
  fixed="$(git merge-base "$base" HEAD 2>/dev/null)" || refuse "no merge-base between $base and HEAD; pass a ref"
  label="$base ($(short "$fixed"))"
fi

if git diff --quiet "$fixed" -- . "${own[@]}" && [ -z "$(git ls-files --others --exclude-standard -- . "${own[@]}" | head -1)" ]; then
  refuse "no diff between $label and the working tree; nothing reviewed"
fi

issue="$(grep -oE '(^|/)[0-9]+-' <<<"$branch" | head -1 | tr -dc '0-9')"
[ -n "$issue" ] || issue="$(git log --format=%s "$fixed..HEAD" | grep -oE '#[0-9]+' | head -1 | tr -d '#')"
spec=none
if [ -f "$ticket" ] && [ -f "$(dirname "$(dirname "$ticket")")/spec.md" ]; then
  spec="$(dirname "$(dirname "$ticket")")/spec.md"
else
  exact=""; containing=()
  [ "${scratch_spec:-none}" = none ] || exact="$scratch_spec"
  # The containing scan reads the scratch the resolver read, in the paths the resolver prints:
  # relative when this tree is the main checkout, absolute from a linked worktree.
  homes=()
  if [ -n "$scratch_root" ]; then
    homes=("$scratch_root"/.scratch/*/spec.md)
    [ "$top" -ef "$scratch_root" ] && homes=("${homes[@]#"$scratch_root"/}")
  fi
  for f in "${homes[@]}" docs/specs/*.md specs/*.md; do
    [ -f "$f" ] || continue
    # A feature folder is dated, .scratch/<YYYYMMDD>-<slug>/, and the date is no part of the slug.
    case "$f" in
      docs/specs/*|specs/*) x="$(basename "$f" .md)" ;;
      *) x="$(basename "$(dirname "$f")")"; x="${x#[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-}" ;;
    esac
    # The exact .scratch match is the resolver's answer, and only for the newest folder of the slug,
    # so an older folder of it is neither exact nor containing; a versioned home never displaces it.
    if [ "$x" = "$core" ]; then
      case "$f" in docs/specs/*|specs/*) [ -n "$exact" ] || exact="$f" ;; esac
      continue
    fi
    if [ -z "$exact" ] && [[ "$x" == *"$core"* || "$core" == *"$x"* ]]; then containing+=("$f"); fi
  done
  if [ -n "$exact" ]; then spec="$exact"; elif [ "${#containing[@]}" = 1 ]; then spec="${containing[0]}"; fi
fi
if [ -f docs/agents/issue-tracker.md ]; then tracker=yes; else tracker=no; fi
review_in_status=yes
case "$review" in
  "$main_checkout"/*) git -C "$main_checkout" check-ignore -q -- "${review#"$main_checkout"/}" && review_in_status=no ;;
  /*) review_in_status=no ;;
  *) git check-ignore -q -- "$review" && review_in_status=no ;;
esac

echo "branch=$branch"
echo "slug=$slug"
echo "head=$head"
echo "dirty=$dirty"
echo "ref=${ref:-none}"
echo "fixed_point=$fixed"
[ -n "$base" ] && echo "base=$base"
echo "diff=git diff $fixed"
echo "status=$status"
echo "commits=$(git rev-list --count "$fixed..HEAD")"
echo "review=$review"
echo "issue=${issue:-none}"
echo "ticket=$ticket"
echo "ticket_handed=$ticket_handed"
echo "spec=$spec"
echo "tracker=$tracker"
echo "review_in_status=$review_in_status"
echo "main_checkout=$main_checkout"
exit 0
