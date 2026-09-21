#!/usr/bin/env bash
# mechanics-references.sh: mechanics.md's positional references reach the text they point at. Some
# of the shared mechanics moved out to conflict-loop.md and forks.md, and a reference left saying
# "below" or "as above" points at text that is no longer in this file, so the reader who follows it
# finds nothing. A reference reaches its text either way: the text sits in mechanics.md, or the
# paragraph carrying the reference links the file the text moved to. mechanics.md never copies
# conflict-loop.md's or forks.md's blocks back in ("never a copy of it here"), so the link is the
# resolution, not the copy.
#
# The check below is generic, not a hand-picked list: it reads every paragraph of mechanics.md that
# carries the word "above" or "below", pulls out the "the <name> above/below" phrase each one names,
# and asks whether that name is a heading (a "## " line, or a bold span opening its own paragraph)
# still in mechanics.md, or a heading moved out to conflict-loop.md or forks.md and linked from the
# paragraph naming it. A phrase that names no heading at all (ordinary prose flow, like "the rebase
# above") is not a moved reference and is left alone.
# Run: bash skills/do/tests/mechanics-references.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
mech="$here/../references/mechanics.md"
moved_to=("$here/../references/conflict-loop.md" "$here/../references/forks.md")
fails=0

reaches() { # $1 label, $2 yes when the text sits in mechanics.md itself, $3 the paragraph the reference sits in, $4 the sibling file the text may have moved to
  if [ "$2" = yes ]; then
    ok "$1 (the text is in mechanics.md)"
  elif grep -qF -- "$(basename "$4")" <<<"$3"; then
    ok "$1 (through the link to $(basename "$4"))"
  else
    fail "$1 (not in mechanics.md, and its paragraph carries no link to $(basename "$4"))"
  fi
}
# The concept headings of a file: every "#" heading and every bold span opening its own paragraph,
# with a leading article and trailing punctuation stripped, lowercased. "the forks below" names the
# concept "forks", which the check meets as forks.md's "## Forks" once it is stripped this way.
headings_of() { # $1 file
  {
    grep -oE '^#+ .*' "$1" | sed -E 's/^#+ //'
    grep -oE '^\*\*[^*]+\*\*' "$1" | sed -E 's/^\*\*(.*)\*\*$/\1/'
  } | sed -E 's/^(The|A|An) //; s/[.:]+$//' | tr '[:upper:]' '[:lower:]' | sort -u
}
# Whether any heading in $1 (one per line) is a substring of the phrase $2, both already lowercased.
names_a_heading_in() { # $1 headings list, $2 phrase
  local h
  while IFS= read -r h; do
    [ -n "$h" ] && [[ "$2" == *"$h"* ]] && {
      echo yes
      return
    }
  done <<<"$1"
  echo no
}

echo "# mechanics.md: every above/below positional reference reaches the text it points at"

mech_headings="$(headings_of "$mech")"
paragraphs="$(awk 'BEGIN { RS = ""; ORS = "\x1e" } { gsub(/\n/, " "); print }' "$mech")"
mapfile -d $'\x1e' -t all_paragraphs < <(printf '%s' "$paragraphs")
n=0
for para in "${all_paragraphs[@]}"; do
  [ -z "$para" ] && continue
  grep -qE '(^| )(above|below)([ .,:;)]|$)' <<<"$para" || continue
  n=$((n + 1))
  mapfile -t names < <(grep -oP '(?:the|The) \K[A-Za-z][A-Za-z'"'"' -]{1,40}?(?= (above|below))' <<<"$para")
  for name in "${names[@]}"; do
    lower="$(tr '[:upper:]' '[:lower:]' <<<"$name")"
    label="the \"$name\" that paragraph $n names is reachable from mechanics.md"
    if [ "$(names_a_heading_in "$mech_headings" "$lower")" = yes ]; then
      reaches "$label" yes "$para" ""
      continue
    fi
    for sibling in "${moved_to[@]}"; do
      sibling_headings="$(headings_of "$sibling")"
      if [ "$(names_a_heading_in "$sibling_headings" "$lower")" = yes ]; then
        reaches "$label" no "$para" "$sibling"
        break
      fi
    done
  done
done
expect "mechanics.md carries at least one above/below reference to check" test "$n" -gt 0

# The Digest write rule's one exception names "the forks" for what a settled Ruling moves in
# place. The forks live in forks.md, not in this file, so the paragraph reaches that text only if
# mechanics.md still carries a Forks heading of its own or the paragraph links forks.md the way
# the other three "the forks" sentences of this file do.
para="$(paragraph_with "$mech" "moves in place, the rest of the file")"
expect "mechanics.md carries the paragraph on the Digest write rule's one exception" test -n "$para"
heading=no
grep -qF -- "## Forks" "$mech" && heading=yes
if [ "$heading" = yes ]; then
  ok "the reference reaches its text (the Forks heading is still in mechanics.md)"
elif grep -qF -- "forks.md" <<<"$para"; then
  ok "the reference reaches its text (through the link to forks.md)"
else
  fail "the reference reaches its text (no Forks section in mechanics.md and no link to forks.md in its paragraph)"
fi

# SKILL.md's own "## Links" rule reads "One per reference": every file under skills/do/references/
# carries exactly one entry there, so a reader who works the list top to bottom finds every
# reference. A file present on disk with no entry is reachable only by chance, through whatever
# inline link another reference happens to carry to it.
echo "# SKILL.md's Links list carries one entry per file under skills/do/references/"
skill="$here/../SKILL.md"
links_section="$(awk '/^## Links/{flag=1; next} /^## /{flag=0} flag' "$skill")"
missing=""
for ref in "$here"/../references/*.md; do
  name="$(basename "$ref")"
  grep -qF -- "references/$name" <<<"$links_section" || missing="$missing $name"
done
if [ -z "$missing" ]; then
  ok "every file under references/ has a Links entry in SKILL.md"
else
  fail "every file under references/ has a Links entry in SKILL.md (missing:$missing)"
fi

[ "$fails" -eq 0 ] && exit 0
exit 1
