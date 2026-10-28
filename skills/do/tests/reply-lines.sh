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

run final --door "$door" --claim "$claim" --review "$review" --order "$order"
check_lines "final refuses sources that match no shape: exit 3" 3 "$rc"
same "final refuses sources that match no shape with one failed line and no Reply line" "failed no-shape"

failed_claim="$(
  src failed_claim <<'EOF'
claim=failed
file=/home/dev/app/.scratch/feature/spec.integration.claim
reason=no-upstream
EOF
)"
run final --door "$door" --claim "$failed_claim" --release "$release" --review "$review" --order "$order"
check_lines "final refuses a claim that failed: exit 3" 3 "$rc"
same "final refuses a claim that failed with one failed line naming it and no Reply line" "failed --claim failed"

resume_door="$(
  src resume_door <<'EOF'
ticket=/home/dev/app/.scratch/feature/issues/03-export.md
root=/home/dev/app
status=resolved
spec_branch=spec/feature
build_repository=none
verdict=resume-final
EOF
)"
state="$(
  src state <<'EOF'
spec_branch=spec/feature
stop=review
verdict=land
EOF
)"
takeover_claim="$(
  src takeover_claim <<'EOF'
claim=claimed
spec_branch=spec/feature
takeover=yes
previous_ticket=/home/dev/app/.scratch/feature/issues/02-import.md
previous_claimed_at=2026-10-27T09:00:00Z
yielded_at=2026-10-27T10:00:00Z
EOF
)"
run final --door "$resume_door" --state "$state" --claim "$takeover_claim" --release "$release" --review "$review" --order "$order"
same "final on a resumed run opens with the state's verdict, its stop and the holder it took over from" \
  "Final integration: resumed from land, stop review, taken over from /home/dev/app/.scratch/feature/issues/02-import.md yielded at 2026-10-27T10:00:00Z
Open: none
Integration: rebased spec/feature onto main, 3 commits, no conflict
Review: landed on main at 1a2b3c4, 0 Act on Findings
spec/feature removed"

bare_state="$(
  src bare_state <<'EOF'
spec_branch=spec/feature
verdict=integration
EOF
)"
run final --door "$resume_door" --state "$bare_state" --claim "$claim" --release "$release" --review "$review" --order "$order"
check_lines "final on a resumed run with no stop and no takeover opens with the state's verdict alone" 0 "$rc" \
  "Final integration: resumed from integration"
check_absent "final on a resumed run with no stop and no takeover names neither" 0 "$rc" ", stop " "taken over from"

exit "$((fails > 0))"
