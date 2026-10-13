#!/usr/bin/env bash
# landing-order.sh: the order the repositories of a feature land in, read from the Tickets of the
# issues/ folder that holds the Ticket it is given. Reads only: no file written, no ref moved, no
# claim taken. Run from anywhere inside the session's repository, the main checkout or a worktree.
#
#   landing-order.sh <the Ticket's path>    absolute in any repository on this machine, or relative
#                                           to the directory the script runs in, then to the main
#                                           checkout
#
# Prints key=value lines, in this order: ticket, repositories=<n>, <n> repository groups in landing
# order, then own, waits_for, the next_landing lines and verdict. Each value is the whole rest of
# its line, so a name or a location with a space stays whole.
#
# A repository group, in this order: repository (the Build repository name as the Tickets write
# it), repository_location (its location in the Spec's ## Repositories section, unlisted with no
# entry), repository_here (yes when that location's main worktree is the session's main checkout),
# repository_state (landed, unlanded or unreadable), repository_reason only on unreadable
# (unlisted, missing or not-git), repository_ticket (the absolute path of the highest-numbered
# Ticket built in it, the argument of its landing command).
#
# The state is read from that repository's own refs, by spec-branch.sh probe run inside it: landed
# when its Spec branch is gone or its tip is on its upstream, unlanded while the branch holds a
# commit its upstream lacks, unreadable when the location cannot be entered. Nothing an earlier
# attempt wrote is read.
#
# A feature whose Tickets carry no Build repository line is a feature of one repository: its one
# group is named none, at the session's main checkout, and own and next_landing read that name.
#
# Landing order: repository A is blocked by repository B when a Ticket built in A names, in Blocked
# by, a Ticket built in B. A provider comes before what consumes it, and among the repositories no
# remaining edge orders, the one whose lowest-numbered Ticket has the smallest number goes first.
#
# After the groups: own (the group the argument Ticket belongs to), waits_for (the first group in
# landing order that own is directly blocked by and that does not read landed, none with none),
# waits_for_location only when that is a name, then next_landing, next_landing_location and
# next_landing_ticket (the first group in landing order that does not read landed, its location
# and its repository_ticket), or the single line next_landing=done when every group reads landed,
# then verdict. An unreadable repository counts as not landed.
#
# On the first four verdicts below the record is ticket, repositories=0, the verdict's own detail
# line (ambiguous=<NN> <detail>, or cycle=<name> <name> ...) and verdict, and no repository is
# probed.
#
# verdict, first match wins: no-spec (the Ticket sits in no feature folder's issues/) · ambiguous
# (a Ticket's status or Build repository line cannot be read, or one Ticket has no such line beside
# Tickets that carry one) · incomplete (a Ticket of the folder does not read resolved) · unordered
# (the repository edges hold a cycle) · elsewhere (own is not the session's repository) · landed
# (own reads landed) · wait (waits_for is a name) · land (the session's repository may run its
# Final integration now).
#
# Exit codes: 0 the record was read · 1 ambiguous or unordered · 2 usage, no file at the path, or
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

# The state is that repository's own refs, so the probe runs with its cwd inside it. With every
# Ticket of it resolved its Spec branch was cut, and spec-branch.sh removes one only once it landed,
# so a branch that is gone landed too.
repository_state_of() { # $1 its build_check word, $2 location, $3 the Ticket's absolute path: prints landed, unlanded, or unreadable and its reason
  local probe
  case "$1" in
    here | elsewhere) ;;
    *) echo "unreadable $1" && return ;;
  esac
  probe="$(cd "$2" && bash "$here/spec-branch.sh" probe "$3")"
  case "$(sed -n 's/^spec_landed=//p' <<<"$probe")" in
    no) echo unlanded ;;
    *) echo landed ;;
  esac
}

refuse() { # $1 verdict, $2 optional detail line, $3 exit code: the record of a feature with no landing order to print
  echo "ticket=${path#"$main"/}"
  echo "repositories=0"
  [ -z "${2:-}" ] || echo "$2"
  echo "verdict=$1"
  exit "${3:-0}"
}

declare -a names=()
declare -A last_ticket=() repository_of=() providers=()

read_tickets() { # fills names in order of lowest Ticket number, last_ticket, repository_of and providers
  local file number name blocker open=0 lineless=""
  while IFS= read -r file; do
    number="$(basename "$file")"
    number="${number%%-*}"
    status_of "$file"
    [ "$word" != ambiguous ] || refuse ambiguous "ambiguous=$number $detail" 1
    [ "$word" = resolved ] || open=1
    build_repository_of "$file"
    [ "$word" != ambiguous ] || refuse ambiguous "ambiguous=$number $detail" 1
    name="$word"
    [ "$name" != none ] || [ -n "$lineless" ] || lineless="$number"
    [ -n "${last_ticket[$name]:-}" ] || names+=("$name")
    last_ticket[$name]="$file"
    repository_of[$((10#$number))]="$name"
  done < <(ticket_files "$(dirname "$path")")
  [ -z "$lineless" ] || [ "${#names[@]}" = 1 ] || refuse ambiguous "ambiguous=$lineless no Build repository line beside Tickets that carry one" 1
  # Nothing lands while a Ticket is open anywhere, so no repository is entered to read its state.
  [ "$open" = 0 ] || refuse incomplete
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

[ "$(bash "$here/spec-branch.sh" probe "$path" | sed -n 's/^spec_branch=//p')" != none ] || refuse no-spec
read_tickets
ordered="$(landing_order)" || refuse unordered "cycle=${ordered//$'\n'/ }" 1

echo "ticket=${path#"$main"/}"
echo "repositories=${#names[@]}"
build_repository_of "$path"
own="$word"
declare -A location_of=() state_of=()
own_here=no waits_for=none next_landing=""
while IFS= read -r name; do
  file="${last_ticket[$name]}"
  if [ "$name" = none ]; then
    location="$main" check=here
  else
    repository_location_of "$file" "$name"
    location="${word/#none/unlisted}"
    check="$(build_check_of "$name" "$word")"
  fi
  here_word=no
  [ "$check" != here ] || here_word=yes
  state="$(repository_state_of "$check" "$location" "$file")"
  location_of[$name]="$location" state_of[$name]="${state%% *}"
  echo "repository=$name"
  echo "repository_location=$location"
  echo "repository_here=$here_word"
  echo "repository_state=${state%% *}"
  case "$state" in unreadable*) echo "repository_reason=${state#* }" ;; esac
  echo "repository_ticket=$file"
  [ "$name" != "$own" ] || own_here="$here_word"
  [ "${state%% *}" != landed ] || continue
  [ -n "$next_landing" ] || next_landing="$name"
  [ "$waits_for" != none ] || ! grep -qxF -- "$name" <<<"${providers[$own]:-}" || waits_for="$name"
done <<<"$ordered"

echo "own=$own"
echo "waits_for=$waits_for"
[ "$waits_for" = none ] || echo "waits_for_location=${location_of[$waits_for]}"
if [ -z "$next_landing" ]; then
  echo "next_landing=done"
else
  echo "next_landing=$next_landing"
  echo "next_landing_location=${location_of[$next_landing]}"
  echo "next_landing_ticket=${last_ticket[$next_landing]}"
fi
if [ "$own_here" = no ]; then
  verdict=elsewhere
elif [ "${state_of[$own]}" = landed ]; then
  verdict=landed
elif [ "$waits_for" != none ]; then
  verdict="wait"
else
  verdict=land
fi
echo "verdict=$verdict"
