#!/usr/bin/env bash
# render-policy.sh: render POLICY.md for one surface.
#
# Usage: render-policy.sh <native|consumer|mixed> [--core-only] [--policy FILE]
#        render-policy.sh --version [--policy FILE]
#   --core-only  print only the core-start..core-end block (what a refresh replaces)
#   --version    print the template version number and exit
#
# Blocks tagged "<!-- @a,b -->" ... "<!-- @/ -->" are emitted only when the chosen surface is in
# the tag list; the TEMPLATE comment and the version line are dropped; {{VERSION}} and {{SURFACE}}
# are substituted. A heading is always preceded by a blank line (a block boundary may swallow the
# template's own); blank runs are squeezed. Tags do not nest.
set -euo pipefail

policy="$(dirname "$0")/../POLICY.md"
surface="" core_only=0 want_version=0
while [ $# -gt 0 ]; do
  case "$1" in
    native|consumer|mixed) surface="$1"; shift ;;
    --core-only) core_only=1; shift ;;
    --version) want_version=1; shift ;;
    --policy) policy="${2:?--policy needs a file}"; shift 2 ;;
    -h|--help) sed -n '2,11p' "$0"; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done
[ -f "$policy" ] || { echo "policy template not found: $policy" >&2; exit 2; }

version="$(sed -nE 's/^<!-- testing-policy version: ([0-9]+(\.[0-9]+)*) -->$/\1/p' "$policy" | head -1)"
[ -n "$version" ] || { echo "no '<!-- testing-policy version: N -->' line in $policy" >&2; exit 2; }
if [ "$want_version" = 1 ]; then echo "$version"; exit 0; fi
[ -n "$surface" ] || { echo "usage: render-policy.sh <native|consumer|mixed> [--core-only]" >&2; exit 2; }

awk -v surface="$surface" -v version="$version" -v core_only="$core_only" '
  function out(l) {
    if (l ~ /^#+ / && last != "" && last !~ /^<!--/) print ""
    print l; last = l
  }
  BEGIN { emit = 1; intpl = 0; incore = 0; last = "" }
  /^<!-- testing-policy version: / { next }
  /^<!-- TEMPLATE/ { intpl = 1 }
  intpl { if ($0 ~ /-->[[:space:]]*$/) intpl = 0; next }
  /^<!-- @\/ -->$/ { emit = 1; next }
  /^<!-- @[a-z,]+ -->$/ {
    s = $0; sub(/^<!-- @/, "", s); sub(/ -->$/, "", s)
    n = split(s, tags, ","); emit = 0
    for (i = 1; i <= n; i++) if (tags[i] == surface) emit = 1
    next
  }
  {
    if (!emit) next
    line = $0
    gsub(/\{\{VERSION\}\}/, version, line)
    gsub(/\{\{SURFACE\}\}/, surface, line)
    if (core_only) {
      if (line ~ /^<!-- testing-policy:core-start -->$/) incore = 1
      if (!incore) next
      out(line)
      if (line ~ /^<!-- testing-policy:core-end -->$/) exit
      next
    }
    out(line)
  }
' "$policy" | cat -s
