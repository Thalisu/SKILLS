#!/usr/bin/env bash
# project-map.sh: the Project map the global test authors read, derived by do from a project that
# has no Testing Policy installed. It fills only the slots a command read, the run commands and the
# test layout, and writes `none yet → /testing-policy` in every other one, since installing the
# policy is what would fill them. The ticket Playbook runs it once per run, at its ground step.
#
#   project-map.sh <project root> <map path>    the map path must sit under <project root>/.scratch/,
#                                               the project's own Scratch, so a map derived from one
#                                               project never lands in the repository the authors
#                                               came from
#
# Each command is read from the first source that carries it: package.json's scripts (read with jq,
# the package manager taken from the lockfile), a Makefile's targets, a justfile's recipes, then a
# pyproject.toml or pytest.ini naming pytest. A single-file or single-flow command is filled only
# when the runner the script names takes a path (vitest, jest, mocha, ava, tap, node --test,
# bun test, pytest, playwright test); a make or just target never fills one. The layout is the
# directories holding test files among the files git lists, the end-to-end ones apart, five at most.
#
# Prints key=value lines, in this order: map, one read=<file> per file a command came from
# (read=none when none did), an unread=<file> <reason> line per file it could not read,
# unit_run_file, unit_run_all, unit_format, unit_test_layout, e2e_run_flow, e2e_run_all,
# e2e_format, e2e_flow_root, then verdict=written.
#
# Exit codes: 0 written · 2 usage, a root that is not a directory, a map path outside the root's
# Scratch, or no `realpath` on PATH to resolve it safely (a `..` or a symlink could otherwise carry
# the write outside the project, so the script fails closed instead of trusting the raw string).
set -uo pipefail

none='none yet → /testing-policy'
usage() { echo "usage: project-map.sh <project root> <map path under <root>/.scratch/>" >&2; exit 2; }
[ "$#" = 2 ] || usage
root="$(cd "$1" 2>/dev/null && pwd -P)" || usage
out="$2"
case "$out" in /*) ;; *) out="$PWD/$out" ;; esac
if command -v realpath >/dev/null 2>&1; then
  out="$(realpath -m -- "$out")"
else
  echo "realpath is not on PATH; the map path cannot be resolved safely, refusing to write $out" >&2
  exit 2
fi
case "$out" in
  "$root/.scratch/"*) ;;
  *) echo "the map path is not under $root/.scratch/: $out" >&2; exit 2 ;;
esac

unit_file="" unit_all="" unit_fmt="" e2e_flow="" e2e_all=""
read_from=() unread=()
takes_path() {
  grep -Eq '^(npx +|pnpm +exec +|yarn +)?(vitest|jest|mocha|ava|tap|node +--test|bun +test|pytest|python3? +-m +pytest|playwright +test)( |$)' <<<"$1"
}
e2e_runner='playwright|cypress|maestro|detox|wdio'

if [ -f "$root/package.json" ]; then
  if command -v jq >/dev/null 2>&1; then
    pm=npm
    [ -f "$root/pnpm-lock.yaml" ] && pm=pnpm
    [ -f "$root/yarn.lock" ] && pm=yarn
    { [ -f "$root/bun.lockb" ] || [ -f "$root/bun.lock" ]; } && pm=bun
    script() { jq -r --arg k "$1" '.scripts[$k] // empty' "$root/package.json" 2>/dev/null; }
    # npm alone needs the separator to pass an argument through to the script.
    with_arg() { if [ "$pm" = npm ]; then echo "npm run $1 -- $2"; else echo "$pm run $1 $2"; fi; }
    for k in test:unit unit test; do
      body="$(script "$k")"
      { [ -n "$body" ] && ! grep -Eq "$e2e_runner" <<<"$body"; } || continue
      unit_all="$pm run $k"
      takes_path "$body" && unit_file="$(with_arg "$k" '<file>')"
      break
    done
    e2e_key=""
    for k in test:e2e e2e; do [ -n "$(script "$k")" ] && { e2e_key="$k"; break; }; done
    [ -n "$e2e_key" ] || e2e_key="$(jq -r --arg re "$e2e_runner" \
      '.scripts // {} | to_entries[] | select(.value | test($re)) | .key' "$root/package.json" 2>/dev/null | head -1)"
    if [ -n "$e2e_key" ]; then
      e2e_all="$pm run $e2e_key"
      takes_path "$(script "$e2e_key")" && e2e_flow="$(with_arg "$e2e_key" '<flow>')"
    fi
    for k in format fmt; do [ -n "$(script "$k")" ] && { unit_fmt="$pm run $k"; break; }; done
    [ -n "$unit_all$e2e_all$unit_fmt" ] && read_from+=(package.json)
  else
    unread+=("package.json jq missing")
  fi
fi

target() { grep -Eq "^$1( [^:=]*)?:([^=]|\$)" "$2"; }
from_targets() { # $1 the file, $2 the command that runs one of its targets
  local file="$root/$1" before="$unit_all$e2e_all$unit_fmt" t
  [ -f "$file" ] || return 0
  [ -n "$unit_all" ] || for t in test-unit test; do target "$t" "$file" && { unit_all="$2 $t"; break; }; done
  [ -n "$e2e_all" ] || for t in test-e2e e2e; do target "$t" "$file" && { e2e_all="$2 $t"; break; }; done
  [ -n "$unit_fmt" ] || for t in format fmt; do target "$t" "$file" && { unit_fmt="$2 $t"; break; }; done
  [ "$before" = "$unit_all$e2e_all$unit_fmt" ] || read_from+=("$1")
}
from_targets Makefile make
for j in justfile Justfile .justfile; do from_targets "$j" just; done

if [ -z "$unit_all" ]; then
  if [ -f "$root/pyproject.toml" ] && grep -q 'pytest' "$root/pyproject.toml"; then
    unit_all="pytest"; unit_file="pytest <file>"; read_from+=(pyproject.toml)
  elif [ -f "$root/pytest.ini" ]; then
    unit_all="pytest"; unit_file="pytest <file>"; read_from+=(pytest.ini)
  fi
fi

files="$(git -C "$root" ls-files --cached --others --exclude-standard 2>/dev/null)"
e2e_dirs='(^|/)(e2e[^/]*|\.maestro|cypress|playwright)/'
test_files='(^|/)(tests?|__tests__|specs?)/|\.(test|spec)\.[A-Za-z0-9]+$|_test\.[A-Za-z0-9]+$|(^|/)test_[^/]*\.py$'
layout() { # stdin: paths; prints the directories holding them, the fullest first
  sed -E 's#/[^/]*$##; t; s#.*#.#' | sort | uniq -c | sort -k1,1nr -k2,2 | head -5 |
    awk '{ printf "%s`%s/` (%d %s)", (NR > 1 ? ", " : ""), $2, $1, ($1 == 1 ? "file" : "files") }'
}
unit_layout="$(grep -E "$test_files" <<<"$files" | grep -Ev "$e2e_dirs" | layout)"
e2e_root="$(grep -E "$e2e_dirs" <<<"$files" | layout)"

v() { if [ -n "$1" ]; then printf '%s' "$1"; else printf '%s' "$none"; fi; }
mkdir -p "$(dirname "$out")"
cat > "$out" <<EOF
# Project map

Derived by \`do\`'s \`scripts/project-map.sh\` from $root for one run, read by the global test
authors, never committed. A slot reads what a command read, or \`$none\`.

## Unit

**Framework & run commands**
- Single file: \`$(v "$unit_file")\`
- Full suite: \`$(v "$unit_all")\`
- Formatter: \`$(v "$unit_fmt")\`

**Test root & layout**: $(v "$unit_layout")

**Shared homes by role**
- Module mocks: \`$none\`
- Helpers / wrappers: \`$none\`
- Factories (data builders): \`$none\`
- Fixtures (static inputs): \`$none\`

**System boundaries**
$none

**Partial test data**
$none

**Discovery: run all of these on every dispatch, before writing**
$none

**Idiom**
$none

## End-to-end

**Tool & run commands**
- Single flow: \`$(v "$e2e_flow")\`
- Full suite (post-feature gate, not yours to run): \`$(v "$e2e_all")\`
- Formatter / linter: \`$(v "$unit_fmt")\`

**Preflight: every check must pass before running**
$none

**Flow root & naming**: $(v "$e2e_root")

**Shared homes by role**
- Page objects / interactions (or shared subflows): \`$none\`
- Data factories (entity builders): \`$none\`
- Backend / DB helpers (fixture state, direct assertions): \`$none\`
- Fixtures (session, context, cleanup): \`$none\`

**Discovery: run all of these on every dispatch, before writing**
$none

**Idiom**
$none
EOF

echo "map=$out"
if [ "${#read_from[@]}" = 0 ]; then echo "read=none"; else printf 'read=%s\n' "${read_from[@]}"; fi
[ "${#unread[@]}" = 0 ] || printf 'unread=%s\n' "${unread[@]}"
echo "unit_run_file=$(v "$unit_file")"
echo "unit_run_all=$(v "$unit_all")"
echo "unit_format=$(v "$unit_fmt")"
echo "unit_test_layout=$(v "$unit_layout")"
echo "e2e_run_flow=$(v "$e2e_flow")"
echo "e2e_run_all=$(v "$e2e_all")"
echo "e2e_format=$(v "$unit_fmt")"
echo "e2e_flow_root=$(v "$e2e_root")"
echo "verdict=written"
