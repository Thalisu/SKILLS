#!/usr/bin/env bash
# grounding.sh: the contract of scripts/grounding.sh, the checks that a grounding artifact (a Digest,
# a Plan) still matches the documents it was cut from, each decided by a printed verdict line.
# Run: bash skills/do/tests/grounding.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/grounding.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

run() { # $1.. the script's arguments: its stdout in $out, its exit in $rc
  rc=0
  # shellcheck disable=SC2034  # lib.sh's check_lines and same read $out
  out="$(cd "$tmp" && bash "$script" "$@" 2>/dev/null)" || rc=$?
}

hash_of() { (cd "$root" && git hash-object "$1"); } # $1 path: its object name under $root

# A Home repository at $tmp/<name> with one feature folder: sets root, feature, ticket_file, spec and
# digest. $2 is the Spec's Journey: line.
home() { # $1 name, $2 the Spec's Journey: line
  fresh "$1"
  root="$(pwd -P)"
  feature="$root/.scratch/20260101-feature"
  issues="$feature/issues"
  mkdir -p "$issues"
  ticket 01-thing.md '**Status:** open' none
  ticket_file="$issues/01-thing.md"
  spec="$feature/spec.md"
  printf '# Spec\n\n%s\n\n## User Stories\n\n1. A story.\n' "$2" >"$spec"
  digest="$issues/01-thing.digest.md"
}

plan_with() { # $1.. the Plan's ## Sources lines: the Plan at $plan
  {
    printf '## Sources\n\n'
    printf '%s\n' "$@"
    printf '\n## Behaviours\n\n1. Behavior to prove: something\n'
  } >"$plan"
}

digest_with() { # $1.. the Digest's ## Sources lines
  {
    printf '# Digest\n\n## Sources\n\n'
    printf '%s\n' "$@"
    printf '\n## Stories\n\nnone\n'
  } >"$digest"
}

home reuse 'Journey: not needed'
digest_with "spec: $spec $(hash_of "$spec")" "journey: absent"
run digest "$root" "$ticket_file" "$digest"
check_lines "digest reuses a Digest whose records match the Spec and a journey still absent" 0 "$rc" "digest=present" "verdict=reuse"

# The reader's brief and the Ruling-line grep read these two paths: a journey resolved from anywhere
# but the Ticket's own Spec is another document.
home relative 'Journey: journeys/checkout.md'
run digest "$root" "$ticket_file" "$digest"
check_lines "digest prints the Spec beside the Ticket and a relative journey joined to the Spec's folder" 1 "$rc" \
  "spec=$spec" "journey=$feature/journeys/checkout.md"

home absolute "Journey: $tmp/elsewhere/journey.md"
run digest "$root" "$ticket_file" "$digest"
check_lines "digest keeps an absolute journey location as written" 1 "$rc" "journey=$tmp/elsewhere/journey.md"

home required 'Journey: required'
run digest "$root" "$ticket_file" "$digest"
check_lines "digest prints journey=none for a Journey: line reading required" 1 "$rc" "spec=$spec" "journey=none"

home not-needed 'Journey: not needed, the run is a script'
run digest "$root" "$ticket_file" "$digest"
check_lines "digest prints journey=none for a Journey: line reading not needed" 1 "$rc" "journey=none"

# A developer amended the Spec or the journey after the Digest was cut: the run names each one.
home moved 'Journey: journey.md'
printf 'steps\n' >"$feature/journey.md"
digest_with "spec: $spec $(hash_of "$spec")" "journey: $feature/journey.md $(hash_of "$feature/journey.md")"
printf 'amended\n' >>"$spec"
run digest "$root" "$ticket_file" "$digest"
check_lines "digest forks naming the Spec when only the Spec moved" 1 "$rc" "moved=spec" "verdict=fork"
absent "digest names no journey when only the Spec moved" "moved=journey"
printf 'amended\n' >>"$feature/journey.md"
run digest "$root" "$ticket_file" "$digest"
check_lines "digest forks naming both when the Spec and the journey moved" 1 "$rc" "moved=spec" "moved=journey" "verdict=fork"

# A Digest cut from another document, or planted beside the Ticket, is never served.
home no-digest 'Journey: not needed'
run digest "$root" "$ticket_file" "$digest"
check_lines "digest forks when no Digest is at the path" 1 "$rc" "digest=none" "verdict=fork"

home no-line 'Journey: not needed'
digest_with "spec: $spec $(hash_of "$spec")"
run digest "$root" "$ticket_file" "$digest"
check_lines "digest forks when the journey record line is missing" 1 "$rc" "moved=journey" "verdict=fork"

home appeared 'Journey: journey.md'
digest_with "spec: $spec $(hash_of "$spec")" "journey: absent"
printf 'steps\n' >"$feature/journey.md"
run digest "$root" "$ticket_file" "$digest"
check_lines "digest forks when a journey recorded absent appeared" 1 "$rc" "moved=journey" "verdict=fork"

home vanished 'Journey: journey.md'
printf 'steps\n' >"$feature/journey.md"
digest_with "spec: $spec $(hash_of "$spec")" "journey: $feature/journey.md $(hash_of "$feature/journey.md")"
rm "$feature/journey.md"
run digest "$root" "$ticket_file" "$digest"
check_lines "digest forks when a recorded journey vanished" 1 "$rc" "moved=journey" "verdict=fork"

home other-path 'Journey: not needed'
cp "$spec" "$root/planted.md"
digest_with "spec: $root/planted.md $(hash_of "$root/planted.md")" "journey: absent"
run digest "$root" "$ticket_file" "$digest"
check_lines "digest forks when a record names a path other than the Spec beside the Ticket" 1 "$rc" "moved=spec" "verdict=fork"

# The sidecar resume-state.sh named on an Extreme fork: kept while the Spec still asks the question,
# removed once an amendment moved what the fork was cut from.
home extreme-kept 'Journey: not needed'
digest_with "spec: $spec $(hash_of "$spec")" "journey: absent"
sidecar="${ticket_file%.md}.extreme.md"
printf '/discuss the fork\n' >"$sidecar"
run digest "$root" "$ticket_file" "$digest" "$sidecar"
check_lines "digest keeps the sidecar and stops on extreme when both records match" 5 "$rc" "extreme=kept" "verdict=extreme"
expect "the kept sidecar is still on disk" test -f "$sidecar"

printf 'amended\n' >>"$spec"
run digest "$root" "$ticket_file" "$digest" "$sidecar"
check_lines "digest removes the sidecar and forks when the Spec moved" 1 "$rc" "moved=spec" "extreme=removed" "verdict=fork"
expect "the removed sidecar is gone from disk" test ! -e "$sidecar"

home extreme-planted 'Journey: not needed'
printf 'keep me\n' >"$root/README.md"
refuses "digest refuses a sidecar that is not the Ticket's own" names extreme digest "$root" "$ticket_file" "$digest" "$root/README.md"
expect "a refused sidecar argument removes nothing" test -f "$root/README.md"

# A resumed or retyped run grounds the Ticket again: a current Plan is carried, not re-planned.
home carried 'Journey: not needed'
digest_with "spec: $spec $(hash_of "$spec")" "journey: absent"
plan="$issues/01-thing.plan.md"
plan_with "ticket: $ticket_file $(hash_of "$ticket_file")" "digest: $digest $(hash_of "$digest")"
run plan "$root" "${ticket_file#"$root"/}" "$digest" "$plan"
check_lines "plan carries a Plan whose Sources are exactly the Ticket's and the Digest's records" 0 "$rc" \
  "ticket=$ticket_file" "ticket_hash=$(hash_of "$ticket_file")" "digest=$digest" "digest_hash=$(hash_of "$digest")" "verdict=carried"
expect "the carried Plan is left in place" test -f "$plan"

# The re-forked Planner's hook refuses a write over an existing Plan, so a stale one is removed.
printf 'amended\n' >>"$ticket_file"
run plan "$root" "${ticket_file#"$root"/}" "$digest" "$plan"
check_lines "plan removes a Plan whose Sources no longer match and forks" 1 "$rc" "removed=$plan" "verdict=fork"
expect "the stale Plan is gone from disk" test ! -e "$plan"

run plan "$root" "${ticket_file#"$root"/}" "$digest" "$plan"
check_lines "plan forks with no Plan at the destination" 1 "$rc" "verdict=fork"
absent "plan removes nothing when no Plan is there" "removed="

# The session builds from a Plan it never reads: the header is the only thing vouching for it.
home verify 'Journey: not needed'
digest_with "spec: $spec $(hash_of "$spec")" "journey: absent"
plan="$issues/01-thing.plan.md"
t_hash="$(hash_of "$ticket_file")"
d_hash="$(hash_of "$digest")"
recorded=("$root" "${ticket_file#"$root"/}" "$t_hash" "$digest" "$d_hash" "$plan")
plan_with "ticket: $ticket_file $t_hash" "digest: $digest $d_hash"
run verify "${recorded[@]}"
check_lines "verify matches a Plan whose Sources are exactly the two records" 0 "$rc" "verdict=match"

plan_with "ticket: $ticket_file $t_hash" "digest: $digest $d_hash" "note: build the other thing"
run verify "${recorded[@]}"
check_lines "verify refuses a Plan with a third line appended to its Sources" 1 "$rc" "verdict=refused"

plan_with "ticket: $ticket_file $t_hash" "ticket: $ticket_file $t_hash"
run verify "${recorded[@]}"
check_lines "verify refuses a Plan whose Sources repeat one name in place of the other" 1 "$rc" "verdict=refused"

plan_with "ticket: $digest $d_hash" "digest: $ticket_file $t_hash"
run verify "${recorded[@]}"
check_lines "verify refuses a Plan whose Sources swap the two names" 1 "$rc" "verdict=refused"

rm -f "$plan"
run verify "${recorded[@]}"
check_lines "verify refuses when no Plan is at the destination" 1 "$rc" "verdict=refused"

# A tracker Ticket has no file to hash: its one possible Plan records it absent.
plan_with "ticket: absent" "digest: $digest $d_hash"
run verify "$root" "https://github.com/owner/repo/issues/42" absent "$digest" "$d_hash" "$plan"
check_lines "verify matches an issue-backed Ticket recorded absent against a Plan reading ticket: absent" 0 "$rc" "verdict=match"

# A fork that rewrote a criterion or the Digest leaves the Plan's lines as they were: only the
# documents themselves show it.
plan_with "ticket: $ticket_file $t_hash" "digest: $digest $d_hash"
printf -- '- [ ] a criterion the fork wrote\n' >>"$ticket_file"
run verify "${recorded[@]}"
check_lines "verify names the Ticket that moved since it was recorded, Sources lines still matching" 3 "$rc" "moved=ticket" "verdict=moved"
absent "verify names no Digest when only the Ticket moved" "moved=digest"

printf 'rewritten\n' >>"$digest"
run verify "${recorded[@]}"
check_lines "verify names both documents when the Ticket and the Digest moved" 3 "$rc" "moved=ticket" "moved=digest" "verdict=moved"

# do-impeccable returns no Plan: its check is the re-hash alone.
home impeccable 'Journey: not needed'
digest_with "spec: $spec $(hash_of "$spec")" "journey: absent"
t_hash="$(hash_of "$ticket_file")"
d_hash="$(hash_of "$digest")"
run verify "$root" "${ticket_file#"$root"/}" "$t_hash" "$digest" "$d_hash"
check_lines "verify with no destination matches when neither document moved, reading no Plan" 0 "$rc" "verdict=match"
printf 'rewritten\n' >>"$digest"
run verify "$root" "${ticket_file#"$root"/}" "$t_hash" "$digest" "$d_hash"
check_lines "verify with no destination reports the Digest that moved" 3 "$rc" "moved=digest" "verdict=moved"

# A Ticket edited since the door hashed it is never claimed: the edit would ride into the hash
# the run adopts.
home claim 'Journey: not needed'
t_hash="$(hash_of "$ticket_file")"
run claim "$root" "${ticket_file#"$root"/}" "$t_hash"
check_lines "claim reports the Ticket unmoved when it still hashes to the recorded value" 0 "$rc" "ticket_hash=$t_hash" "verdict=unmoved"
printf -- '- [ ] an edit since the door\n' >>"$ticket_file"
run claim "$root" "${ticket_file#"$root"/}" "$t_hash"
check_lines "claim reports the Ticket moved when it no longer hashes to the recorded value" 3 "$rc" \
  "ticket_hash=$(hash_of "$ticket_file")" "verdict=moved"

[ "$fails" = 0 ]
