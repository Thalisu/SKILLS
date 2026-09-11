#!/usr/bin/env bash
# The do evals whose fixture installs the stand-in do-code-review: each fixture's Project facts name
# a unit full suite (and an E2E full suite where the fixture has flows) that runs green and passes
# Node's test runner no directory of the fixture, since Node 24 and 25 load a directory argument as
# one module and fail it; and the stand-in, called the way do calls it on a green plant, runs the
# unit suite by the command those facts name and lands.
# Run: bash skills/do/tests/fixture-suites.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
fails=0
evals="$here/../evals"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

facts_cmd() { # $1 fixture dir, $2 Unit|E2E: the full-suite command its Project facts line names
  sed -n "s/^- \*\*$2\*\*:.* full suite \`\([^\`]*\)\`.*/\1/p" "$1/CLAUDE.md" 2>/dev/null | head -1
}
dir_args() { # $1 fixture dir, $2 command: each argument of the command that is a directory of the fixture
  local a
  while IFS= read -r a; do
    case "$a" in -*) continue ;; esac
    [ -d "$1/$a" ] && printf '%s\n' "$a"
  done < <(xargs -n1 printf '%s\n' <<<"$2" | tail -n +2)
}
green_counts() { # $1 text: true when it reports pass >= 1 and fail 0
  grep -qE '(^|[^a-z])pass [1-9]' <<<"$1" && grep -qE '(^|[^a-z])fail 0( |$)' <<<"$1"
}
suite_line_of() { # the review's `- suite:` line, from its return or from the Review its return names
  local line review
  line="$(grep -F -- '- suite: ' <<<"$out" | head -1)"
  if [ -z "$line" ]; then
    review="$(sed -n 's/^Review: //p' <<<"$out" | head -1)"
    [ -n "$review" ] && line="$(grep -F -- '- suite: ' "$review" 2>/dev/null | head -1)"
  fi
  printf '%s\n' "$line"
}
scaffolded() { # $1 case, $2 dir: the case's fixture scaffolded at $2
  mkdir -p "$2" && (cd "$2" && scaffold_of "$evals/$1" | bash >/dev/null 2>&1) || return 1
  g -C "$2" config gc.auto 0
  g -C "$2" config maintenance.auto false
}
review_green() { # $1 fixture dir, $2 worktree dir: the stand-in's return on a green plant, into $out and $rc
  local fixed spec
  # do hands the review the Ticket it runs when the fixture has one, and the branch otherwise.
  spec="$(cd "$1" && find .scratch -path '*/issues/*.md' 2>/dev/null | sort | head -1)"
  spec="${spec:-do/x}"
  g -C "$1" worktree add -q -b do/x "$2" >/dev/null 2>&1 || return 1
  printf 'one change\n' >"$2/change.md"
  g -C "$2" add change.md && g -C "$2" commit -qm "docs: one change" >/dev/null 2>&1 || return 1
  # An integration fixture moves main after the first do/ commit; do rebases onto it before the
  # review, whose fixed point is then main's tip.
  g -C "$2" rebase -q main >/dev/null 2>&1 || return 1
  fixed="$(g -C "$1" rev-parse main)"
  echo green >"$2/.claude/skills/do-code-review/plant"
  rc=0
  out="$(cd "$2" && bash .claude/skills/do-code-review/review.sh "$spec" "$fixed" main 2>&1)" || rc=$?
}

cases=()
while IFS= read -r f; do cases+=("$(basename "$(dirname "$f")")"); done < <(grep -lE 'if \[ -d e2e \]; then suite=' "$evals"/*/case.yaml)
if [ "${#cases[@]}" -ge 9 ]; then ok "nine or more fixtures install the stand-in review"; else fail "nine or more fixtures install the stand-in review (found ${#cases[@]})"; fi

for c in "${cases[@]}"; do
  fx="$tmp/$c/fixture"
  if scaffolded "$c" "$fx"; then ok "$c: the scaffold runs"; else
    fail "$c: the scaffold runs"
    continue
  fi

  kinds=(Unit)
  if [ -d "$fx/e2e" ] || [ -n "$(facts_cmd "$fx" E2E)" ]; then kinds+=(E2E); fi
  for k in "${kinds[@]}"; do
    cmd="$(facts_cmd "$fx" "$k")"
    if [ -n "$cmd" ]; then ok "$c: the facts name a $k full-suite command"; else
      fail "$c: the facts name a $k full-suite command"
      continue
    fi
    dirs="$(dir_args "$fx" "$cmd")"
    if [ -z "$dirs" ]; then ok "$c: the $k full suite passes Node's test runner no directory of the fixture"; else
      fail "$c: the $k full suite passes Node's test runner no directory of the fixture (\`$cmd\` names: ${dirs//$'\n'/ })"
    fi
    out="$(cd "$fx" && bash -c "$cmd" 2>&1)"
    if green_counts "$out"; then ok "$c: the $k full suite the facts name runs green"; else
      fail "$c: the $k full suite the facts name runs green (\`$cmd\`)"
      dump_out
    fi
  done

  unit="$(facts_cmd "$fx" Unit)"
  if [ "$c" = protected-branch-said-first ]; then landing="not landed: main is protected"; else landing="landed at"; fi
  if review_green "$fx" "$tmp/$c/wt"; then
    suite_line="$(suite_line_of)"
    if [[ "$suite_line" == "- suite: \`$unit\`: "* ]] && ! grep -qF -- ': red, ' <<<"$suite_line" && green_counts "$suite_line"; then
      check "$c: a green plant's review runs the facts' unit suite green and reaches its landing" 0 "$rc" "$landing"
    else
      fail "$c: a green plant's review runs the facts' unit suite green and reaches its landing (facts: \`$unit\`)"
      dump_out
    fi
  else
    fail "$c: a green plant's review runs the facts' unit suite green and reaches its landing (the do/x worktree could not be made)"
  fi

  # The facts alone change: the review must quote and run the new command, never one of its own.
  fx2="$tmp/$c/renamed"
  if scaffolded "$c" "$fx2" && [ -n "$unit" ]; then
    renamed="${unit/node --test/node --test --test-concurrency=1}"
    sed -i "s|^\(- \*\*Unit\*\*: full suite \`\)[^\`]*\`|\1$renamed\`|" "$fx2/CLAUDE.md"
    g -C "$fx2" add CLAUDE.md && g -C "$fx2" commit -qm "facts: the unit suite runs one file at a time"
    if review_green "$fx2" "$tmp/$c/wt2"; then
      suite_line="$(suite_line_of)"
      if [ "$rc" = 0 ] && [[ "$suite_line" == "- suite: \`$renamed\`: "* ]]; then
        ok "$c: the review runs the unit suite by the command its facts name"
      else
        fail "$c: the review runs the unit suite by the command its facts name (facts: \`$renamed\`, review: ${suite_line:-no suite line}, exit $rc)"
      fi
    else
      fail "$c: the review runs the unit suite by the command its facts name (the do/x worktree could not be made)"
    fi
  else
    fail "$c: the review runs the unit suite by the command its facts name (the fixture has no unit facts to rename)"
  fi
done

if [ "$fails" = 0 ]; then echo "all ok"; else
  echo "$fails failing"
  exit 1
fi
