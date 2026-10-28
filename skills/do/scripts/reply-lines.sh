#!/usr/bin/env bash
# reply-lines.sh: the lines a /do Reply copies for the Final integration, the repositories of a
# feature, the Spec landing and the stop on work for another repository, printed from the saved
# stdout of the state scripts the session ran. Reads only: writes nothing, runs no other script.
#
#   reply-lines.sh final        --door <f> [--state <f>] [--claim <f>] [--release <f>] [--yield <f>]
#                               [--order <f>] [--review <f>] [--reason <text>]
#   reply-lines.sh repositories --door <f> [--claim <f>] [--release <f>] [--yield <f>] [--order <f>]
#   reply-lines.sh landing      --door <f> --land <f> [--check <f>]
#   reply-lines.sh elsewhere    --door <f> [--build <worktree>] <finding file> <behaviour> [<finding file> <behaviour>]...
#
# Each <f> is one state script's saved key=value output, read in a key space of its own, the last
# occurrence of a key winning: --door ticket-door.sh, --state final-state.sh, --claim
# `final-claim.sh claim`, --release `final-claim.sh release`, --yield `final-claim.sh yield`,
# --order landing-order.sh (the run's last read), --land land-spec.sh's one line, --check
# completion-check.sh. A finding file is spec-finding.sh's output, its behaviour the argument the
# session gave it. --review holds the Integration line and the
# Review return as the session wrote them, copied as they stand.
#
# The same files and arguments print the same lines.
#
# Exit codes: 0 the lines · 2 usage (no or unknown subcommand, unknown flag, a flag given twice, a
# required flag missing, a file not readable) · 3 `failed <reason>` on one line, nothing else.
set -uo pipefail

usage() {
  echo "usage: reply-lines.sh final|repositories|landing|elsewhere --door <f> [--state <f>] [--claim <f>] [--release <f>] [--yield <f>] [--order <f>] [--review <f>] [--reason <text>]" >&2
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
  if [ "$door" = resume-final ] && [ -z "${given[claim]-}" ] && [ "$order" = wait ]; then
    echo out-of-order
  elif [ "$door" = resolved ] && [ "$order" = landed ] && [ "$(v order next_landing)" != "done" ]; then
    echo already-landed
  elif [ -z "${given[claim]-}" ] && [ "$order" = wait ]; then
    echo waiting
  elif [ "$claim" = taken ] && [ "$door" = resume-final ]; then
    echo not-resumed
  elif [ "$claim" = taken ]; then
    echo claimed-elsewhere
  elif [ "$claim" = claimed ] && [ "$(v release claim)" = released ]; then
    echo landed
  elif [ "$claim" = claimed ] && [ "$(v yield claim)" = yielded ] && [ "$(v claim takeover)" = yes ]; then
    echo stopped-again
  elif [ "$claim" = claimed ] && [ "$(v yield claim)" = yielded ]; then
    echo stopped
  else
    failed no-shape
  fi
}

g_name=() g_location=() g_here=() g_state=() g_reason=() g_ticket=()

load_groups() { # the --order record's repository groups, in its order, into the g_ arrays
  local line key value n=-1
  [ -n "${given[order]-}" ] || return 0
  while IFS= read -r line || [ -n "$line" ]; do
    key="${line%%=*}" value="${line#*=}"
    case "$key" in
      repository)
        n=$((n + 1))
        g_name[n]="$value" g_location[n]="" g_here[n]="" g_state[n]="" g_reason[n]="" g_ticket[n]=""
        ;;
      repository_location) [ "$n" -lt 0 ] || g_location[n]="$value" ;;
      repository_here) [ "$n" -lt 0 ] || g_here[n]="$value" ;;
      repository_state) [ "$n" -lt 0 ] || g_state[n]="$value" ;;
      repository_reason) [ "$n" -lt 0 ] || g_reason[n]="$value" ;;
      repository_ticket) [ "$n" -lt 0 ] || g_ticket[n]="$value" ;;
    esac
  done <"${given[order]}"
}

joined() { # $@ the entries: comma-joined, or none when there is none
  local IFS=,
  if [ "$#" = 0 ]; then echo none; else
    local out="$*"
    echo "${out//,/, }"
  fi
}

group_lines() { # the record's groups -> the Landed: and Still to land: lines
  local i landed=() still=()
  for i in "${!g_name[@]}"; do
    if [ "${g_state[i]}" = landed ]; then
      landed+=("${g_name[i]}")
    elif [ "${g_state[i]}" = unreadable ]; then
      still+=("${g_name[i]} (unreadable: ${g_reason[i]})")
    else
      still+=("${g_name[i]}")
    fi
  done
  echo "Landed: $(joined "${landed[@]}")"
  echo "Still to land: $(joined "${still[@]}")"
}

command_lines() { # $1 the shape: the record's groups -> a place line and a /do line per group still to land
  local i once=""
  [ "$1" != waiting ] || once=", once $(v order waits_for) landed"
  for i in "${!g_name[@]}"; do
    [ "${g_state[i]}" != landed ] || continue
    if [ "${g_here[i]}" = yes ]; then
      echo "${g_name[i]}: this session's repository$once"
    elif [ "${g_location[i]}" = unlisted ]; then
      echo "${g_name[i]}: the Spec's ## Repositories list holds no location for it"
    else
      echo "${g_name[i]}: open a session in ${g_location[i]}"
    fi
    echo "/do ${g_ticket[i]}"
  done
}

cmd_repositories() {
  local shape count next location ticket
  shape="$(select_shape)" || {
    echo "$shape"
    exit 3
  }
  case "$shape" in
    out-of-order)
      value_of next order next_landing
      value_of location order next_landing_location
      value_of ticket order next_landing_ticket
      echo "$next: open a session in $location"
      echo "/do $ticket"
      ;;
    landed | waiting | already-landed)
      value_of count order repositories
      [ "$count" -gt 1 ] || return 0
      load_groups
      group_lines
      if [ "$(v order next_landing)" = "done" ]; then
        echo "Every repository of the feature landed"
      else
        command_lines "$shape"
      fi
      ;;
  esac
}

open_entries() { # the --check record's open= lines -> one `<stem> (<status>)` entry each, comma-joined
  local line rest status path entries=()
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in open=none | open=) continue ;; open=*) ;; *) continue ;; esac
    rest="${line#open=* }"
    status="${rest%% *}"
    path="${rest#* }"
    path="${path##*/}"
    entries+=("${path%.md} ($status)")
  done <"${given[check]}"
  [ "${#entries[@]}" = 0 ] || joined "${entries[@]}"
}

physical() { # $1 a path: its physical form when it can be entered, else as given
  (cd "$1" 2>/dev/null && pwd -P) || printf '%s\n' "$1"
}

main_checkout() { # the session's main checkout, physical, from the directory the script runs in
  local line
  line="$(git worktree list --porcelain 2>/dev/null | head -n 1)"
  [ -n "$line" ] || {
    echo "reply-lines.sh: not inside a git repository" >&2
    exit 2
  }
  physical "${line#worktree }"
}

cmd_landing() {
  local land branch entries root main build
  IFS= read -r land <"${given[land]}" || [ -n "$land" ] || failed "land unknown"
  value_of branch door spec_branch
  value_of root door root
  value_of build door build_repository
  main="$(main_checkout)" || exit 2
  root="$(physical "$root")"
  if [ "$root" != "$main" ]; then
    if [ "$build" = none ]; then
      echo "Repositories: built in $main, artifacts in $root"
    else
      echo "Repositories: built in $build ($main), artifacts in $root"
    fi
  fi
  case "$land" in
    "landed "*) echo "landed at ${land#landed } on $branch" ;;
    "checked-out "*) echo "not landed: $branch is checked out in ${land#checked-out }" ;;
    "moved "* | "failed "*) echo "not landed: $land" ;;
    *) failed "land unknown" ;;
  esac
  echo "Review: none, the Spec is reviewed once its last Ticket lands"
  if [ "${land%% *}" = landed ] && [ -n "${given[check]-}" ]; then
    entries="$(open_entries)"
    if [ -n "$entries" ]; then
      echo "Open: $entries"
    elif [ "$(v check verdict)" = complete ]; then
      echo "Open: none"
    fi
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
  local shape branch holder since number own waits location next count again="" resumed=no
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
    out-of-order)
      value_of next order next_landing
      echo "Final integration: not started, $next has to land first"
      ;;
    already-landed)
      value_of own order own
      echo "Final integration: not started, $own already landed"
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
    stopped | stopped-again)
      [ -n "${given[reason]-}" ] || failed "--reason missing"
      value_of count order repositories
      [ "$shape" = stopped ] || again=" again"
      [ "$resumed" = no ] || resume_line
      echo "Final integration: stopped$again: ${given[reason]}"
      if [ "$count" -gt 1 ]; then
        load_groups
        group_lines
      fi
      ;;
  esac
}

cmd_elsewhere() { # $@ finding file and behaviour pairs: the whole stop message after its first line
  local i=0 spec home number status relative repository written list line moved
  local out=() listed=() unknown=() pairs=("$@") command
  while [ "$#" -ge 2 ]; do
    i=$((i + 1))
    [ -f "$1" ] && [ -r "$1" ] || usage
    read_source "finding$i" "$1"
    if [ "$i" = 1 ]; then
      value_of spec finding1 spec
      value_of home finding1 home
    fi
    shift 2
  done
  number="$(ticket_number)" || {
    echo "$number"
    exit 3
  }
  value_of status door status
  relative="${spec#"$home"/}"
  command="/tickets $relative"
  set -- "${pairs[@]}"
  i=0
  while [ "$#" -ge 2 ]; do
    i=$((i + 1))
    value_of repository "finding$i" repository
    value_of list "finding$i" list
    value_of line "finding$i" line
    moved="one line naming the behaviour as moved by the run on Ticket $number"
    [ "$line" != present ] || moved="the line naming the behaviour as moved, already there, written by an earlier run on Ticket $number"
    case "$list" in
      added) written="$repository added to its repositories list, and $moved." ;;
      unchanged) written="$moved; $repository was already in its repositories list." ;;
      no-location) written="$moved, with the location of $repository marked as not known. No entry was added to its repositories list." ;;
      *) failed no-shape ;;
    esac
    if [ "$list" = no-location ]; then
      unknown+=("$repository")
      command="$command $repository: <its absolute location on this machine>"
    else
      listed+=("$repository")
    fi
    out+=("Stopped at the Plan, before anything was built: \"$2\" has no place in this repository. It belongs to $repository.")
    out+=("Written into the Spec ($relative): $written")
    shift 2
  done
  out+=("Ticket $number still reads $status.")
  if [ "${#unknown[@]}" = 0 ]; then
    out+=("Yours: outward: cut the moved behaviour for $(joined "${listed[@]}") with the command below, then run /do on this Ticket again")
  else
    out+=("Yours: outward: the location of $(joined "${unknown[@]}") on this machine is the one thing you supply: type it in the command below in place of <its absolute location on this machine>, with no file to edit by hand, then run /do on this Ticket again")
  fi
  out+=("$command")
  printf '%s\n' "${out[@]}"
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
      case "$name" in review | land) ;; *) read_source "$name" "$2" ;; esac
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
  landing)
    parse_flags "door land check" "" "$@"
    [ -n "${given[door]-}" ] && [ -n "${given[land]-}" ] || usage
    cmd_landing
    ;;
  repositories)
    parse_flags "door claim release yield order" "" "$@"
    [ -n "${given[door]-}" ] || usage
    cmd_repositories
    ;;
  elsewhere)
    flags=()
    while [ "$#" -gt 0 ] && [[ "$1" == --* ]]; do
      [ "$#" -ge 2 ] || usage
      flags+=("$1" "$2")
      shift 2
    done
    parse_flags "door" "build" "${flags[@]}"
    [ -n "${given[door]-}" ] || usage
    [ -z "${given[build]-}" ] || [ -d "${given[build]}" ] || usage
    [ "$#" -ge 2 ] && [ "$(($# % 2))" = 0 ] || usage
    cmd_elsewhere "$@"
    ;;
  *) usage ;;
esac
