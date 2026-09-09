#!/usr/bin/env bash
# feature-folder.sh: the feature folder of a local spec, allocated by the script so the name is
# never the model's to compose. The caller passes the slug alone and the folder comes back dated,
# `.scratch/<YYYYMMDD>-<slug>/`, so a folder says when its spec was written. Run from anywhere
# inside the project.
#
#   feature-folder.sh <slug>    the slug of the feature, the spec's title in kebab-case. It is
#                               normalised (lowercased, every other character turned into a dash,
#                               dashes squeezed and trimmed) and a `YYYYMMDD-` prefix already on it
#                               is dropped, so handing back a folder name allocates nothing new
#
# A folder for the slug that already exists is reused whatever date it carries, and an undated one
# left by an older run is reused too: a rerun rewrites its spec in place, and the date is the day
# the feature was first written, not the day of the last rerun. Otherwise the folder is created
# with today's date, and the create is the claim: `mkdir` without `-p` fails when a twin run got
# there first, which is the same feature, so the loser reuses instead of stopping. See
# ../../../.agents/scratch.md.
#
# Everything is allocated in the main checkout, never in the linked worktree a build runs in: that
# tree holds no scratch of its own and `git worktree remove` deletes an ignored folder in it with
# everything inside. From a linked worktree the paths come back absolute, the way the rest of the
# chain reaches the developer's checkout; from the main checkout they are relative to its top.
#
# The `.scratch/` line is appended to the project's own `.gitignore` before the folder is created,
# whenever the rule is not already coming from that file: `git check-ignore -v` names the file the
# rule comes from, and `.git/info/exclude`, a global excludes file and no answer at all all mean
# the line is owed. What is reported is the state after the write, read back with the same probe,
# so a run never claims a line it did not manage to add.
#
# Prints key=value lines: slug (the normalised slug), folder, spec (the spec's path in it),
# created (yes when this run created the folder, no when it reused one), date (the folder's date,
# none for a reused undated folder) and gitignore, which is one of: present (the project's own
# `.gitignore` already carried the rule), appended (this run added it and the probe confirms it),
# symlink (`.gitignore` is a symlink, so the append would write through it, outside the tree: it is
# refused and nothing is written), not-ignored (the append did not take, so the scratch shows up in
# `git status` and the caller says so) and no-repo (outside a git repository).
# Exit codes: 0 the folder is there · 2 usage, a slug that normalises to nothing, or a `.scratch`
# that is not a plain directory of this checkout, which would put the folder somewhere the
# repository does not control.
set -uo pipefail

usage() { echo "usage: feature-folder.sh <slug>" >&2; exit 2; }
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
  echo ".scratch is not a plain directory of this checkout; nothing allocated" >&2; exit 2
fi

folder=""
for d in .scratch/[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-"$slug"; do
  [ -d "$d" ] && folder="$d"   # the glob is sorted, so the last match is the newest date
done
[ -d ".scratch/$slug" ] && folder=".scratch/$slug"
if [ -n "$folder" ] && [ -L "$folder" ]; then
  echo "$prefix$folder is a symlink; nothing allocated" >&2; exit 2
fi

gitignore=no-repo
if [ -n "$top" ]; then
  rule="$(git check-ignore -v .scratch/ 2>/dev/null | cut -d: -f1)"
  if [ "$rule" = .gitignore ]; then
    gitignore=present
  elif [ -L .gitignore ]; then
    gitignore=symlink
  else
    # A file whose last line has no newline would swallow the appended line into it.
    if [ -s .gitignore ] && [ -n "$(tail -c 1 .gitignore)" ]; then printf '\n' >> .gitignore 2>/dev/null; fi
    grep -qxF '.scratch/' .gitignore 2>/dev/null || printf '.scratch/\n' >> .gitignore 2>/dev/null
    rule="$(git check-ignore -v .scratch/ 2>/dev/null | cut -d: -f1)"
    if [ "$rule" = .gitignore ]; then gitignore=appended; else gitignore=not-ignored; fi
  fi
fi

created=no
if [ -z "$folder" ]; then
  folder=".scratch/$(date +%Y%m%d)-$slug"
  mkdir -p .scratch || exit 2
  if mkdir "$folder" 2>/dev/null; then created=yes; elif [ ! -d "$folder" ]; then
    echo "could not create $prefix$folder" >&2; exit 2
  fi
fi

date_of="$(sed -E 's#^\.scratch/([0-9]{8})-.*#\1#' <<<"$folder")"
[ "$date_of" = "$folder" ] && date_of=none

echo "slug=$slug"
echo "folder=$prefix$folder"
echo "spec=$prefix$folder/spec.md"
echo "created=$created"
echo "date=$date_of"
echo "gitignore=$gitignore"
exit 0
