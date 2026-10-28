#!/usr/bin/env bash
# next-step.sh: prints the body of a do Reply's `## Next step` section from the key=value lines a run
# holds, so the same lines on stdin print the same Next step.
#
#   <key=value lines> | next-step.sh
#
# Reads key=value lines on stdin, the last value of a key winning and keys no route reads ignored,
# so a script's output is piped whole. outcome= names the route.
# Exit codes: 0 printed · 2 usage: an argument, or a key the route needs missing; nothing on stdout.
set -uo pipefail

declare -A key

usage() {
  echo "next-step.sh: $1" >&2
  exit 2
}

read_keys() {
  local line
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      *=*) key["${line%%=*}"]="${line#*=}" ;;
    esac
  done
}

need() { # $@ the keys the route reads: exits 2 naming the first one missing
  local name
  for name in "$@"; do
    [ -n "${key[$name]:-}" ] || usage "missing $name="
  done
}

push_line() {
  need branch
  echo "git push origin ${key[branch]}"
}

repository_line() { # $1 the repository's name, $2 its location or unlisted
  if [ "$2" = unlisted ]; then
    echo "$1: the Spec's ## Repositories list holds no location for it"
  else
    echo "$1: open a session in $2"
  fi
}

next_line() { # the Completion check's next= routes, shared by spec-landed and setup-resolved
  need next
  case "${key[next]}" in
    wait)
      echo "Every open Ticket is claimed by another run: the Spec integrates when those runs land, and there is nothing to type."
      return
      ;;
    none)
      echo "Nothing else in the Spec is open, and there is nothing to type."
      return
      ;;
    ambiguous)
      need ambiguous
      echo "Repair the **Status:** line of Ticket ${key[ambiguous]%% *} (${key[ambiguous]#* })."
      return
      ;;
  esac
  if [ -n "${key[next_build]:-}" ]; then
    need next_build_location next_location
    repository_line "${key[next_build]}" "${key[next_build_location]}"
    echo "/do ${key[next_location]}"
    return
  fi
  echo "/do ${key[next]}"
}

landing_line() { # the landing record's next_landing= routes; a feature with no record takes the push
  case "${key[next_landing]:-done}" in
    done) push_line ;;
    *)
      need next_landing_ticket
      echo "/do ${key[next_landing_ticket]}"
      ;;
  esac
}

merge_lines() { # $1 awaiting when a required approval is missing: the pr routes
  need pr pushed
  [ "$1" = awaiting ] && echo "Once the required approval on pull request #${key[pr]} is given:"
  if [ "${key[pushed]}" = yes ]; then
    need head
    echo "On your checkout of ${key[head]}: git pull --ff-only origin ${key[head]}"
  fi
  echo "gh pr merge ${key[pr]}"
}

main() {
  [ "$#" = 0 ] || usage "takes no argument"
  read_keys
  need outcome
  case "${key[outcome]}" in
    landed) push_line ;;
    spec-landed | setup-resolved) next_line ;;
    final-landed | landing-wait) landing_line ;;
    pr-green) merge_lines green ;;
    pr-awaiting-approval) merge_lines awaiting ;;
    integrated)
      need op
      if [ "${key[op]}" = rebase ] && [ "${key[upstream]:-no}" = yes ]; then
        echo "git push --force-with-lease"
      else
        echo "git push"
      fi
      ;;
    integrate-blocked)
      need abort
      echo "${key[abort]}"
      ;;
    unlanded)
      need worktree run_branch
      echo "Nothing landed: the work sits in ${key[worktree]} on ${key[run_branch]}, and the review and the landing are yours to run."
      ;;
    claim-taken) echo "Another run is integrating the Spec, and there is nothing to type." ;;
    final-stopped)
      need ticket
      echo "/do ${key[ticket]}"
      ;;
  esac
}

main "$@"
