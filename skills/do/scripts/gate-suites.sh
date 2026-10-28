#!/usr/bin/env bash
# gate-suites.sh: the full suites the project's Post-feature gate adds to a run, read off the main
# checkout's Project facts line and whether the Ticket is its feature's last. Reads only. Run from
# anywhere inside the project being built, the main checkout or a worktree of it.
#
#   gate-suites.sh <the Ticket's path>    last= as completion-check.sh prints it; a relative path is
#                                         read from the directory the script runs in, then from the
#                                         main checkout
#
# The facts value is the text after `- **Post-feature gate**: ` on the main checkout's CLAUDE.md,
# up to the next `:` or the line's end, trimmed.
# Prints last=, facts=, full_unit=yes|no, full_e2e=yes|no, in that order.
# Exit codes: 0 read · 2 not a git repository, or completion-check.sh exiting 2 (its stderr passed
# through, nothing printed).
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
# shellcheck source=skills/do/scripts/ticket-read.sh
. "$here/ticket-read.sh"

main="$(main_of .)"
[ -n "$main" ] || {
  echo "not a git repository" >&2
  exit 2
}
check="$(bash "$here/completion-check.sh" "$1")"
[ $? -ne 2 ] || exit 2
last="$(sed -n 's/^last=//p' <<<"$check")"
[ "$last" = yes ] || last=no

facts="$(sed -n 's/^- \*\*Post-feature gate\*\*: //p' "$main/CLAUDE.md" 2>/dev/null | head -1)"
facts="${facts%%:*}"
facts="$(sed 's/^ *//; s/ *$//' <<<"$facts")"

full_unit=no full_e2e=no
case "$facts" in
  "full unit suite") full_unit=yes ;;
  "full E2E suite") full_e2e=yes ;;
esac
printf 'last=%s\nfacts=%s\nfull_unit=%s\nfull_e2e=%s\n' "$last" "$facts" "$full_unit" "$full_e2e"
