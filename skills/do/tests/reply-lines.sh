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

run repositories --door "$door" --order "$wait_order"
same "repositories names the session's own group as this session's repository, once its provider landed, while waiting" \
  "Landed: none
Still to land: api, web
api: open a session in /home/dev/api
/do /home/dev/app/.scratch/feature/issues/03-export.md
web: this session's repository, once api landed
/do /home/dev/app/.scratch/feature/issues/04-show.md"

unlisted_order="$(
  src unlisted_order <<'EOF'
ticket=/home/dev/api/.scratch/feature/issues/03-export.md
repositories=2
repository=api
repository_location=/home/dev/api
repository_here=yes
repository_state=landed
repository_ticket=/home/dev/app/.scratch/feature/issues/03-export.md
repository=web
repository_location=unlisted
repository_here=no
repository_state=unreadable
repository_reason=unlisted
repository_ticket=/home/dev/app/.scratch/feature/issues/04-show.md
own=api
waits_for=none
next_landing=web
next_landing_location=unlisted
next_landing_ticket=/home/dev/app/.scratch/feature/issues/04-show.md
verdict=landed
EOF
)"
run repositories --door "$door" --order "$unlisted_order"
check_lines "repositories names an unlisted location as one the Spec's list does not hold" 0 "$rc" \
  "web: the Spec's ## Repositories list holds no location for it"
absent "repositories hands over no unlisted location to open a session in" "open a session in unlisted"

run repositories --door "$resume_door" --order "$wait_order"
same "repositories out of order prints only the repository that has to land first, its place and its /do" \
  "api: open a session in /home/dev/api
/do /home/dev/app/.scratch/feature/issues/03-export.md"

run repositories --door "$door" --claim "$claim" --release "$release" --order "$order"
check_lines "repositories on a feature of one repository: exit 0" 0 "$rc"
same "repositories on a feature of one repository prints no line" ""

run repositories --door "$door" --claim "$taken" --order "$stop_order"
check_lines "repositories on a held claim: exit 0" 0 "$rc"
same "repositories on a held claim prints no line" ""

fresh app
printf 'base\n' >README.md
commit base
main_checkout="$(pwd -P)"
cd "$tmp" || exit 1
run_in() { # $1 the directory the script runs from, $2.. its arguments
  local dir="$1"
  shift
  rc=0
  out="$(cd "$dir" && bash "$script" "$@" 2>&1)" || rc=$?
}

home_door="$(
  src home_door <<EOF
ticket=$main_checkout/.scratch/feature/issues/03-export.md
root=$main_checkout
status=resolved
spec_branch=spec/feature
build_repository=none
verdict=resolved
EOF
)"
land="$(src land <<<"landed 1a2b3c4d5e6f")"
check_open="$(
  src check_open <<EOF
ticket=$main_checkout/.scratch/feature/issues/03-export.md
spec_branch=spec/feature
open=02 claimed $main_checkout/.scratch/feature/issues/02-import.md
open=04 ready-for-agent $main_checkout/.scratch/feature/issues/04-show.md
verdict=incomplete
EOF
)"
run_in "$main_checkout" landing --door "$home_door" --land "$land" --check "$check_open"
check_lines "landing on a Ticket that landed: exit 0" 0 "$rc"
same "landing prints the landed line, the Review none line and one Open entry per open Ticket with its status" \
  "landed at 1a2b3c4d5e6f on spec/feature
Review: none, the Spec is reviewed once its last Ticket lands
Open: 02-import (claimed), 04-show (ready-for-agent)"

checked_out="$(src checked_out <<<"checked-out /home/dev/app/.claude/worktrees/spec-feature")"
run_in "$main_checkout" landing --door "$home_door" --land "$checked_out" --check "$check_open"
same "landing on a Spec branch checked out in a worktree says it did not land and where it is checked out, with no Open line" \
  "not landed: spec/feature is checked out in /home/dev/app/.claude/worktrees/spec-feature
Review: none, the Spec is reviewed once its last Ticket lands"

moved="$(src moved <<<"moved 9f8e7d6c5b4a")"
run_in "$main_checkout" landing --door "$home_door" --land "$moved"
check_lines "landing on a Spec branch that moved quotes the land line whole" 0 "$rc" "not landed: moved 9f8e7d6c5b4a"

failed_land="$(src failed_land <<<"failed spec/feature does not resolve")"
run_in "$main_checkout" landing --door "$home_door" --land "$failed_land"
check_lines "landing that failed quotes the land line whole" 0 "$rc" "not landed: failed spec/feature does not resolve"
absent "landing that failed never reads landed at" "landed at"

mkdir -p "$tmp/home"
home_root="$(cd "$tmp/home" && pwd -P)"
build_door="$(
  src build_door <<EOF
ticket=$home_root/.scratch/feature/issues/03-export.md
root=$home_root
status=resolved
spec_branch=spec/feature
build_repository=billing
verdict=resolved
EOF
)"
run_in "$main_checkout" landing --door "$build_door" --land "$land"
check_lines "landing from a Build repository names where it built and where its artifacts are" 0 "$rc" \
  "Repositories: built in billing ($main_checkout), artifacts in $home_root"

unnamed_door="$(
  src unnamed_door <<EOF
ticket=$home_root/.scratch/feature/issues/03-export.md
root=$home_root
status=resolved
spec_branch=spec/feature
build_repository=none
verdict=resolved
EOF
)"
run_in "$main_checkout" landing --door "$unnamed_door" --land "$land"
check_lines "landing from a Build repository whose name reads none leaves the name out" 0 "$rc" \
  "Repositories: built in $main_checkout, artifacts in $home_root"

wt="$(branch_worktree "$main_checkout" export)"
run_in "$wt" landing --door "$home_door" --land "$land"
check_absent "landing from a worktree of the checkout that holds the artifacts prints no Repositories line" 0 "$rc" "Repositories:"

check_complete="$(
  src check_complete <<'EOF'
spec_branch=spec/feature
open=none
verdict=complete
EOF
)"
run_in "$main_checkout" landing --door "$home_door" --land "$land" --check "$check_complete"
same "landing on a run whose Completion check read complete prints Open: none" \
  "landed at 1a2b3c4d5e6f on spec/feature
Review: none, the Spec is reviewed once its last Ticket lands
Open: none"

check_none="$(
  src check_none <<'EOF'
spec_branch=spec/feature
open=none
verdict=wait
EOF
)"
run_in "$main_checkout" landing --door "$home_door" --land "$land" --check "$check_none"
check_absent "landing with nothing open on a check that did not read complete prints no Open line" 0 "$rc" "Open:"

plan_door="$(
  src plan_door <<'EOF'
ticket=/home/dev/app/.scratch/feature/issues/03-export.md
root=/home/dev/app
status=ready-for-agent
spec_branch=spec/feature
build_repository=none
verdict=ready
EOF
)"
finding_added="$(
  src finding_added <<'EOF'
spec=/home/dev/app/.scratch/feature/spec.md
repository=orders-service
listed=no
list=added
line=written
home=/home/dev/app
home_name=app
here=yes
EOF
)"
run elsewhere --door "$plan_door" "$finding_added" "show the hold"
check_lines "elsewhere on a finding that added the repository: exit 0" 0 "$rc"
same "elsewhere prints the Plan-step stop: the behaviour and repository, what was written, the status, the Yours line and /tickets relative to the Home repository" \
  "Stopped at the Plan, before anything was built: \"show the hold\" has no place in this repository. It belongs to orders-service.
Written into the Spec (.scratch/feature/spec.md): orders-service added to its repositories list, and one line naming the behaviour as moved by the run on Ticket 03.
Ticket 03 still reads ready-for-agent.
Yours: outward: cut the moved behaviour for orders-service with the command below, then run /do on this Ticket again
/tickets .scratch/feature/spec.md"

finding_unchanged="$(
  src finding_unchanged <<'EOF'
spec=/home/dev/app/.scratch/feature/spec.md
repository=orders-service
listed=yes
list=unchanged
line=written
home=/home/dev/app
home_name=app
here=yes
EOF
)"
run elsewhere --door "$plan_door" "$finding_unchanged" "show the hold"
check_lines "elsewhere on a repository already listed names the one line and says it was already listed" 0 "$rc" \
  "Written into the Spec (.scratch/feature/spec.md): one line naming the behaviour as moved by the run on Ticket 03; orders-service was already in its repositories list."

finding_present="$(
  src finding_present <<'EOF'
spec=/home/dev/app/.scratch/feature/spec.md
repository=orders-service
listed=yes
list=unchanged
line=present
home=/home/dev/app
home_name=app
here=yes
EOF
)"
run elsewhere --door "$plan_door" "$finding_present" "show the hold"
check_lines "elsewhere on a finding line an earlier run wrote says the line was already there" 0 "$rc" \
  "Written into the Spec (.scratch/feature/spec.md): the line naming the behaviour as moved, already there, written by an earlier run on Ticket 03; orders-service was already in its repositories list."

finding_unknown="$(
  src finding_unknown <<'EOF'
spec=/home/dev/app/.scratch/feature/spec.md
repository=orders-service
listed=no
list=no-location
line=written
home=/home/dev/app
home_name=app
here=yes
EOF
)"
run elsewhere --door "$plan_door" "$finding_unknown" "show the hold"
same "elsewhere on a finding with no location marks it not known, hands the location to the developer and appends it to the command" \
  "Stopped at the Plan, before anything was built: \"show the hold\" has no place in this repository. It belongs to orders-service.
Written into the Spec (.scratch/feature/spec.md): one line naming the behaviour as moved by the run on Ticket 03, with the location of orders-service marked as not known. No entry was added to its repositories list.
Ticket 03 still reads ready-for-agent.
Yours: outward: the location of orders-service on this machine is the one thing you supply: type it in the command below in place of <its absolute location on this machine>, with no file to edit by hand, then run /do on this Ticket again
/tickets .scratch/feature/spec.md orders-service: <its absolute location on this machine>"

finding_away="$(
  src finding_away <<'EOF'
spec=/home/dev/app/.scratch/feature/spec.md
repository=orders-service
listed=no
list=added
line=written
home=/home/dev/app
home_name=app
here=no
EOF
)"
run elsewhere --door "$plan_door" "$finding_away" "show the hold"
same "elsewhere stopped outside the Home repository names it as the place to open a session in, before the command" \
  "Stopped at the Plan, before anything was built: \"show the hold\" has no place in this repository. It belongs to orders-service.
Written into the Spec (.scratch/feature/spec.md): orders-service added to its repositories list, and one line naming the behaviour as moved by the run on Ticket 03.
Ticket 03 still reads ready-for-agent.
Yours: outward: cut the moved behaviour for orders-service with the command below, then run /do on this Ticket again
app: open a session in /home/dev/app
/tickets .scratch/feature/spec.md"

finding_nameless="$(
  src finding_nameless <<'EOF'
spec=/home/dev/app/.scratch/feature/spec.md
repository=orders-service
listed=no
list=added
line=written
home=/home/dev/app
home_name=none
here=no
EOF
)"
run elsewhere --door "$plan_door" "$finding_nameless" "show the hold"
check_lines "elsewhere names a Home repository with no name by its location alone" 0 "$rc" \
  "Open a session in /home/dev/app"

g -C "$main_checkout" branch spec/feature
printf 'one\n' >"$wt/one.txt"
g -C "$wt" add one.txt && g -C "$wt" commit -qm one
printf 'two\n' >"$wt/two.txt"
g -C "$wt" add two.txt && g -C "$wt" commit -qm two
run_in "$main_checkout" elsewhere --door "$plan_door" --build "$wt" "$finding_added" "show the hold"
same "elsewhere --build opens at the build step, reads the Ticket as claimed and names the worktree, its branch and the commits kept" \
  "Stopped at the build step: \"show the hold\" has no place in this repository. It belongs to orders-service.
Written into the Spec (.scratch/feature/spec.md): orders-service added to its repositories list, and one line naming the behaviour as moved by the run on Ticket 03.
Ticket 03 still reads claimed.
Kept for the next /do on this Ticket: $wt on do/export, 2 commits.
Yours: outward: cut the moved behaviour for orders-service with the command below, then run /do on this Ticket again
/tickets .scratch/feature/spec.md"

finding_second="$(
  src finding_second <<'EOF'
spec=/home/dev/app/.scratch/feature/spec.md
repository=billing-service
listed=yes
list=unchanged
line=written
home=/home/dev/app
home_name=app
here=yes
EOF
)"
run elsewhere --door "$plan_door" "$finding_added" "show the hold" "$finding_second" "bill the hold"
same "elsewhere with two findings prints each item's two lines, then the status, Yours and command lines once" \
  "Stopped at the Plan, before anything was built: \"show the hold\" has no place in this repository. It belongs to orders-service.
Written into the Spec (.scratch/feature/spec.md): orders-service added to its repositories list, and one line naming the behaviour as moved by the run on Ticket 03.
Stopped at the Plan, before anything was built: \"bill the hold\" has no place in this repository. It belongs to billing-service.
Written into the Spec (.scratch/feature/spec.md): one line naming the behaviour as moved by the run on Ticket 03; billing-service was already in its repositories list.
Ticket 03 still reads ready-for-agent.
Yours: outward: cut the moved behaviour for orders-service, billing-service with the command below, then run /do on this Ticket again
/tickets .scratch/feature/spec.md"

finding_other="$(
  src finding_other <<'EOF'
spec=/home/dev/app/.scratch/other/spec.md
repository=billing-service
listed=yes
list=unchanged
line=written
home=/home/dev/app
home_name=app
here=yes
EOF
)"
run elsewhere --door "$plan_door" "$finding_added" "show the hold" "$finding_other" "bill the hold"
check_lines "elsewhere refuses findings that name different Specs: exit 3" 3 "$rc"
same "elsewhere refuses findings that name different Specs with one failed line and no Reply line" "failed findings disagree"

# reply.md hands each of these groups of lines to the script and composes none of them itself: a
# template or a selection rule left beside the call is the session composing the lines again.
reply="$here/../references/reply.md"
item29="$(item_holding "$reply" '[0-9]+\.' '**Spec landing lines.**')"
item30="$(item_holding "$reply" '[0-9]+\.' '**Final integration lines.**')"
elsewhere_passage="$(paragraph_with "$reply" 'stopped on work for another repository')"
out="$item29"
check "reply.md's Spec landing lines are the ones reply-lines.sh landing printed" 0 0 'reply-lines.sh landing'
out="$item30"
check "reply.md's Final integration lines are the ones reply-lines.sh final and repositories printed" 0 0 \
  'reply-lines.sh final' 'reply-lines.sh repositories'
out="$elsewhere_passage"
check "reply.md's work-for-another-repository stop is the lines reply-lines.sh elsewhere printed" 0 0 'reply-lines.sh elsewhere'
out="$(cat "$reply")"
check_absent "reply.md carries no template and no selection rule for the lines reply-lines.sh prints" 0 0 \
  'Repositories: built in <' 'Final integration: not started, <' 'Stopped at the Plan, before anything was built:' \
  'Written into the Spec (<spec>)' 'takeover=yes' 'Every repository of the feature landed'

exit "$((fails > 0))"
