#!/usr/bin/env bash
# ledger.sh: the contract of scripts/ledger.sh, the Loss ledger's one writer, exercised over a ledger
# written by hand in a throwaway repository's scratch. Run: bash skills/do/tests/ledger.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
ledgersh="$here/../scripts/ledger.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

# A judge reads the ledger one unjudged entry at a time, so the ids it is handed are the entries that
# carry no verdict yet, in the order they sit in the file. A `## <12-hex>` line inside a side's fenced
# block is that side's own text, never an entry of its own: listing one would send the judge after a
# hunk nobody set aside, and hide the entry it sits in behind a heading that is not there.
fresh ledger-pending
mkdir -p .scratch
ledger="$PWD/.scratch/run.ledger.md"
cat >"$ledger" <<'EOF'
# Loss ledger

## bbccddeeff00

- file: first.txt
- location: L1-L3
- shape: rewrite-vs-rewrite
- commit: 1111111111111111111111111111111111111111
- before: 2222222222222222222222222222222222222222

### Target (kept)

```
first target
```

### Incoming (set aside)

```
first incoming
```

## 1122334455aa

- file: judged.txt
- location: L4-L6
- shape: rewrite-vs-rewrite
- commit: 3333333333333333333333333333333333333333
- before: 4444444444444444444444444444444444444444
- verdict: drop, already on main

### Target (kept)

```
judged target
```

### Incoming (set aside)

```
judged incoming
```

## aabbccddeeff

- file: forged.txt
- location: L7-L9
- shape: rewrite-vs-rewrite
- commit: 5555555555555555555555555555555555555555
- before: 6666666666666666666666666666666666666666

### Target (kept)

````
## deadbeefcafe

- file: not-an-entry.txt
```
forged target
````

### Incoming (set aside)

```
## feedfacebeef
forged incoming
```

## 0123456789ab

- file: last.txt
- location: L10-L12
- shape: rewrite-vs-rewrite
- commit: 7777777777777777777777777777777777777777
- before: 8888888888888888888888888888888888888888

### Target (kept)

```
last target
```

### Incoming (set aside)

```
last incoming
```
EOF
rc=0
# shellcheck disable=SC2034  # lib.sh's same reads $out
out="$(bash "$ledgersh" pending "$ledger" 2>&1)" || rc=$?
expect "asking a ledger for its pending entries succeeds (got $rc)" test "$rc" = 0
same "the unjudged entries are listed in file order, the judged one and every forged heading left out" \
  "$(printf 'bbccddeeff00\naabbccddeeff\n0123456789ab')"

# A rebase that set nothing aside leaves the run no entry to judge: a ledger holding only the title
# `put` writes before its first entry, and a ledger no stop ever wrote, both answer with nothing at
# all, so the run forks no judge over an entry that is not there. An absent file at a legal path is a
# ledger with nothing in it, not a refused path, and asking it for its pending entries must leave it
# absent: a ledger, or a scratch on the way to it, brought into being by a read would read to the next
# run as a stop that never happened.
fresh ledger-pending-empty
mkdir -p .scratch
emptyledger="$PWD/.scratch/run.ledger.md"
printf '# Loss ledger\n' >"$emptyledger"
rc=0
# shellcheck disable=SC2034  # lib.sh's same reads $out
out="$(bash "$ledgersh" pending "$emptyledger" 2>&1)" || rc=$?
expect "a ledger holding only its title succeeds (got $rc)" test "$rc" = 0
same "a ledger holding only its title lists no entry at all" ""

fresh ledger-pending-absent
goneledger="$PWD/.scratch/run.ledger.md"
rc=0
# shellcheck disable=SC2034  # lib.sh's same reads $out
out="$(bash "$ledgersh" pending "$goneledger" 2>&1)" || rc=$?
expect "a ledger no stop ever wrote succeeds (got $rc)" test "$rc" = 0
same "a ledger no stop ever wrote lists no entry at all" ""
expect "asking an absent ledger for its pending entries does not create it" test ! -e "$goneledger"
expect "asking an absent ledger for its pending entries does not create the scratch on the way to it" test ! -e "$PWD/.scratch"

# A ledger that exists but that this run cannot read is not a ledger with nothing in it: the read
# failed, it did not come back empty. Answering with the same rc 0 and empty stdout an empty or
# absent ledger gets is indistinguishable data loss, since a run cannot tell "nothing to judge" from
# "could not find out". A ledger present but refused must fail loud, not read as if it held nothing.
fresh ledger-pending-unreadable
mkdir -p .scratch
unreadableledger="$PWD/.scratch/run.ledger.md"
cat >"$unreadableledger" <<'EOF'
# Loss ledger

## bbccddeeff00

- file: first.txt
- location: L1-L3
- shape: rewrite-vs-rewrite
- commit: 1111111111111111111111111111111111111111
- before: 2222222222222222222222222222222222222222

### Target (kept)

```
first target
```

### Incoming (set aside)

```
first incoming
```
EOF
chmod 000 "$unreadableledger"
rc=0
# shellcheck disable=SC2034  # lib.sh's same reads $out
out="$(bash "$ledgersh" pending "$unreadableledger" 2>&1)" || rc=$?
expect "asking an unreadable ledger for its pending entries fails (got $rc)" test "$rc" != 0
expect "a ledger that could not be read says so on stderr" grep -qF "could not be read" <<<"$out"
chmod 644 "$unreadableledger"

# A judge's reading of an entry lands in the entry itself, as one `- verdict: <verdict>, <reason>`
# line right beneath the keys the stop wrote, where `put`'s carry-over rule already preserves a key
# line it does not write itself. The reason is the judge's own sentence, commas and all, and it must
# reach the ledger whole: a reason cut at its first comma reads as a different judgement. Once an
# entry is judged it drops out of `pending`, so a rerun forks no second judge over it, and a later
# `put` rewriting that same entry's sides leaves the verdict standing.
fresh ledger-verdict
mkdir -p .scratch
vledger="$PWD/.scratch/run.ledger.md"
cat >"$vledger" <<'EOF'
# Loss ledger

## aa00bb11cc22

- file: first.txt
- location: L1-L3
- shape: rewrite-vs-rewrite
- commit: 1111111111111111111111111111111111111111
- before: 2222222222222222222222222222222222222222

### Target (kept)

```
first target
```

### Incoming (set aside)

```
first incoming
```

## 1122334455aa

- file: judged.txt
- location: L4-L6
- shape: rewrite-vs-rewrite
- commit: 3333333333333333333333333333333333333333
- before: 4444444444444444444444444444444444444444

### Target (kept)

```
judged target
```

### Incoming (set aside)

```
judged incoming
```

## 0123456789ab

- file: last.txt
- location: L7-L9
- shape: rewrite-vs-rewrite
- commit: 5555555555555555555555555555555555555555
- before: 6666666666666666666666666666666666666666

### Target (kept)

```
last target
```

### Incoming (set aside)

```
last incoming
```
EOF
judged_before='- before: 4444444444444444444444444444444444444444'
verdict_line='- verdict: drop, already on main, by hand'
line_under() { # $1 ledger, $2 a whole line it carries: the line standing directly under it
  grep -A1 -xF -- "$2" "$1" | tail -n 1
}
vdentry="$tmp/verdict-dir.judged"
ledger_verdict_entry_fixture "$vdentry" 1122334455aa drop 'already on main, by hand'
rc=0
out="$(bash "$ledgersh" verdict "$vledger" "$vdentry" 2>&1)" || rc=$?
check "a judge's verdict on an entry the ledger carries succeeds" 0 "$rc"
expect "the verdict lands directly beneath that entry's - before: line, its reason whole" \
  test "$(line_under "$vledger" "$judged_before")" = "$verdict_line"
expect "judging one entry leaves one verdict line in the ledger" \
  test "$(grep -c '^- verdict: ' "$vledger")" = 1
rc=0
# shellcheck disable=SC2034  # lib.sh's same reads $out
out="$(bash "$ledgersh" pending "$vledger" 2>&1)" || rc=$?
expect "asking a judged ledger for its pending entries succeeds (got $rc)" test "$rc" = 0
same "the judged entry drops out of the pending list and the entries beside it stay" \
  "$(printf 'aa00bb11cc22\n0123456789ab')"

ventry="$tmp/verdict.entry"
ledger_entry_fixture "$ventry" 1122334455aa judged.txt L4-L6 rewrite-vs-rewrite \
  3333333333333333333333333333333333333333 4444444444444444444444444444444444444444 \
  'rewritten target' 'rewritten incoming'
rc=0
out="$(bash "$ledgersh" put "$vledger" "$ventry" 2>&1)" || rc=$?
check "a later put over a judged entry succeeds" 0 "$rc"
has "the later put rewrote that entry's sides" "$vledger" 'rewritten target' 'rewritten incoming'
expect "the verdict survives the rewrite, still directly beneath the entry's - before: line" \
  test "$(line_under "$vledger" "$judged_before")" = "$verdict_line"
expect "the rewrite leaves one verdict line in the ledger" \
  test "$(grep -c '^- verdict: ' "$vledger")" = 1
rc=0
# shellcheck disable=SC2034  # lib.sh's same reads $out
out="$(bash "$ledgersh" pending "$vledger" 2>&1)" || rc=$?
same "the rewritten entry is still no entry the run sends a judge after" \
  "$(printf 'aa00bb11cc22\n0123456789ab')"

# A run cut short and resumed can fork a judge over an entry a first pass already read. A second
# verdict call for that id has nothing left to add: the entry already carries a reading, and letting
# a second call overwrite it would mean whichever judge runs last wins silently, with no trace of the
# first reading left to audit. So a resumed run that reaches an entry it already judged is refused
# whole, and the first verdict stands exactly as it was written.
fresh ledger-verdict-already-judged
mkdir -p .scratch
rjledger="$PWD/.scratch/run.ledger.md"
cat >"$rjledger" <<'EOF'
# Loss ledger

## 5566778899bb

- file: resumed.txt
- location: L1-L3
- shape: rewrite-vs-rewrite
- commit: 1111111111111111111111111111111111111111
- before: 2222222222222222222222222222222222222222

### Target (kept)

```
resumed target
```

### Incoming (set aside)

```
resumed incoming
```

## ccddeeff0011

- file: beside.txt
- location: L4-L6
- shape: rewrite-vs-rewrite
- commit: 3333333333333333333333333333333333333333
- before: 4444444444444444444444444444444444444444

### Target (kept)

```
beside target
```

### Incoming (set aside)

```
beside incoming
```
EOF
rj_before='- before: 2222222222222222222222222222222222222222'
rjentry_first="$tmp/verdict-dir.rj-first"
ledger_verdict_entry_fixture "$rjentry_first" 5566778899bb reapply 'the incoming side is the fix'
rc=0
out="$(bash "$ledgersh" verdict "$rjledger" "$rjentry_first" 2>&1)" || rc=$?
check "a first judge's verdict on an entry succeeds" 0 "$rc"
cp "$rjledger" "$tmp/rejudged.after-first.md"
rjentry_second="$tmp/verdict-dir.rj-second"
ledger_verdict_entry_fixture "$rjentry_second" 5566778899bb drop 'on a second reading, already on main'
rc=0
out="$(bash "$ledgersh" verdict "$rjledger" "$rjentry_second" 2>"$tmp/rejudged.err")" || rc=$?
expect "a resumed run judging that same entry again is refused with a non-zero exit (got $rc)" test "$rc" != 0
expect "the refused re-judgment gives a reason on stderr" test -s "$tmp/rejudged.err"
expect "the refused re-judgment names the id the judge asked for" \
  grep -qF -- 5566778899bb "$tmp/rejudged.err"
expect "the refused re-judgment leaves the ledger byte-identical to right after the first verdict" \
  cmp -s "$rjledger" "$tmp/rejudged.after-first.md"
expect "the entry still carries only the first reading, its reason whole" \
  test "$(line_under "$rjledger" "$rj_before")" = '- verdict: reapply, the incoming side is the fix'
rc=0
# shellcheck disable=SC2034  # lib.sh's same reads $out
out="$(bash "$ledgersh" pending "$rjledger" 2>&1)" || rc=$?
same "the once-judged entry is still no entry the run sends a judge after, and the one beside it waits" \
  ccddeeff0011

# A judge naming an id no entry in the ledger carries has read something that is not this ledger, and
# a verdict written for it either lands nowhere or lands against the wrong hunk. The call is refused
# whole, so the entries a stop set aside are all still there, exactly as they were, for a judge that
# reads the ledger it was handed.
fresh ledger-verdict-unknown-id
mkdir -p .scratch
unledger="$PWD/.scratch/run.ledger.md"
cat >"$unledger" <<'EOF'
# Loss ledger

## 5566778899bb

- file: resumed.txt
- location: L1-L3
- shape: rewrite-vs-rewrite
- commit: 1111111111111111111111111111111111111111
- before: 2222222222222222222222222222222222222222

### Target (kept)

```
resumed target
```

### Incoming (set aside)

```
resumed incoming
```

## ccddeeff0011

- file: beside.txt
- location: L4-L6
- shape: rewrite-vs-rewrite
- commit: 3333333333333333333333333333333333333333
- before: 4444444444444444444444444444444444444444

### Target (kept)

```
beside target
```

### Incoming (set aside)

```
beside incoming
```
EOF
cp "$unledger" "$tmp/unknown.before"
unentry="$tmp/verdict-dir.unknown"
ledger_verdict_entry_fixture "$unentry" 99887766aabb drop 'a hunk nobody set aside'
rc=0
out="$(bash "$ledgersh" verdict "$unledger" "$unentry" 2>"$tmp/unknown.err")" || rc=$?
expect "a verdict for an id no entry carries is refused with exit 2 (got $rc)" test "$rc" = 2
expect "the refused verdict gives a reason on stderr" test -s "$tmp/unknown.err"
expect "the refused verdict names the id the judge asked for" \
  grep -qF -- 99887766aabb "$tmp/unknown.err"
expect "the refused verdict leaves the ledger byte-identical to before the call" \
  cmp -s "$unledger" "$tmp/unknown.before"
rc=0
# shellcheck disable=SC2034  # lib.sh's same reads $out
out="$(bash "$ledgersh" pending "$unledger" 2>&1)" || rc=$?
same "the refused verdict leaves every entry still waiting for a judge" \
  "$(printf '5566778899bb\nccddeeff0011')"

# A verdict word that is neither `reapply` nor `drop` is not a reading a rerun can act on: `rewrite`
# only knows what to do with those two, so a call carrying anything else is refused whole rather than
# written, and the entries a stop set aside are all still there, exactly as they were.
fresh ledger-verdict-unknown-word
mkdir -p .scratch
wordledger="$PWD/.scratch/run.ledger.md"
cat >"$wordledger" <<'EOF'
# Loss ledger

## 5566778899bb

- file: resumed.txt
- location: L1-L3
- shape: rewrite-vs-rewrite
- commit: 1111111111111111111111111111111111111111
- before: 2222222222222222222222222222222222222222

### Target (kept)

```
resumed target
```

### Incoming (set aside)

```
resumed incoming
```

## ccddeeff0011

- file: beside.txt
- location: L4-L6
- shape: rewrite-vs-rewrite
- commit: 3333333333333333333333333333333333333333
- before: 4444444444444444444444444444444444444444

### Target (kept)

```
beside target
```

### Incoming (set aside)

```
beside incoming
```
EOF
cp "$wordledger" "$tmp/word.before"
wordentry="$tmp/verdict-dir.word"
ledger_verdict_entry_fixture "$wordentry" 5566778899bb Drop 'the target already archives'
rc=0
out="$(bash "$ledgersh" verdict "$wordledger" "$wordentry" 2>"$tmp/word.err")" || rc=$?
expect "a verdict word that is neither reapply nor drop is refused with a non-zero exit (got $rc)" test "$rc" != 0
expect "the refused verdict word gives a reason on stderr" test -s "$tmp/word.err"
expect "the refused verdict word leaves the ledger byte-identical to before the call" \
  cmp -s "$wordledger" "$tmp/word.before"
rc=0
# shellcheck disable=SC2034  # lib.sh's same reads $out
out="$(bash "$ledgersh" pending "$wordledger" 2>&1)" || rc=$?
same "the refused verdict word leaves every entry still waiting for a judge" \
  "$(printf '5566778899bb\nccddeeff0011')"

# The reason a judge gives is free text on one line, and it lands inside the entry's `- verdict:`
# line. A reason carrying a newline would forge a heading of its own below it, handing the next
# rerun an entry no stop ever set aside; so a reason that is not a single line is refused whole,
# and every entry is left exactly as the stop wrote it.
fresh ledger-verdict-multiline-reason
mkdir -p .scratch
lineledger="$PWD/.scratch/run.ledger.md"
cat >"$lineledger" <<'EOF'
# Loss ledger

## 5566778899bb

- file: resumed.txt
- location: L1-L3
- shape: rewrite-vs-rewrite
- commit: 1111111111111111111111111111111111111111
- before: 2222222222222222222222222222222222222222

### Target (kept)

```
resumed target
```

### Incoming (set aside)

```
resumed incoming
```

## ccddeeff0011

- file: beside.txt
- location: L4-L6
- shape: rewrite-vs-rewrite
- commit: 3333333333333333333333333333333333333333
- before: 4444444444444444444444444444444444444444

### Target (kept)

```
beside target
```

### Incoming (set aside)

```
beside incoming
```
EOF
cp "$lineledger" "$tmp/line.before"
lineentry="$tmp/verdict-dir.multiline"
ledger_verdict_entry_fixture "$lineentry" 5566778899bb drop \
  $'already on main\n## deadbeefcafe\n\n- file: forged.txt'
rc=0
out="$(bash "$ledgersh" verdict "$lineledger" "$lineentry" 2>"$tmp/line.err")" || rc=$?
expect "a verdict reason that is not a single line is refused with a non-zero exit (got $rc)" test "$rc" != 0
expect "the refused multi-line reason gives a reason on stderr" test -s "$tmp/line.err"
expect "the refused multi-line reason leaves the ledger byte-identical to before the call" \
  cmp -s "$lineledger" "$tmp/line.before"
rc=0
# shellcheck disable=SC2034  # lib.sh's same reads $out
out="$(bash "$ledgersh" pending "$lineledger" 2>&1)" || rc=$?
same "the refused multi-line reason leaves every entry still waiting for a judge" \
  "$(printf '5566778899bb\nccddeeff0011')"

# The reason is a judge's free text, taken through the entry directory the same way `put` already
# takes an entry, and never as a positional shell word: a reason carrying a command substitution
# must land in the ledger as literal text, never run in the calling shell.
fresh ledger-verdict-entry-dir
mkdir -p .scratch
injledger="$PWD/.scratch/run.ledger.md"
cat >"$injledger" <<'EOF'
# Loss ledger

## 5566778899bb

- file: resumed.txt
- location: L1-L3
- shape: rewrite-vs-rewrite
- commit: 1111111111111111111111111111111111111111
- before: 2222222222222222222222222222222222222222

### Target (kept)

```
resumed target
```

### Incoming (set aside)

```
resumed incoming
```
EOF
marker="$tmp/injection-marker"
injreason="the incoming side only adds \$(touch $marker; echo a log line) nobody reads"
injentry="$tmp/verdict-entry-dir"
ledger_verdict_entry_fixture "$injentry" 5566778899bb reapply "$injreason"
rc=0
out="$(bash "$ledgersh" verdict "$injledger" "$injentry" 2>&1)" || rc=$?
check "a verdict taken through an entry directory succeeds" 0 "$rc"
expect "the reason's command substitution is never executed" test ! -e "$marker"
has "the ledger carries the reason text verbatim, the \$(...) left as literal text" "$injledger" \
  "- verdict: reapply, $injreason"

# An entry the judge sent back for a reapply comes back as its own commit, and the ledger is where a
# rerun reads which commit that was: one `- applied: <commit>, <reason>` line directly under the
# reading it answers, so the two lines are read as one pair however the entry moves. A reapply that
# left nothing to commit, an incoming side the rebase had already landed, still has to say so: the
# word `none` in the commit's place is a reapply accounted for, where a missing line is a reapply
# nobody can tell from one never run. Recording it touches that one line and nothing else: the keys
# the stop wrote, the reading the judge gave and both sides' text are the entry's audit trail, and a
# rerun that rewrote any of them while noting a commit would lose what the run is answering for.
fresh ledger-applied
mkdir -p .scratch
aledger="$PWD/.scratch/run.ledger.md"
cat >"$aledger" <<'EOF'
# Loss ledger

## ab12cd34ef56

- file: reapplied.txt
- location: L1-L3
- shape: rewrite-vs-rewrite
- commit: 1111111111111111111111111111111111111111
- before: 2222222222222222222222222222222222222222
- verdict: reapply, the incoming side is the fix

### Target (kept)

```
reapplied target
```

### Incoming (set aside)

```
reapplied incoming
```

## f0e1d2c3b4a5

- file: empty.txt
- location: L4-L6
- shape: rewrite-vs-rewrite
- commit: 3333333333333333333333333333333333333333
- before: 4444444444444444444444444444444444444444
- verdict: reapply, the incoming side renames the helper

### Target (kept)

```
empty target
```

### Incoming (set aside)

```
empty incoming
```
EOF
applied_fixture() { # $1 dir, $2 id, $3 commit, $4 reason: an applied directory for `ledger.sh applied`
  mkdir -p "$1" || return 1
  printf '%s\n' "$2" >"$1/id"
  printf '%s\n' "$3" >"$1/commit"
  printf '%s\n' "$4" >"$1/reason"
}
sha_verdict='- verdict: reapply, the incoming side is the fix'
none_verdict='- verdict: reapply, the incoming side renames the helper'
sha_applied='- applied: 9f8e7d6c5b4a39281706f5e4d3c2b1a09f8e7d6c, reapplied onto the rebased tip, its tests green'
none_applied='- applied: none, the rebase had already landed that side, nothing left to commit'
cp "$aledger" "$tmp/applied.before"
shadir="$tmp/applied-dir.sha"
applied_fixture "$shadir" ab12cd34ef56 9f8e7d6c5b4a39281706f5e4d3c2b1a09f8e7d6c \
  'reapplied onto the rebased tip, its tests green'
rc=0
out="$(bash "$ledgersh" applied "$aledger" "$shadir" 2>&1)" || rc=$?
check "recording the commit a reapplied entry came back as succeeds" 0 "$rc"
expect "the commit lands directly beneath that entry's - verdict: line, its reason whole" \
  test "$(line_under "$aledger" "$sha_verdict")" = "$sha_applied"
expect "recording it opens one applied line in the ledger" \
  test "$(grep -c '^- applied: ' "$aledger")" = 1
expect "recording it leaves every other line of the ledger as it stood" \
  test "$(grep -vxF -- "$sha_applied" "$aledger")" = "$(cat "$tmp/applied.before")"

cp "$aledger" "$tmp/applied.after-sha"
nonedir="$tmp/applied-dir.none"
applied_fixture "$nonedir" f0e1d2c3b4a5 none \
  'the rebase had already landed that side, nothing left to commit'
rc=0
out="$(bash "$ledgersh" applied "$aledger" "$nonedir" 2>&1)" || rc=$?
check "recording a reapply that came back as no commit at all succeeds" 0 "$rc"
expect "the word none lands beneath that entry's - verdict: line the same way a sha does" \
  test "$(line_under "$aledger" "$none_verdict")" = "$none_applied"
expect "the entry recorded first still carries its own commit, beneath its own verdict" \
  test "$(line_under "$aledger" "$sha_verdict")" = "$sha_applied"
expect "recording the second leaves every other line of the ledger as it stood" \
  test "$(grep -vxF -- "$none_applied" "$aledger")" = "$(cat "$tmp/applied.after-sha")"

exit $((fails > 0))
