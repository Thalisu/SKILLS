#!/usr/bin/env bash
# grounding.sh: whether a grounding artifact of a do ticket run still matches the documents it was
# cut from. Run from the main checkout; <root> is the door's root=, the directory every
# git hash-object runs in, and <ticket> is the door's ticket=, a relative path read from <root>.
#
#   grounding.sh digest <root> <ticket> <digest path>
#       the Digest reuse gate: reuse when the Digest's ## Sources records the Spec beside the
#       Ticket's issues/ folder and the journey its Journey: line names, each with its current
#       hash, or `<name>: absent` for a document not on disk; fork otherwise
#
# A record is one ## Sources line, `<name>: <absolute path> <hash>`, or `<name>: absent`. It matches
# when the section holds exactly one line opening `<name>:` and that line equals it.
#
# Prints key=value lines, verdict= last. Exit codes: digest 0 reuse, 1 fork · 2 usage, or <root>
# not a git work tree.
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd -P)"
# shellcheck source=skills/do/scripts/ticket-read.sh
. "$here/ticket-read.sh"

usage() {
  echo "usage: grounding.sh digest <root> <ticket> <digest path>" >&2
  exit 2
}

at_root() { # $1 root: exits 2 unless it is a git work tree
  [ "$(git -C "$1" rev-parse --is-inside-work-tree 2>/dev/null)" = true ] || {
    echo "not a git work tree: $1" >&2
    exit 2
  }
}

absolute() { # $1 a path, relative ones read from $root
  case "$1" in /*) echo "$1" ;; *) echo "$root/$1" ;; esac
}

hash_at() { # $1 path or none: its object name under $root, or absent
  if [ "$1" != none ] && [ -f "$1" ]; then (cd "$root" && git hash-object -- "$1"); else echo absent; fi
}

record() { # $1 name, $2 path, $3 hash
  if [ "$3" = absent ]; then echo "$1: absent"; else echo "$1: $2 $3"; fi
}

sources_of() { # $1 file: the non-blank lines of its ## Sources section
  awk '/^## Sources[[:space:]]*$/ { on = 1; next } on && /^## / { exit } on && NF' "$1" 2>/dev/null
}

matches() { # $1 section, $2 record
  [ "$(grep -c -- "^${2%%:*}:" <<<"$1")" = 1 ] && grep -qxF -- "$2" <<<"$1"
}

cmd_digest() {
  [ $# = 3 ] || usage
  root="$1"
  at_root "$root"
  local ticket spec journey spec_hash journey_hash section
  ticket="$(absolute "$2")"
  spec="$(spec_beside "$ticket")"
  journey="$(journey_beside "$spec")"
  [ "$spec" = /dev/null ] && spec=none
  spec_hash="$(hash_at "$spec")"
  journey_hash="$(hash_at "$journey")"
  echo "spec=$spec"
  echo "spec_hash=$spec_hash"
  echo "journey=$journey"
  echo "journey_hash=$journey_hash"
  if [ -f "$3" ]; then
    echo "digest=present"
    section="$(sources_of "$3")"
    if matches "$section" "$(record spec "$spec" "$spec_hash")" &&
      matches "$section" "$(record journey "$journey" "$journey_hash")"; then
      echo "verdict=reuse"
      return 0
    fi
  else
    echo "digest=none"
  fi
  echo "verdict=fork"
  return 1
}

case "${1:-}" in
  digest)
    shift
    cmd_digest "$@"
    ;;
  *) usage ;;
esac
