#!/usr/bin/env bash
# resolve-feature-folder.sh: the feature folder a bare slug names and the spec in it, read out of
# the main checkout's scratch. It is the one executable form of the rule, so every door that turns
# a slug into a folder calls it instead of restating it. Run from anywhere inside the project, or
# outside a repository, where the caller's own directory is the root.
#
# It resolves in the main checkout, so a slug names one folder from whichever tree the caller
# stands in. A linked worktree holds no scratch of its own, so from there the paths come back
# absolute, the way the review door's Review path already does. See ../scratch.md.
#
#   resolve-feature-folder.sh <slug>    the slug alone, in any case, with or without the date the
#                                       folder carries: it is lowercased, every other character
#                                       becomes a dash, dashes are squeezed and trimmed, and a
#                                       YYYYMMDD- prefix already on it is dropped
#
# The rule: a slug names the folder called <slug> or <YYYYMMDD>-<slug> and no other, the newest of
# them when a slug carries more than one, and an undated folder from before the dated rule over
# every dated one, never renamed. Never a folder that merely ends in the slug.
#
# Prints key=value lines: slug, the normalised slug; root, the main checkout it resolved in;
# folder, the feature folder it named, or none; spec, the spec.md in that folder, or none; date,
# the folder's date, or none for an undated folder.
#
# Exit codes: 0 it resolved, folder=none included, so a slug that names nothing never fails the
# caller's run · 2 usage, a slug that normalises to nothing, a .scratch that is not a plain
# directory of the checkout, a feature folder that is a symlink, or a spec.md, an issues folder or
# a journey.md in it that is a symlink, any of which would name a path the repository does not
# control.
set -uo pipefail

usage() { echo "usage: resolve-feature-folder.sh <slug>" >&2; exit 2; }

[ "$#" = 1 ] || usage

slug="$(tr '[:upper:]' '[:lower:]' <<<"$1" | tr -c 'a-z0-9' '-' | tr -s '-')"
slug="${slug#-}"; slug="${slug%-}"
slug="$(sed -E 's/^[0-9]{8}-//' <<<"$slug")"
[ -n "$slug" ] || { echo "a slug is needed: $1 normalises to nothing" >&2; exit 2; }

top="$(git rev-parse --show-toplevel 2>/dev/null)"
root="$top"
prefix=""
if [ -n "$top" ]; then
  # A bare main worktree has no working tree to anchor on, and git lists it first all the same.
  main_checkout="$(git worktree list --porcelain 2>/dev/null |
    awk '/^$/ { exit } /^worktree /{ p = substr($0, 10) } /^bare$/ { p = "" } END { print p }')"
  [ -n "$main_checkout" ] && [ -d "$main_checkout" ] || main_checkout="$top"
  root="$main_checkout"
  [ "$top" -ef "$root" ] || prefix="$root/"
fi
[ -n "$root" ] || root="$(pwd -P)"
cd "$root" || exit 2

if [ -L .scratch ] || { [ -e .scratch ] && [ ! -d .scratch ]; }; then
  echo ".scratch is not a plain directory of this checkout; nothing resolved" >&2; exit 2
fi

folder=""
for d in .scratch/[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-"$slug"; do
  [ -d "$d" ] && folder="$d"   # the glob is sorted, so the last match is the newest date
done
[ -d ".scratch/$slug" ] && folder=".scratch/$slug"
if [ -n "$folder" ] && [ -L "$folder" ]; then
  echo "$prefix$folder is a symlink; nothing resolved" >&2; exit 2
fi
if [ -n "$folder" ] && [ -L "$folder/spec.md" ]; then
  echo "$prefix$folder/spec.md is a symlink; nothing resolved" >&2; exit 2
fi
# The folder is also the home of the tickets the chain writes at issues/<NN>-<slug>.md, and the
# caller composes that path off the folder key without a gate of its own.
if [ -n "$folder" ] && [ -L "$folder/issues" ]; then
  echo "$prefix$folder/issues is a symlink; nothing resolved" >&2; exit 2
fi
# journey writes journey.md beside the spec this names, and calls no gate of its own either.
if [ -n "$folder" ] && [ -L "$folder/journey.md" ]; then
  echo "$prefix$folder/journey.md is a symlink; nothing resolved" >&2; exit 2
fi

date_of="$(sed -E 's#^\.scratch/([0-9]{8})-.*#\1#' <<<"$folder")"
[ "$date_of" = "$folder" ] && date_of=none

spec=none
if [ -n "$folder" ]; then
  [ -f "$folder/spec.md" ] && spec="$prefix$folder/spec.md"
  folder="$prefix$folder"
else folder=none; fi

echo "slug=$slug"
echo "root=$root"
echo "folder=$folder"
echo "spec=$spec"
echo "date=$date_of"
exit 0
