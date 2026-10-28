#!/usr/bin/env bash
# reply-lines.sh: the lines a /do Reply copies for the Final integration, the repositories of a
# feature, the Spec landing and the stop on work for another repository, printed from the saved
# stdout of the state scripts the session ran. Reads only: writes nothing, runs no other script.
#
#   reply-lines.sh final        --door <f> [--state <f>] [--claim <f>] [--release <f>] [--yield <f>]
#                               [--order <f>] [--review <f>] [--reason <text>]
#
# Each <f> is one state script's saved key=value output, read in a key space of its own, the last
# occurrence of a key winning: --door ticket-door.sh, --state final-state.sh, --claim
# `final-claim.sh claim`, --release `final-claim.sh release`, --yield `final-claim.sh yield`,
# --order landing-order.sh (the run's last read). --review holds the Integration line and the
# Review return as the session wrote them, copied as they stand.
#
# The same files and arguments print the same lines.
#
# Exit codes: 0 the lines · 2 usage (no or unknown subcommand, unknown flag, a flag given twice, a
# required flag missing, a file not readable) · 3 `failed <reason>` on one line, nothing else.
set -uo pipefail

usage() {
  echo "usage: reply-lines.sh final --door <f> [--state <f>] [--claim <f>] [--release <f>] [--yield <f>] [--order <f>] [--review <f>] [--reason <text>]" >&2
  exit 2
}

failed() { # $1 reason
  echo "failed $1"
  exit 3
}

declare -A kv=() given=()

read_source() { # $1 flag, $2 file: loads its key=value lines into that flag's key space
  local line
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in *=*) kv["$1:${line%%=*}"]="${line#*=}" ;; esac
  done <"$2"
}

has() { # $1 flag, $2 key
  local key="$1:$2"
  [ -n "${kv[$key]+set}" ]
}

v() { # $1 flag, $2 key: the last value, empty when the key is absent
  local key="$1:$2"
  printf '%s' "${kv[$key]-}"
}

value_of() { # $1 the variable to set, $2 flag, $3 key: its last value, or the missing-key refusal
  has "$2" "$3" || failed "--$2 $3 missing"
  printf -v "$1" '%s' "$(v "$2" "$3")"
}

select_shape() { # the sources present -> one FinalShape word, or failed no-shape
  local flag
  for flag in claim release yield; do
    [ "$(v "$flag" claim)" != failed ] || failed "--$flag failed"
  done
  local door claim order
  door="$(v door verdict)" claim="$(v claim claim)" order="$(v order verdict)"
  if [ -z "${given[claim]-}" ] && [ "$order" = wait ]; then
    echo waiting
  elif [ "$claim" = taken ] && [ "$door" = resume-final ]; then
    echo not-resumed
  elif [ "$claim" = taken ]; then
    echo claimed-elsewhere
  elif [ "$claim" = claimed ] && [ "$(v release claim)" = released ]; then
    echo landed
  else
    failed no-shape
  fi
}

ticket_number() { # the door Ticket's leading number, from its file name
  local ticket
  value_of ticket door ticket
  ticket="${ticket##*/}"
  echo "${ticket%%[!0-9]*}"
}

resume_line() { # the opener of a resumed Final integration
  local verdict line previous yielded
  value_of verdict state verdict
  line="Final integration: resumed from $verdict"
  if has state stop; then line="$line, stop $(v state stop)"; fi
  if [ "$(v claim takeover)" = yes ]; then
    value_of previous claim previous_ticket
    value_of yielded claim yielded_at
    line="$line, taken over from $previous yielded at $yielded"
  fi
  echo "$line"
}

cmd_final() {
  local shape branch holder since number own waits location resumed=no
  shape="$(select_shape)" || {
    echo "$shape"
    exit 3
  }
  [ "$(v door verdict)" != resume-final ] || resumed=yes
  case "$shape" in
    claimed-elsewhere | not-resumed)
      value_of holder claim holder_ticket
      value_of since claim claimed_at
      if [ "$shape" = not-resumed ]; then
        echo "Final integration: not resumed, its claim is held by $holder since $since"
      else
        number="$(ticket_number)" || {
          echo "$number"
          exit 3
        }
        echo "Final integration: the Spec is being integrated by another run, $holder since $since; Ticket $number landed and reads resolved"
      fi
      ;;
    waiting)
      value_of own order own
      value_of waits order waits_for
      value_of location order waits_for_location
      echo "Final integration: not started, the feature is complete and $own waits for $waits to land, at $location"
      echo "Open: none"
      ;;
    landed)
      [ -n "${given[review]-}" ] || failed "--review missing"
      [ "$(v release removed)" != yes ] || value_of branch release spec_branch
      if [ "$resumed" = yes ]; then
        resume_line
        echo "Open: none"
      fi
      cat "${given[review]}"
      [ -z "${branch-}" ] || echo "$branch removed"
      ;;
  esac
}

parse_flags() { # $1 the flags a file names, $2 the flags a text names, $3.. the arguments
  local files="$1" texts="$2" flag name
  shift 2
  while [ "$#" -gt 0 ]; do
    flag="$1"
    name="${flag#--}"
    [ "$#" -ge 2 ] && [ "$flag" != "$name" ] || usage
    [ -z "${given[$name]+set}" ] || usage
    if [[ " $files " == *" $name "* ]]; then
      [ -f "$2" ] && [ -r "$2" ] || usage
      given[$name]="$2"
      [ "$name" = review ] || read_source "$name" "$2"
    elif [[ " $texts " == *" $name "* ]]; then
      given[$name]="$2"
    else
      usage
    fi
    shift 2
  done
}

[ "$#" -ge 1 ] || usage
sub="$1"
shift
case "$sub" in
  final)
    parse_flags "door state claim release yield order review" "reason" "$@"
    [ -n "${given[door]-}" ] || usage
    cmd_final
    ;;
  *) usage ;;
esac
