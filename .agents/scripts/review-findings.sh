#!/usr/bin/env bash
# review-findings.sh: the Findings of a Review, each with its Bucket and its latest Fix run line,
# read in the format of ../formats/review-format.md. It is the one reading the debt gather and the
# fix run share, so neither restates it.
#
#   review-findings.sh <review file>
#
# A Finding is a `### <n>. <rest>` line inside one of the sections `## Act on`, `## Consider`,
# `## Noted` or `## Cleared`; a section runs until the next `## ` line, and a `### ` line anywhere
# else is no Finding. The latest line of a Finding is the text after `- <n>: ` on the last such
# line of the file across every `## Fix run` section, so a later section overrides an earlier one.
#
# Prints one line per Finding, in file order, tab-separated:
#   finding=<n>  bucket=<Act on|Consider|Noted|Cleared>  latest=<text>|none  header=<text>
# where header is the text after `### <n>. `. A Review with no Finding prints nothing.
#
# Exit codes: 0 it read the file, no Finding included · 2 usage, or a file that is missing or
# unreadable.
set -uo pipefail

if [ "$#" -ne 1 ]; then
  echo "usage: review-findings.sh <review file>" >&2
  exit 2
fi
review="$1"
if [ ! -f "$review" ] || [ ! -r "$review" ]; then
  echo "review-findings.sh: cannot read $review" >&2
  exit 2
fi

awk '
  /^## / {
    section = substr($0, 4)
    inrun = ($0 == "## Fix run")
    bucket = (section == "Act on" || section == "Consider" || section == "Noted" || section == "Cleared") ? section : ""
    next
  }
  bucket != "" && match($0, /^### [0-9]+\. /) {
    n = substr($0, 5, RLENGTH - 6)
    fcount++
    num[fcount] = n
    buck[fcount] = bucket
    head[fcount] = substr($0, RLENGTH + 1)
    next
  }
  inrun && match($0, /^- [0-9]+: /) {
    n = substr($0, 3, RLENGTH - 4)
    text[n] = substr($0, RLENGTH + 1)
  }
  END {
    for (i = 1; i <= fcount; i++) {
      n = num[i]
      printf "finding=%s\tbucket=%s\tlatest=%s\theader=%s\n", n, buck[i], (n in text) ? text[n] : "none", head[i]
    }
  }
' "$review"
