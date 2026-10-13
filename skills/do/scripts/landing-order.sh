#!/usr/bin/env bash
# landing-order.sh: the order the repositories of a feature land in, read from the Tickets of the
# issues/ folder that holds the Ticket it is given. Reads only: no file written, no ref moved, no
# claim taken. Run from anywhere inside the session's repository, the main checkout or a worktree.
#
#   landing-order.sh <the Ticket's path>    absolute in any repository on this machine, or relative
#                                           to the directory the script runs in, then to the main
#                                           checkout
#
# Prints key=value lines, in this order: ticket, repositories=<n>, then <n> repository groups in
# landing order. Each value is the whole rest of its line, so a name or a location with a space
# stays whole.
#
# A repository group, in this order: repository (the Build repository name as the Tickets write
# it), repository_location (its location in the Spec's ## Repositories section, unlisted with no
# entry), repository_here (yes when that location's main worktree is the session's main checkout),
# repository_state (landed or unlanded), repository_ticket (the absolute path of the
# highest-numbered Ticket built in it, the argument of its landing command).
#
# Landing order: repository A is blocked by repository B when a Ticket built in A names, in Blocked
# by, a Ticket built in B. A provider comes before what consumes it, and among the repositories no
# remaining edge orders, the one whose lowest-numbered Ticket has the smallest number goes first.
#
# Exit codes: 0 the record was read · 1 the edges hold a cycle · 2 usage, no file at the path, or
# not a git repository.
# shellcheck disable=SC2154 # the readers of ticket-read.sh set word and detail.
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd -P)"
# shellcheck source=skills/do/scripts/ticket-read.sh
. "$here/ticket-read.sh"

usage() {
  echo "usage: landing-order.sh <the Ticket's path>" >&2
  exit 2
}
[ "$#" = 1 ] || usage

git rev-parse --show-toplevel >/dev/null 2>&1 || {
  echo "not a git repository" >&2
  exit 2
}
main="$(main_of .)"

case "$1" in
  /*) path="$1" ;;
  *) if [ -f "$1" ]; then path="$(pwd -P)/${1#./}"; else path="$main/${1#./}"; fi ;;
esac
[ -f "$path" ] || {
  echo "no Ticket at $1" >&2
  exit 2
}

# The state is that repository's own refs, so the probe runs with its cwd inside it.
repository_state_of() { # $1 location, $2 the Ticket's absolute path: prints landed or unlanded
  local probe
  probe="$(cd "$1" && bash "$here/spec-branch.sh" probe "$2")"
  case "$(sed -n 's/^spec_landed=//p' <<<"$probe")" in
    yes) echo landed ;;
    *) echo unlanded ;;
  esac
}

declare -a names=()
declare -A last_ticket=() repository_of=() providers=()

read_tickets() { # fills names in order of lowest Ticket number, last_ticket, repository_of and providers
  local file number name blocker
  while IFS= read -r file; do
    number="$(basename "$file")"
    number="$((10#${number%%-*}))"
    build_repository_of "$file"
    name="$word"
    [ -n "${last_ticket[$name]:-}" ] || names+=("$name")
    last_ticket[$name]="$file"
    repository_of[$number]="$name"
  done < <(ticket_files "$(dirname "$path")")
  while IFS= read -r file; do
    build_repository_of "$file"
    name="$word"
    blockers_of "$file"
    case "$word" in none | ambiguous) continue ;; esac
    for blocker in $word; do
      blocker="${repository_of[$((10#$blocker))]:-}"
      [ -n "$blocker" ] && [ "$blocker" != "$name" ] || continue
      providers[$name]+="$blocker"$'\n'
    done
  done < <(ticket_files "$(dirname "$path")")
}

landing_order() { # prints one repository name per line in landing order; returns 1 with the cycle's names when the edges hold one
  local -A placed=()
  local -a left=("${names[@]}") rest
  local name provider free picked
  while [ "${#left[@]}" -gt 0 ]; do
    picked="" rest=()
    for name in "${left[@]}"; do
      free=1
      while IFS= read -r provider; do
        [ -z "$provider" ] || [ -n "${placed[$provider]:-}" ] || free=0
      done <<<"${providers[$name]:-}"
      if [ -z "$picked" ] && [ "$free" = 1 ]; then picked="$name"; else rest+=("$name"); fi
    done
    if [ -z "$picked" ]; then
      printf '%s\n' "${left[@]}"
      return 1
    fi
    echo "$picked"
    placed[$picked]=1
    left=("${rest[@]}")
  done
}

read_tickets
ordered="$(landing_order)" || {
  echo "the repositories block each other in a cycle: ${ordered//$'\n'/, }" >&2
  exit 1
}

echo "ticket=${path#"$main"/}"
echo "repositories=${#names[@]}"
while IFS= read -r name; do
  file="${last_ticket[$name]}"
  repository_location_of "$file" "$name"
  location="${word/#none/unlisted}"
  echo "repository=$name"
  echo "repository_location=$location"
  if [ "$(build_check_of "$name" "$location")" = here ]; then echo "repository_here=yes"; else echo "repository_here=no"; fi
  echo "repository_state=$(repository_state_of "$location" "$file")"
  echo "repository_ticket=$file"
done <<<"$ordered"
