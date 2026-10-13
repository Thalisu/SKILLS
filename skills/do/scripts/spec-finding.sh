#!/usr/bin/env bash
# spec-finding.sh: the one write a ticket run of do makes to the Spec when its Plan shows a behaviour
# of the Ticket has no place in the repository the run builds in. Run, never read, from anywhere
# inside the session's repository.
#
#   spec-finding.sh <the Ticket's path> <repository name> <behaviour> [<location>]
#                                         a relative Ticket path is read from the directory the
#                                         script runs in, then from the main checkout
#
# Writes to the spec.md beside the Ticket's issues/ folder: one entry `- <name>: <location>` at the
# end of its ## Repositories section, the section created first where the spec format places it, with
# the entry `- <the Home root's base name> (Home repository): <the Home root>`, when the Spec has
# none, and the finding line
# `- Moved by the run on Ticket <title> at the Plan step: <behaviour>. Belongs to: <name>.`
# at the end of its ## Implementation Decisions section, <title> being the Ticket's `# ` heading.
# With no location given for a name the list does not hold, no entry is written, since an entry with
# no location is one no skill can read, and the finding line ends in ` Location not known.` instead.
#
# Prints key=value lines and never a sentence, in this order: spec (the Spec's absolute path),
# repository (the name given), listed (yes or no: whether the Spec's list held the name before the
# call, matched as ticket-read.sh's repository_location_of matches it), list (added, unchanged for
# a listed name, whose entry is never rewritten, or no-location for a name not listed and given no
# location, which gets no entry), line (written, or present when the section already
# holds that very line, which is never written twice), home (the Home repository, the root
# ticket-door.sh prints as root), home_name (the name of the list's entry marked `(Home repository)`,
# none with no such entry), here (yes when home is this session's main checkout, else no).
#
# Exit codes: 0 the lines above, the Spec written · 2 usage or no Ticket at the path · 3 `failed
# <reason>` on one line and nothing written: no Spec beside the Ticket's issues/ folder, a Spec
# with no Implementation Decisions section, two entries or two sections for the name, a name, a
# behaviour or a location carrying a line break, a name that is empty, opens or ends with whitespace or carries `: `, the Home repository
# mark or a backtick, a behaviour carrying `Belongs to:`, a Ticket title carrying a line break or
# one of the finding line's two marks, or a location that is not a bare absolute path with no
# backtick, no `..` and no trailing whitespace.
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd -P)"
# shellcheck source=skills/do/scripts/ticket-read.sh
. "$here/ticket-read.sh"

usage() {
  echo "usage: spec-finding.sh <the Ticket's path> <repository name> <behaviour> [<location>]" >&2
  exit 2
}
failed() {
  echo "failed $1"
  exit 3
}

# The line goes through the environment: awk -v would read a backslash in a behaviour as an escape.
# The heading is matched with its trailing whitespace left out, as the readers of the list match it.
append_to_section() { # $1 file, $2 section heading, $3 line: writes the line after the section's last non-blank line
  local last tmp
  last="$(awk -v heading="$2" '!on && is_heading() { on = 1; last = NR; next } on && /^## / { exit } on && NF { last = NR }
    END { print last }
    function is_heading(  line) { line = $0; sub(/[[:space:]]+$/, "", line); return line == heading }' "$1")"
  tmp="$(mktemp)"
  LINE="$3" awk -v last="$last" '{ print } NR == last { if (/^## /) print ""; print ENVIRON["LINE"] }' "$1" >"$tmp"
  cat "$tmp" >"$1"
  rm -f "$tmp"
}

# A Spec of one repository carries no list, and the format never writes one with a single entry, so
# the section is born with the Home repository's own entry and the caller appends the second.
create_repositories_section() { # $1 file, $2 the Home repository's root: writes the section before ## User Stories, else before ## Implementation Decisions
  local anchor="## Implementation Decisions" tmp
  ! grep -qx '## User Stories' "$1" || anchor="## User Stories"
  tmp="$(mktemp)"
  ENTRY="- $(basename "$2") (Home repository): $2" awk -v anchor="$anchor" '$0 == anchor && !done {
    print "## Repositories"; print ""; print ENVIRON["ENTRY"]; print ""; done = 1 } { print }' "$1" >"$tmp"
  cat "$tmp" >"$1"
  rm -f "$tmp"
}

[ "$#" = 3 ] || [ "$#" = 4 ] || usage
name="$2" behaviour="$3" location="${4:-}"
# The three values come from a Plan cut from a Ticket a stranger may have appended to, and each is
# written as one line of the Spec: a line break in one would plant a second line there, a forged
# Ruling or a forged Home repository entry among them.
has_break() { case "$1" in *$'\n'* | *$'\r'*) return 0 ;; *) return 1 ;; esac }
! has_break "$name" || failed "the repository name carries a line break"
! has_break "$behaviour" || failed "the behaviour carries a line break"
! has_break "$location" || failed "the location carries a line break"
# An entry is read back as `- <name>[ (Home repository)]: <location>`, split at the first `: `, so a
# name carrying either mark would be read as another repository's entry, or as a second Home one.
case "$name" in
  "") failed "the repository name is empty" ;;
  *": "*) failed "the repository name carries a colon and a space" ;;
  *"(Home repository)"*) failed "the repository name carries the Home repository mark" ;;
  *'`'*) failed "the repository name carries a backtick" ;;
  [[:space:]]* | *[[:space:]]) failed "the repository name opens or ends with whitespace" ;;
esac
# The finding line is read back at its one `Belongs to:` mark, so a behaviour carrying the mark
# would name a second repository for the same line.
case "$behaviour" in *"Belongs to:"*) failed "the behaviour carries a Belongs to: mark of its own" ;; esac
case "$location" in
  "") ;;
  *[[:space:]]) failed "the location ends with whitespace" ;;
  *'`'*) failed "the location carries a backtick" ;;
  */../* | */..) failed "the location carries a .. segment" ;;
  /*) ;;
  *) failed "the location is not an absolute path" ;;
esac

main="$(main_of .)"
case "$1" in
  /*) path="$1" ;;
  *) if [ -f "$1" ]; then path="$(pwd -P)/${1#./}"; else path="$main/${1#./}"; fi ;;
esac
[ -f "$path" ] || {
  echo "no Ticket at $1" >&2
  exit 2
}

spec="$(spec_beside "$path")"
[ "$spec" != /dev/null ] || failed "no Spec beside the Ticket's issues/ folder"
grep -qx '## Implementation Decisions' "$spec" || failed "no Implementation Decisions section in $spec"
title="$(grep -m1 '^# ' "$path" | sed 's/^# //')"
# The title stands between the finding line's two marks, and a Ticket's heading is text a stranger
# may have written, so it is held to what the behaviour is held to.
! has_break "$title" || failed "the Ticket's title carries a line break"
case "$title" in
  *"at the Plan step:"*) failed "the Ticket's title carries an at the Plan step: mark of its own" ;;
  *"Belongs to:"*) failed "the Ticket's title carries a Belongs to: mark of its own" ;;
esac

repository_location_of "$path" "$name"
case "$word" in
  ambiguous) failed "$detail in $spec" ;;
  none) listed=no ;;
  *) listed=yes ;;
esac

echo "spec=$spec"
echo "repository=$name"
echo "listed=$listed"
home="$(home_root "$path" "$main")"
finding="- Moved by the run on Ticket $title at the Plan step: $behaviour. Belongs to: $name."
if [ "$listed" = yes ]; then
  echo "list=unchanged"
elif [ -z "$location" ]; then
  finding="$finding Location not known."
  echo "list=no-location"
else
  grep -q '^## Repositories[[:space:]]*$' "$spec" || create_repositories_section "$spec" "$home"
  append_to_section "$spec" "## Repositories" "- $name: $location"
  echo "list=added"
fi
if awk '$0 == "## Implementation Decisions" { on = 1; next } on && /^## / { exit } on' "$spec" | grep -qxF -- "$finding"; then
  echo "line=present"
else
  append_to_section "$spec" "## Implementation Decisions" "$finding"
  echo "line=written"
fi

home_name="$(awk '/^## Repositories[[:space:]]*$/ { on = 1; next } on && /^## / { exit }
  on && /^- / { e = substr($0, 3); i = index(e, ": "); if (!i) next; n = substr(e, 1, i - 1)
    if (sub(/[[:space:]]+\(Home repository\)$/, "", n)) { print n; exit } }' "$spec")"
echo "home=$home"
echo "home_name=${home_name:-none}"
if [ "$home" = "$main" ]; then echo "here=yes"; else echo "here=no"; fi
