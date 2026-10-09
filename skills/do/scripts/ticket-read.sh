#!/usr/bin/env bash
# ticket-read.sh: what a Ticket file is and what its status reads, the one rule ticket-door.sh and
# completion-check.sh share. Sourced, never run: it defines these functions and a helper
# they share, and does nothing else.
#
#   status_of <file>              sets word to the status and detail to nothing, or word to
#                                 ambiguous with detail saying why
#   kind_of <file>                sets word to the kind the **Kind:** line reads, logic with none
#   front_end_of <file>           sets word to the front-end builder the Front-end: line of the
#                                 Ticket's Spec reads, the spec.md beside its issues/ folder; none
#                                 with no such line, no Spec, or no issues/ folder
#                                 (both: read from the lines above the first ## heading only; two
#                                 lines or a word outside the set is ambiguous, as a status is)
#   ticket_files <folder> [<NN>]  prints the Ticket files directly in the issues folder, in number
#                                 order, or only the ones numbered <NN>
#   build_repository_of <file>    sets word to the name its one **Build repository:** header line
#                                 reads, none with no line, or ambiguous with detail saying why
#   repository_location_of <file> <name>
#                                 sets word to the location of the entry of that name in the
#                                 ## Repositories section of the Spec beside its issues/ folder, none
#                                 with no entry, section or Spec, or ambiguous with detail saying why
#   spec_beside <file>            prints the spec.md beside its issues/ folder, /dev/null with no
#                                 Spec or no issues/ folder
#   main_of <directory>           prints the main worktree of the repository holding it, nothing
#                                 when it is in none
#   home_root <file> <main checkout>
#                                 prints the root whose .scratch/ holds the Ticket's feature folder,
#                                 <file> absolute and <main checkout> as main_of prints it
#
# A status is the one **Status:** line at column 0: none, two or a word outside the walk
# (ready-for-agent, claimed, resolved) is ambiguous, and no word is taken out of it. A Ticket file
# is a <NN>-<slug>.md. A review, digest, project map, sketch or plan of a Ticket is never one, even
# with its Ticket gone; any other <stem>.<kind>.md is left out only beside a <stem>.md, so a slug
# that itself holds a dot (20-upgrade-to-v1.2.md) still counts.

# shellcheck disable=SC2034 # word and detail are read by the sourcing script.
status_of() { # $1 file: sets word to the status, or to ambiguous with detail set
  local lines
  lines="$(grep -n '^\*\*Status:\*\*' "$1" | cut -d: -f1 | tr '\n' ' ')"
  lines="${lines% }"
  detail=""
  if [ "$(wc -w <<<"$lines")" != 1 ]; then
    word=ambiguous
    detail="status lines ${lines:-none}"
    return
  fi
  word="$(grep '^\*\*Status:\*\*' "$1" | sed 's/^\*\*Status:\*\*//' | awk '{ print $1 }')"
  case "$word" in
    ready-for-agent | claimed | resolved) ;;
    *)
      detail="status word ${word:-none}"
      word=ambiguous
      ;;
  esac
}

kind_of() { # $1 file: sets word to the kind its **Kind:** line reads, logic when it has none
  line_word "$1" '^\*\*Kind:\*\*' kind logic 'logic front-end setup'
}

front_end_of() { # $1 file: sets word to the front-end builder its Spec reads, or none
  local folder spec=/dev/null
  folder="$(dirname "$1")"
  [ "$(basename "$folder")" != issues ] || [ ! -f "$(dirname "$folder")/spec.md" ] || spec="$(dirname "$folder")/spec.md"
  line_word "$spec" '^Front-end:' front-end none 'none builder impeccable'
}

# Only the header counts: the lines above the first column-0 `## ` heading. A file written before the
# line existed has none of its own, so a line planted lower down (a quoted body, a copied comment)
# would otherwise be the only match and be read as the developer's.
line_word() { # $1 file, $2 line pattern, $3 name, $4 default, $5 allowed words: sets word and detail
  local lines head
  head="$(awk '/^## / { exit } { print }' "$1")"
  lines="$(grep -n "$2" <<<"$head" | cut -d: -f1 | tr '\n' ' ')"
  lines="${lines% }"
  detail=""
  word="$4"
  case "$(wc -w <<<"$lines")" in
    0) return ;;
    1) ;;
    *)
      word=ambiguous
      detail="$3 lines $lines"
      return
      ;;
  esac
  word="$(grep "$2" <<<"$head" | sed "s/$2//" | awk '{ print $1 }')"
  case " $5 " in
    *" $word "*) ;;
    *)
      detail="$3 word ${word:-none}"
      word=ambiguous
      ;;
  esac
}

ticket_files() { # $1 issues folder, $2 optional Ticket number: the Ticket files, sorted, sidecars left out
  find "$1" -maxdepth 1 -type f -name "${2:-[0-9]*}-*.md" ! -name '*.review.md' ! -name '*.digest.md' \
    ! -name '*.project-map.md' ! -name '*.sketch.md' ! -name '*.plan.md' -printf '%f\n' | grep -E '^[0-9]+-' |
    sort -n | awk -v dir="$1" '{ c[NR] = $0; has[$0] = 1 }
    END { for (i = 1; i <= NR; i++) { if (match(c[i], /\.[^.\/]+\.md$/) && has[substr(c[i], 1, RSTART - 1) ".md"]) continue; print dir "/" c[i] } }'
}

# Only the header counts: the lines above the first column-0 `## ` heading, so a line quoted lower
# down in the body is never read as the Ticket's own.
build_repository_of() { # $1 file: sets word to the name its one **Build repository:** header line reads, none, or ambiguous with detail set
  local head lines
  head="$(awk '/^## / { exit } { print }' "$1")"
  lines="$(grep -n '^\*\*Build repository:\*\*' <<<"$head" | cut -d: -f1 | tr '\n' ' ')"
  lines="${lines% }"
  detail=""
  word=none
  case "$(wc -w <<<"$lines")" in
    0) return ;;
    1) ;;
    *)
      word=ambiguous
      detail="build-repository lines $lines"
      return
      ;;
  esac
  word="$(grep '^\*\*Build repository:\*\*' <<<"$head" | sed -E 's/^\*\*Build repository:\*\*[[:space:]]*//; s/[[:space:]]+$//')"
}

spec_beside() { # $1 Ticket file: prints the spec.md beside its issues/ folder, or /dev/null
  local folder
  folder="$(dirname "$1")"
  if [ "$(basename "$folder")" = issues ] && [ -f "$(dirname "$folder")/spec.md" ]; then
    echo "$(dirname "$folder")/spec.md"
  else echo /dev/null; fi
}

# An entry is `- {name}[ (Home repository)]: {location}`, one line, the name matched whole with the
# Home mark left out, the location the rest of the line after the first `: `.
repository_location_of() { # $1 Ticket file, $2 name: sets word to the entry's location, none, or ambiguous with detail set
  local spec sections entries count
  spec="$(spec_beside "$1")"
  sections="$(grep -n '^## Repositories[[:space:]]*$' "$spec" | cut -d: -f1 | tr '\n' ' ')"
  sections="${sections% }"
  detail=""
  word=none
  case "$(wc -w <<<"$sections")" in
    0) return ;;
    1) ;;
    *)
      word=ambiguous
      detail="repositories sections $sections"
      return
      ;;
  esac
  entries="$(awk -v name="$2" '/^## Repositories[[:space:]]*$/ { on = 1; next } on && /^## / { exit }
    on && /^- / { e = substr($0, 3); i = index(e, ": "); if (!i) next; n = substr(e, 1, i - 1)
      sub(/[[:space:]]+\(Home repository\)$/, "", n); if (n != name) next
      loc = substr(e, i + 2); gsub(/^[[:space:]]+|[[:space:]]+$/, "", loc); print NR "\t" loc }' "$spec")"
  count="$(grep -c . <<<"$entries")"
  case "$count" in
    0) return ;;
    1) word="$(cut -f2- <<<"$entries")" ;;
    *)
      word=ambiguous
      detail="repositories entries $2 $(cut -f1 <<<"$entries" | tr '\n' ' ')"
      detail="${detail% }"
      ;;
  esac
}

# A bare main worktree has no working tree to anchor on, and git lists it first all the same.
main_of() { # $1 directory: prints the main worktree of the repository holding it, empty when it is not in one
  local top main
  top="$(git -C "$1" rev-parse --show-toplevel 2>/dev/null)" || return 0
  main="$(git -C "$1" worktree list --porcelain 2>/dev/null |
    awk '/^$/ { exit } /^worktree /{ p = substr($0, 10) } /^bare$/ { p = "" } END { print p }')"
  [ -n "$main" ] && [ -d "$main" ] || main="$top"
  (cd "$main" && pwd -P)
}

home_root() { # $1 the Ticket's absolute path, $2 the main checkout: prints the root whose .scratch/ holds the Ticket's feature folder
  if [ "$(main_of "$(dirname "$1")")" = "$2" ]; then echo "$2" && return; fi
  case "$1" in */.scratch/*) echo "${1%/.scratch/*}" ;; *) echo "$2" ;; esac
}
