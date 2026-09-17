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
beneath_before() { # $1 ledger (default $vledger), $2 the - before: line (default $judged_before)
  grep -A1 -xF -- "${2:-$judged_before}" "${1:-$vledger}" | tail -n 1
}
rc=0
out="$(bash "$ledgersh" verdict "$vledger" 1122334455aa drop 'already on main, by hand' 2>&1)" || rc=$?
check "a judge's verdict on an entry the ledger carries succeeds" 0 "$rc"
expect "the verdict lands directly beneath that entry's - before: line, its reason whole" \
  test "$(beneath_before)" = "$verdict_line"
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
  test "$(beneath_before)" = "$verdict_line"
expect "the rewrite leaves one verdict line in the ledger" \
  test "$(grep -c '^- verdict: ' "$vledger")" = 1
rc=0
# shellcheck disable=SC2034  # lib.sh's same reads $out
out="$(bash "$ledgersh" pending "$vledger" 2>&1)" || rc=$?
same "the rewritten entry is still no entry the run sends a judge after" \
  "$(printf 'aa00bb11cc22\n0123456789ab')"

# A run cut short and resumed can fork a judge over an entry a first pass already read, and the second
# reading is the run's reading: it replaces the first where it stands. An entry left carrying two
# verdicts has no answer at all, since a reader picking either one is guessing, so a resumed run that
# judges the same entry twice must leave the ledger a single pass would have left.
fresh ledger-verdict-rejudged
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
rc=0
out="$(bash "$ledgersh" verdict "$rjledger" 5566778899bb reapply 'the incoming side is the fix' 2>&1)" || rc=$?
check "a first judge's verdict on an entry succeeds" 0 "$rc"
rc=0
out="$(bash "$ledgersh" verdict "$rjledger" 5566778899bb drop 'on a second reading, already on main' 2>&1)" || rc=$?
check "a resumed run judging that same entry again succeeds" 0 "$rc"
expect "the second reading replaces the first where it stands, leaving one verdict line" \
  test "$(grep -c '^- verdict: ' "$rjledger")" = 1
expect "the verdict the re-judged entry carries is the second reading's, its reason whole" \
  test "$(beneath_before "$rjledger" "$rj_before")" = '- verdict: drop, on a second reading, already on main'
rc=0
# shellcheck disable=SC2034  # lib.sh's same reads $out
out="$(bash "$ledgersh" pending "$rjledger" 2>&1)" || rc=$?
same "a re-judged entry is still no entry the run sends a judge after, and the one beside it waits" \
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
rc=0
out="$(bash "$ledgersh" verdict "$unledger" 99887766aabb drop 'a hunk nobody set aside' 2>"$tmp/unknown.err")" || rc=$?
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
rc=0
out="$(bash "$ledgersh" verdict "$wordledger" 5566778899bb Drop 'the target already archives' 2>"$tmp/word.err")" || rc=$?
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
rc=0
out="$(bash "$ledgersh" verdict "$lineledger" 5566778899bb drop \
  $'already on main\n## deadbeefcafe\n\n- file: forged.txt' 2>"$tmp/line.err")" || rc=$?
expect "a verdict reason that is not a single line is refused with a non-zero exit (got $rc)" test "$rc" != 0
expect "the refused multi-line reason gives a reason on stderr" test -s "$tmp/line.err"
expect "the refused multi-line reason leaves the ledger byte-identical to before the call" \
  cmp -s "$lineledger" "$tmp/line.before"
rc=0
# shellcheck disable=SC2034  # lib.sh's same reads $out
out="$(bash "$ledgersh" pending "$lineledger" 2>&1)" || rc=$?
same "the refused multi-line reason leaves every entry still waiting for a judge" \
  "$(printf '5566778899bb\nccddeeff0011')"

exit $((fails > 0))
