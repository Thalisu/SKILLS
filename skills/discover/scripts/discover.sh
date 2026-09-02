#!/usr/bin/env bash
# discover.sh — deterministic "does X exist / where is X" report for a batch of symbols.
#
# Usage: discover.sh [--root DIR] < spec            (default root: current directory)
#
# Spec: one item per line, five fields separated by " | ":
#   <id> | <names, comma-separated> | <behaviour text or -> | <extra rg regex or -> | <callers: yes|no>
#
# Output (read by the discover agent, not by people):
#   ROOT <absolute root dir>                every relative path below is relative to this
#   LANGS <ast-grep languages present>      GENERIC <code extensions without ast coverage>
#   INTEL_FILE yes|no                       whether .planning/intel/file-roles.json exists
#   # <id> names=<names>
#   INTEL <path> <type> exports=<names>     entries of file-roles.json matching a candidate name
#   DEF <path>:<line> <signature> uses=<n> via=ast     one per definition, most used first
#   NAME <path>:<line> <line text> via=generic         word hits when no definition exists
#   ANALOG <path>:<line> <first definition line> stems=<hit stems> score=<n>
#   HOME <dir>                              where a new symbol would go (only when nothing is defined)
#   UNATTRIBUTED <n>                        uses whose import resolves to none of the duplicates
#   CALLERS <path>:<line>, ... [+N more]    when the item asked for callers
#   STATE FOUND|DUPLICATE|NAME_ONLY|NOT_FOUND|ERROR <reason>
# Uses, callers, analogs and the generic funnel only look at code files: docs, data, lock, style and
# image extensions are ignored. A malformed spec line yields STATE ERROR for that item only. Exit 0;
# exit 2 with one stderr line on an empty/all-malformed spec or a missing dependency (rg, ast-grep, jq).
set -euo pipefail
export LC_ALL=C

root=.
while [ $# -gt 0 ]; do
  case "$1" in
    --root) root="${2:?--root needs a directory}"; shift 2 ;;
    -h|--help) sed -n '2,24p' "$0"; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done
for dep in rg ast-grep jq; do
  command -v "$dep" >/dev/null 2>&1 || { echo "missing dependency: $dep" >&2; exit 2; }
done
cd "$root" 2>/dev/null || { echo "not a directory: $root" >&2; exit 2; }
echo "ROOT $(pwd -P)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

trim() { local s="$1"; s="${s#"${s%%[![:space:]]*}"}"; printf '%s' "${s%"${s##*[![:space:]]}"}"; }
# head would SIGPIPE its producer, which pipefail turns into a script abort.
first() { awk -v n="$1" 'NR <= n'; }
esc_re() { printf '%s' "$1" | sed -E 's/[][\\.^$*+?(){}|]/\\&/g'; }
clip() {
  local s; s="$(printf '%s' "$1" | tr '\t' ' ' | sed -E 's/ +/ /g; s/^ //; s/ $//')"
  if [ ${#s} -le 90 ]; then printf '%s' "$s"; else printf '%s...' "${s:0:87}"; fi
}

# ---------- spec ----------
# A bad line is stored as a per-item error, not fatal: the rest of the batch is still
# answered. Exit 2 only when the spec is empty or every line is malformed.
ids=() names=() texts=() regexes=() callers=() errors=()
lineno=0
while IFS= read -r line || [ -n "$line" ]; do
  [ -z "$(trim "$line")" ] && continue
  lineno=$((lineno + 1))
  IFS='|' read -r f1 f2 f3 f4 f5 _ <<<"$line"
  id="$(trim "$f1")"; nm="${f2//[[:space:]]/}"
  nm="$(tr ',' '\n' <<<"$nm" | awk 'NF && !seen[$0]++' | paste -sd,)"
  text="$(trim "$f3")"; re="$(trim "$f4")"; cl="$(trim "$f5")"
  err=""
  [ -n "$id" ] && [ -n "$nm" ] || err="malformed spec line"
  case "${cl:-no}" in yes|no) ;; *) err="callers must be yes or no" ;; esac
  [ "$cl" = yes ] || cl=no
  ids+=("${id:-$lineno}"); names+=("$nm"); texts+=("${text:--}"); regexes+=("${re:--}")
  callers+=("$cl"); errors+=("$err")
done
[ ${#ids[@]} -gt 0 ] || { echo "empty spec" >&2; exit 2; }
n_ok=0
for e in "${errors[@]}"; do [ -z "$e" ] && n_ok=$((n_ok + 1)); done
[ "$n_ok" -gt 0 ] || { echo "every spec line malformed" >&2; exit 2; }

# ---------- stage 0: file list ----------
rg --files --no-require-git \
  -g '!node_modules' -g '!dist' -g '!build' -g '!.next' -g '!coverage' -g '!__snapshots__' \
  -g '!*.test.*' -g '!*.spec.*' -g '!*.stories.*' -g '!*.d.ts' \
  -g '!test_*.py' -g '!*_test.py' -g '!*_test.go' -g '!*Test.java' \
  -g '!__tests__' -g '!__mocks__' -g '!jest.setup.*' -g '!vitest.setup.*' -g '!setupTests.*' \
  2>/dev/null | sort > "$tmp/files" || true

awk -v tmp="$tmp" '
  BEGIN {
    n = split("ts:ts tsx:tsx js:javascript jsx:javascript mjs:javascript cjs:javascript py:python rs:rust go:go java:java kt:kotlin kts:kotlin swift:swift c:c h:c cc:cpp cpp:cpp cxx:cpp hpp:cpp hh:cpp cs:csharp rb:ruby php:php lua:lua sh:bash bash:bash", pairs, " ")
    for (i = 1; i <= n; i++) { split(pairs[i], kv, ":"); map[kv[1]] = kv[2] }
    n = split("md mdx txt rst adoc json json5 yaml yml toml ini cfg lock xml csv tsv svg png jpg jpeg gif webp avif ico bmp woff woff2 ttf otf eot pdf log env html htm css scss sass less map snap patch diff key pem crt cer der p12 pfx pub sum example sample", nc, " ")
    for (i = 1; i <= n; i++) noncode[nc[i]] = 1
  }
  { k = split($0, p, "/"); b = p[k]; ext = ""
    if (match(b, /\.[^.]+$/) && RSTART > 1) ext = tolower(substr(b, RSTART + 1))
    lang = (ext in map) ? map[ext] : ((ext in noncode) ? "other" : "generic")
    print lang "\t" ext "\t" $0
    if (lang == "other") next
    print $0 > (tmp "/files.code")
    if (lang != "generic") { print $0 > (tmp "/files.ast"); langs[lang] = 1 } else if (ext != "") gen[ext]++
  }
  END {
    for (l in langs) print l > (tmp "/langs")
    for (e in gen) print gen[e] "\t" e > (tmp "/generic_ext")
  }
' "$tmp/files" > "$tmp/classified"
touch "$tmp/files.ast" "$tmp/files.code" "$tmp/langs" "$tmp/generic_ext"
awk -F'\t' '$1 == "generic" {print $3}' "$tmp/classified" > "$tmp/files.generic"
# language families for use counting: dialects that call each other freely count as one
awk -F'\t' '{ l = $1
  if (l == "ts" || l == "tsx" || l == "javascript") l = "js"
  else if (l == "java" || l == "kotlin") l = "jvm"
  print $3 "\t" l }' "$tmp/classified" > "$tmp/family"
langs_present="$(sort "$tmp/langs" | paste -sd,)"
generic_present="$(sort -t$'\t' -k1,1nr -k2,2 "$tmp/generic_ext" | first 10 | cut -f2 | paste -sd,)"
echo "LANGS ${langs_present:--}"
echo "GENERIC ${generic_present:--}"

# ---------- stage 1: intel ----------
intel=.planning/intel/file-roles.json
if [ -f "$intel" ]; then
  echo "INTEL_FILE yes"
  jq -r '(.entries // {}) | to_entries[] | [.key, (.value.type // "-"), ((.value.exports // []) | join(","))] | @tsv' "$intel" 2>/dev/null > "$tmp/intel" || : > "$tmp/intel"
else
  echo "INTEL_FILE no"; : > "$tmp/intel"
fi

# ---------- stage 2: definitions (one ast-grep run for the whole batch) ----------
alt="$(for i in "${!ids[@]}"; do [ -z "${errors[$i]}" ] && printf '%s\n' "${names[$i]}"; done \
  | tr ',' '\n' | awk 'NF' | sort -u | while IFS= read -r n; do esc_re "$n"; echo; done | paste -sd'|')"
R='^('"$alt"')$'
RQ='(^|[.:])('"$alt"')$'
fld() { printf "has: {field: %s, regex: '%s', pattern: \$NAME}" "$1" "$2"; }
kid() { printf "has: {kind: %s, regex: '%s', pattern: \$NAME}" "$1" "$2"; }
k() { printf '    - {kind: %s, %s}\n' "$1" "$2"; }
rules=""
for lang in ${langs_present//,/ }; do
  body=""
  case "$lang" in
    ts|tsx|javascript)
      body+="$(k function_declaration "$(fld name "$R")")"$'\n'
      body+="$(k method_definition "$(fld name "$R")")"$'\n'
      # Only top-level declarators: every local `const x = …` is a variable_declarator too.
      body+="$(k variable_declarator "$(fld name "$R"), inside: {any: [{kind: lexical_declaration}, {kind: variable_declaration}], inside: {any: [{kind: program}, {kind: export_statement}]}}")"$'\n'
      body+="$(k class_declaration "$(fld name "$R")")"$'\n'
      body+="$(k export_specifier "$(fld alias "$R")")"$'\n'
      if [ "$lang" != javascript ]; then
        body+="$(k interface_declaration "$(fld name "$R")")"$'\n'
        body+="$(k enum_declaration "$(fld name "$R")")"$'\n'
        body+="$(k type_alias_declaration "$(fld name "$R")")"$'\n'
      fi ;;
    python) for kind in function_definition class_definition; do body+="$(k $kind "$(fld name "$R")")"$'\n'; done ;;
    rust) for kind in function_item function_signature_item struct_item enum_item const_item type_item; do body+="$(k $kind "$(fld name "$R")")"$'\n'; done ;;
    go)
      for kind in function_declaration method_declaration; do body+="$(k $kind "$(fld name "$R")")"$'\n'; done
      body+="$(k type_declaration "has: {kind: type_spec, $(fld name "$R")}")"$'\n' ;;
    java) for kind in method_declaration constructor_declaration class_declaration interface_declaration; do body+="$(k $kind "$(fld name "$R")")"$'\n'; done ;;
    kotlin)
      body+="$(k function_declaration "$(kid simple_identifier "$R")")"$'\n'
      body+="$(k property_declaration "has: {kind: variable_declaration, $(kid simple_identifier "$R")}")"$'\n'
      body+="$(k class_declaration "$(kid type_identifier "$R")")"$'\n' ;;
    swift) for kind in function_declaration property_declaration class_declaration; do body+="$(k $kind "$(fld name "$R")")"$'\n'; done ;;
    c) body+="$(k function_definition "has: {kind: function_declarator, $(fld declarator "$R")}")"$'\n' ;;
    cpp) body+="$(k function_definition "has: {kind: function_declarator, $(fld declarator "$RQ")}")"$'\n' ;;
    csharp) for kind in method_declaration property_declaration class_declaration; do body+="$(k $kind "$(fld name "$R")")"$'\n'; done ;;
    ruby) for kind in method singleton_method class; do body+="$(k $kind "$(fld name "$R")")"$'\n'; done ;;
    php) for kind in function_definition method_declaration class_declaration; do body+="$(k $kind "$(fld name "$R")")"$'\n'; done ;;
    lua) body+="$(k function_declaration "$(fld name "$RQ")")"$'\n' ;;
    bash) body+="$(k function_definition "$(fld name "$R")")"$'\n' ;;
  esac
  rules+="${rules:+---$'\n'}id: def_$lang"$'\n'"language: $lang"$'\n'"severity: hint"$'\n'"rule:"$'\n'"  any:"$'\n'"$body"
done

: > "$tmp/ast.json"
if [ -n "$rules" ] && [ -s "$tmp/files.ast" ]; then
  rc=0
  xargs -r -d '\n' -a "$tmp/files.ast" ast-grep scan --inline-rules "$rules" --json=stream > "$tmp/ast.json" 2> "$tmp/ast.err" || rc=$?
  if [ "$rc" -ne 0 ]; then echo "ast-grep failed: $(head -1 "$tmp/ast.err")" >&2; exit 2; fi
fi
# range.start.line is 0-based. A class and its constructor (Java) or the overloads of one function
# share file+name: one DEF per (file, matched name), the first line wins.
jq -r '[(.metaVariables.single.NAME.text // ""), .file, (.range.start.line + 1), (.text | split("\n")[0])] | @tsv' "$tmp/ast.json" \
  | awk -F'\t' -v OFS='\t' '
      { q = $1; b = q; sub(/.*[.:]/, "", b); s = $4
        gsub(/\\t/, " ", s); gsub(/[ \t]+/, " ", s); sub(/^ /, "", s); sub(/ $/, "", s)
        sub(/^async function /, "async ", s); sub(/^async def /, "async ", s)
        while (sub(/^(export default |export |pub\([^)]*\) |pub |public |private |protected |internal |static |inline |declare |abstract |override |final |open |local |function |def |fn |func |fun )/, "", s)) {}
        if (s ~ / => ?\{?$/ && match(s, /^[A-Za-z_$][A-Za-z0-9_$]* = (async )?\(/)) {
          name = s; sub(/ = .*/, "", name); rest = substr(s, length(name) + 4); a = ""
          if (rest ~ /^async /) { a = "async "; rest = substr(rest, 7) }
          s = a name rest }
        sub(/\) ?\{.*\}$/, ")", s)
        while (sub(/ ?(\{|=>|:|=|;)$/, "", s)) {}
        if (length(s) > 90) s = substr(s, 1, 87) "..."
        print b, $2, $3, s, q }' \
  | sort -t$'\t' -k2,2 -k5,5 -k3,3n | awk -F'\t' '!seen[$2 FS $5]++' > "$tmp/defs.tsv"

# ---------- helpers for the per-item stages ----------
rank_paths() {
  awk '{ s = 0
         if ($0 ~ /(^|\/)(utils|lib|helpers|hooks|shared|services)(\/|$)/) s += 2
         if ($0 ~ /legacy|deprecated|__mocks__|old/) s -= 2
         print s "\t" length($0) "\t" $0 }' | sort -t$'\t' -k1,1nr -k2,2n -k3,3 | cut -f3
}
first_def_line() {
  local h
  h="$(rg -n -m1 -e '^\s*(export|pub|def|fn|func|fun|public|function|class|module|local function|struct|impl|CREATE)\b' "$1" 2>/dev/null || true)"
  [ -n "$h" ] || h="1:$(head -1 "$1")"
  printf '%s' "$h"
}
use_lines() { # $1 name, $2 comma list of defining files → path<TAB>line<TAB>text
  # imports, the defining files, and files outside the defining languages' family are dropped
  # (a TS `id.trim()` must not count as a use of a bash `trim`); the NAME funnel and analogs
  # stay cross-language on purpose.
  xargs -r -d '\n' -a "$tmp/files.code" rg -n -w -F -H --no-heading -e "$1" > "$tmp/hits" 2>/dev/null || true
  awk -v deffiles="$2" '
    NR == FNR { i = index($0, "\t"); fam[substr($0, 1, i - 1)] = substr($0, i + 1); next }
    FNR == 1 { n = split(deffiles, d, ","); for (i = 1; i <= n; i++) { skip[d[i]] = 1; allowed[fam[d[i]]] = 1 } }
    { if (!match($0, /^[^:]+:[0-9]+:/)) next
      p = $0; sub(/:.*/, "", p); rest = substr($0, length(p) + 2); ln = rest; sub(/:.*/, "", ln); txt = substr(rest, length(ln) + 2)
      if (p in skip) next
      if (!(fam[p] in allowed)) next
      if (txt ~ /^[ \t]*(import|from|use)[ \t{(]/) next
      if (txt ~ /^[ \t]*export[ \t]*(\{|\*|type[ \t]*\{)/) next
      if (txt ~ /^[ \t]*(const|let|var)[ \t].*=[ \t]*require\(/) next
      print p "\t" ln "\t" txt }' "$tmp/family" "$tmp/hits" | sort -t$'\t' -k1,1 -k2,2n
}
import_specs() { # $1 importer file, $2 name → module specifiers through which the file imports the name
  awk -v name="$2" '
    BEGIN { inimp = 0; buf = ""; w = "[^A-Za-z0-9_$]" }
    { line = $0
      if (!inimp && (line ~ /^[ \t]*import[ \t]/ || line ~ /^[ \t]*export[ \t]*(\{|\*|type[ \t]*\{)/)) { inimp = 1; buf = "" }
      if (inimp) {
        buf = buf " " line
        if (line ~ /from[ \t]*["\x27][^"\x27]+["\x27]/ || line ~ /^[ \t]*import[ \t]+["\x27][^"\x27]+["\x27]/ || line ~ /;[ \t]*$/) {
          inimp = 0
          if (buf ~ (w name w) && match(buf, /from[ \t]*["\x27][^"\x27]+["\x27]/)) { s = substr(buf, RSTART, RLENGTH); gsub(/^from[ \t]*["\x27]|["\x27]$/, "", s); print s }
        }
        next
      }
      if (line ~ /^[ \t]*from[ \t]+[A-Za-z0-9_.]+[ \t]+import[ \t]/ && line ~ ("(^|[^A-Za-z0-9_])" name "([^A-Za-z0-9_]|$)")) { s = line; sub(/^[ \t]*from[ \t]+/, "", s); sub(/[ \t]+import.*/, "", s); print s; next }
      if (line ~ /^[ \t]*use[ \t]+[A-Za-z0-9_:]+/ && line ~ ("(^|[^A-Za-z0-9_])" name "([^A-Za-z0-9_]|$)")) { s = line; sub(/^[ \t]*use[ \t]+/, "", s); sub(/::\{.*/, "", s); sub(/::[A-Za-z0-9_]+;?[ \t]*$/, "", s); sub(/;.*/, "", s); print s; next }
      if (match(line, /require\([ \t]*["\x27][^"\x27]+["\x27][ \t]*\)/) && line ~ (w name w)) { s = substr(line, RSTART, RLENGTH); gsub(/^require\([ \t]*["\x27]|["\x27][ \t]*\)$/, "", s); print s }
    }' "$1" | sort -u
}
resolve_spec() { # $1 importer, $2 specifier → repo-relative module path without extension ("" when external)
  local importer="$1" spec="$2" p dots rest up="" i
  case "$spec" in
    ./*|../*) p="$(realpath -m --relative-to=. "$(dirname "$importer")/$spec")" ;;
    @/*) p="${spec#@/}" ;;
    "~/"*) p="${spec#\~/}" ;;
    *::*) p="${spec//:://}"; p="${p#crate/}"; p="${p#self/}"; p="${p#super/}" ;;
    .*) dots="${spec%%[!.]*}"; rest="${spec#"$dots"}"
        for ((i = 1; i < ${#dots}; i++)); do up+="../"; done
        p="$(realpath -m --relative-to=. "$(dirname "$importer")/${up}${rest//.//}")" ;;
    */*) p="$spec" ;;
    *) p="${spec//.//}" ;;
  esac
  p="${p%/}"
  for ext in ts tsx js jsx mjs cjs py; do p="${p%.$ext}"; done
  printf '%s' "${p%/index}"
}
def_matches() { # $1 resolved module path, $2 definition file
  local p="$1" d="${2%.*}"
  [ -n "$p" ] || return 1
  [ "${d##*/}" = index ] && d="${d%/index}"
  [ "$d" = "$p" ] || [[ "$d" == */"$p" ]]
}
stems_of() { # $1 names csv, $2 behaviour text → one stem per line
  { tr ',' '\n' <<<"$1" | sed -E 's/([a-z0-9])([A-Z])/\1 \2/g; s/([A-Z]+)([A-Z][a-z])/\1 \2/g'; printf '%s\n' "$2"; } \
    | tr 'A-Z' 'a-z' | tr -c 'a-z0-9\n' ' ' | tr ' ' '\n' \
    | awk 'BEGIN { n = split("the and for with from into that this whether tell get set has have are was were will can should would could not any all one two given when where which who what how its their there then than also just only some such via per each using use used uses onto out about after before between over under around against string number value values return returns returning function util utils helper helpers hook hooks component components service services type types data object list array item items new old like make makes does doing done exists exist existing already current currently directly inside within without while every same other another", w, " "); for (i = 1; i <= n; i++) stop[w[i]] = 1 }
           length($0) >= 3 && $0 ~ /[a-z]/ && !($0 in stop) && !seen[$0]++'
}

# ---------- per item ----------
for i in "${!ids[@]}"; do
  id="${ids[$i]}" nm="${names[$i]}" text="${texts[$i]}" ure="${regexes[$i]}" want_callers="${callers[$i]}"
  echo "# $id names=${nm:--}"
  if [ -n "${errors[$i]}" ]; then echo "STATE ERROR ${errors[$i]}"; continue; fi
  item_alt="$(tr ',' '\n' <<<"$nm" | while IFS= read -r n; do esc_re "$n"; echo; done | paste -sd'|')"
  awk -F'\t' -v re="^($item_alt)\$" '$1 ~ re' "$tmp/defs.tsv" > "$tmp/item_defs"
  awk -F'\t' -v re="(^|,)($item_alt)(,|\$)" -v pre="(^|/)($(tr 'A-Z' 'a-z' <<<"$item_alt"))[.]" '$3 ~ re || tolower($1) ~ pre' "$tmp/intel" | first 5 \
    | awk -F'\t' '{ print "INTEL " $1 " " $2 " exports=" $3 }'
  ndef="$(wc -l < "$tmp/item_defs")"
  : > "$tmp/all_uses"; : > "$tmp/def_out"; unattributed=0

  if [ "$ndef" -gt 0 ]; then
    for name in $(cut -f1 "$tmp/item_defs" | sort -u); do
      awk -F'\t' -v n="$name" '$1 == n' "$tmp/item_defs" > "$tmp/name_defs"
      deffiles="$(cut -f2 "$tmp/name_defs" | sort -u | paste -sd,)"
      use_lines "$name" "$deffiles" > "$tmp/uses"
      cat "$tmp/uses" >> "$tmp/all_uses"
      if [ "$(wc -l < "$tmp/name_defs")" -eq 1 ]; then
        awk -F'\t' -v u="$(wc -l < "$tmp/uses")" '{ print u "\t" $2 "\t" $3 "\t" $4 }' "$tmp/name_defs" >> "$tmp/def_out"
      else
        declare -A count=()
        while IFS= read -r p; do
          n_in_file="$(awk -F'\t' -v p="$p" '$1 == p' "$tmp/uses" | wc -l)"
          matched=""
          while IFS= read -r spec; do
            [ -n "$spec" ] || continue
            resolved="$(resolve_spec "$p" "$spec")"
            while IFS=$'\t' read -r _ dfile _; do
              if def_matches "$resolved" "$dfile"; then matched="$dfile"; break; fi
            done < "$tmp/name_defs"
            [ -n "$matched" ] && break
          done < <(import_specs "$p" "$name")
          if [ -n "$matched" ]; then count["$matched"]=$(( ${count["$matched"]:-0} + n_in_file )); else unattributed=$(( unattributed + n_in_file )); fi
        done < <(cut -f1 "$tmp/uses" | sort -u)
        while IFS=$'\t' read -r _ dfile dline dsig _; do
          printf '%s\t%s\t%s\t%s\n' "${count[$dfile]:-0}" "$dfile" "$dline" "$dsig" >> "$tmp/def_out"
        done < "$tmp/name_defs"
        unset count
      fi
    done
    sort -t$'\t' -k1,1nr -k2,2 -k3,3n "$tmp/def_out" | awk -F'\t' '{ print "DEF " $2 ":" $3 " " $4 " uses=" $1 " via=ast" }'
  fi

  # generic funnel: everything when nothing is defined, otherwise only extensions without ast coverage
  nname=0; : > "$tmp/gen_files"
  if [ "$ndef" -eq 0 ]; then list="$tmp/files.code"; else list="$tmp/files.generic"; fi
  if [ -s "$list" ]; then
    args=(); while IFS= read -r n; do args+=(-e "$n"); done < <(tr ',' '\n' <<<"$nm")
    xargs -r -d '\n' -a "$list" rg -l -w -F "${args[@]}" 2>/dev/null | sort -u > "$tmp/gen_files" || true
    while IFS= read -r p; do
      hit="$(rg -n -w -F -m1 "${args[@]}" "$p" 2>/dev/null || true)"
      [ -n "$hit" ] || continue
      printf 'NAME %s:%s %s via=generic\n' "$p" "${hit%%:*}" "$(clip "${hit#*:}")"
      nname=$((nname + 1))
    done < <(rank_paths < "$tmp/gen_files" | first 3)
  fi

  # stems and analogs: only worth printing when nothing is defined
  if [ "$ndef" -eq 0 ]; then
    stems="$(stems_of "$nm" "$text" | sort | paste -sd'|')"
    pattern="$stems"
    [ "$ure" != "-" ] && pattern="${pattern:+$pattern|}($ure)"
    : > "$tmp/analogs"
    if [ -n "$pattern" ]; then
      xargs -r -d '\n' -a "$tmp/files.code" rg -i -o -m 20 -H --no-heading --no-line-number -e "($pattern)" 2>/dev/null > "$tmp/stem_hits" || true
      awk -v stems="$stems" '
        BEGIN { n = split(stems, s, "|"); for (i = 1; i <= n; i++) st[s[i]] = 1 }
        { if (!match($0, /^[^:]+:/)) next
          p = substr($0, 1, RLENGTH - 1); m = tolower(substr($0, RLENGTH + 1))
          print p "\t" ((m in st) ? m : "~") }' "$tmp/stem_hits" | sort -u \
        | awk -F'\t' '
            $1 != prev { if (prev != "") print cnt "\t" prev "\t" h; prev = $1; cnt = 0; h = "" }
            { cnt++; h = (h == "") ? $2 : h "," $2 }
            END { if (prev != "") print cnt "\t" prev "\t" h }' \
        | awk -F'\t' '{ h = 0
            if ($2 ~ /(^|\/)(utils|lib|helpers|hooks|shared|services)(\/|$)/) h = 1
            if ($2 ~ /legacy|deprecated|__mocks__|old/) h = -1
            print $1 "\t" h "\t" length($2) "\t" $2 "\t" $3 }' \
        | sort -t$'\t' -k1,1nr -k2,2nr -k3,3n -k4,4 | first 3 > "$tmp/analogs"
    fi
    home=""
    while IFS=$'\t' read -r score _ _ p hits; do
      grep -qxF -- "$p" "$tmp/gen_files" 2>/dev/null && continue
      d="$(first_def_line "$p")"
      printf 'ANALOG %s:%s %s stems=%s score=%s\n' "$p" "${d%%:*}" "$(clip "${d#*:}")" "$hits" "$score"
      [ -n "$home" ] || home="$(dirname "$p")"
    done < "$tmp/analogs"
    if [ -z "$home" ]; then
      home="$(for d in src/utils src/lib src/helpers src/hooks src/services; do printf '%s\t%s\n' "$(grep -c "^$d/" "$tmp/files" || true)" "$d"; done | awk -F'\t' '$1 > 0' | sort -t$'\t' -k1,1nr -k2,2 | first 1 | cut -f2)"
      [ -n "$home" ] || { grep -q '^src/' "$tmp/files" && home=src || home=.; }
    fi
    echo "HOME $home"
  fi

  [ "$unattributed" -gt 0 ] && echo "UNATTRIBUTED $unattributed"
  if [ "$want_callers" = yes ] && [ -s "$tmp/all_uses" ]; then
    total="$(wc -l < "$tmp/all_uses")"
    shown="$(sort -t$'\t' -k1,1 -k2,2n "$tmp/all_uses" | first 8 | awk -F'\t' '{ printf "%s%s:%s", (NR > 1 ? ", " : ""), $1, $2 }')"
    if [ "$total" -gt 8 ]; then echo "CALLERS $shown +$((total - 8)) more"; else echo "CALLERS $shown"; fi
  fi

  if [ "$ndef" -ge 2 ]; then state=DUPLICATE
  elif [ "$ndef" -eq 1 ]; then state=FOUND
  elif [ "$nname" -gt 0 ]; then state=NAME_ONLY
  else state=NOT_FOUND; fi
  echo "STATE $state"
done
