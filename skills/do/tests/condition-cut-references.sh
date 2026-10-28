#!/usr/bin/env bash
# condition-cut-references.sh: the text a run needs only under a condition lives in a reference of
# its own, read when that condition holds, so a run whose condition does not hold never loads it.
# The files every run opens whole keep a pointer to it in its place.
# Run: bash skills/do/tests/condition-cut-references.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
refs="$here/../references"
builder="$refs/builder.md"
fails=0

subsection() { # $1 file, $2 the heading line; the flattened subsection on stdout
  passage_of "$1" "$2" "#" 2>/dev/null | tail -n +2 | tr '\n' ' ' | tr -s ' '
}

echo "# flows.md: a Builder whose Digest names no observable criterion loads no text about the flows"

# shellcheck disable=SC2034  # lib.sh's absent reads $out
out="$(cat "$builder")"
absent "builder.md no longer holds the flows section" "## The flows"
absent "builder.md no longer decides which criteria get a flow" "Which criteria get a flow"
absent "builder.md no longer decides who authors a flow" "Who authors it"
absent "builder.md no longer reads the E2E author's report" "Reading the author's report"
flat="$(tr '\n' ' ' <"$builder" | tr -s ' ')"
carries_each "builder.md points at flows.md when the Digest's Observable criteria names a criterion" \
  "Read [flows.md](flows.md) when " -- "Observable criteria"

expect "flows.md exists" test -f "$refs/flows.md"
flat="$(subsection "$refs/flows.md" "## Which criteria get a flow")"
carries "flows.md decides which criteria get a flow from the Digest's Observable criteria" \
  "\`## Observable criteria\`" "no criterion a user can observe"
flat="$(subsection "$refs/flows.md" "## Who authors it")"
carries "flows.md decides who authors a flow from the brief's Loop: key" "\`Loop: policy\`"
# shellcheck disable=SC2034  # lib.sh's carries reads $flat
flat="$(subsection "$refs/flows.md" "## Reading the author's report")"
carries "flows.md counts the report's runs before its verdict, then routes each verdict" \
  "third run" "\`GREEN\`" "\`BLOCKED\`" "\`HANDBACK\`" "\`REFUSED_INCOMPLETE_INPUT\`"

[ "$fails" -eq 0 ]
