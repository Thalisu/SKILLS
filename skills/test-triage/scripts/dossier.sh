#!/usr/bin/env bash
# dossier.sh: deterministic operations on test-triage dossiers (docs/tests/NNNN-<slug>.md).
#
# Usage: dossier.sh [--dir DIR] <command> [args]        (DIR defaults to docs/tests)
#   next-id                                  highest NNNN prefix + 1, zero-padded; 0001 when the
#                                            directory is empty or missing
#   new <slug> --kind K --test T --signature S --repro R --veto V
#                                            create NNNN-<slug>.md from assets/dossier-template.md
#                                            with failed_at = HEAD and dates = today; prints the path.
#                                            Exit 3 when an open dossier already has that test.
#   check-visible                            report whether DIR is hidden from git: "visible: yes",
#                                            or "gitignored: <rule>" when a .gitignore rule hides it;
#                                            never edits .gitignore. Run by new before writing.
#   list-open                                one line per open dossier, oldest first:
#                                            path | test | signature | veto | occurrences | green_runs
#   bump <path> --failed-at SHA              occurrences+1, last_seen = today, failed_at = SHA;
#                                            no-op when SHA and today are already recorded
#   green <path> --sha SHA                   green_runs+1, then status: fixed + fixed_by: SHA at once,
#                                            or only at green_runs >= 2 for veto: race-condition;
#                                            no-op on a dossier that is already fixed
# Frontmatter edits rewrite single keys in place; the body is never touched. Exit 2 on misuse.
# Requires only bash, awk, sed, grep, git.
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
template="$here/../assets/dossier-template.md"
dir="docs/tests"
VETOS="schema contract race-condition multi-file uncertain assertion"

usage() { sed -n '2,22p' "$0" >&2; exit 2; }
die() { echo "dossier.sh: $*" >&2; exit 2; }

# fm_get FILE KEY: value of KEY in the frontmatter, unquoted; empty when absent
fm_get() {
  awk -v key="$2" '
    function unq(v) {
      if (v ~ /^".*"$/) { v = substr(v, 2, length(v) - 2); gsub(/\\"/, "\"", v); gsub(/\\\\/, "\\", v) }
      return v
    }
    NR == 1 { if ($0 != "---") exit; next }
    $0 == "---" { exit }
    index($0, key ":") == 1 {
      v = substr($0, length(key) + 2); sub(/^[[:space:]]+/, "", v); print unq(v); exit
    }' "$1"
}

# fm_set FILE KEY VALUE: rewrite KEY in the frontmatter; a missing key is inserted after
# failed_at (for fixed_by) or before the closing marker. Everything else is copied byte for byte.
fm_set() {
  local file="$1" tmp
  tmp="$(mktemp "${file}.XXXXXX")" || die "cannot write next to $file"
  V_KEY="$2" V_VAL="$3" awk '
    BEGIN { key = ENVIRON["V_KEY"]; val = ENVIRON["V_VAL"]; done = 0; infm = 0 }
    NR == 1 && $0 == "---" { infm = 1; print; next }
    infm && $0 == "---" {
      if (!done) { print key ": " val; done = 1 }
      infm = 0; print; next
    }
    infm && index($0, key ":") == 1 { if (!done) { print key ": " val; done = 1 } ; next }
    infm && key == "fixed_by" && index($0, "failed_at:") == 1 { print; if (!done) { print key ": " val; done = 1 }; next }
    { print }
  ' "$file" > "$tmp" && mv "$tmp" "$file"
}

# yaml_str VALUE: double-quoted YAML scalar
yaml_str() { printf '"%s"' "$(printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')"; }

is_open() { [ "$(fm_get "$1" status)" = "open" ]; }

cmd_next_id() {
  local last=0 f n
  for f in "$dir"/[0-9][0-9][0-9][0-9]-*; do
    [ -e "$f" ] || continue
    n="${f##*/}"
    n=$((10#${n:0:4}))
    [ "$n" -gt "$last" ] && last=$n
  done
  printf '%04d\n' $((last + 1))
}

cmd_list_open() {
  local f
  [ -d "$dir" ] || return 0
  for f in "$dir"/*.md; do
    [ -f "$f" ] || continue
    is_open "$f" || continue
    printf '%s | %s | %s | %s | %s | %s\n' "$f" \
      "$(fm_get "$f" test | tr '|' '/')" "$(fm_get "$f" signature | tr '|' '/')" \
      "$(fm_get "$f" veto)" "$(fm_get "$f" occurrences)" "$(fm_get "$f" green_runs)"
  done
}

# The dossiers and runner.json are this repo's own record of its test failures, meant to be committed:
# whoever clones it inherits the investigation instead of re-running the triage on their machine. A
# .gitignore rule hiding them is a defect, reported here and never fixed, because editing .gitignore is
# the user's call. The probe uses a phantom path inside DIR, so it holds before the directory exists,
# whatever pattern form covers it; `check-ignore -v` names the rule.
cmd_check_visible() {
  local v
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "not a git repository"; return 0; }
  if v="$(git check-ignore -v -- "$dir/x" 2>/dev/null)"; then
    echo "gitignored: ${v%%$'\t'*}"
  else
    echo "visible: yes"
  fi
}

cmd_new() {
  local slug="" kind="" test="" signature="" repro="" veto="" id path today head existing
  [ $# -ge 1 ] && [ "${1#--}" = "$1" ] && { slug="$1"; shift; }
  while [ $# -gt 0 ]; do
    case "$1" in
      --kind) kind="${2:-}"; shift 2 ;;
      --test) test="${2:-}"; shift 2 ;;
      --signature) signature="${2:-}"; shift 2 ;;
      --repro) repro="${2:-}"; shift 2 ;;
      --veto) veto="${2:-}"; shift 2 ;;
      *) die "new: unknown argument: $1" ;;
    esac
  done
  printf '%s' "$slug" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$' || die "new: slug must be kebab-case: '$slug'"
  [ "${#slug}" -le 60 ] || die "new: slug longer than 60 characters"
  case "$kind" in unit|e2e) ;; *) die "new: --kind must be unit or e2e" ;; esac
  [ -n "$test" ] && [ -n "$signature" ] && [ -n "$repro" ] || die "new: --test, --signature and --repro are required"
  printf ' %s ' "$VETOS" | grep -q " $veto " || die "new: --veto must be one of: $VETOS"
  [ -f "$template" ] || die "template missing: $template"
  existing="$(cmd_list_open | awk -F' \\| ' -v t="$(printf '%s' "$test" | tr '|' '/')" '$2 == t { print $1; exit }')"
  [ -z "$existing" ] || { echo "exists: $existing"; exit 3; }
  cmd_check_visible
  id="$(cmd_next_id)"
  path="$dir/$id-$slug.md"
  today="$(date +%F)"
  head="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
  mkdir -p "$dir" || die "cannot create $dir"
  V_KIND="$kind" V_TEST="$(yaml_str "$test")" V_SIG="$(yaml_str "$signature")" V_REPRO="$(yaml_str "$repro")" \
  V_HEAD="$head" V_VETO="$veto" V_TODAY="$today" awk '
    function rep(s, ph, val,   i, out) {
      out = ""
      while ((i = index(s, ph)) > 0) { out = out substr(s, 1, i - 1) val; s = substr(s, i + length(ph)) }
      return out s
    }
    {
      s = $0
      s = rep(s, "{{kind}}", ENVIRON["V_KIND"]); s = rep(s, "{{test}}", ENVIRON["V_TEST"])
      s = rep(s, "{{signature}}", ENVIRON["V_SIG"]); s = rep(s, "{{repro}}", ENVIRON["V_REPRO"])
      s = rep(s, "{{failed_at}}", ENVIRON["V_HEAD"]); s = rep(s, "{{veto}}", ENVIRON["V_VETO"])
      s = rep(s, "{{today}}", ENVIRON["V_TODAY"])
      print s
    }' "$template" > "$path" || die "cannot write $path"
  echo "$path"
}

cmd_bump() {
  local path="" sha="" today occ
  while [ $# -gt 0 ]; do
    case "$1" in
      --failed-at) sha="${2:-}"; shift 2 ;;
      --*) die "bump: unknown argument: $1" ;;
      *) path="$1"; shift ;;
    esac
  done
  [ -n "$path" ] && [ -f "$path" ] || die "bump: dossier not found: '$path'"
  [ -n "$sha" ] || die "bump: --failed-at SHA is required"
  is_open "$path" || { echo "not open: $path"; exit 2; }
  today="$(date +%F)"
  if [ "$(fm_get "$path" failed_at)" = "$sha" ] && [ "$(fm_get "$path" last_seen)" = "$today" ]; then
    echo "unchanged: $path"; return 0
  fi
  occ="$(fm_get "$path" occurrences)"; occ=$(( ${occ:-0} + 1 ))
  fm_set "$path" occurrences "$occ"
  fm_set "$path" last_seen "$today"
  fm_set "$path" failed_at "$sha"
  echo "bumped: $path occurrences=$occ"
}

cmd_green() {
  local path="" sha="" runs veto
  while [ $# -gt 0 ]; do
    case "$1" in
      --sha) sha="${2:-}"; shift 2 ;;
      --*) die "green: unknown argument: $1" ;;
      *) path="$1"; shift ;;
    esac
  done
  [ -n "$path" ] && [ -f "$path" ] || die "green: dossier not found: '$path'"
  [ -n "$sha" ] || die "green: --sha SHA is required"
  is_open "$path" || { echo "already fixed: $path"; return 0; }
  runs="$(fm_get "$path" green_runs)"; runs=$(( ${runs:-0} + 1 ))
  veto="$(fm_get "$path" veto)"
  fm_set "$path" green_runs "$runs"
  if [ "$veto" = "race-condition" ] && [ "$runs" -lt 2 ]; then
    echo "green_runs=$runs (still open): $path"; return 0
  fi
  fm_set "$path" status fixed
  fm_set "$path" fixed_by "$sha"
  echo "fixed: $path"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dir) dir="${2:?--dir needs a directory}"; shift 2 ;;
    -h|--help) sed -n '2,22p' "$0"; exit 0 ;;
    *) break ;;
  esac
done
[ $# -ge 1 ] || usage
cmd="$1"; shift
case "$cmd" in
  next-id) cmd_next_id ;;
  new) cmd_new "$@" ;;
  check-visible) cmd_check_visible ;;
  list-open) cmd_list_open ;;
  bump) cmd_bump "$@" ;;
  green) cmd_green "$@" ;;
  *) usage ;;
esac
