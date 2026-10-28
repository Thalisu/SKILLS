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

value_of() { # $1 flag, $2 key: the last value, or the missing-key refusal
  has "$1" "$2" || failed "--$1 $2 missing"
  v "$1" "$2"
}

select_shape() { # the sources present -> one FinalShape word, or failed no-shape
  local flag
  for flag in claim release yield; do
    [ "$(v "$flag" claim)" != failed ] || failed "--$flag failed"
  done
  if [ "$(v claim claim)" = claimed ] && [ "$(v release claim)" = released ]; then
    echo landed
    return
  fi
  failed no-shape
}

cmd_final() {
  local shape branch
  shape="$(select_shape)" || {
    echo "$shape"
    exit 3
  }
  case "$shape" in
    landed)
      [ -n "${given[review]-}" ] || failed "--review missing"
      cat "${given[review]}"
      if [ "$(v release removed)" = yes ]; then
        branch="$(value_of release spec_branch)" || {
          echo "$branch"
          exit 3
        }
        echo "$branch removed"
      fi
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
