#!/usr/bin/env bash
# ledger-judge.sh: the frontmatter contract of the judging agent at skills/do/agents/ledger-judge.md,
# the read-only fork a do session hands one Loss ledger entry to.
# Run: bash skills/do/tests/ledger-judge.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
agent="$here/../agents/ledger-judge.md"
fails=0

frontmatter() { # the YAML between the file's opening and closing `---`, on stdout
  awk 'NR == 1 && $0 != "---" { exit 1 } NR > 1 && $0 == "---" { exit } NR > 1' "$agent"
}
field() { sed -n "s/^$1: *//p" <<<"$out"; }

echo "# skills/do/agents/ledger-judge.md: a read-only judging agent the do session forks"
expect "the do skill ships a judging agent at agents/ledger-judge.md" test -f "$agent"

rc=0
out="$(frontmatter 2>/dev/null)" || rc=$?

check_lines "the judging agent's frontmatter names it ledger-judge, the name the harness dispatches on" 0 "$rc" \
  "name: ledger-judge"
check_lines "the judging agent runs on opus at high effort" 0 "$rc" \
  "model: opus" "effort: high"
check_lines "the judging agent holds reading and search alone" 0 "$rc" \
  "tools: Read, Glob, Grep"

# link-skills.sh links the definition under its file name while the harness dispatches on the
# frontmatter `name`, so a disagreement leaves an agent nothing can fork.
expect "the judging agent's file name and its frontmatter name agree" \
  test "$(field name)" = "$(basename "$agent" .md)"

# ADR 0032: a fork that reads a stranger's text holds no tool that writes a file, changes one or
# runs a command, and the session that forked it writes what it returns.
tools="$(field tools)"
expect "the judging agent's tool list names no tool that writes a file, changes one or runs a command" \
  bash -c '[ -n "$1" ] && ! grep -qE "\b(Write|Edit|Bash)\b" <<<"$1"' _ "$tools"

desc="$(field description)"
expect "the judging agent's description names the do session as its only caller" \
  grep -qF "Forked only by the do skill" <<<"$desc"
expect "the judging agent's description refuses invocation on its own initiative" \
  grep -qF "Never on your own initiative." <<<"$desc"

# A `replace:`/`with:` field is by construction a multi-line rewrite (a Loss ledger entry can carry
# a function plus its appended sibling), so the return-block format needs a delimiter closing each
# one: otherwise the reader cannot tell the field's last line from the next key or the next entry's
# `<id>` line.
block_section="$(sed -n '/^Return one block per entry/,/^On a `drop`/p' "$agent")"
expect "the return-block section names a fence delimiter that closes replace and with" \
  bash -c 'grep -qi "fence" <<<"$1"' _ "$block_section"
expect "the return-block section reuses ledger.sh's fenced idiom to compute that delimiter" \
  bash -c 'grep -qF "fenced" <<<"$1"' _ "$block_section"

exit $((fails > 0))
