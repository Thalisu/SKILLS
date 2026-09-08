#!/usr/bin/env bash
# fixed-point.sh: the door of do-code-review, the facts of the diff that a script can observe, so the
# orchestrator reads them off one run and a reviewer can rerun them. Run from anywhere inside the
# project.
#
#   fixed-point.sh            the fixed point is the merge-base with the base branch: the remote's
#                             HEAD branch, else main, else master
#   fixed-point.sh <ref>      the fixed point is the merge-base of <ref> and HEAD, which is <ref>
#                             itself when it sits on the branch
#
# Prints key=value lines: branch, slug (the branch with every slash turned into a dash), head,
# dirty (yes when the working tree has uncommitted or untracked changes), ref (the ref given, or
# none), fixed_point (the full sha), base (only when inferred), diff (the command that shows the
# working tree against the fixed point), commits (the commits between the fixed point and HEAD),
# review (the Review's path in the scratch reviews folder), issue (a number in the branch name,
# else one written as #<n> in a commit subject since the fixed point, else none), ticket (a Ticket
# file under .scratch/*/issues/ named after the branch's slug, else none), spec (the spec beside
# that Ticket, else the one spec in the usual spec homes, .scratch/<x>/spec.md, docs/specs/<x>.md,
# specs/<x>.md, whose <x> is the slug or contains it, else none when there is none or more than
# one), tracker (yes when docs/agents/issue-tracker.md exists) and scratch_ignored (yes when git
# ignores .scratch).
# Exit codes: 0 the door holds · 1 a refusal, with refusal=<the one line to print> · 2 usage, or not
# a git repository.
set -uo pipefail

[ "$#" -le 1 ] || { echo "usage: fixed-point.sh [<ref>]" >&2; exit 2; }
top="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "not a git repository" >&2; exit 2; }
cd "$top" || exit 2

refuse() { echo "refusal=$1"; exit 1; }
short() { git rev-parse --short "$1"; }

ref="${1:-}"
branch="$(git symbolic-ref -q --short HEAD || echo HEAD)"
slug="${branch//\//-}"
head="$(short HEAD)"
if [ -n "$(git status --porcelain)" ]; then dirty=yes; else dirty=no; fi

base=""
if [ -n "$ref" ]; then
  commit="$(git rev-parse --verify -q "${ref}^{commit}")" || refuse "$ref does not resolve; nothing reviewed"
  fixed="$(git merge-base "$commit" HEAD 2>/dev/null || echo "$commit")"
  label="$ref ($(short "$fixed"))"
else
  remote="$(git remote | grep -x origin || git remote | head -1)"
  if [ -n "$remote" ]; then base="$(git symbolic-ref -q --short "refs/remotes/$remote/HEAD" || true)"; fi
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

if git diff --quiet "$fixed" && [ -z "$(git ls-files --others --exclude-standard | head -1)" ]; then
  refuse "no diff between $label and the working tree; nothing reviewed"
fi

core="${branch##*/}"
core="$(sed -E 's/^[0-9]+-//' <<<"$core")"
issue="$(grep -oE '(^|/)[0-9]+-' <<<"$branch" | head -1 | tr -dc '0-9')"
[ -n "$issue" ] || issue="$(git log --format=%s "$fixed..HEAD" | grep -oE '#[0-9]+' | head -1 | tr -d '#')"
ticket=none
for f in .scratch/*/issues/[0-9][0-9]-"$core".md; do [ -f "$f" ] && { ticket="$f"; break; }; done
spec=none
if [ "$ticket" != none ] && [ -f "$(dirname "$(dirname "$ticket")")/spec.md" ]; then
  spec="$(dirname "$(dirname "$ticket")")/spec.md"
else
  exact=""; containing=()
  for f in .scratch/*/spec.md docs/specs/*.md specs/*.md; do
    [ -f "$f" ] || continue
    case "$f" in .scratch/*) x="$(basename "$(dirname "$f")")" ;; *) x="$(basename "$f" .md)" ;; esac
    if [ "$x" = "$core" ]; then exact="$f"; break; fi
    if [[ "$x" == *"$core"* || "$core" == *"$x"* ]]; then containing+=("$f"); fi
  done
  if [ -n "$exact" ]; then spec="$exact"; elif [ "${#containing[@]}" = 1 ]; then spec="${containing[0]}"; fi
fi
if [ -f docs/agents/issue-tracker.md ]; then tracker=yes; else tracker=no; fi
if git check-ignore -q .scratch; then scratch_ignored=yes; else scratch_ignored=no; fi

echo "branch=$branch"
echo "slug=$slug"
echo "head=$head"
echo "dirty=$dirty"
echo "ref=${ref:-none}"
echo "fixed_point=$fixed"
[ -n "$base" ] && echo "base=$base"
echo "diff=git diff $fixed"
echo "commits=$(git rev-list --count "$fixed..HEAD")"
echo "review=.scratch/reviews/$slug.md"
echo "issue=${issue:-none}"
echo "ticket=$ticket"
echo "spec=$spec"
echo "tracker=$tracker"
echo "scratch_ignored=$scratch_ignored"
exit 0
