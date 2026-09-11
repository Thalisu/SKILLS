#!/usr/bin/env bash
# lib.sh: the assertions and fixture builders the test scripts share. A script sources it after its
# `here=` line and sets fails=0; the assertions read the caller's $out and bump the caller's $fails.

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
lacks() { # $1 label, $2 file, $3.. fixed strings the file must not carry; a missing file fails
  local label="$1" file="$2"
  shift 2
  local line
  [ -f "$file" ] || {
    fail "$label ($file missing)"
    return
  }
  for line in "$@"; do grep -qF -- "$line" "$file" && {
    fail "$label ($file, found: $line)"
    return
  }; done
  ok "$label"
}
ordered() { # $1 label, $2 file, $3.. fixed strings that must appear in the file in this order
  local label="$1" file="$2"
  shift 2
  local last=0 n line good=1
  for line in "$@"; do
    n="$(grep -nF -- "$line" "$file" 2>/dev/null | awk -F: -v l="$last" '$1 >= l { print $1; exit }')"
    [ -n "$n" ] || good=0
    last="${n:-$last}"
  done
  if [ "$good" = 1 ]; then ok "$label"; else fail "$label ($file)"; fi
}
flat() { tr '\n' ' ' <"$1" 2>/dev/null | tr -s ' '; } # $1 file: its text on one line, so a wrapped sentence matches

para_has() { # $1 label, $2 file, $3 a fixed string opening the paragraph, $4.. strings in that same paragraph
  local label="$1" file="$2" anchor="$3"
  shift 3
  local ok=1 para joined line
  para="$(awk -v a="$anchor" 'BEGIN { RS = "" } index($0, a) { print; exit }' "$file" 2>/dev/null)"
  [ -n "$para" ] || ok=0
  # A paragraph's own line-wrapping must never hide a string that is whole in its prose: each line
  # break and the indentation after it read as one space, so a string that wraps across two lines
  # still matches, in a plain paragraph or in an indented bullet.
  joined="$(awk 'NR > 1 { sub(/^[[:space:]]+/, ""); printf " " } { printf "%s", $0 }' <<<"$para")"
  for line in "$@"; do [ "$ok" = 1 ] && grep -qF -- "$line" <<<"$joined" || ok=0; done
  if [ "$ok" = 1 ]; then echo "ok    $label"; else
    echo "FAIL  $label ($file)"
    fails=$((fails + 1))
  fi
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
scaffold_of() { # $1 case folder: the scaffold_script block of its case file
  awk '/^  scaffold_script: \|/ { f = 1; next } f && /^    / { sub(/^    /, ""); print; next } f && /^[[:space:]]*$/ { print ""; next } f { exit }' \
    "$1/case.yaml" 2>/dev/null
}
