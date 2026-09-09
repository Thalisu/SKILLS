#!/usr/bin/env bash
# resolve-feature-folder.sh: the feature folder a bare slug names and the spec in it, read out of
# the main checkout's scratch. It is the one executable form of the rule, so every door that turns
# a slug into a folder calls it instead of restating it. Run from anywhere inside the project.
#
#   resolve-feature-folder.sh <slug>    the slug alone
#
# The rule: a slug names the folder called <slug> or <YYYYMMDD>-<slug> and no other, the newest of
# them when a slug carries more than one, and an undated folder from before the dated rule over
# every dated one, never renamed. Never a folder that merely ends in the slug.
#
# Prints key=value lines: slug, the normalised slug; root, the main checkout it resolved in;
# folder, the feature folder it named; spec, the spec.md in that folder; date, the folder's date,
# or none for an undated folder.
#
# Exit codes: 0 it resolved.
set -uo pipefail

slug="$1"

top="$(git rev-parse --show-toplevel 2>/dev/null)"
root="$top"
[ -n "$root" ] || root="$(pwd -P)"
cd "$root" || exit 2

folder=""
for d in .scratch/[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-"$slug"; do
  [ -d "$d" ] && folder="$d"   # the glob is sorted, so the last match is the newest date
done
[ -d ".scratch/$slug" ] && folder=".scratch/$slug"

date_of="$(sed -E 's#^\.scratch/([0-9]{8})-.*#\1#' <<<"$folder")"
[ "$date_of" = "$folder" ] && date_of=none

echo "slug=$slug"
echo "root=$root"
echo "folder=$folder"
echo "spec=$folder/spec.md"
echo "date=$date_of"
exit 0
