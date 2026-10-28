#!/usr/bin/env bash
# resume-tick.sh: the Built list and the tick of a resumed ticket run, read off resume-state.sh's
# behaviour= lines. Run from anywhere inside the project, the main checkout or a worktree of it.
#
#   resume-tick.sh built <Ticket path | issue ref>
#     one built=<text> per behaviour= line whose text is not none, oldest commit first, <text> being
#     the line past its behaviour=<short sha> prefix; built=none once when no line qualifies
#   resume-tick.sh tick <Ticket path | issue ref> <Plan path>
#     one item=<n> <short sha> | item=<n> open per item of the Plan's ## Behaviours section that
#     carries `Behavior to prove:`, in Plan order, ticked with the oldest commit whose built text
#     equals the item's text exactly; then one stray=<short sha> <text> per built text that equals
#     no item's text, oldest first
#
# Exit codes: 0 · 2 usage, an unknown subcommand, a missing argument, an unreadable Plan, or
# resume-state.sh exiting 2 · 3 the Plan has no ## Behaviours section.
set -uo pipefail

usage() {
  echo "usage: resume-tick.sh built <the Ticket's path, or its issue reference>" >&2
  echo "       resume-tick.sh tick <the Ticket's path, or its issue reference> <the Plan's path>" >&2
  exit 2
}

# Every behaviour= line resume-state.sh prints whose text is not none, as <short sha> <text>.
built_pairs() { # $1 the Ticket
  local state rc=0
  state="$(bash "$(dirname "$0")/resume-state.sh" "$1")" || rc=$?
  [ "$rc" != 2 ] || exit 2
  sed -n 's/^behaviour=//p' <<<"$state" | awk '{ sha = $1; sub(/^[^ ]+ /, ""); if ($0 != "none") print sha " " $0 }'
}

# Each `Behavior to prove:` item of the Plan's ## Behaviours section, as <n><TAB><text>.
plan_items() { # $1 the Plan
  awk '
    /^## / { on = ($0 == "## Behaviours"); next }
    !on { next }
    match($0, /^[0-9]+\. Behavior to prove: /) {
      n = $0; sub(/\..*/, "", n)
      print n "\t" substr($0, RLENGTH + 1)
    }
  ' "$1"
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
  tick)
    [ "$#" = 3 ] || usage
    [ -r "$3" ] || {
      echo "no readable Plan at $3" >&2
      exit 2
    }
    grep -qx '## Behaviours' "$3" || {
      echo "$3 has no ## Behaviours section" >&2
      exit 3
    }
    pairs="$(built_pairs "$2")" || exit 2
    plan_items "$3" | PAIRS="$pairs" awk -F '\t' '
      BEGIN {
        m = split(ENVIRON["PAIRS"], line, "\n")
        for (i = 1; i <= m; i++) {
          sha[i] = line[i]; sub(/ .*/, "", sha[i])
          text[i] = substr(line[i], length(sha[i]) + 2)
          if (!(text[i] in tick)) tick[text[i]] = sha[i]
        }
      }
      { item[$2] = 1; print "item=" $1 " " (($2 in tick) ? tick[$2] : "open") }
      END { for (i = 1; i <= m; i++) if (!(text[i] in item)) print "stray=" sha[i] " " text[i] }
    '
    ;;
  *) usage ;;
esac
exit 0
