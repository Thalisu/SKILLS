#!/usr/bin/env bash
# ticket-door.sh: the door facts of the ticket Playbook of do that a script can observe, so the
# Reply's Run section states what one run printed and the developer can rerun it for the same answer.
# Run from anywhere inside the project, the main checkout or a worktree of it.
#
#   ticket-door.sh <the Ticket's path>    the Ticket, its blockers, its worktree, the loop and the
#                                         developer's branch; a relative path is read from the
#                                         directory the script runs in, then from the main checkout
#
# Prints key=value lines, in this order: ticket, title, status, one blocker=<NN> <status> <path> per
# Ticket the Blocked by line names (blockers=none for None), slug, worktree (the do-<slug> worktree
# when git lists one at that path, else none), run_branch (do/<slug> when git lists that branch
# locally, else none, read beside worktree so a start-over knows whether the branch survived the
# worktree's removal), loop (policy when the project has
# .claude/agents/unit-test-author.md, else global when ~/.claude/agents/global-unit-test-author.md
# is linked, else fallback), branch, protected and reason as
# `trivial-door.sh branch` prints them in the main checkout, then verdict. An ambiguous=<what>
# <detail> line follows the line it concerns. A blocker is the leading number of each part of the
# Blocked by paragraph split on `;`, `,`, the word `and` and each line break, read from the Ticket's
# own issues/ folder as the one <NN>-<slug>.md. A review, digest, project map or sketch of a Ticket
# is never counted, even with its Ticket gone, so a sidecar never supplies a blocker's status; any
# other <stem>.<kind>.md is left out only beside a <stem>.md, and a slug that itself holds a dot
# (20-upgrade-to-v1.2.md) still counts; a number elsewhere in the
# paragraph that no part starts with is ambiguous. A status is the one **Status:** line at column
# 0: none, two or a word outside the walk (ready-for-agent, claimed, resolved) is ambiguous, and no
# word is taken out of it. The Blocked by line is held to the same rule: two or more at column 0
# print blockers=ambiguous with their line numbers, and no blocker is read out of any of them.
#
# verdict, first match wins: ambiguous (the Ticket's status) · resolved · ambiguous (a blocker with
# no file, two files, or no single status line; two Blocked by lines, or one naming no number and
# not None, or a number it cannot split out) ·
# blocked (a blocker not resolved) · resume (claimed, the worktree there) · start-over (claimed, the
# worktree gone) · ambiguous (ready-for-agent with a worktree already there) · start. A protected
# branch is a warning for the Reply's Run section, never a stop.
#
# Exit codes: 0 the run may go on: start, resume or start-over · 1 the door stops the run:
# resolved, blocked or ambiguous · 2 usage, no Ticket at the path, or not a git repository.
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd -P)"

usage() { echo "usage: ticket-door.sh <the Ticket's path>" >&2; exit 2; }
[ "$#" = 1 ] || usage

top="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "not a git repository" >&2; exit 2; }
# A bare main worktree has no working tree to anchor on, and git lists it first all the same.
main="$(git worktree list --porcelain 2>/dev/null |
  awk '/^$/ { exit } /^worktree /{ p = substr($0, 10) } /^bare$/ { p = "" } END { print p }')"
[ -n "$main" ] && [ -d "$main" ] || main="$top"

case "$1" in
  /*) path="$1" ;;
  *) if [ -f "$1" ]; then path="$(pwd -P)/${1#./}"; else path="$main/${1#./}"; fi ;;
esac
[ -f "$path" ] || { echo "no Ticket at $1" >&2; exit 2; }

status_of() { # $1 file: sets word to the status, or to ambiguous with detail set
  local lines
  lines="$(grep -n '^\*\*Status:\*\*' "$1" | cut -d: -f1 | tr '\n' ' ')"
  lines="${lines% }"
  detail=""
  if [ "$(wc -w <<<"$lines")" != 1 ]; then word=ambiguous; detail="status lines ${lines:-none}"; return; fi
  word="$(grep '^\*\*Status:\*\*' "$1" | sed 's/^\*\*Status:\*\*//' | awk '{ print $1 }')"
  case "$word" in
    ready-for-agent|claimed|resolved) ;;
    *) detail="status word ${word:-none}"; word=ambiguous ;;
  esac
}

stop_ambiguous=0 stop_blocked=0

echo "ticket=${path#"$main"/}"
title="$(grep -m1 '^# ' "$path" | sed 's/^# //')"
echo "title=${title:-none}"
status_of "$path"; status="$word"
echo "status=$status"
[ -z "$detail" ] || echo "ambiguous=$detail"

folder="$(dirname "$path")"
by_lines="$(grep -n '^\*\*Blocked by:\*\*' "$path" | cut -d: -f1 | tr '\n' ' ')"
by_lines="${by_lines% }"
blocked_by="$(awk '/^\*\*Blocked by:\*\*/ { on = 1; sub(/^\*\*Blocked by:\*\*[[:space:]]*/, "") } on && /^[[:space:]]*$/ { exit } on { print }' "$path")"
numbers="$(sed -E 's/(^|[[:space:]])and([[:space:]]|$)/\1,\2/g' <<<"$blocked_by" | tr ';,' '\n\n' |
  sed -nE 's/^[[:space:]]*([0-9]+)([^[:alnum:]].*)?$/\1/p' | awk '!seen[$0]++')"
unsplit="$(grep -oE '[[:alnum:]]+' <<<"$blocked_by" | grep -xE '[0-9]+' |
  awk -v read="$(tr '\n' ' ' <<<"$numbers")" 'BEGIN { split(read, r, " "); for (i in r) ok[r[i]] = 1 } !ok[$0] && !seen[$0]++' | tr '\n' ' ')"
unsplit="${unsplit% }"
if [ "$(wc -w <<<"$by_lines")" -gt 1 ]; then
  echo "blockers=ambiguous"; echo "ambiguous=blocked-by lines $by_lines"; stop_ambiguous=1
  numbers="" unsplit=""
elif [ -z "$numbers" ]; then
  case "$blocked_by" in
    None*|none*) echo "blockers=none" ;;
    *) echo "blockers=none"; echo "ambiguous=blocked-by names no Ticket number"; stop_ambiguous=1 ;;
  esac
fi
for n in $numbers; do
  files="$(find "$folder" -maxdepth 1 -type f -name "$n-*.md" ! -name '*.review.md' ! -name '*.digest.md' \
    ! -name '*.project-map.md' ! -name '*.sketch.md' | sort | awk '{ c[NR] = $0; has[$0] = 1 }
    END { for (i = 1; i <= NR; i++) { if (match(c[i], /\.[^.\/]+\.md$/) && has[substr(c[i], 1, RSTART - 1) ".md"]) continue; print c[i] } }')"
  count="$(grep -c . <<<"$files")"
  if [ "$count" != 1 ]; then
    rel=""
    while IFS= read -r f; do [ -z "$f" ] || rel="$rel ${f#"$main"/}"; done <<<"$files"
    rel="${rel# }"
    if [ "$count" = 0 ]; then echo "blocker=$n missing none"; else echo "blocker=$n ambiguous $rel"; fi
    echo "ambiguous=$n files ${rel:-none}"
    stop_ambiguous=1; continue
  fi
  status_of "$files"
  echo "blocker=$n $word ${files#"$main"/}"
  case "$word" in
    ambiguous) echo "ambiguous=$n $detail"; stop_ambiguous=1 ;;
    resolved) ;;
    *) stop_blocked=1 ;;
  esac
done
[ -z "$unsplit" ] || { echo "ambiguous=blocked-by numbers it cannot split $unsplit"; stop_ambiguous=1; }

slug="$(basename "$path" .md)"; slug="$(sed -E 's/^[0-9]+-//' <<<"$slug")"
echo "slug=$slug"
worktree="$main/.claude/worktrees/do-$slug"
# grep -q would stop reading at the match and git would die of SIGPIPE on a long list, which
# pipefail turns into a missing worktree.
if git worktree list --porcelain | grep -xF -- "worktree $worktree" >/dev/null; then echo "worktree=$worktree"; else worktree=none; echo "worktree=none"; fi
if git -C "$main" show-ref --verify --quiet "refs/heads/do/$slug"; then echo "run_branch=do/$slug"; else echo "run_branch=none"; fi
stale=0
if [ "$status" = ready-for-agent ] && [ "$worktree" != none ]; then echo "ambiguous=worktree exists for a ready-for-agent Ticket"; stale=1; fi

if [ -f "$main/.claude/agents/unit-test-author.md" ]; then echo "loop=policy"
elif [ -f "$HOME/.claude/agents/global-unit-test-author.md" ]; then echo "loop=global"
else echo "loop=fallback"; fi
(cd "$main" && bash "$here/trivial-door.sh" branch) | grep -E '^(branch|protected|reason)='

if [ "$status" = ambiguous ]; then verdict=ambiguous
elif [ "$status" = resolved ]; then verdict=resolved
elif [ "$stop_ambiguous" = 1 ]; then verdict=ambiguous
elif [ "$stop_blocked" = 1 ]; then verdict=blocked
elif [ "$status" = claimed ] && [ "$worktree" != none ]; then verdict=resume
elif [ "$status" = claimed ]; then verdict=start-over
elif [ "$stale" = 1 ]; then verdict=ambiguous
else verdict=start
fi
echo "verdict=$verdict"
case "$verdict" in start|resume|start-over) exit 0 ;; *) exit 1 ;; esac
