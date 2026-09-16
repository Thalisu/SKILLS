#!/usr/bin/env bash
# contract.sh: the sketch destination SKILL.md composes and do's shape-step containment check, both
# run for real in throwaway checkouts.
# Run: bash skills/sketch/tests/contract.sh
# shellcheck disable=SC2016
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
repo="$(cd "$here/../../.." && pwd -P)"
skill="$repo/skills/sketch"
fails=0
skill_md="$skill/SKILL.md"
resolver="$(grep -o '\.\./\.\./\.agents/scripts/[a-z0-9-]*\.sh' "$skill_md" 2>/dev/null | head -n 1)"
resolver="${resolver#../../}"
# The exit-0 row's own composition, read off the row and run for real: a subdirectory of the main
# checkout (not the root, and not a linked worktree) is where the resolver's `folder=` comes back
# relative to the root, so the destination the row composes, and the containment check that
# follows it, must land the same place a session standing at the root would.
sketch_row="$(grep -E '^\| exit 0 \|' "$skill_md" 2>/dev/null | head -n 1)"
sketch_template="$(grep -o '`[^`]*`' <<<"$sketch_row" | tr -d '`' |
  grep -F '<folder>' | grep -E 'sketch\.md$' | head -n 1)"
expect "the exit-0 row carries a destination template built on <folder> and ending in sketch.md" \
  test -n "$sketch_template"
sketch_tmp="$(mktemp -d)"
sketch_today="$(date +%Y%m%d)"
mkdir -p "$sketch_tmp/repo/src"
(cd "$sketch_tmp/repo" && g init -q -b main)
mkdir -p "$sketch_tmp/repo/.scratch/${sketch_today}-export-notes"
sketch_resolver_out="$(cd "$sketch_tmp/repo/src" && bash "$repo/${resolver:-none.sh}" export-notes 2>&1)"
sketch_folder="$(sed -n 's/^folder=//p' <<<"$sketch_resolver_out")"
sketch_root="$(sed -n 's/^root=//p' <<<"$sketch_resolver_out")"
sketch_destination="${sketch_template//<root>/$sketch_root}"
sketch_destination="${sketch_destination//<folder>/$sketch_folder}"
sketch_dest_resolved="$(cd "$sketch_tmp/repo/src" && readlink -m "$sketch_destination")"
sketch_scratch_resolved="$(cd "$sketch_tmp/repo/src" && readlink -m "$sketch_root/.scratch")"
case "$sketch_dest_resolved" in
  "$sketch_scratch_resolved"/*) sketch_result="inside" ;;
  *) sketch_result="refused" ;;
esac
sketch_want_dest="$sketch_root/$sketch_folder/sketch.md"
expect "from a subdirectory of the main checkout, the exit-0 destination passes the containment check" \
  test "$sketch_result" = "inside"
expect "from a subdirectory of the main checkout, the exit-0 destination is the absolute <root>/<folder>/sketch.md" \
  test "$sketch_dest_resolved" = "$sketch_want_dest"
rm -rf "$sketch_tmp"

# do's shape step runs its own containment check, in skills/do/references/ticket.md, before it
# forks the agent. Run for real, against a main checkout whose `.scratch` is itself a symlink: the
# resolved destination and the unresolved root/.scratch prefix must still refuse it, never compare
# the two sides through the same link.
door_snippet="$(awk '
  /^Before it forks, the destination the brief names goes through one check/ { f = 1 }
  f && /^```sh$/ { c++; if (c == 1) { p = 1; next } }
  p && /^```$/ { exit }
  p
' "$repo/skills/do/references/ticket.md")"
expect "the shape step's containment check is found in ticket.md" test -n "$door_snippet"

door_tmp="$(mktemp -d)"
mkdir -p "$door_tmp/outside" "$door_tmp/repo"
ln -s "$door_tmp/outside" "$door_tmp/repo/.scratch"
door_root="$(cd "$door_tmp/repo" && pwd -P)"
door_dest="$door_root/.scratch/sketches/42.md"
door_filled="${door_snippet//<the destination>/$door_dest}"
door_filled="${door_filled//<root>/$door_root}"
door_result="$(bash -c "$door_filled")"
expect "a main checkout whose .scratch is a symlink is refused, never compared through the link" \
  test "$door_result" = "refused"
rm -rf "$door_tmp"

door_tmp2="$(mktemp -d)"
mkdir -p "$door_tmp2/repo/.scratch/sketches"
door_root2="$(cd "$door_tmp2/repo" && pwd -P)"
door_dest2="$door_root2/.scratch/sketches/42.md"
door_filled2="${door_snippet//<the destination>/$door_dest2}"
door_filled2="${door_filled2//<root>/$door_root2}"
door_result2="$(bash -c "$door_filled2")"
expect "a plain .scratch directory still lets a destination inside it through" \
  test "$door_result2" = "inside"
rm -rf "$door_tmp2"

ignore_append_keeps_lines() { # $1 a file relative to the repo root, $2 the regex of the line its sh block follows
  local snippet tmp root
  snippet="$(awk -v anchor="$2" '
    $0 ~ anchor { f = 1 }
    f && /^```sh$/ { p = 1; next }
    p && /^```$/ { exit }
    p
  ' "$repo/$1")"
  expect "the scratch ignore append is found in $1" test -n "$snippet"
  tmp="$(mktemp -d)"
  mkdir -p "$tmp/repo"
  (cd "$tmp/repo" && g init -q -b main)
  printf 'node_modules' >"$tmp/repo/.gitignore"
  root="$(cd "$tmp/repo" && pwd -P)"
  bash -c "${snippet//<root>/$root}"
  expect "$1: the ignore append to a .gitignore without a final newline makes .scratch/ ignored" \
    bash -c 'cd "$1" && git check-ignore -q .scratch/' _ "$root"
  expect "$1: the ignore append to a .gitignore without a final newline keeps its last pattern intact" \
    grep -qxF node_modules "$root/.gitignore"
  rm -rf "$tmp"
}
ignore_append_keeps_lines skills/do/references/ticket.md \
  '^A first field of `.gitignore` owes nothing; anything else owes the line'
ignore_append_keeps_lines skills/sketch/SKILL.md \
  '^A first field of `.gitignore` owes nothing[.] Anything else'

if [ "$fails" = 0 ]; then echo "PASS"; else
  echo "$fails failing"
  exit 1
fi
