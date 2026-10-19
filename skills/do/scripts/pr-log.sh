#!/usr/bin/env bash
# pr-log.sh: the excerpt of a red check's failed steps, cut from its log, so the pr Playbook's fixer
# fork starts from the failure and never reads the whole log.
#
#   pr-log.sh <link> <tree>
#     <link>    a red= line's link from pr-watch.sh
#     <tree>    the work tree the paths are matched against
#
# Prints key=value lines: one step=<step name> per failed step in log order, dropped=<n> (the lines
# cut above the excerpt), then one file=<path> per tracked path the excerpt names (repo-relative,
# first appearance first, once), then the last 200 lines of the failed steps' output as
# excerpt=<text>, with the timestamp and ANSI escapes stripped, then repo=<host>/<owner>/<repo> and
# run=<run id> as the last two lines, the run id read off the link. Keys repeat in order.
#
# A link whose <host>/<owner>/<repo> is not the pull request's base repository, as gh resolves it
# from <tree>, is refused unread: whoever posts a status sets the link, and its repo= and run= go on
# to pr-rerun.sh.
#
# Exits 0 an excerpt printed · 1 gh missing or unable to read the repository or the log · 2 usage ·
# 3 nothing to cut (not an Actions job link, a link to another repository, or no failed step).
# Nothing on stdout for 1, 2 or 3; a one-line pr-log.sh: <reason> goes to stderr.
set -uo pipefail

excerpt_lines=200

parse_link() { # $1 link: prints "<host>/<owner>/<repo> <run id> <job id>", or exits 3 when it is not an Actions job URL
  local re='^https://([^/]+)/([^/]+)/([^/]+)/actions/runs/([0-9]+)/job/([0-9]+)([?#].*)?$'
  if [[ ! "$1" =~ $re ]]; then
    echo "pr-log.sh: not a GitHub Actions job link: $1" >&2
    exit 3
  fi
  printf '%s/%s/%s %s %s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" "${BASH_REMATCH[4]}" "${BASH_REMATCH[5]}"
}

read_base_repo() { # $1 tree: prints <host>/<owner>/<repo> of the pull request's base repository; 1 on a read failure
  local url
  url="$(cd "$1" && gh repo view --json url --jq .url 2>/dev/null)" || return 1
  url="${url#https://}"
  [ -n "$url" ] && [ "$url" != "${url#*/*/}" ] || return 1
  printf '%s\n' "${url%/}"
}

read_failed_log() { # $1 repo, $2 job id: the raw log lines
  gh run view --job "$2" --repo "$1" --log-failed
}

cut_excerpt() { # stdin raw lines: prints step=, dropped= and excerpt= lines; exits 3 when no failed step
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
      if (n == 0) exit 3
      for (s = 1; s <= steps; s++) print "step=" order[s]
      start = n > keep ? n - keep + 1 : 1
      print "dropped=" start - 1
      for (k = start; k <= n; k++) print "excerpt=" lines[k]
    }'
}

named_files() { # stdin: the excerpt's lines; $1 tree: prints one file=<path> per tracked path named
  awk '
    FNR == NR { tracked[$0] = 1; next }
    function wrap(t) {
      while (t ~ /^[\047"(\[<{]/) t = substr(t, 2)
      while (t ~ /[\047")\]>}]$/) t = substr(t, 1, length(t) - 1)
      return t
    }
    {
      for (f = 1; f <= NF; f++) {
        t = wrap($f)
        sub(/:[0-9]+(:[0-9]+)?$/, "", t)
        t = wrap(t)
        if (t == "") continue
        hit = ""
        if (t in tracked) hit = t
        else {
          rest = t
          while ((p = index(rest, "/")) > 0) {
            rest = substr(rest, p + 1)
            if (rest in tracked) { hit = rest; break }
          }
        }
        if (hit != "" && !(hit in seen)) { seen[hit] = 1; print "file=" hit }
      }
    }' <(git -C "$1" ls-files) -
}

main() {
  local parsed repo run job log cut base
  if [ "$#" -ne 2 ]; then
    echo "usage: pr-log.sh <link> <tree>" >&2
    exit 2
  fi
  if ! git -C "$2" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "pr-log.sh: not a git work tree: $2" >&2
    exit 2
  fi
  parsed="$(parse_link "$1")" || exit $?
  if ! command -v gh >/dev/null 2>&1; then
    echo "pr-log.sh: gh is not on PATH" >&2
    exit 1
  fi
  read -r repo run job <<<"$parsed"
  base="$(read_base_repo "$2")" || {
    echo "pr-log.sh: cannot read the pull request's repository" >&2
    exit 1
  }
  if [ "${repo,,}" != "${base,,}" ]; then
    echo "pr-log.sh: the link is to $repo, not the pull request's repository $base: $1" >&2
    exit 3
  fi
  if ! log="$(read_failed_log "$repo" "$job")"; then
    echo "pr-log.sh: gh could not read the log of job $job" >&2
    exit 1
  fi
  [ -n "$log" ] && cut="$(printf '%s\n' "$log" | cut_excerpt)" || {
    echo "pr-log.sh: no failed step in the log of job $job" >&2
    exit 3
  }
  printf '%s\n' "$cut" | grep -E '^(step|dropped)='
  printf '%s\n' "$cut" | sed -n 's/^excerpt=//p' | named_files "$2"
  printf '%s\n' "$cut" | grep '^excerpt='
  printf 'repo=%s\nrun=%s\n' "$repo" "$run"
}

main "$@"
