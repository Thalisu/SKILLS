#!/usr/bin/env bash
# trivial-door.sh: the door checks of the trivial Playbook of do that a script can observe, so a
# reviewer can rerun them. Run from anywhere inside the project.
#
#   trivial-door.sh branch [<name>]     the named branch, or the current one, against the
#                                       protected-branch rule of test-triage; is_protected below
#                                       is a verbatim copy of skills/test-triage/scripts/context.sh,
#                                       and tests/trivial-door.sh fails when the two drift
#   trivial-door.sh covering <file>...  the tracked test files that name a touched file, by its stem
#   trivial-door.sh diff <file>...      the touched files against HEAD: a test file, a new file, a new
#                                       exported symbol or a changed exported signature is not Trivial
#
# Prints key=value lines. Exit codes: 0 the door holds · 1 not Trivial, with goes_to=<playbook> ·
# 2 usage, or not a git repository · 3 a language the diff check has no pattern for, left to the
# run's judgment. covering always exits 0.
#
# Test-file classes come from the project's installed Testing Policy
# (<project>/.claude/testing-policy/skip-patterns.sh, skip_pattern_for) when it exists, else from
# the built-in list below, which mirrors the policy's classes plus common ones for languages it does
# not cover. Exports are matched by pattern for JavaScript, TypeScript and Python only; a head is the
# declaration up to its body, whitespace-normalised, so a reflow passes and a changed parameter, a
# widened type or a new interface member does not. The initializer of an exported variable is not
# part of its head (a log wording held in an exported constant is the covering suite's to judge),
# except for an arrow or function value, whose parameter list is, and for module.exports and
# export lists, which name what the module exports.
set -uo pipefail

usage() { echo "usage: trivial-door.sh branch [<name>] | trivial-door.sh covering <file>... | trivial-door.sh diff <file>..." >&2; exit 2; }

top="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "not a git repository" >&2; exit 2; }
prefix="$(git rev-parse --show-prefix 2>/dev/null)"

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

cmd_branch() {
  local cur locals remotes others answer
  cur="${1:-$(git symbolic-ref --short -q HEAD || echo HEAD)}"
  locals="$(git for-each-ref --format='%(refname:short)' refs/heads)"
  remotes="$(git for-each-ref --format='%(refname:short)' refs/remotes | sed -E 's#^[^/]+/##')"
  others="$(printf '%s\n%s\n' "$locals" "$remotes" | grep -v '^$' | grep -vx HEAD | grep -vx "$cur" \
    | sort -u | grep -Ex 'main|master|develop|development|staging|production|prod|release.*' | tr '\n' ' ' || true)"
  echo "branch=$cur"
  echo "rule=main or master beside develop, development, staging or release*; production or prod beside any of those or main or master; a lone default branch is the working branch"
  answer="$(is_protected "$cur" "$others")"
  case "$answer" in
    yes*)
      echo "protected=yes"
      echo "reason=${answer#yes (}" | sed 's/)$//'
      return 1 ;;
  esac
  echo "protected=no"
  return 0
}

classes=built-in
if [ -f "$top/.claude/testing-policy/skip-patterns.sh" ]; then
  # shellcheck disable=SC1091
  . "$top/.claude/testing-policy/skip-patterns.sh"
  classes=policy
fi

is_test_file() { # $1 absolute path
  if [ "$classes" = policy ]; then
    SKIP_KIND=""
    skip_pattern_for "$1"
    [ -n "${SKIP_KIND:-}" ]
    return
  fi
  case "$1" in
    *.test.ts|*.test.tsx|*.test.mts|*.test.cts|*.test.js|*.test.jsx|*.test.mjs|*.test.cjs|\
    *.spec.ts|*.spec.tsx|*.spec.mts|*.spec.cts|*.spec.js|*.spec.jsx|*.spec.mjs|*.spec.cjs|\
    *.cy.ts|*.cy.tsx|*.cy.js|*.cy.jsx|*/__tests__/*|*/__snapshots__/*|*.snap|\
    */test_*.py|*_test.py|*/conftest.py|*/.maestro/*.yaml|*/.maestro/*.yml|\
    *_test.go|*_test.rb|*_spec.rb|*Test.java|*Tests.java|*Test.kt|*Tests.cs|*.feature|\
    */tests/*|*/test/*|*/spec/*|*/e2e/*) return 0 ;;
  esac
  return 1
}

# A head is one exported declaration with its whitespace squeezed: one space between words, none
# beside punctuation, `;` read as `,`, trailing commas and quotes unified.
AWK_COMMON='
function paren_delta(s,  i, c, d) { d = 0; for (i = 1; i <= length(s); i++) { c = substr(s, i, 1); if (c == "(") d++; else if (c == ")") d-- } return d }
function total_delta(s,  i, c, d) { d = 0; for (i = 1; i <= length(s); i++) { c = substr(s, i, 1); if (c == "(" || c == "{" || c == "[") d++; else if (c == ")" || c == "}" || c == "]") d-- } return d }
function squeeze(s,  i, c, out, prev, nxt) {
  gsub(/[[:space:]]+/, " ", s); sub(/^ /, "", s); sub(/ $/, "", s); out = ""
  for (i = 1; i <= length(s); i++) {
    c = substr(s, i, 1)
    if (c == " ") { prev = substr(out, length(out), 1); nxt = substr(s, i + 1, 1)
      if ((prev != "" && index(PUNCT, prev)) || (nxt != "" && index(PUNCT, nxt))) continue }
    out = out c }
  return out }
function norm(s) {
  s = squeeze(s); gsub(/;/, ",", s); gsub(/,\)/, ")", s); gsub(/,\]/, "]", s); gsub(/,\}/, "}", s); sub(/,$/, "", s); gsub(/\047/, "\"", s)
  return s }
function cut_at_body(s,  i, c, d) {
  d = 0; for (i = 1; i <= length(s); i++) { c = substr(s, i, 1); if (c == "(") d++; else if (c == ")") d--; else if (c == "{" && d == 0) return substr(s, 1, i) }
  d = 0; for (i = 1; i < length(s); i++) { c = substr(s, i, 1); if (c == "(") d++; else if (c == ")") d--; else if (c == "=" && substr(s, i + 1, 1) == ">" && d == 0) return substr(s, 1, i + 1) }
  return s }
function cut_at_eq(s,  i, c, d, prev, nxt) { d = 0; for (i = 1; i <= length(s); i++) { c = substr(s, i, 1); if (c == "(" || c == "{" || c == "[") d++; else if (c == ")" || c == "}" || c == "]") d--; else if (c == "=" && d == 0) { prev = substr(s, i - 1, 1); nxt = substr(s, i + 1, 1); if (prev != "!" && prev != "<" && prev != ">" && prev != "=" && nxt != "=" && nxt != ">") return substr(s, 1, i - 1) } } return s }
BEGIN { PUNCT = "(){}[]<>,:;=|.?!+-*/&%" }
'

extract_js() {
  awk "$AWK_COMMON"'
function jsname(s,  m) {
  s = first; sub(/^[[:space:]]+/, "", s)
  if (s ~ /^module\.exports[[:space:]]*\./) { sub(/^module\.exports[[:space:]]*\./, "", s); match(s, /^[A-Za-z_$][A-Za-z0-9_$]*/); return substr(s, RSTART, RLENGTH) }
  if (s ~ /^module\.exports/) return "module.exports"
  if (s ~ /^exports\./) { sub(/^exports\./, "", s); match(s, /^[A-Za-z_$][A-Za-z0-9_$]*/); return substr(s, RSTART, RLENGTH) }
  sub(/^export[[:space:]]*/, "", s)
  if (s ~ /^default([[:space:]]|$)/) return "default"
  if (s ~ /^[{*]/ || s ~ /^type[[:space:]]*\{/) return norm(head)
  while (s ~ /^(async|abstract|declare|const|let|var|function\*?|class|type|interface|enum|namespace|module)([[:space:]]|$)/) sub(/^[A-Za-z*]+[[:space:]]*/, "", s)
  if (match(s, /^[A-Za-z_$][A-Za-z0-9_$]*/)) return substr(s, RSTART, RLENGTH)
  return norm(first) }
function emit() {
  if (body) head = cut_at_body(buf)
  else if (first ~ /^[[:space:]]*export[[:space:]]+(declare[[:space:]]+)?(const|let|var)[[:space:]]/ || first ~ /^[[:space:]]*exports\./) head = cut_at_eq(buf)
  else head = buf
  head = norm(head); print jsname() "\t" head; capturing = 0 }
{
  line = $0; sub(/\/\/.*$/, "", line)
  if (!capturing) {
    if (line ~ /^[[:space:]]*export([[:space:]]|[{*])/ || line ~ /^[[:space:]]*module\.exports[[:space:]]*(\.[A-Za-z_$][A-Za-z0-9_$]*)?[[:space:]]*=/ || line ~ /^[[:space:]]*exports\.[A-Za-z_$][A-Za-z0-9_$]*[[:space:]]*=/) {
      capturing = 1; first = line; buf = ""; paren_depth = 0; total_depth = 0; n = 0
      body = (line ~ /^[[:space:]]*export[[:space:]]+(default[[:space:]]+)?(async[[:space:]]+)?function/ \
           || line ~ /^[[:space:]]*export[[:space:]]+(default[[:space:]]+)?(abstract[[:space:]]+)?class/ \
           || line ~ /^[[:space:]]*export[[:space:]]+(declare[[:space:]]+)?(namespace|module)[[:space:]]/ \
           || line ~ /=[[:space:]]*(async[[:space:]]+)?(function|class)([[:space:]*(]|$)/) ? 1 : 0
    } else next
  }
  buf = buf (buf == "" ? "" : " ") line; n++
  paren_depth += paren_delta(line); total_depth += total_delta(line)
  if (!body && paren_depth <= 0 && line ~ /=>/) body = 1
  if (body) { if ((paren_depth <= 0 && line ~ /\{/) || (paren_depth <= 0 && line ~ /;[[:space:]]*$/) || line ~ /^[[:space:]]*$/ || n >= 40) emit() }
  else if (total_depth <= 0 || n >= 40) emit()
}
END { if (capturing) emit() }'
}

extract_py() {
  awk "$AWK_COMMON"'
function emit() { print name "\t" norm(body || name == "__all__" ? buf : cut_at_eq(buf)); capturing = 0 }
{
  line = $0; sub(/[[:space:]]#.*$/, "", line)
  if (!capturing) {
    if (line ~ /^#/) next
    if (line ~ /^(async[[:space:]]+)?def[[:space:]]+[A-Za-z][A-Za-z0-9_]*/) { s = line; sub(/^(async[[:space:]]+)?def[[:space:]]+/, "", s); body = 1 }
    else if (line ~ /^class[[:space:]]+[A-Za-z][A-Za-z0-9_]*/) { s = line; sub(/^class[[:space:]]+/, "", s); body = 1 }
    else if (line ~ /^__all__[[:space:]]*\+?=/) { s = "__all__"; body = 0 }
    else if (line ~ /^[A-Za-z][A-Za-z0-9_]*[[:space:]]*(:[^=]*)?=[^=]/) { s = line; body = 0 }
    else next
    match(s, /^[A-Za-z_][A-Za-z0-9_]*/); name = substr(s, RSTART, RLENGTH)
    capturing = 1; buf = ""; paren_depth = 0; total_depth = 0; n = 0
  }
  buf = buf (buf == "" ? "" : " ") line; n++
  paren_depth += paren_delta(line); total_depth += total_delta(line)
  if (body) { if ((paren_depth <= 0 && line ~ /:[[:space:]]*$/) || n >= 40) emit() }
  else if (total_depth <= 0 || n >= 40) emit()
}
END { if (capturing) emit() }'
}

rel_of() { # $1 a path as given: the repo-relative path
  local rel
  case "$1" in
    /*) rel="${1#"$top"/}" ;;
    *) rel="$prefix$1" ;;
  esac
  echo "${rel#./}"
}

cmd_covering() {
  [ "$#" -ge 1 ] || usage
  echo "classes=$classes"
  local f rel stem pattern t found tests
  tests="$(git -C "$top" ls-files | while IFS= read -r t; do is_test_file "$top/$t" && echo "$t"; done)"
  for f in "$@"; do
    rel="$(rel_of "$f")"
    stem="${rel##*/}"; stem="${stem%.*}"
    pattern="(^|[^A-Za-z0-9_])$(printf '%s' "$stem" | sed 's/[][\.*^$+?(){}|]/\\&/g')([^A-Za-z0-9_]|$)"
    found=0
    while IFS= read -r t; do
      [ -n "$t" ] && [ "$t" != "$rel" ] || continue
      grep -qE -- "$pattern" "$top/$t" 2>/dev/null && { echo "covering=$rel: $t"; found=1; }
    done <<<"$tests"
    [ "$found" = 1 ] || echo "uncovered=$rel"
  done
  return 0
}

lang_of() { # $1 repo-relative path: js | py | none | other
  local base ext
  base="${1##*/}"
  case "$base" in
    LICENSE|LICENCE|README|CHANGELOG|NOTICE|AUTHORS|CODEOWNERS|VERSION|CONTRIBUTING) echo none; return ;;
  esac
  case "$base" in *.*) ext="${base##*.}" ;; *) echo other; return ;; esac
  case "$ext" in
    js|jsx|mjs|cjs|ts|tsx|mts|cts) echo js ;;
    py) echo py ;;
    md|mdx|txt|rst|adoc|json|jsonc|json5|yaml|yml|toml|ini|cfg|conf|env|html|htm|css|scss|sass|less|\
    svg|png|jpg|jpeg|gif|ico|webp|woff|woff2|ttf|eot|lock|csv|tsv|xml|properties|log|pdf|\
    editorconfig|gitignore|gitattributes|gitkeep|npmrc|nvmrc|prettierrc|prettierignore|eslintignore|dockerignore) echo none ;;
    *) echo other ;;
  esac
}

rank_of() { case "$1" in refactoring) echo 3 ;; discuss) echo 2 ;; bug-fix) echo 1 ;; *) echo 0 ;; esac; }

cmd_diff() {
  [ "$#" -ge 1 ] || usage
  echo "classes=$classes"
  local f rel abs lang before after name head stop=0 judgment=0 goes="" reported had_new
  raise_goes() { stop=1; [ "$(rank_of "$1")" -gt "$(rank_of "$goes")" ] && goes="$1"; return 0; }
  for f in "$@"; do
    rel="$(rel_of "$f")"
    abs="$top/$rel"
    if ! git cat-file -e "HEAD:$rel" 2>/dev/null; then
      [ -e "$abs" ] || { echo "missing=$rel" >&2; exit 2; }
      is_test_file "$abs" && { echo "test_file=$rel"; raise_goes bug-fix; }
      echo "new_file=$rel"; raise_goes discuss
      continue
    fi
    if is_test_file "$abs"; then
      echo "test_file=$rel"; raise_goes bug-fix
      continue
    fi
    lang="$(lang_of "$rel")"
    [ -e "$abs" ] || echo "deleted_file=$rel"
    case "$lang" in
      none) echo "no_exports=$rel"; continue ;;
      other) echo "judgment=$rel"; judgment=1; continue ;;
    esac
    before="$(git show "HEAD:$rel" | "extract_$lang")"
    if [ -e "$abs" ]; then after="$("extract_$lang" < "$abs")"; else after=""; fi
    reported=0; had_new=0
    while IFS=$'\t' read -r name head; do
      [ -n "$name" ] || continue
      grep -qxF -- "$name	$head" <<<"$before" && continue
      if cut -f1 <<<"$before" | grep -qxF -- "$name"; then
        echo "changed_signature=$rel: $head"; raise_goes refactoring
      else
        echo "new_export=$rel: $head"; raise_goes discuss; had_new=1
      fi
      reported=1
    done <<<"$after"
    while IFS=$'\t' read -r name head; do
      [ -n "$name" ] || continue
      grep -qxF -- "$name	$head" <<<"$after" && continue
      cut -f1 <<<"$after" | grep -qxF -- "$name" && continue
      echo "removed_export=$rel: $name"; reported=1
      [ "$had_new" = 1 ] && raise_goes refactoring
    done <<<"$before"
    [ "$reported" = 1 ] || echo "ok=$rel"
  done
  if [ "$stop" = 1 ]; then echo "verdict=not-trivial"; echo "goes_to=$goes"; return 1; fi
  if [ "$judgment" = 1 ]; then echo "verdict=judgment"; return 3; fi
  echo "verdict=trivial"
  return 0
}

case "${1:-}" in
  branch) shift; cmd_branch "$@" ;;
  covering) shift; cmd_covering "$@" ;;
  diff) shift; cmd_diff "$@" ;;
  *) usage ;;
esac
