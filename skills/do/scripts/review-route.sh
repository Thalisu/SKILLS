#!/usr/bin/env bash
# review-route.sh: the route a session takes after the review's return, and after every fix call's,
# read off the return's landing line and the run's state. It reads stdin alone, no git and no file,
# and prints lines the session copies as they are.
#
# Stdin: key=value lines, each key once. Required: landing (the return's landing line, as it reads),
# integration (the verdict= word of the integration.sh check run just before this return: noop,
# rebase or reapply), last (the call that produced the return: review, fix or resume), review (the
# Review's location), target (the landing target), worktree, branch, rerun (the Ticket, or the
# request that started the run). Optional: command (the run's own gate command= line, only when that
# gate ran before the review), before (the commit recorded before the integration started).
#
# Prints, in order: landing=landed|not landed, commit=<sha> (landed only), then route=verify.
#
# Exit codes: 0 verify · 2 usage: a missing required key, an unknown or repeated key, an integration=
# or last= word outside its union, or a landing= line of neither form.
set -uo pipefail

usage() {
  echo "usage: review-route.sh <key=value lines on stdin>: $1" >&2
  exit 2
}

declare -A in=()
while IFS= read -r line || [ -n "$line" ]; do
  [ -n "$line" ] || continue
  case "$line" in *=*) ;; *) usage "not a key=value line: $line" ;; esac
  key="${line%%=*}"
  case "$key" in
    landing | integration | last | review | target | worktree | branch | rerun | command | before) ;;
    *) usage "unknown key $key" ;;
  esac
  [ -z "${in[$key]+set}" ] || usage "repeated key $key"
  in[$key]="${line#*=}"
done
for key in landing integration last review target worktree branch rerun; do
  [ -n "${in[$key]:-}" ] || usage "missing key $key"
done
case "${in[integration]}" in noop | rebase | reapply) ;; *) usage "integration=${in[integration]} is none of noop, rebase, reapply" ;; esac
case "${in[last]}" in review | fix | resume) ;; *) usage "last=${in[last]} is none of review, fix, resume" ;; esac

landing="${in[landing]}"
if [[ "$landing" =~ ^landed\ at\ ([0-9a-f]{7,40})(,|$) ]]; then
  echo "landing=landed"
  echo "commit=${BASH_REMATCH[1]}"
  echo "route=verify"
  exit 0
fi
usage "a landing= line of neither form: $landing"
