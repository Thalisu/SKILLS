#!/usr/bin/env bash
# lib.sh: the assertions and fixture builders the test scripts share. A script sources it after its
# `here=` line and sets fails=0; the assertions read the caller's $out and bump the caller's $fails.
# shellcheck disable=SC2154 # $out and $tmp belong to the sourcing script, which assigns them first.

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
