#!/usr/bin/env bash
# fixed-load.sh: the contract of scripts/estimate-load.sh, the estimator of a do run's fixed load,
# exercised against a scaffolded skill and project of known sizes.
# Run: bash skills/do/tests/fixed-load.sh
# shellcheck disable=SC2016
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
repo="$(cd "$here/../../.." && pwd -P)"
fails=0
# The estimator runs against a scaffolded skill and project whose files have known sizes, so every
# term it prints is a number this script can state: 4000 bytes is 1000 tokens.
estimator="$repo/skills/do/scripts/estimate-load.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
skill="$tmp/skills/do"
mkdir -p "$skill/scripts" "$skill/references" "$tmp/.agents/formats" "$tmp/docs/adr" "$tmp/t"
cp "$estimator" "$skill/scripts/" 2>/dev/null
mk() { head -c "$2" /dev/zero | tr '\0' a >"$1"; }
for f in "$skill/SKILL.md" "$skill/references/ticket.md" "$skill/references/mechanics.md" \
  "$skill/references/build-loop.md" "$skill/references/forks.md" "$skill/references/conflict-loop.md" \
  "$skill/references/reply.md" "$skill/references/digest.md" "$skill/references/plan.md" \
  "$skill/references/builder.md" "$tmp/.agents/formats/ticket-format.md"; do
  mk "$f" 4000
done
mk "$tmp/docs/adr/0001-x.md" 10
mk "$tmp/CONTEXT.md" 3990
est() { # runs the scaffolded estimator from the fixture's root; sets out, err and code
  out="$(cd "$tmp" && bash "$skill/scripts/estimate-load.sh" "$@" 2>"$tmp/t/err")"
  code=$?
  err="$(cat "$tmp/t/err")"
}
is() { [ "$1" = "$2" ]; }
out_has() { printf '%s\n' "$out" | grep -qxF -- "$1"; }
err_has() { printf '%s\n' "$err" | grep -qF -- "$1"; }

est
expect "with no argument the estimator exits zero" is "$code" 0
expect "with no argument it prints the fixed load by term, in order, then the total" is "$out" \
  "$(printf '%s\n' baseline=32000 reference_chain=9000 door=5000 ground=7500 shape=1000 total=46000)"

ticket() { # $1 path, $2 criteria: a Ticket in the format, padded to 4000 bytes
  {
    printf '# 01: A slice\n\n**What to build:** A slice.\n\n**Blocked by:** None\n\n'
    printf '**Status:** ready-for-agent\n\n'
    for _ in $(seq "$2"); do printf -- '- [ ] A criterion.\n'; done
    printf '\n## Evidence\n'
  } >"$1"
  local size
  size="$(wc -c <"$1")"
  head -c $((4000 - size - 1)) /dev/zero | tr '\0' a >>"$1"
  echo >>"$1"
}
fixed="$(printf '%s\n' baseline=32000 reference_chain=9000 door=5000 ground=7500 shape=1000 total=46000)"
ticket "$tmp/t/01-small.md" 2
est t/01-small.md
expect "given a Ticket the estimator exits zero" is "$code" 0
expect "given a Ticket it adds the criteria, the per-criterion term, the peak and the band" is "$out" \
  "$fixed"$'\n'"$(printf '%s\n' criteria=2 per_criterion=18000 peak=82000 band=small)"
# The session's total is what fills its window, so a Digest large enough to carry it past a threshold
# moves the band where no count of criteria does.
ticket "$tmp/t/02-medium.md" 2
mk "$tmp/t/02-medium.digest.md" 440000
est t/02-medium.md
expect "a medium Ticket reads its band and exits zero" \
  sh -c '[ "$1" = 0 ] && printf "%s\n" "$2" | grep -qx "total=153500" && printf "%s\n" "$2" | grep -qx "band=medium"' \
  _ "$code" "$out"
ticket "$tmp/t/03-large.md" 2
mk "$tmp/t/03-large.digest.md" 720000
est t/03-large.md
expect "a large Ticket reads its band and still exits zero, since the estimate gates nothing" \
  sh -c '[ "$1" = 0 ] && printf "%s\n" "$2" | grep -qx "total=223500" && printf "%s\n" "$2" | grep -qx "band=large"' \
  _ "$code" "$out"
# Two Tickets of the same size load the session alike, so the criteria they carry move no band.
ticket "$tmp/t/05-one-criterion.md" 1
est t/05-one-criterion.md
few_band="$(printf '%s\n' "$out" | grep '^band=')"
ticket "$tmp/t/06-ten-criteria.md" 10
est t/06-ten-criteria.md
many_band="$(printf '%s\n' "$out" | grep '^band=')"
expect "a Ticket's band is read from the session's total alone, so many criteria read the band of one" \
  sh -c '[ -n "$1" ] && [ "$1" = "$2" ]' _ "$few_band" "$many_band"
# The Digest beside the Ticket is the one the door reads, so its size replaces the allowance.
ticket "$tmp/t/04-digested.md" 2
mk "$tmp/t/04-digested.digest.md" 4000
est t/04-digested.md
expect "a Digest beside the Ticket is counted in place of the allowance" \
  sh -c 'printf "%s\n" "$1" | grep -qx "door=3500" && printf "%s\n" "$1" | grep -qx "peak=80500"' _ "$out"

# A reading it cannot take names the term it could not read, prints no figure and exits non-zero.
refused() { # $1 the exit code, $2 the term the message must name
  [ "$code" = "$1" ] && [ -z "$out" ] && err_has "cannot read $2:"
}
printf '# Notes\n\n- [ ] Not a criterion of any Ticket.\n' >"$tmp/t/notes.md"
est t/notes.md
expect "a path that is not a Ticket names the criteria it could not read and exits 3" refused 3 criteria
est t/none.md
expect "a Ticket that is not on disk names the criteria and exits 3" refused 3 criteria
mv "$skill/references/mechanics.md" "$tmp/t/mechanics.md"
est
expect "a missing file of the reference chain names reference_chain and exits 3" \
  refused 3 reference_chain
mv "$tmp/t/mechanics.md" "$skill/references/mechanics.md"
# A ticket run's fork steps and its integration step each read a reference of their own beside the
# shared mechanics, so each is a file of the chain too.
for f in forks conflict-loop; do
  mv "$skill/references/$f.md" "$tmp/t/$f.md"
  est
  expect "a missing references/$f.md names reference_chain and exits 3" refused 3 reference_chain
  mv "$tmp/t/$f.md" "$skill/references/$f.md"
done
# The session plans and builds through forks, so it reads the Planner's and the Builder's briefs and
# never the build loop, and the grounding and the shape are the Planner's to carry, not the session's.
term() { printf '%s\n' "$out" | sed -n "s/^$1=//p"; }
est
expect "the session's total is its baseline, its reference chain and its door only" \
  sh -c '[ "$1" = 0 ] && [ -n "$3" ] && [ "$2" = $(($3 + $4 + $5)) ]' \
  _ "$code" "$(term total)" "$(term baseline)" "$(term reference_chain)" "$(term door)"
chain_before="$(term reference_chain)"
for f in plan builder; do
  mk "$skill/references/$f.md" 8000
  est
  expect "a larger references/$f.md grows reference_chain by its size" \
    is "$(term reference_chain)" "$((chain_before + 1000))"
  mk "$skill/references/$f.md" 4000
  mv "$skill/references/$f.md" "$tmp/t/$f.md"
  est
  expect "a missing references/$f.md names reference_chain and exits 3" refused 3 reference_chain
  mv "$tmp/t/$f.md" "$skill/references/$f.md"
done
mk "$skill/references/build-loop.md" 8000
est
expect "the build loop is not in the session's reference chain" \
  sh -c '[ "$1" = 0 ] && [ "$2" = "$3" ]' _ "$code" "$(term reference_chain)" "$chain_before"
mk "$skill/references/build-loop.md" 4000
mv "$skill/references/build-loop.md" "$tmp/t/build-loop.md"
est
expect "a missing references/build-loop.md no longer refuses reference_chain" is "$code" 0
mv "$tmp/t/build-loop.md" "$skill/references/build-loop.md"
mv "$skill/references/digest.md" "$tmp/t/digest.md"
est
expect "a missing Digest brief names the door and exits 3" refused 3 door
mv "$tmp/t/digest.md" "$skill/references/digest.md"
est t/01-small.md t/02-medium.md
expect "two arguments are a usage error and exit 2" \
  sh -c '[ "$1" = 2 ] && [ -z "$2" ] && printf "%s\n" "$3" | grep -qF "usage: estimate-load.sh"' \
  _ "$code" "$out" "$err"

# A project with several contexts keeps its glossary through CONTEXT-MAP.md, and the ground step reads
# the map and the one context it names that the plan touches. Which one is not knowable without the
# Ticket, so the largest named is counted, beside the map itself.
mv "$tmp/CONTEXT.md" "$tmp/t/CONTEXT.md"
mkdir -p "$tmp/ctx/a" "$tmp/ctx/b"
mk "$tmp/ctx/a/CONTEXT.md" 8000
mk "$tmp/ctx/b/CONTEXT.md" 4000
printf '# Context map\n\n## Contexts\n\n- [A](./ctx/a/CONTEXT.md): one\n- [B](./ctx/b/CONTEXT.md): two\n' \
  >"$tmp/CONTEXT-MAP.md"
map_size="$(wc -c <"$tmp/CONTEXT-MAP.md")"
head -c $((1990 - map_size - 1)) /dev/zero | tr '\0' a >>"$tmp/CONTEXT-MAP.md"
echo >>"$tmp/CONTEXT-MAP.md"
est
expect "with CONTEXT-MAP.md the ground term counts the map and the largest context it names" \
  sh -c '[ "$1" = 0 ] && printf "%s\n" "$2" | grep -qx "ground=9000"' _ "$code" "$out"
mv "$tmp/ctx/a/CONTEXT.md" "$tmp/t/ctx-a.md"
est
expect "a context the map names that is not on disk names ground and exits 3" refused 3 ground
mv "$tmp/t/ctx-a.md" "$tmp/ctx/a/CONTEXT.md"
printf '# Context map\n' >"$tmp/CONTEXT-MAP.md"
est
expect "a map that names no context names ground and exits 3" refused 3 ground
rm -r "$tmp/CONTEXT-MAP.md" "$tmp/ctx"
mv "$tmp/t/CONTEXT.md" "$tmp/CONTEXT.md"

if [ "$fails" = 0 ]; then echo "PASS"; else
  echo "$fails failing"
  exit 1
fi
