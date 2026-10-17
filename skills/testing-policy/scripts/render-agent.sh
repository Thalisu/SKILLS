#!/usr/bin/env bash
# render-agent.sh: render an agent or skill template for installation.
#
# Usage: render-agent.sh <unit|e2e> [--core-only] [--model <m>] [--effort <e>]
#        render-agent.sh test-author <native|consumer|mixed|unit>
#   unit         AGENT-UNIT.md        → .claude/agents/unit-test-author.md
#   e2e          AGENT-E2E.md         → .claude/agents/e2e-test-author.md
#   test-author  SKILL-TEST-AUTHOR.md → .claude/skills/test-author/SKILL.md, for the policy's surface
#   --core-only  print only the core-start..core-end block (what a refresh replaces); agents only
#   --model, --effort  the author's tier, written into the agent's frontmatter; agents only
#
# Drops the TEMPLATE comment, substitutes {{VERSION}} (read from POLICY.md via render-policy.sh
# --version), squeezes blank runs. Every other {{slot}} is left for the install to fill. Blocks
# tagged "<!-- @a,b -->" ... "<!-- @/ -->" are emitted only when the surface is in the tag list,
# as in render-policy.sh; only the test-author template carries them.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
target="" surface="" core_only=0 model="" effort=""
while [ $# -gt 0 ]; do
  case "$1" in
    unit|e2e|test-author)
      if [ "$target" = test-author ] && [ -z "$surface" ]; then surface="$1"; else target="$1"; fi
      shift ;;
    native|consumer|mixed) [ "$target" = test-author ] || { echo "a surface goes after test-author" >&2; exit 2; }
      surface="$1"; shift ;;
    --core-only) core_only=1; shift ;;
    --model) model="${2:-}"; shift 2 ;;
    --effort) effort="${2:-}"; shift 2 ;;
    -h|--help) sed -n '2,15p' "$0"; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done
[ -n "$target" ] || { echo "usage: render-agent.sh <unit|e2e> [--core-only] | test-author <surface>" >&2; exit 2; }
case "$target" in
  unit) template="$here/../AGENT-UNIT.md" ;;
  e2e) template="$here/../AGENT-E2E.md" ;;
  test-author) template="$here/../SKILL-TEST-AUTHOR.md"
    [ "$core_only" = 0 ] || { echo "test-author has no core block" >&2; exit 2; }
    [ -n "$surface" ] || { echo "test-author needs the policy's surface: native|consumer|mixed|unit" >&2; exit 2; } ;;
esac
[ -f "$template" ] || { echo "template not found: $template" >&2; exit 2; }
# The values Claude Code accepts in an agent's frontmatter; omitting `effort:` inherits the session's.
case "$model" in ""|sonnet|opus|haiku|fable|inherit) ;; *) echo "unknown model: $model (sonnet|opus|haiku|fable|inherit)" >&2; exit 2 ;; esac
case "$effort" in ""|low|medium|high|xhigh|max) ;; *) echo "unknown effort: $effort (low|medium|high|xhigh|max)" >&2; exit 2 ;; esac
version="$(bash "$here/render-policy.sh" --version)"

awk -v version="$version" -v surface="$surface" -v core_only="$core_only" -v model="$model" -v effort="$effort" '
  BEGIN { intpl = 0; incore = 0; fm = 0; emit = 1 }
  /^<!-- @\/ -->$/ { emit = 1; next }
  /^<!-- @[a-z,]+ -->$/ {
    s = $0; sub(/^<!-- @/, "", s); sub(/ -->$/, "", s)
    n = split(s, tags, ","); emit = 0
    for (i = 1; i <= n; i++) if (tags[i] == surface) emit = 1
    next
  }
  !emit { next }
  !core_only && fm < 2 && /^---$/ {
    if (++fm == 2) { if (model != "") print "model: " model; if (effort != "") print "effort: " effort }
    print; next
  }
  /^<!-- TEMPLATE/ { intpl = 1 }
  intpl { if ($0 ~ /-->[[:space:]]*$/) intpl = 0; next }
  {
    line = $0
    gsub(/\{\{VERSION\}\}/, version, line)
    if (core_only) {
      if (line ~ /^<!-- testing-policy:core-start -->$/) incore = 1
      if (!incore) next
      print line
      if (line ~ /^<!-- testing-policy:core-end -->$/) exit
      next
    }
    print line
  }
' "$template" | cat -s
