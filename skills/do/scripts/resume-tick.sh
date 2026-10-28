#!/usr/bin/env bash
# resume-tick.sh: the Built list and the tick of a resumed ticket run, read off resume-state.sh's
# behaviour= lines. Run from anywhere inside the project, the main checkout or a worktree of it.
#
#   resume-tick.sh built <Ticket path | issue ref>
#     one built=<text> per behaviour= line whose text is not none, oldest commit first, <text> being
#     the line past its behaviour=<short sha> prefix; built=none once when no line qualifies
#
# Exit codes: 0 · 2 usage, an unknown subcommand, a missing argument, or resume-state.sh exiting 2.
set -uo pipefail

usage() {
  echo "usage: resume-tick.sh built <the Ticket's path, or its issue reference>" >&2
  exit 2
}

# Every behaviour= line resume-state.sh prints whose text is not none, as <short sha> <text>.
built_pairs() { # $1 the Ticket
  local state rc=0
  state="$(bash "$(dirname "$0")/resume-state.sh" "$1")" || rc=$?
  [ "$rc" != 2 ] || exit 2
  sed -n 's/^behaviour=//p' <<<"$state" | awk '{ sha = $1; sub(/^[^ ]+ /, ""); if ($0 != "none") print sha " " $0 }'
}

[ "$#" -ge 1 ] || usage
case "$1" in
  built)
    [ "$#" = 2 ] || usage
    pairs="$(built_pairs "$2")" || exit 2
    if [ -z "$pairs" ]; then
      echo "built=none"
    else
      sed 's/^[^ ]* /built=/' <<<"$pairs"
    fi
    ;;
  *) usage ;;
esac
exit 0
