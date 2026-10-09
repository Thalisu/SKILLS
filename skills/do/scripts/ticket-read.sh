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
#   build_check_of <name> <location>
#                                 prints the build_check word of ticket-door.sh for a Build
#                                 repository name and its location, here when the location's main
#                                 worktree is the sourcing script's $main
#   build_of <file>               sets build_name, build_place and build_check to what
#                                 build_repository_of, repository_location_of and build_check_of
#                                 read for the Ticket, with name_detail and place_detail
#   blockers_of <file>            sets word to the numbers its one **Blocked by:** paragraph names,
#                                 space separated in the order written, none for None, none with
#                                 detail set when it names no Ticket number, or ambiguous with
#                                 detail set on two such lines; unsplit to the numbers of the
#                                 paragraph that no part starts with (the split rule is worded in
#                                 ticket-door.sh's header)
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

build_check_of() { # $1 name (or none/ambiguous), $2 location (or none/ambiguous): prints one build_check word, comparing main_of "$2" with the session's $main
  case "$1" in none | ambiguous) echo "$1" && return ;; esac
  case "$2" in none) echo unlisted && return ;; ambiguous) echo ambiguous && return ;; esac
  # A relative location is never resolved against the session's directory, which is not the Spec's.
  case "$2" in /*) [ -d "$2" ] || { echo missing && return; } ;; *) echo missing && return ;; esac
  # Asked from a plain folder nested in a working tree, git answers for the enclosing repository,
  # which the Spec never named.
  local top
  top="$(git -C "$2" rev-parse --show-toplevel 2>/dev/null)"
  [ -n "$top" ] && [ "$(cd "$top" && pwd -P)" = "$(cd "$2" && pwd -P)" ] || { echo not-git && return; }
  if [ "$(main_of "$2")" = "$main" ]; then echo here; else echo elsewhere; fi
}

# The Ticket and its next blocker are both read through here, against the one Spec they share.
build_of() { # $1 Ticket file: sets build_name, build_place and build_check as build_repository, build_location and build_check read, with name_detail and place_detail
  build_repository_of "$1"
  build_name="$word" name_detail="$detail"
  word=none detail=""
  case "$build_name" in none | ambiguous) ;; *) repository_location_of "$1" "$build_name" ;; esac
  build_place="$word" place_detail="$detail"
  build_check="$(build_check_of "$build_name" "$build_place")"
}

# shellcheck disable=SC2034 # unsplit is read by the sourcing script.
blockers_of() { # $1 Ticket file: sets word to the numbers its Blocked by paragraph names, none, or ambiguous, with detail and unsplit
  local by_lines blocked_by numbers
  by_lines="$(grep -n '^\*\*Blocked by:\*\*' "$1" | cut -d: -f1 | tr '\n' ' ')"
  by_lines="${by_lines% }"
  detail="" unsplit=""
  if [ "$(wc -w <<<"$by_lines")" -gt 1 ]; then
    word=ambiguous
    detail="blocked-by lines $by_lines"
    return
  fi
  blocked_by="$(awk '/^\*\*Blocked by:\*\*/ { on = 1; sub(/^\*\*Blocked by:\*\*[[:space:]]*/, ""); if ($0 == "") next }
    on && /^[[:space:]]*$/ { gap = 1; next }
    on { sub(/^[[:space:]]*[-*+][[:space:]]+/, ""); if (gap && $0 !~ /^[[:space:]]*[0-9]/) exit; gap = 0; print }' "$1")"
  numbers="$(sed -E 's/(^|[[:space:]])and([[:space:]]|$)/\1,\2/g' <<<"$blocked_by" | tr ';,' '\n\n' |
    sed -nE 's/^[[:space:]]*([0-9]+)([^[:alnum:]].*)?$/\1/p' | awk '!seen[$0]++' | tr '\n' ' ')"
  numbers="${numbers% }"
  unsplit="$(grep -oE '[[:alnum:]]+' <<<"$blocked_by" | grep -xE '[0-9]+' |
    awk -v read="$numbers" 'BEGIN { split(read, r, " "); for (i in r) ok[r[i]] = 1 } !ok[$0] && !seen[$0]++' | tr '\n' ' ')"
  unsplit="${unsplit% }"
  word="${numbers:-none}"
  if [ -z "$numbers" ]; then
    case "$blocked_by" in None* | none*) ;; *) detail="blocked-by names no Ticket number" ;; esac
  fi
}
