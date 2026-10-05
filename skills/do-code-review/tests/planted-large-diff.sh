#!/usr/bin/env bash
# planted-large-diff.sh: the fixture the planted-large-diff eval case scaffolds, laid once the way
# scripts/run-eval.sh lays it and read by every case below.
# Run: bash skills/do-code-review/tests/planted-large-diff.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
case_file="$here/../evals/planted-large-diff/case.yaml"
shards="$here/../scripts/shards.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

fixture="$tmp/fixture"
mkdir "$fixture"
yq -r '.context.scaffold_script // ""' "$case_file" >"$tmp/scaffold.sh" 2>"$tmp/extract.log"
scaffold_rc=0
(cd "$fixture" && bash "$tmp/scaffold.sh") >"$tmp/scaffold.log" 2>&1 || scaffold_rc=$?

run_shards() { # $1.. the Shard script's arguments, from the scaffolded repository: its stdout in $out, its stderr in $err, its exit in $rc
  rc=0
  out="$(cd "$fixture" && bash "$shards" "$@" 2>"$tmp/stderr")" || rc=$?
  err="$(cat "$tmp/stderr")"
}

# A sharded fan-out can only be graded on a diff the Shard script cuts: one Shard is the review
# the orchestrator already runs unsharded.
run_shards main
count="$(term shards)"
label="the scaffolded branch's diff since main is cut into more than one Shard"
if [ "$rc" = 0 ] && [[ "$count" =~ ^[0-9]+$ ]] && [ "$count" -gt 1 ]; then ok "$label"; else
  fail "$label (shards.sh exit $rc, shards=${count:-no such line}, scaffold exit $scaffold_rc)"
  echo "      extract: $(tail -1 "$tmp/extract.log")"
  echo "      scaffold: $(tail -1 "$tmp/scaffold.log")"
  echo "      shards.sh stderr: ${err//$'\n'/$'\n'      }"
  grep -E '^(shards?|budget)=' <<<"$out" | sed 's/^/      /'
fi

# A per-Shard grader can only show a Shard was read by a defect found in it, so a Shard holding no
# defect file is one nobody can grade.
shards_without_a_defect() { # the Shards of the cut in $out that hold neither defect file, on one line; `none cut` when the cut lists no Shard
  awk '
    /^shard=[0-9]+/ { id = $1; sub(/^shard=/, "", id); seen[id] = 1 }
    /^file shard=[0-9]+ tokens=[0-9]+ path=/ {
      id = $2; sub(/^shard=/, "", id); seen[id] = 1
      path = $0; sub(/^file shard=[0-9]+ tokens=[0-9]+ path=/, "", path)
      if (path == "src/locales/index.js" || path == "src/shortcodes/expand.js") planted[id] = 1
    }
    END {
      n = 0
      for (id in seen) { n++; if (!(id in planted)) bare = bare " " id }
      if (n == 0) bare = " none cut"
      print substr(bare, 2)
    }
  ' <<<"$out"
}
bare="$(shards_without_a_defect)"
label="every Shard of the cut holds a file carrying a planted defect"
if [ "$rc" = 0 ] && [ -z "$bare" ]; then ok "$label"; else
  fail "$label (shards.sh exit $rc, Shards with no defect file: ${bare:-none})"
  grep -E '^file shard=' <<<"$out" | sed 's/^/      /'
fi

# A red suite is a defect the reviewer finds by running the tests, not by reading the Shard.
suite_rc=0
(cd "$fixture" && node --test tests/*.test.js) >"$tmp/suite.log" 2>&1 || suite_rc=$?
label="the fixture's suite is green on the scaffolded branch"
if [ "$suite_rc" = 0 ]; then ok "$label"; else
  fail "$label (node --test exit $suite_rc)"
  tail -20 "$tmp/suite.log" | sed 's/^/      /'
fi

exit "$((fails > 0))"
