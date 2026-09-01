#!/usr/bin/env bash
# context.sh — load-time repository facts for the test-triage skill, injected into SKILL.md
# through its `!` block.
#
# Usage: context.sh [PROJECT_DIR]      (default: current directory)
#
# Prints a compact fixed-format report and ALWAYS exits 0: a non-zero exit from an injected
# command aborts the whole skill invocation, so every branch below tolerates failure.
# Sections, each capped so the worst case stays under 60 lines:
#   branch / protected / other long-lived branches      (see is_protected for the rule)
#   dirty tracked files                                  git status --short, 8 lines
#   package.json scripts                                 all when <= 12, else the ones whose name
#                                                        matches test|e2e|spec|dev|start|docker (12);
#                                                        each tagged [local] or [remote-smelling]
#   package_manager / lockfiles                          the packageManager field, files named *lock*
#   docs/tests/runner.json                               verbatim, 16 lines
#   open dossiers                                        dossier.sh list-open, 8 lines
# package.json is parsed with awk only (no jq): a minified or unusually formatted file yields an
# empty scripts section, and SKILL.md tells the agent to read the file itself in that case.

here="$(cd "$(dirname "$0")" && pwd)"
project="${1:-.}"
cd "$project" 2>/dev/null || { echo "project dir not found: $project"; exit 0; }

DIRTY_CAP=8
SCRIPTS_CAP=12
RUNNER_CAP=16
DOSSIER_CAP=8

# Long-lived branch names. main/master are protected only when an integration branch
# (develop/development/staging/release*) exists; production/prod also when main/master exists.
# A default branch that is the only branch is the working branch (not protected).
is_protected() {
  local cur="$1" others="$2" b
  for b in $others; do
    case "$cur" in
      main|master)
        case "$b" in develop|development|staging|release*) echo "yes ($b exists)"; return ;; esac ;;
      production|prod)
        case "$b" in main|master|develop|development|staging|release*) echo "yes ($b exists)"; return ;; esac ;;
    esac
  done
  echo "no"
}

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  cur="$(git symbolic-ref --short -q HEAD 2>/dev/null)"
  [ -n "$cur" ] || cur="detached at $(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
  others="$( { git for-each-ref --format='%(refname:short)' refs/heads 2>/dev/null
              git for-each-ref --format='%(refname:short)' refs/remotes 2>/dev/null | sed -E 's#^[^/]+/##'; } \
            | grep -vx 'HEAD' | grep -vx "$cur" | sort -u \
            | grep -Ex 'main|master|develop|development|staging|production|prod|release.*' | tr '\n' ' ' | sed 's/ $//')"
  echo "branch: $cur"
  echo "protected: $(is_protected "$cur" "$others")"
  echo "other long-lived branches: ${others:-none}"
  dirty="$(git status --short --untracked-files=no 2>/dev/null)"
  if [ -z "$dirty" ]; then
    echo "dirty tracked files: none"
  else
    n="$(printf '%s\n' "$dirty" | wc -l | tr -d ' ')"
    echo "dirty tracked files ($n):"
    printf '%s\n' "$dirty" | head -n "$DIRTY_CAP" | sed 's/^/  /'
    [ "$n" -gt "$DIRTY_CAP" ] && echo "  ... +$((n - DIRTY_CAP)) more"
  fi
else
  echo "branch: not a git repository"
  echo "protected: n/a"
  echo "dirty tracked files: n/a"
fi

if [ -f package.json ]; then
  # name<TAB>body per script; the tokenizer consumes each body up to its closing unescaped quote
  scripts="$(awk '
    function emit(s,   n, b, i, c) {
      while (match(s, /"[^"]+"[[:space:]]*:[[:space:]]*"/)) {
        n = substr(s, RSTART + 1); sub(/".*/, "", n)
        s = substr(s, RSTART + RLENGTH)
        b = ""; i = 1
        while (i <= length(s)) {
          c = substr(s, i, 1)
          if (c == "\\") { b = b c substr(s, i + 1, 1); i += 2; continue }
          if (c == "\"") break
          b = b c; i++
        }
        gsub(/\\"/, "\"", b); print n "\t" b
        s = substr(s, i + 1)
      }
    }
    inb {
      buf = buf "\n" $0
      if ($0 ~ /^[[:space:]]*\}/) { emit(buf); inb = 0 }
      next
    }
    /^[[:space:]]*"scripts"[[:space:]]*:[[:space:]]*\{/ {
      buf = $0; sub(/^[[:space:]]*"scripts"[[:space:]]*:[[:space:]]*\{/, "", buf)
      if (buf ~ /\}[[:space:]]*,?[[:space:]]*$/) { emit(buf) } else { inb = 1 }
    }
  ' package.json 2>/dev/null)"
  if [ -z "$scripts" ]; then
    echo "package.json scripts: none found (read the file yourself if it has any)"
  else
    total="$(printf '%s\n' "$scripts" | wc -l | tr -d ' ')"
    if [ "$total" -le "$SCRIPTS_CAP" ]; then
      shown="$scripts"; label="all $total"
    else
      shown="$(printf '%s\n' "$scripts" | grep -Ei '^[^	]*(test|e2e|spec|dev|start|docker)[^	]*	' | head -n "$SCRIPTS_CAP")"
      label="$(printf '%s\n' "$shown" | grep -c . ) of $total, matching test|e2e|spec|dev|start|docker"
    fi
    echo "package.json scripts ($label):"
    printf '%s\n' "$shown" | while IFS='	' read -r name body; do
      [ -n "$name" ] || continue
      if printf '%s %s' "$name" "$body" | grep -Eiq ':remote|:ci|(^|[^[:alnum:]_.-])(ssh|rsync|scp)([^[:alnum:]_.-]|$)'; then
        tag="remote-smelling"
      else
        tag="local"
      fi
      echo "  $name: $body  [$tag]"
    done
  fi
  pm="$(grep -oE '"packageManager"[[:space:]]*:[[:space:]]*"[^"]*"' package.json 2>/dev/null | head -1 | sed -E 's/.*:[[:space:]]*"([^"]*)"/\1/')"
  echo "package_manager: ${pm:-none}"
else
  echo "package.json: absent"
fi
locks="$(ls -1 2>/dev/null | grep -i 'lock' | grep -v '/$' | tr '\n' ' ' | sed 's/ $//')"
echo "lockfiles: ${locks:-none}"

if [ -d docs/tests ]; then
  if [ -f docs/tests/runner.json ]; then
    n="$(wc -l < docs/tests/runner.json | tr -d ' ')"
    echo "docs/tests/runner.json:"
    head -n "$RUNNER_CAP" docs/tests/runner.json | sed 's/^/  /'
    [ "$n" -gt "$RUNNER_CAP" ] && echo "  ... +$((n - RUNNER_CAP)) more lines"
  else
    echo "docs/tests/runner.json: absent"
  fi
  open="$(bash "$here/dossier.sh" --dir docs/tests list-open 2>/dev/null)"
  if [ -z "$open" ]; then
    echo "open dossiers: none"
  else
    n="$(printf '%s\n' "$open" | wc -l | tr -d ' ')"
    echo "open dossiers ($n): path | test | signature | veto | occurrences | green_runs"
    printf '%s\n' "$open" | head -n "$DOSSIER_CAP" | sed 's/^/  /'
    [ "$n" -gt "$DOSSIER_CAP" ] && echo "  ... +$((n - DOSSIER_CAP)) more"
  fi
else
  echo "docs/tests/: absent"
fi

exit 0
