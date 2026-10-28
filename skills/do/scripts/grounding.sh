#!/usr/bin/env bash
# grounding.sh: whether a grounding artifact of a do ticket run still matches the documents it was
# cut from. Run from the main checkout; <root> is the door's root=, the directory every
# git hash-object runs in, and <ticket> is the door's ticket=, a relative path read from <root>.
#
#   grounding.sh digest <root> <ticket> <digest path> [<extreme sidecar>]
#       the Digest reuse gate: reuse when the Digest's ## Sources records the Spec beside the
#       Ticket's issues/ folder and the journey its Journey: line names, each with its current
#       hash, or `<name>: absent` for a document not on disk; fork otherwise, one moved= line per
#       record that is not a match. With the sidecar resume-state.sh printed as extreme= (it must
#       be <ticket> with .md replaced by .extreme.md): extreme when both match, the sidecar kept;
#       otherwise fork, the sidecar removed
#   grounding.sh plan <root> <ticket> <digest path> <destination>
#       whether the Plan at <destination>, a .plan.md, carries over: carried when its ## Sources
#       is exactly the Ticket's and the Digest's records, hashed now; fork otherwise, a Plan that
#       is there removed first, since the Planner's hook refuses a write over one. The ticket=,
#       ticket_hash=, digest= and digest_hash= lines are the values the session records
#   grounding.sh verify <root> <ticket> <ticket hash> <digest path> <digest hash> [<destination>]
#       the re-hash and the check of a returned Plan against the recorded hashes: moved, one
#       moved= line per document, when the Ticket or the Digest no longer hashes to its recorded
#       value; refused when the destination holds no file or its ## Sources is not exactly the two
#       records; match otherwise
#   grounding.sh claim <root> <ticket> <recorded ticket hash>
#       the Ticket's re-hash right before the claim is written: unmoved when it still hashes to
#       the recorded value; moved otherwise
#
# A record is one ## Sources line, `<name>: <absolute path> <hash>`, or `<name>: absent`, a
# relative Ticket path joined to <root>. It matches a Digest's section when the section holds
# exactly one line opening `<name>:` and that line equals it, and a Plan's section matches when it
# holds exactly two non-blank lines, the Ticket's record and the Digest's.
#
# Prints key=value lines, verdict= last. Exit codes: digest 0 reuse, 1 fork, 5 extreme · plan
# 0 carried, 1 fork · verify 0 match, 1 refused, 3 moved · claim 0 unmoved, 3 moved · 2 usage,
# <root> not a git work tree, a hash argument that is neither an object name nor absent, or a
# sidecar that is not the Ticket's own.
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd -P)"
# shellcheck source=skills/do/scripts/ticket-read.sh
. "$here/ticket-read.sh"

usage() {
  echo "usage: grounding.sh digest <root> <ticket> <digest path> [<extreme sidecar>]" >&2
  echo "       grounding.sh plan <root> <ticket> <digest path> <destination>" >&2
  echo "       grounding.sh verify <root> <ticket> <ticket hash> <digest path> <digest hash> [<destination>]" >&2
  echo "       grounding.sh claim <root> <ticket> <recorded ticket hash>" >&2
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

plan_matches() { # $1 Plan, $2 the ticket record, $3 the digest record
  local section
  section="$(sources_of "$1")"
  [ "$(grep -c . <<<"$section")" = 2 ] && grep -qxF -- "$2" <<<"$section" && grep -qxF -- "$3" <<<"$section"
}

ticket_of() { # $1 the door's ticket=: the Ticket's absolute path, or an issue reference as given
  if [ -f "$(absolute "$1")" ]; then absolute "$1"; else echo "$1"; fi
}

cmd_plan() {
  [ $# = 4 ] || usage
  root="$1"
  at_root "$root"
  case "$4" in *.plan.md) ;; *) usage ;; esac
  local ticket ticket_hash digest digest_hash
  ticket="$(ticket_of "$2")"
  ticket_hash="$(hash_at "$ticket")"
  digest="$(absolute "$3")"
  digest_hash="$(hash_at "$digest")"
  echo "ticket=$ticket"
  echo "ticket_hash=$ticket_hash"
  echo "digest=$digest"
  echo "digest_hash=$digest_hash"
  if [ -f "$4" ]; then
    if plan_matches "$4" "$(record ticket "$ticket" "$ticket_hash")" "$(record digest "$digest" "$digest_hash")"; then
      echo "verdict=carried"
      return 0
    fi
    rm -f -- "$4"
    echo "removed=$4"
  fi
  echo "verdict=fork"
  return 1
}

a_hash() { # $1 a hash argument: exits 2 unless it is an object name or absent
  [[ "$1" =~ ^([0-9a-f]{40}|[0-9a-f]{64}|absent)$ ]] || {
    echo "not an object name or absent: $1" >&2
    exit 2
  }
}

cmd_verify() {
  [ $# = 5 ] || [ $# = 6 ] || usage
  root="$1"
  at_root "$root"
  a_hash "$3"
  a_hash "$5"
  local ticket digest moved=0
  ticket="$(ticket_of "$2")"
  digest="$(absolute "$4")"
  [ "$(hash_at "$ticket")" = "$3" ] || {
    echo "moved=ticket"
    moved=1
  }
  [ "$(hash_at "$digest")" = "$5" ] || {
    echo "moved=digest"
    moved=1
  }
  if [ "$moved" = 1 ]; then
    echo "verdict=moved"
    return 3
  fi
  if [ $# = 6 ] && ! { [ -f "$6" ] && plan_matches "$6" "$(record ticket "$ticket" "$3")" "$(record digest "$digest" "$5")"; }; then
    echo "verdict=refused"
    return 1
  fi
  echo "verdict=match"
}

cmd_claim() {
  [ $# = 3 ] || usage
  root="$1"
  at_root "$root"
  a_hash "$3"
  local ticket_hash
  ticket_hash="$(hash_at "$(ticket_of "$2")")"
  echo "ticket_hash=$ticket_hash"
  if [ "$ticket_hash" != "$3" ]; then
    echo "verdict=moved"
    return 3
  fi
  echo "verdict=unmoved"
}

cmd_digest() {
  [ $# = 3 ] || [ $# = 4 ] || usage
  root="$1"
  at_root "$root"
  local ticket spec journey spec_hash journey_hash section sidecar="" moved=0
  ticket="$(absolute "$2")"
  if [ $# = 4 ]; then
    sidecar="$(absolute "$4")"
    [ "$sidecar" = "${ticket%.md}.extreme.md" ] || {
      echo "the extreme sidecar is not ${ticket%.md}.extreme.md: $4" >&2
      exit 2
    }
  fi
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
    matches "$section" "$(record spec "$spec" "$spec_hash")" || {
      echo "moved=spec"
      moved=1
    }
    matches "$section" "$(record journey "$journey" "$journey_hash")" || {
      echo "moved=journey"
      moved=1
    }
  else
    echo "digest=none"
    moved=1
  fi
  if [ -n "$sidecar" ]; then
    if [ "$moved" = 0 ]; then
      echo "extreme=kept"
      echo "verdict=extreme"
      return 5
    fi
    rm -f -- "$sidecar"
    echo "extreme=removed"
  elif [ "$moved" = 0 ]; then
    echo "verdict=reuse"
    return 0
  fi
  echo "verdict=fork"
  return 1
}

case "${1:-}" in
  digest)
    shift
    cmd_digest "$@"
    ;;
  plan)
    shift
    cmd_plan "$@"
    ;;
  verify)
    shift
    cmd_verify "$@"
    ;;
  claim)
    shift
    cmd_claim "$@"
    ;;
  *) usage ;;
esac
