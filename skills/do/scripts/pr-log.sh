#!/usr/bin/env bash
# pr-log.sh: the excerpt of a red check's failed steps, cut from its log, so the pr Playbook's fixer
# fork starts from the failure and never reads the whole log.
#
#   pr-log.sh <link> <tree>
#     <link>    a red= line's link from pr-watch.sh
#     <tree>    the work tree the paths are matched against
#
# Prints key=value lines: one step=<step name> per failed step in log order, dropped=<n> (the lines
# cut above the excerpt), then the last 200 lines of the failed steps' output as excerpt=<text>,
# with the timestamp and ANSI escapes stripped. Keys repeat in order. Exits 0.
set -uo pipefail

excerpt_lines=200

parse_link() { # $1 link: prints "<host>/<owner>/<repo> <job id>"
  local rest host owner repo job
  rest="${1#*://}"
  IFS=/ read -r host owner repo _ _ _ _ job _ <<<"$rest"
  printf '%s/%s/%s %s\n' "$host" "$owner" "$repo" "$job"
}

read_failed_log() { # $1 repo, $2 job id: the raw log lines
  gh run view --job "$2" --repo "$1" --log-failed
}

cut_excerpt() { # stdin raw lines: prints step=, dropped= and excerpt= lines
  awk -v keep="$excerpt_lines" '
    BEGIN { esc = sprintf("%c", 27) }
    {
      i = index($0, "\t")
      rest = substr($0, i + 1)
      j = index(rest, "\t")
      step = substr(rest, 1, j - 1)
      text = substr(rest, j + 1)
      if (!(step in seen)) { seen[step] = 1; order[++steps] = step }
      sub(/^[^ ]+ /, "", text)
      gsub(esc "\\[[0-9;?]*[A-Za-z]", "", text)
      lines[++n] = text
    }
    END {
      for (s = 1; s <= steps; s++) print "step=" order[s]
      start = n > keep ? n - keep + 1 : 1
      print "dropped=" start - 1
      for (k = start; k <= n; k++) print "excerpt=" lines[k]
    }'
}

main() {
  local parsed repo job
  parsed="$(parse_link "$1")"
  repo="${parsed% *}"
  job="${parsed#* }"
  read_failed_log "$repo" "$job" | cut_excerpt
}

main "$@"
exit 0
