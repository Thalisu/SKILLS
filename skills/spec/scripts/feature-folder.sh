#!/usr/bin/env bash
# feature-folder.sh: the feature folder of a local spec, allocated by the script so the name is
# never the model's to compose. The caller passes the slug alone and the folder comes back dated,
# `.scratch/<YYYYMMDD>-<slug>/`, so a folder says when its spec was written. Run from anywhere
# inside the project.
#
#   feature-folder.sh <slug>    the slug of the feature, the spec's title in kebab-case. It is
#                               normalised by the resolver (lowercased, every other character
#                               turned into a dash, dashes squeezed and trimmed) and a `YYYYMMDD-`
#                               prefix already on it is dropped, so handing back a folder name
#                               allocates nothing new
#
# Which folder a slug names is not this script's rule to hold: it asks
# ../../../.agents/scripts/resolve-feature-folder.sh, the one executable form of it, and allocates
# only when that answer is `none`. The resolver normalises the slug, finds the main checkout, and
# refuses a `.scratch` that is not a plain directory of it, a folder, a `spec.md`, an `issues`
# folder or a `journey.md` that is a symlink, so this script inherits all seven and none of them is
# written twice. See
# ../../../docs/adr/0031-a-shared-read-only-script-resolves-a-slug-to-its-feature-folder.md.
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
# so a run never claims a line it did not manage to add. The ignore is this script's alone: the
# resolver only reads, so it never appends and never reports one.
#
# Prints key=value lines: slug (the normalised slug), folder, spec (the spec's path in it),
# created (yes when this run created the folder, no when it reused one), date (the folder's date,
# none for a reused undated folder) and gitignore, which is one of: present (the project's own
# `.gitignore` already carried the rule), appended (this run added it and the probe confirms it),
# symlink (`.gitignore` is a symlink, so the append would write through it, outside the tree: it is
# refused and nothing is written), not-ignored (the append did not take, so the scratch shows up in
# `git status` and the caller says so) and no-repo (outside a git repository).
# Exit codes: 0 the folder is there · 2 usage, a missing resolver, or any refusal the resolver
# makes, reported in this script's own words.
set -uo pipefail

usage() { echo "usage: feature-folder.sh <slug>" >&2; exit 2; }
[ "$#" = 1 ] || usage

here="$(cd "$(dirname "$0")" && pwd -P)"
resolver="$here/../../../.agents/scripts/resolve-feature-folder.sh"
if [ ! -f "$resolver" ]; then
  echo "resolve-feature-folder.sh not found at $resolver; nothing allocated" >&2
  exit 2
fi

rc=0
resolved="$(bash "$resolver" "$1" 2>&1)" || rc=$?
if [ "$rc" != 0 ]; then
  # The reason is the resolver's; the verb is this script's, which allocates where it only reads.
  echo "${resolved/%nothing resolved/nothing allocated}" >&2
  exit "$rc"
fi

slug="$(sed -n 's/^slug=//p' <<<"$resolved")"
root="$(sed -n 's/^root=//p' <<<"$resolved")"
folder="$(sed -n 's/^folder=//p' <<<"$resolved")"
date_of="$(sed -n 's/^date=//p' <<<"$resolved")"
[ "$folder" = none ] && folder=""

# The resolver answers in the main checkout's own paths, absolute only when the caller stands
# somewhere else, so the prefix is read back off the tree this run was invoked from.
top="$(git rev-parse --show-toplevel 2>/dev/null)"
prefix=""
if [ -n "$top" ] && ! [ "$top" -ef "$root" ]; then prefix="$root/"; fi
folder="${folder#"$prefix"}"
cd "$root" || exit 2

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
  date_of="$(date +%Y%m%d)"
  folder=".scratch/$date_of-$slug"
  mkdir -p .scratch || exit 2
  if mkdir "$folder" 2>/dev/null; then created=yes; elif [ ! -d "$folder" ]; then
    echo "could not create $prefix$folder" >&2; exit 2
  fi
fi

echo "slug=$slug"
echo "folder=$prefix$folder"
echo "spec=$prefix$folder/spec.md"
echo "created=$created"
echo "date=$date_of"
echo "gitignore=$gitignore"
exit 0
