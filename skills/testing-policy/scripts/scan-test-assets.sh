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
#                  local-factories inline-helpers subflows skip-markers)
#
# Output is plain text with fixed "## <section>" headers so callers can grep it.
# Exit 0 whenever the scan ran (a finding is not an error); exit 2 on usage errors.
set -uo pipefail

roots=() shared=() flows=() only=""
while [ $# -gt 0 ]; do
  case "$1" in
    --root)    roots+=("${2:?--root needs a dir}"); shift 2 ;;
    --shared)  shared+=("${2:?--shared needs a dir}"); shift 2 ;;
    --flows)   flows+=("${2:?--flows needs a dir}"); shift 2 ;;
    --section) only="${2:?--section needs a name}"; shift 2 ;;
    -h|--help) sed -n '2,17p' "$0"; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

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
    *.test.ts|*.test.tsx|*.test.js|*.test.jsx|*.test.mjs|*.spec.ts|*.spec.tsx|*.spec.js|*.spec.jsx) return 0 ;;
    */__tests__/*.ts|*/__tests__/*.tsx|*/__tests__/*.js|*/__tests__/*.jsx) return 0 ;;
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

all_files=() test_files=() scan_files=()
for r in "${roots[@]}"; do
  [ -d "$r" ] || { echo "warning: root $r does not exist" >&2; continue; }
  rb="$(basename "$r")"
  while IFS= read -r -d '' f; do
    case "$f" in *.d.ts) continue ;; esac
    all_files+=("$f")
    if is_test_file "$f"; then test_files+=("$f"); scan_files+=("$f"); continue; fi
    if [[ "$rb" =~ $TEST_ROOT_RE ]] || in_flows "$r"; then
      case "$f" in *.ts|*.tsx|*.js|*.jsx|*.mjs|*.py|*.yaml|*.yml) scan_files+=("$f") ;; esac
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
      case "$f" in
        *.ts|*.tsx|*.js|*.jsx|*.mjs)
          grep -HoE '^export (default )?(async )?(function\*? |const |let |class |type |interface |enum )[A-Za-z_$][A-Za-z0-9_$]*' "$f" 2>/dev/null | awk -F: '{n=split($0,a," "); print a[n] "\t" $1}' ;;
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
        *.ts|*.tsx|*.js|*.jsx|*.mjs)
          grep -HoE '^[[:space:]]*(export )?(async )?(function\*? |const |let )(make|build|create|fake|stub|mk|given|setup)[A-Z][A-Za-z0-9_]*' "$f" 2>/dev/null | awk -F: '{n=split($0,a," "); print a[n] "\t" $1}' ;;
        *.py)
          grep -HoE '^[[:space:]]*def (make|build|create|fake|stub|given|setup)_[a-z0-9_]+' "$f" 2>/dev/null | awk -F: '{n=split($0,a," "); print a[n] "\t" $1}' ;;
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
      *.ts|*.tsx|*.js|*.jsx)
        grep -HnE '^[[:space:]]*(export )?(async )?function [A-Za-z_][A-Za-z0-9_]*\(.*\bpage\b' "$f" 2>/dev/null ;;
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

# --- skip-markers ------------------------------------------------------------------------
if want skip-markers; then
  hdr skip-markers
  for f in "${scan_files[@]}"; do
    case "$f" in
      *.ts|*.tsx|*.js|*.jsx|*.mjs) grep -HnE '\.(skip|only)\(|\b(xit|xdescribe|xtest|fit|fdescribe)\(' "$f" 2>/dev/null ;;
      *.py) grep -HnE 'pytest\.mark\.(skip|skipif|xfail)|pytest\.skip\(' "$f" 2>/dev/null ;;
      *.yaml|*.yml) grep -HnE 'optional:[[:space:]]*true' "$f" 2>/dev/null ;;
    esac
  done
fi
exit 0
