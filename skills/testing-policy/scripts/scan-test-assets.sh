#!/usr/bin/env bash
# scan-test-assets.sh — discovery and duplication scan of a project's test tree.
# Installed by the testing-policy skill into <project>/.claude/testing-policy/ and invoked
# from the test-author agents' "Project map" on every dispatch.
#
# Usage: scan-test-assets.sh [--root DIR]... [--shared DIR]... [--flows DIR]... [--section NAME]
#   --root DIR     test root to scan (repeatable). Default: every existing dir among
#                  tests test __tests__ spec e2e e2e-tests .maestro src
#   --shared DIR   a canonical shared home (repeatable). Symbols defined there are never
#                  reported as "local" copies.
#   --flows DIR    E2E flow root (repeatable). Enables the inline-helpers and subflows sections.
#   --section NAME print only that section (roots layout candidate-homes duplicate-symbols
#                  local-factories inline-helpers subflows mock-targets skip-markers)
#
# Sections: duplicate-symbols = a name defined in two or more files (exports, plus top-level
# function/class declarations) — files under a fixtures-role directory (`__fixtures__/`, `fixtures/`)
# that is not a declared --shared home are skipped: they are inputs, and a corpus repeats names on
# purpose; local-factories = builder-shaped definitions living in test files
# instead of a shared home; inline-helpers = page-taking helpers and fixtures defined inside flow
# files; mock-targets = every module-mock target (jest/vi mock, bun mock.module, unittest patch,
# mocker.patch, monkeypatch.setattr) with its file count, classed `package` (a bare specifier or a
# module outside the repo — a system boundary) or `internal` (a relative/alias path or a module of
# this repo — either a thin wrapper around a boundary, or an internal collaborator: debt);
# skip-markers = every marker from skip-patterns.sh (sourced from this script's directory).
# Output is plain text with fixed "## <section>" headers so callers can grep it.
# Exit 0 whenever the scan ran (a finding is not an error); exit 2 on usage errors.
set -uo pipefail

roots=() shared=() flows=() only=""
while [ $# -gt 0 ]; do
  case "$1" in
    --root)    arg="${2:?--root needs a dir}"; roots+=("${arg%/}"); shift 2 ;;
    --shared)  arg="${2:?--shared needs a dir}"; shared+=("${arg%/}"); shift 2 ;;
    --flows)   arg="${2:?--flows needs a dir}"; flows+=("${arg%/}"); shift 2 ;;
    --section) only="${2:?--section needs a name}"; shift 2 ;;
    -h|--help) sed -n '2,17p' "$0"; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done
case "$only" in
  ""|roots|layout|candidate-homes|duplicate-symbols|local-factories|inline-helpers|subflows|mock-targets|skip-markers) ;;
  *) echo "unknown section: $only (roots layout candidate-homes duplicate-symbols local-factories inline-helpers subflows mock-targets skip-markers)" >&2; exit 2 ;;
esac

if [ ${#roots[@]} -eq 0 ]; then
  for d in tests test __tests__ spec e2e e2e-tests .maestro src; do [ -d "$d" ] && roots+=("$d"); done
fi
if [ ${#roots[@]} -eq 0 ]; then echo "no test roots found (pass --root)" >&2; exit 2; fi
for f in "${flows[@]}"; do
  case " ${roots[*]} " in *" $f "*) ;; *) roots+=("$f") ;; esac
done

PRUNE=( \( -name node_modules -o -name .git -o -name dist -o -name build -o -name coverage -o -name .venv -o -name venv -o -name __pycache__ -o -name .next -o -name .expo -o -name android -o -name ios -o -name .pytest_cache -o -name .ruff_cache -o -name worktrees -o -name test-artifacts -o -name .turbo \) -prune )
TEST_ROOT_RE='^(__tests__|tests?|spec|e2e|e2e-tests|\.maestro)$'
ROLE_VOCAB='__mocks__|mocks|__helpers__|helpers|support|__factories__|factories|builders|__fixtures__|fixtures|pages|page_objects|pageobjects|screens|data|subflows|shared|common|utils|lib'

in_flows() {
  local p="$1" f
  for f in "${flows[@]}"; do case "$p" in "$f"/*|"./$f"/*|"$f") return 0 ;; esac; done
  return 1
}
is_test_file() {
  case "$1" in
    *.test.ts|*.test.tsx|*.test.mts|*.test.cts|*.test.js|*.test.jsx|*.test.mjs|*.test.cjs) return 0 ;;
    *.spec.ts|*.spec.tsx|*.spec.mts|*.spec.cts|*.spec.js|*.spec.jsx|*.spec.mjs|*.spec.cjs) return 0 ;;
    *.cy.ts|*.cy.tsx|*.cy.js|*.cy.jsx) return 0 ;;
    */__tests__/*.ts|*/__tests__/*.tsx|*/__tests__/*.mts|*/__tests__/*.cts|*/__tests__/*.js|*/__tests__/*.jsx|*/__tests__/*.mjs|*/__tests__/*.cjs) return 0 ;;
    test_*.py|*/test_*.py|*_test.py) return 0 ;;
    .maestro/*.yaml|.maestro/*.yml|*/.maestro/*.yaml|*/.maestro/*.yml) return 0 ;;
    *.yaml|*.yml) in_flows "$1" && return 0 ;;
  esac
  return 1
}
is_shared_path() {
  local p="$1" s
  for s in "${shared[@]}"; do case "$p" in "$s"/*|"./$s"/*) return 0 ;; esac; done
  return 1
}
# A fixtures-role directory holds inputs (a scanner's corpus, recorded payloads), not assets, unless the
# project declared it as a --shared home.
is_input_corpus() {
  [[ "$1" =~ (^|/)(__fixtures__|fixtures)/ ]] || return 1
  is_shared_path "$1" && return 1
  return 0
}

all_files=() test_files=() scan_files=()
for r in "${roots[@]}"; do
  [ -d "$r" ] || { echo "warning: root $r does not exist" >&2; continue; }
  rb="$(basename "$r")"
  while IFS= read -r -d '' f; do
    case "$f" in *.d.ts) continue ;; esac
    all_files+=("$f")
    if is_test_file "$f"; then test_files+=("$f"); scan_files+=("$f"); continue; fi
    if [[ "$rb" =~ $TEST_ROOT_RE ]] || in_flows "$r"; then
      case "$f" in *.ts|*.tsx|*.mts|*.cts|*.js|*.jsx|*.mjs|*.cjs|*.py|*.yaml|*.yml) scan_files+=("$f") ;; esac
    elif [[ "$f" =~ (^|/)(__tests__|__mocks__|__fixtures__|__helpers__|__factories__)(/|$) ]]; then
      scan_files+=("$f")
    fi
  done < <(find "$r" "${PRUNE[@]}" -o -type f -print0)
done

want() { [ -z "$only" ] || [ "$only" = "$1" ]; }
hdr() { printf '\n## %s\n' "$1"; }

# --- roots -------------------------------------------------------------------------------
if want roots; then
  hdr roots
  for r in "${roots[@]}"; do
    n=0; for f in "${test_files[@]}"; do case "$f" in "$r"/*|"$r") n=$((n+1)) ;; esac; done
    printf '%s\t%d test files\n' "$r" "$n"
  done
  printf 'scanned files (tests + shared homes): %d\n' "${#scan_files[@]}"
fi

# --- layout ------------------------------------------------------------------------------
if want layout; then
  hdr layout
  under=0 coloc=0
  for f in "${test_files[@]}"; do
    if [[ "$f" =~ (^|/)(__tests__|tests?|spec|e2e|e2e-tests|\.maestro)(/|$) ]]; then under=$((under+1)); else coloc=$((coloc+1)); fi
  done
  printf 'under a test root: %d\tcolocated with source: %d\n' "$under" "$coloc"
  printf 'test-file suffixes: '; printf '%s\n' "${test_files[@]}" | sed -E 's/.*\/([^/]*)$/\1/; s/^test_.*\.py$/test_*.py/; s/^.*(\.(test|spec)\.[a-z]+)$/*\1/; s/^[^*t].*\.(ya?ml)$/*.\1/' | sort | uniq -c | sort -rn | awk '{printf "%s(%d) ", $2, $1}'; echo
fi

# --- candidate-homes ---------------------------------------------------------------------
if want candidate-homes; then
  hdr candidate-homes
  for r in "${roots[@]}"; do
    [ -d "$r" ] || continue
    rb="$(basename "$r")"
    if [[ "$rb" =~ $TEST_ROOT_RE ]] || in_flows "$r"; then vocab="$ROLE_VOCAB"; else vocab='__mocks__|__helpers__|__factories__|__fixtures__'; fi
    find "$r" "${PRUNE[@]}" -o -type d -print | sort | while IFS= read -r d; do
      b="$(basename "$d")"
      [[ "$b" =~ ^($vocab)$ ]] || continue
      n=$(find "$d" "${PRUNE[@]}" -o -type f -print | wc -l)
      [ "$n" -gt 0 ] || continue
      case "$b" in
        __mocks__|mocks) role=mocks ;;
        __helpers__|helpers|support|utils|lib) role=helpers ;;
        __factories__|factories|builders|data) role=factories/backend-helpers ;;
        __fixtures__|fixtures) role=fixtures ;;
        pages|page_objects|pageobjects|screens) role=page-objects ;;
        subflows|shared|common) role=subflows/shared-steps ;;
      esac
      printf '%s\t%s\t%d files\n' "$d" "$role" "$n"
    done
    [ -f "$r/conftest.py" ] && printf '%s/conftest.py\tfixtures (pytest)\t1 file\n' "$r"
  done
fi

# --- duplicate-symbols -------------------------------------------------------------------
if want duplicate-symbols; then
  hdr duplicate-symbols
  {
    for f in "${scan_files[@]}"; do
      is_input_corpus "$f" && continue
      case "$f" in
        *.ts|*.tsx|*.mts|*.cts|*.js|*.jsx|*.mjs|*.cjs)
          grep -HoE '^(export (default )?)?(async )?(function\*? |class )[A-Za-z_$][A-Za-z0-9_$]*|^export (default )?(const |let |type |interface |enum )[A-Za-z_$][A-Za-z0-9_$]*' "$f" 2>/dev/null | awk -F: '{n=split($0,a," "); print a[n] "\t" $1}' ;;
        *.py)
          grep -HoE '^(def|class) [A-Za-z_][A-Za-z0-9_]*' "$f" 2>/dev/null | awk -F: '{n=split($0,a," "); print a[n] "\t" $1}' | grep -vE '^(test_|Test[A-Z]|_)' ;;
      esac
    done
  } | sort -u | awk -F'\t' '{c[$1]++; f[$1]=f[$1] " " $2} END {for (k in c) if (c[k]>1) printf "%s\t%d\t%s\n", k, c[k], f[k]}' | sort -t$'\t' -k2,2nr -k1,1
fi

# --- local-factories ---------------------------------------------------------------------
if want local-factories; then
  hdr local-factories
  {
    for f in "${test_files[@]}"; do
      is_shared_path "$f" && continue
      case "$f" in
        *.ts|*.tsx|*.mts|*.cts|*.js|*.jsx|*.mjs|*.cjs)
          grep -HoE '^[[:space:]]*(export )?(async )?(function\*? |const |let )(make|build|create|fake|stub|mk|mock|given|setup|render|seed|spy|with|sample|dummy|arrange|prepare)[A-Z][A-Za-z0-9_]*' "$f" 2>/dev/null | awk -F: '{n=split($0,a," "); print a[n] "\t" $1}' ;;
        *.py)
          grep -HoE '^[[:space:]]*def (make|build|create|fake|stub|mock|given|setup|seed|sample|dummy|arrange|prepare)_[a-z0-9_]+' "$f" 2>/dev/null | awk -F: '{n=split($0,a," "); print a[n] "\t" $1}' ;;
      esac
    done
  } | sort -u | awk -F'\t' '{c[$1]++; f[$1]=f[$1] " " $2} END {for (k in c) printf "%s\t%d\t%s\n", k, c[k], f[k]}' | sort -t$'\t' -k2,2nr -k1,1
fi

# --- inline-helpers (flow files) ---------------------------------------------------------
if want inline-helpers && [ ${#flows[@]} -gt 0 ]; then
  hdr inline-helpers
  for f in "${test_files[@]}"; do
    in_flows "$f" || continue
    case "$f" in
      *.py)
        grep -HnE '^[[:space:]]*def [a-z_][a-z0-9_]*\(.*\b(page|context|browser)\b' "$f" 2>/dev/null | grep -vE 'def test_'
        grep -HnE '^[[:space:]]*@pytest\.fixture' "$f" 2>/dev/null | sed 's/$/\t<- fixture defined in a flow file/' ;;
      *.ts|*.tsx|*.mts|*.cts|*.js|*.jsx|*.mjs|*.cjs)
        grep -HnE '^[[:space:]]*(export )?(async )?function [A-Za-z_$][A-Za-z0-9_$]*\(.*\bpage\b' "$f" 2>/dev/null
        grep -HnE '^[[:space:]]*(export )?(const|let) [A-Za-z_$][A-Za-z0-9_$]* = (async )?\([^)]*\bpage\b[^)]*\)[^=]*=>' "$f" 2>/dev/null
        grep -HnE '\b(test|base)\.extend(<[^>]*>)?\(' "$f" 2>/dev/null | sed 's/$/\t<- fixture defined in a flow file/' ;;
    esac
  done
fi

# --- subflows (Maestro / yaml flows) -----------------------------------------------------
if want subflows && [ ${#flows[@]} -gt 0 ]; then
  hdr subflows
  yaml_flows=(); for f in "${test_files[@]}"; do case "$f" in *.yaml|*.yml) in_flows "$f" && yaml_flows+=("$f") ;; esac; done
  if [ ${#yaml_flows[@]} -gt 0 ]; then
    printf 'runFlow targets by use count:\n'
    grep -hoE '(runFlow:|file:)[[:space:]]*[^[:space:]]+\.ya?ml' "${yaml_flows[@]}" 2>/dev/null | sed -E 's/^(runFlow|file):[[:space:]]*//' | sort | uniq -c | sort -rn | awk '{printf "%s\t%d\n", $2, $1}'
    printf 'flows with no runFlow (candidates for shared steps):\n'
    for f in "${yaml_flows[@]}"; do case "$f" in */subflows/*) continue ;; esac; grep -q 'runFlow' "$f" || printf '%s\n' "$f"; done
  fi
fi

# --- mock-targets ------------------------------------------------------------------------
if want mock-targets; then
  hdr mock-targets
  q="['\"]" nq="[^'\"]+"
  py_class() {
    local seg="${1%%.*}"
    if [ -d "$seg" ] || [ -f "$seg.py" ] || [ -d "src/$seg" ] || [ -f "src/$seg.py" ]; then echo internal; else echo package; fi
  }
  {
    for f in "${scan_files[@]}"; do
      case "$f" in
        *.ts|*.tsx|*.mts|*.cts|*.js|*.jsx|*.mjs|*.cjs)
          grep -vE '^[[:space:]]*(//|/?\*)' "$f" 2>/dev/null \
            | grep -oE "\b(jest|vi)\.(do[mM]ock|mock|unstable_mockModule)\([[:space:]]*$q$nq$q|\bmock\.module\([[:space:]]*$q$nq$q" \
            | sed -E "s/^.*\([[:space:]]*$q//; s/$q\$//" \
            | awk -v f="$f" '{ c = ($0 ~ /^(\.|\/|@\/|~\/|#|src\/|app\/|lib\/)/) ? "internal" : "package"; print $0 "\t" c "\t" f }' ;;
        *.py)
          grep -vE '^[[:space:]]*#' "$f" 2>/dev/null \
            | grep -oE "\b(mock\.|mocker\.)?patch\([[:space:]]*$q$nq$q|\bmonkeypatch\.setattr\([[:space:]]*$q$nq$q" \
            | sed -E "s/^.*\([[:space:]]*$q//; s/$q\$//" \
            | while IFS= read -r t; do printf '%s\t%s\t%s\n' "$t" "$(py_class "$t")" "$f"; done ;;
      esac
    done
  } | sort -u | awk -F'\t' '{k=$1 "\t" $2; c[k]++; f[k]=f[k] " " $3} END {for (k in c) printf "%s\t%d\t%s\n", k, c[k], f[k]}' | sort -t$'\t' -k2,2 -k3,3nr -k1,1
fi

# --- skip-markers ------------------------------------------------------------------------
if want skip-markers; then
  hdr skip-markers
  patterns="$(dirname "$0")/skip-patterns.sh"
  if [ ! -f "$patterns" ]; then
    echo "skip-patterns.sh not found next to $(basename "$0") — skip-markers not scanned" >&2
  else
    . "$patterns"
    for f in "${scan_files[@]}"; do
      skip_pattern_for "$f"
      if [ -z "$SKIP_PAT" ]; then
        case "$f" in
          *.ts|*.tsx|*.mts|*.cts|*.js|*.jsx|*.mjs|*.cjs) SKIP_PAT="$SKIP_PAT_JS" ;;
          *.py) SKIP_PAT="$SKIP_PAT_PY" ;;
          *.yaml|*.yml) SKIP_PAT="$SKIP_PAT_MAESTRO" ;;
        esac
      fi
      [ -n "$SKIP_PAT" ] || continue
      grep -HnE "$SKIP_PAT" "$f" 2>/dev/null
    done
  fi
fi
exit 0
