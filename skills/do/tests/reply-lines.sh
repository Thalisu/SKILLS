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

taken="$(
  src taken <<'EOF'
claim=taken
file=/home/dev/app/.scratch/feature/spec.integration.claim
holder_ticket=/home/dev/app/.scratch/feature/issues/02-import.md
claimed_at=2026-10-27T09:00:00Z
yield_command=bash final-claim.sh yield /home/dev/app/.scratch/feature/issues/02-import.md
EOF
)"
run final --door "$door" --claim "$taken" --order "$order"
check_lines "final on a claim held by another run: exit 0" 0 "$rc"
same "final on a claim held by another run names the holder's Ticket and claim time, and this Ticket as landed" \
  "Final integration: the Spec is being integrated by another run, /home/dev/app/.scratch/feature/issues/02-import.md since 2026-10-27T09:00:00Z; Ticket 03 landed and reads resolved"

run final --door "$resume_door" --state "$state" --claim "$taken" --order "$order"
same "final on a resume whose claim another run holds reads not resumed, with no resumed opener" \
  "Final integration: not resumed, its claim is held by /home/dev/app/.scratch/feature/issues/02-import.md since 2026-10-27T09:00:00Z"

wait_order="$(
  src wait_order <<'EOF'
ticket=/home/dev/web/.scratch/feature/issues/04-show.md
repositories=2
repository=api
repository_location=/home/dev/api
repository_here=no
repository_state=unlanded
repository_ticket=/home/dev/app/.scratch/feature/issues/03-export.md
repository=web
repository_location=/home/dev/web
repository_here=yes
repository_state=unlanded
repository_ticket=/home/dev/app/.scratch/feature/issues/04-show.md
own=web
waits_for=api
waits_for_location=/home/dev/api
next_landing=api
next_landing_location=/home/dev/api
next_landing_ticket=/home/dev/app/.scratch/feature/issues/03-export.md
verdict=wait
EOF
)"
run final --door "$door" --order "$wait_order"
check_lines "final with no claim on a record that waits: exit 0" 0 "$rc"
same "final with no claim on a record that waits says the feature is complete and the session's repository waits for its provider, at its location, then Open: none" \
  "Final integration: not started, the feature is complete and web waits for api to land, at /home/dev/api
Open: none"

run final --door "$resume_door" --state "$state" --order "$wait_order"
check_lines "final on a landing command typed too early: exit 0" 0 "$rc"
same "final on a landing command typed too early names the repository that has to land first, with no resumed line" \
  "Final integration: not started, api has to land first"

landed_order="$(
  src landed_order <<'EOF'
ticket=/home/dev/api/.scratch/feature/issues/03-export.md
repositories=2
repository=api
repository_location=/home/dev/api
repository_here=yes
repository_state=landed
repository_ticket=/home/dev/app/.scratch/feature/issues/03-export.md
repository=web
repository_location=/home/dev/web
repository_here=no
repository_state=unlanded
repository_ticket=/home/dev/app/.scratch/feature/issues/04-show.md
own=api
waits_for=none
next_landing=web
next_landing_location=/home/dev/web
next_landing_ticket=/home/dev/app/.scratch/feature/issues/04-show.md
verdict=landed
EOF
)"
run final --door "$door" --order "$landed_order"
check_lines "final on a repository that already landed, with another still to land: exit 0" 0 "$rc"
same "final on a repository that already landed, with another still to land, says it already landed" \
  "Final integration: not started, api already landed"

yielded="$(
  src yielded <<'EOF'
claim=yielded
file=/home/dev/app/.scratch/feature/spec.integration.claim
EOF
)"
stop_order="$(
  src stop_order <<'EOF'
ticket=/home/dev/web/.scratch/feature/issues/04-show.md
repositories=2
repository=api
repository_location=/home/dev/api
repository_here=no
repository_state=landed
repository_ticket=/home/dev/app/.scratch/feature/issues/03-export.md
repository=web
repository_location=/home/dev/web
repository_here=yes
repository_state=unlanded
repository_ticket=/home/dev/app/.scratch/feature/issues/04-show.md
own=web
waits_for=none
next_landing=web
next_landing_location=/home/dev/web
next_landing_ticket=/home/dev/app/.scratch/feature/issues/04-show.md
verdict=land
EOF
)"
reason="not landed: Finding 1 not fixed or not verified"
run final --door "$door" --claim "$claim" --yield "$yielded" --order "$stop_order" --reason "$reason"
check_lines "final on a yielded claim: exit 0" 0 "$rc"
same "final on a yielded claim prints the stop with its reason, then Landed and Still to land across repositories" \
  "Final integration: stopped: $reason
Landed: api
Still to land: web"

run final --door "$resume_door" --state "$state" --claim "$takeover_claim" --yield "$yielded" --order "$stop_order" --reason "$reason"
check_lines "final on a yielded claim it had taken over reads stopped again" 0 "$rc" \
  "Final integration: stopped again: $reason" "Landed: api" "Still to land: web"

run final --door "$resume_door" --state "$state" --claim "$claim" --yield "$yielded" --order "$stop_order" --reason "$reason"
check_absent "final on a yielded claim with no takeover never reads stopped again, even on a resumed door" 0 "$rc" "stopped again"

run final --door "$door" --claim "$claim" --yield "$yielded" --order "$order" --reason "$reason"
same "final on a yielded claim of a feature of one repository prints the stop alone" \
  "Final integration: stopped: $reason"

three_order="$(
  src three_order <<'EOF'
ticket=/home/dev/api/.scratch/feature/issues/03-export.md
repositories=3
repository=api
repository_location=/home/dev/api
repository_here=no
repository_state=landed
repository_ticket=/home/dev/app/.scratch/feature/issues/03-export.md
repository=web
repository_location=/home/dev/web
repository_here=no
repository_state=unlanded
repository_ticket=/home/dev/app/.scratch/feature/issues/04-show.md
repository=jobs
repository_location=/home/dev/jobs
repository_here=no
repository_state=unreadable
repository_reason=missing
repository_ticket=/home/dev/app/.scratch/feature/issues/05-jobs.md
own=api
waits_for=none
next_landing=web
next_landing_location=/home/dev/web
next_landing_ticket=/home/dev/app/.scratch/feature/issues/04-show.md
verdict=landed
EOF
)"
run repositories --door "$door" --order "$three_order"
check_lines "repositories on a feature across repositories: exit 0" 0 "$rc"
same "repositories prints Landed and Still to land in the record's order, an unreadable group with its reason, then each repository still to land as a place and its /do command" \
  "Landed: api
Still to land: web, jobs (unreadable: missing)
web: open a session in /home/dev/web
/do /home/dev/app/.scratch/feature/issues/04-show.md
jobs: open a session in /home/dev/jobs
/do /home/dev/app/.scratch/feature/issues/05-jobs.md"

done_order="$(
  src done_order <<'EOF'
ticket=/home/dev/web/.scratch/feature/issues/04-show.md
repositories=2
repository=api
repository_location=/home/dev/api
repository_here=no
repository_state=landed
repository_ticket=/home/dev/app/.scratch/feature/issues/03-export.md
repository=web
repository_location=/home/dev/web
repository_here=yes
repository_state=landed
repository_ticket=/home/dev/app/.scratch/feature/issues/04-show.md
own=web
waits_for=none
next_landing=done
verdict=landed
EOF
)"
run repositories --door "$door" --claim "$claim" --release "$release" --order "$done_order"
check_lines "repositories at the last landing: exit 0" 0 "$rc"
same "repositories at the last landing says every repository landed and hands over no command" \
  "Landed: api, web
Still to land: none
Every repository of the feature landed"

exit "$((fails > 0))"
