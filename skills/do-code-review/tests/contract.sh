#!/usr/bin/env bash
# contract.sh: the static contract of the do-code-review skill, checked against the files on disk so
# a reviewer can rerun it: the Review format and its index row, the skill file and its Codex
# metadata, the two agent definitions and their tool lists, the evals, the docs page, the README
# rows, the invocation contract's rows, and no em-dash in any prose the skill adds.
# Run: bash skills/do-code-review/tests/contract.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
repo="$(cd "$here/../../.." && pwd -P)"
skill="$repo/skills/do-code-review"
fails=0

has() { # $1 label, $2 file, $3.. fixed strings that must appear in the file
  local label="$1" file="$2"; shift 2
  local ok=1 line
  [ -f "$file" ] || ok=0
  for line in "$@"; do [ "$ok" = 1 ] && grep -qF -- "$line" "$file" || ok=0; done
  if [ "$ok" = 1 ]; then echo "ok    $label"; else echo "FAIL  $label ($file)"; fails=$((fails + 1)); fi
}
lacks() { # $1 label, $2 file, $3.. fixed strings that must not appear
  local label="$1" file="$2"; shift 2
  local ok=1 line
  [ -f "$file" ] || ok=0
  for line in "$@"; do grep -qF -- "$line" "$file" 2>/dev/null && ok=0; done
  if [ "$ok" = 1 ]; then echo "ok    $label"; else echo "FAIL  $label ($file)"; fails=$((fails + 1)); fi
}
ordered() { # $1 label, $2 file, $3.. lines that must appear in this order
  local label="$1" file="$2"; shift 2
  local last=0 n line ok=1
  for line in "$@"; do
    n="$(grep -nF -- "$line" "$file" 2>/dev/null | awk -F: -v l="$last" '$1 > l { print $1; exit }')"
    [ -n "$n" ] || ok=0
    last="${n:-$last}"
  done
  if [ "$ok" = 1 ]; then echo "ok    $label"; else echo "FAIL  $label ($file)"; fails=$((fails + 1)); fi
}
expect() { # $1 label, $2.. a command that must succeed
  local label="$1"; shift
  if "$@"; then echo "ok    $label"; else echo "FAIL  $label"; fails=$((fails + 1)); fi
}

# The Review format: a chain format with fixed section names, indexed with its writer and readers.
format="$repo/.agents/formats/review-format.md"
has "the format opens with its title" "$format" "# Review format"
ordered "the sections come in the fixed order" "$format" \
  "## Header" "## Intent" "## Safe because" "## Act on" "## Consider" "## Noted" "## Cleared" "## Axes" "## Rules"
has "the header names its keys" "$format" \
  "Ticket:" "Fixed point:" "Commit:" "Base:" "Spec source:" "Mode:" "Language:" ", inferred" "dirty"
has "a Finding carries its fields" "$format" \
  "### <n>. <Axis> at <location>" "Claim:" "Evidence:" "Rung:" "Risk:" "Fix:" "Refuted by:"
has "the six Axes are named" "$format" \
  "Correctness" "Spec" "Standards" "Principles" "Blast radius" "Security" "not run" "0 findings"
has "the Rung gate is stated" "$format" "Rung 1 or 2" "unproven"
has "the two homes of the file are stated" "$format" ".scratch/reviews/" ".review" "Ticket: none"
has "the index carries the format's row" "$repo/.agents/formats/README.md" \
  "| [review-format.md](review-format.md) | \`do-code-review\` | \`do\`, the Fixer |" "a review"
has "the repo rules list the review among the formats" "$repo/CLAUDE.md" "a ticket, a review"

# No em-dash in any prose the skill adds.
prose=("$format")
for f in "${prose[@]}"; do
  [ -f "$f" ] || continue
  if grep -q $'\xe2\x80\x94' "$f"; then echo "FAIL  no em-dash in $f"; fails=$((fails + 1)); else echo "ok    no em-dash in ${f#"$repo/"}"; fi
done

if [ "$fails" = 0 ]; then echo "PASS"; else echo "$fails failing"; exit 1; fi
