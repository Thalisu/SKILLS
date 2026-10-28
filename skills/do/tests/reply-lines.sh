#!/usr/bin/env bash
# reply-lines.sh: the contract of scripts/reply-lines.sh, the printer of a Reply's Final integration,
# repository, Spec landing and work-for-another-repository lines, from the state scripts' saved
# key=value outputs the session hands it as files.
# Run: bash skills/do/tests/reply-lines.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/reply-lines.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

run() {
  rc=0
  # shellcheck disable=SC2034  # lib.sh's check_lines and same read $out
  out="$(cd "$tmp" && bash "$script" "$@" 2>&1)" || rc=$?
}

src() { # $1 name, stdin its lines: a saved source file under $tmp, its path on stdout
  cat >"$tmp/$1"
  printf '%s\n' "$tmp/$1"
}

door="$(
  src door <<'EOF'
ticket=/home/dev/app/.scratch/feature/issues/03-export.md
root=/home/dev/app
title=Export
status=resolved
slug=export
spec_branch=spec/feature
build_repository=none
verdict=resolved
EOF
)"
claim="$(
  src claim <<'EOF'
claim=claimed
file=/home/dev/app/.scratch/feature/spec.integration.claim
spec=/home/dev/app/.scratch/feature/spec.md
spec_branch=spec/feature
takeover=no
EOF
)"
release="$(
  src release <<'EOF'
claim=released
spec_branch=spec/feature
removed=yes
EOF
)"
review="$(
  src review <<'EOF'
Integration: rebased spec/feature onto main, 3 commits, no conflict
Review: landed on main at 1a2b3c4, 0 Act on Findings
EOF
)"
order="$(
  src order <<'EOF'
ticket=/home/dev/app/.scratch/feature/issues/03-export.md
repositories=1
repository=none
repository_location=/home/dev/app
repository_here=yes
repository_state=landed
repository_ticket=/home/dev/app/.scratch/feature/issues/03-export.md
own=none
waits_for=none
next_landing=done
verdict=landed
EOF
)"

run final --door "$door" --claim "$claim" --release "$release" --review "$review" --order "$order"
check_lines "final on a landed Spec prints the review's lines as given, then the Spec branch removed" 0 "$rc"
same "final on a landed Spec prints the review's lines as given, then the Spec branch removed: the whole output" \
  "Integration: rebased spec/feature onto main, 3 commits, no conflict
Review: landed on main at 1a2b3c4, 0 Act on Findings
spec/feature removed"

first="$out"
run final --door "$door" --claim "$claim" --release "$release" --review "$review" --order "$order"
same "final prints the same lines on a second call with the same files" "$first"

exit "$((fails > 0))"
