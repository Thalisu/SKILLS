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
# end of its ## Repositories section, and the finding line
# `- Moved by the run on Ticket <title> at the Plan step: <behaviour>. Belongs to: <name>.`
# at the end of its ## Implementation Decisions section, <title> being the Ticket's `# ` heading.
#
# Prints key=value lines and never a sentence, in this order: spec (the Spec's absolute path),
# repository (the name given), listed (whether the Spec's list held the name before the call),
# list (added), line (written).
#
# Exit codes: 0 the lines above, the Spec written · 2 usage or no Ticket at the path · 3 `failed
# <reason>` on one line and nothing written: no Spec beside the Ticket's issues/ folder, or a Spec
# with no Implementation Decisions section.
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
append_to_section() { # $1 file, $2 section heading, $3 line: writes the line after the section's last non-blank line
  local last tmp
  last="$(awk -v heading="$2" '$0 == heading { on = 1; last = NR; next } on && /^## / { exit } on && NF { last = NR }
    END { print last }' "$1")"
  tmp="$(mktemp)"
  LINE="$3" awk -v last="$last" -v heading="$2" '{ print } NR == last { if ($0 == heading) print ""; print ENVIRON["LINE"] }' "$1" >"$tmp"
  cat "$tmp" >"$1"
  rm -f "$tmp"
}

[ "$#" = 3 ] || [ "$#" = 4 ] || usage
name="$2" behaviour="$3" location="${4:-}"

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

echo "spec=$spec"
echo "repository=$name"
echo "listed=no"
append_to_section "$spec" "## Repositories" "- $name: $location"
echo "list=added"
append_to_section "$spec" "## Implementation Decisions" "- Moved by the run on Ticket $title at the Plan step: $behaviour. Belongs to: $name."
echo "line=written"
