#!/usr/bin/env bash
# lib.sh: the assertions and fixture builders the test scripts share. A script sources it after its
# `here=` line and sets fails=0; the assertions read the caller's $out and bump the caller's $fails.
# shellcheck disable=SC2154 # $out, $flat and $tmp belong to the sourcing script, which assigns them first.

ok() { echo "ok    $1"; }
fail() {
  echo "FAIL  $1"
  fails=$((fails + 1))
}
dump_out() { echo "      ${out//$'\n'/$'\n'      }"; }

expect() { # $1 label, $2.. a command that must succeed
  local label="$1"
  shift
  if "$@"; then ok "$label"; else fail "$label"; fi
}
check() { # $1 label, $2 expected exit, $3 actual exit, $4.. fixed strings that must appear in $out
  local label="$1" want="$2" rc="$3"
  shift 3
  local good=1 line
  [ "$rc" = "$want" ] || good=0
  for line in "$@"; do grep -qF -- "$line" <<<"$out" || good=0; done
  if [ "$good" = 1 ]; then ok "$label"; else
    fail "$label (exit $rc, wanted $want)"
    dump_out
  fi
}
check_lines() { # $1 label, $2 expected exit, $3 actual exit, $4.. whole lines that must appear in $out
  local label="$1" want="$2" rc="$3"
  shift 3
  local good=1 line
  [ "$rc" = "$want" ] || good=0
  for line in "$@"; do grep -qxF -- "$line" <<<"$out" || good=0; done
  if [ "$good" = 1 ]; then ok "$label"; else
    fail "$label (exit $rc, wanted $want)"
    dump_out
  fi
}
check_absent() { # $1 label, $2 expected exit, $3 actual exit, $4.. fixed strings that must not appear in $out
  local label="$1" want="$2" rc="$3"
  shift 3
  local good=1 line found=""
  [ "$rc" = "$want" ] || good=0
  for line in "$@"; do if grep -qF -- "$line" <<<"$out"; then
    good=0
    found="$found $line"
  fi; done
  if [ "$good" = 1 ]; then ok "$label"; else
    fail "$label (exit $rc, wanted $want, found:$found)"
    dump_out
  fi
}
absent() { # $1 label, $2 a fixed string that must not appear in $out
  if grep -qF -- "$2" <<<"$out"; then fail "$1 (found: $2)"; else ok "$1"; fi
}
same() { # $1 label, $2 the expected output; the whole of $out must equal it
  if [ "$out" = "$2" ]; then ok "$1"; else
    fail "$1"
    dump_out
  fi
}
has() { # $1 label, $2 file, $3.. fixed strings the file must carry; a missing file fails
  local label="$1" file="$2"
  shift 2
  local line
  [ -f "$file" ] || {
    fail "$label ($file missing)"
    return
  }
  for line in "$@"; do grep -qF -- "$line" "$file" || {
    fail "$label ($file, missing: $line)"
    return
  }; done
  ok "$label"
}
# A contract's section on one line: the references hard-wrap their prose, so a phrase a contract
# carries sits across two lines as often as not and no fixed string would match it on either.
flat_section() { # $1 file, $2 the section's heading line; the flattened section on stdout
  awk -v h="$2" 'index($0, h) == 1 { on = 1; next } on && /^## / { exit } on' "$1" |
    tr '\n' ' ' | tr -s ' '
}
passage_of() { # $1 file, $2 the line the passage opens with, $3 the line past its end, both matched as a prefix; on stdout
  awk -v h="$2" -v e="$3" 'on && index($0, e) == 1 { exit } index($0, h) == 1 { on = 1 } on' "$1"
}
# The fenced blocks of a section, unindented: a contract that hands a session a command puts it in a
# block, and a brief's own lines are a block too.
blocks_of() { # $1 file, $2 the heading whose section holds them: its fenced blocks, unindented
  # Optional: $3 the opening of the line from which blocks are read, $4 n: only the nth block from it
  awk -v h="$2" -v a="${3:-}" -v n="${4:-0}" '
    $0 == h { on = 1; from = (a == ""); next }
    on && !fence && /^#+ / { exit }
    on && !fence && !from && index($0, a) == 1 { from = 1 }
    on && /^ *```/ { if (fence) fence = 0; else { fence = 1; if (from) k++; match($0, /^ */); ind = RLENGTH }; next }
    on && fence && from && (n == 0 || k == n) { print substr($0, ind + 1) }
  ' "$1"
}
carries() { # $1 label, $2.. fixed strings the flattened section in $flat must carry
  local label="$1" key
  shift
  for key in "$@"; do
    grep -qF -- "$key" <<<"$flat" || {
      fail "$label (missing: $key)"
      return
    }
  done
  ok "$label"
}
carries_any() { # $1 label, $2.. fixed strings, one of which the flattened section in $flat must carry
  local label="$1" key
  shift
  for key in "$@"; do
    grep -qF -- "$key" <<<"$flat" && {
      ok "$label"
      return
    }
  done
  fail "$label (none of: $*)"
}
before() { # $1 label, $2 the fixed string that comes first in $flat, $3 the fixed string that follows it
  local first second
  first="$(awk -v s="$flat" -v k="$2" 'BEGIN { print index(s, k) }')"
  second="$(awk -v s="$flat" -v k="$3" 'BEGIN { print index(s, k) }')"
  if [ "$first" -gt 0 ] && [ "$second" -gt "$first" ]; then ok "$1"; else
    fail "$1 ($2 at $first, $3 at $second)"
  fi
}
# Where in $flat the earliest of the fixed strings sits, 0 when none does: an order check that keeps
# the same phrasings carries_any accepts.
first_at() { # $1.. fixed strings; the smallest positive index of any of them in $flat, on stdout
  local key at best=0
  for key in "$@"; do
    at="$(awk -v s="$flat" -v k="$key" 'BEGIN { print index(s, k) }')"
    if [ "$at" -gt 0 ] && { [ "$best" = 0 ] || [ "$at" -lt "$best" ]; }; then best="$at"; fi
  done
  echo "$best"
}
# One tree is gated once: the phrasings a contract may use for a branch the run hands over without
# running the Gate itself, and the ones naming the call it is handed to as what gates that same tree.
# A case reads them with `mapfile -t names < <(no_gate_phrasings)` and passes them to carries_any.
no_gate_phrasings() { # one accepted phrasing per line: the run runs no Gate of its own
  cat <<'EOF'
no **Gate** of its own
no Gate of its own
no **Gate** of the run's own
no Gate of the run's own
runs no **Gate**
runs no Gate
no **Gate** runs
no Gate runs
without a **Gate** of its own
without a Gate of its own
skips the **Gate**
skips that **Gate**
skips the Gate
skips that Gate
skips the gate
skips that gate
the **Gate** is skipped
the Gate is skipped
never runs the **Gate**
never runs the Gate
does not run the **Gate**
does not run the Gate
EOF
}
fix_call_gates_phrasings() { # one accepted phrasing per line: the call the branch is handed to gates that tree
  cat <<'EOF'
gates the same tree
the fix call gates
that fix call gates
the landing call gates
gates that tree itself
runs the same **Gate** itself
the fix call runs the **Gate**
the fix call runs the Gate
the fix call's own **Gate**
the fix call's own Gate
EOF
}
g() { command git -c user.email=t@example.com -c user.name=t -c init.defaultBranch=main "$@"; }
commit() {
  g add -A >/dev/null
  g commit -qm "$1"
}         # $1 message: commits the whole tree
fresh() { # $1 name: a new repository at $tmp/<name>, entered
  mkdir -p "$tmp/$1" && cd "$tmp/$1" || exit 1
  git init -q -b main
  # Git's background maintenance races the trap's cleanup and leaves the repository undeletable.
  g config gc.auto 0
  g config maintenance.auto false
  # A fixture pins what git writes into a conflicted file rather than taking the machine's own
  # rerere and merge.conflictStyle.
  g config rerere.enabled false
  g config merge.conflictStyle merge
}
stop_state() { # the stop as git left it, on stdout: the index and status, and the hash of every working file
  git status --porcelain=v2
  find . -path ./.git -prune -o -type f -print0 | sort -z | xargs -0 sha256sum
}
union_of() { # $1 a conflicted path: the union of its three index stages, Target side first, on stdout
  local dir s
  dir="$(mktemp -d "$tmp/union.XXXXXX")" || return
  for s in 1 2 3; do git cat-file blob ":$s:$1" >"$dir/$s" || return; done
  git merge-file --union -p "$dir/2" "$dir/1" "$dir/3"
}
ledger_entry_fixture() { # $1 dir, $2 id, $3 file, $4 location, $5 shape, $6 commit, $7 before, $8 target, $9 incoming: an entry directory for `ledger.sh put`
  mkdir -p "$1" || return 1
  printf '%s\n' "$2" >"$1/id"
  printf '%s\n' "$3" >"$1/file"
  printf '%s\n' "$4" >"$1/location"
  printf '%s\n' "$5" >"$1/shape"
  printf '%s\n' "$6" >"$1/commit"
  printf '%s\n' "$7" >"$1/before"
  printf '%s\n' "$8" >"$1/target"
  printf '%s\n' "${9}" >"$1/incoming"
}
ledger_verdict_entry_fixture() { # $1 dir, $2 id, $3 verdict, $4 reason: an entry directory for `ledger.sh verdict`
  mkdir -p "$1" || return 1
  printf '%s\n' "$2" >"$1/id"
  printf '%s\n' "$3" >"$1/verdict"
  printf '%s\n' "$4" >"$1/reason"
}
# One part of the ledger entry whose `- file:` key is $2, on stdout: its key lines (`keys`), or the
# body of the fenced block under its Target (`target`) or Incoming (`incoming`) section. A fence may
# be any length of backticks or tildes, so a side's own fence lines never close it.
# The file goes through the environment, since `awk -v` would unescape a quoted name's `\040`.
ledger_part() { # $1 ledger, $2 file as the classifier prints it, $3 keys|target|incoming
  want="$2" awk -v part="$3" '
    function flush() { if (inentry && file == ENVIRON["want"]) printf "%s", buf[part] }
    function run_of(s, c,   n) { n = 0; while (substr(s, n + 1, 1) == c) n++; return n }
    fence {
      n = run_of($0, fc)
      if (n >= flen && substr($0, n + 1) ~ /^[ \t]*$/) { fence = 0; next }
      if (sec != "") buf[sec] = buf[sec] $0 "\n"
      next
    }
    /^## / { flush(); inentry = 1; file = ""; sec = "keys"; split("", buf); next }
    !inentry { next }
    /^### / {
      sec = $0 == "### Target (kept)" ? "target" : $0 == "### Incoming (set aside)" ? "incoming" : "other"
      next
    }
    /^```/ || /^~~~/ { fc = substr($0, 1, 1); flen = run_of($0, fc); fence = 1; next }
    sec == "keys" && /^- [a-z]+: / {
      buf["keys"] = buf["keys"] $0 "\n"
      if (index($0, "- file: ") == 1) file = substr($0, 9)
    }
    END { flush() }
  ' "$1"
}

# The testing-policy scripts of the checkout this file sits in, so a fixture renders the templates under test.
policy_scripts() { (cd "$(dirname "${BASH_SOURCE[0]}")/../../skills/testing-policy/scripts" && pwd -P); }
# A project whose CLAUDE.md holds the surface's rendered policy section with every {{slot}} filled, minus
# the lines the grep pattern drops: an unfilled slot fails an install by itself.
policy_section_fixture() { # $1 project dir, $2 surface, $3 grep -v pattern (empty keeps every line)
  local scripts
  scripts="$(policy_scripts)"
  mkdir -p "$1"
  {
    echo "# Project"
    echo
    bash "$scripts/render-policy.sh" "$2"
  } |
    { if [ -n "$3" ]; then grep -vE -- "$3"; else cat; fi; } |
    sed -E 's/\{\{[^}]*\}\}/filled/g' >"$1/CLAUDE.md"
}
# Every other piece the verifier folds into its exit code, so the exit code a case reads is the one the
# policy section alone decides: a fixture missing a piece exits 1 whatever the section holds.
policy_pieces_fixture() { # $1 project dir, $2.. the agents to install (unit, e2e); the test-author skill and both scripts always
  local p="$1" scripts kind
  shift
  scripts="$(policy_scripts)"
  mkdir -p "$p/.claude/agents" "$p/.claude/skills/test-author" "$p/.claude/testing-policy"
  for kind in "$@"; do bash "$scripts/render-agent.sh" "$kind" >"$p/.claude/agents/$kind-test-author.md"; done
  bash "$scripts/render-agent.sh" test-author >"$p/.claude/skills/test-author/SKILL.md"
  cp "$scripts/scan-test-assets.sh" "$scripts/skip-patterns.sh" "$p/.claude/testing-policy/"
}
