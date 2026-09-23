#!/usr/bin/env bash
# review-token.sh: the contract of scripts/review-token.sh, the secret the review step mints for a
# run and the build step revokes before it forks a Builder. `resume-state.sh`'s marked() lets a
# Review beside the Ticket spare the next run a second review only when the `<Ticket>.review.marker`
# holds the token stored at <the clone's git common dir>/do/review-token/<slug>, so the mint has to
# reach that one file from the main checkout and from a worktree of it alike, the revoke has to
# leave nothing behind at the one moment a fork holds a shell in the worktree, and a slug is never
# a path: a `/` or a `..` in it would carry either write out of that folder, and a fork that reads a
# live token or guesses one forges the Review and marker pair that lands an unreviewed branch.
# Run: bash skills/do/tests/review-token.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../scripts/review-token.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

run() { # $1.. the script's arguments, from $PWD: its stdout in $out, its stderr in $err, its exit in $rc
  rc=0
  out="$(bash "$script" "$@" 2>"$tmp/err")" || rc=$?
  err="$(cat "$tmp/err")"
}
# The whole of stdout is the token: one value a fork cannot be bothered to guess, and no label,
# path or second line beside it, since the run pastes what it reads into the call it makes.
is_token() { # $1 the whole of stdout
  case "$1" in "" | *[!0-9a-f]*) return 1 ;; esac
  [ "${#1}" -ge 32 ]
}
stored_is() { # $1 the value the mint printed, $2 the token file: the file holds exactly that value
  [ -n "$1" ] && [ -f "$2" ] && [ "$(cat "$2")" = "$1" ]
}
differ() { # $1, $2: two mints that a fork cannot predict one from the other
  [ -n "$1" ] && [ "$1" != "$2" ]
}
revoked() { # $1 the token file: the call this follows exited 0 and left no token on disk
  [ "$rc" = 0 ] && [ ! -e "$1" ]
}
store_paths() { find "$common/do" -mindepth 1 -printf '%P %y\n' 2>/dev/null | sort; }
# A refused slug is refused whole: the build step feeds it a slug off a Ticket's file name, so a
# refusal that still wrote or still removed something would be the escape it was meant to stop.
refused() { # $1 label: exit 2, with the store, the live token and the clone's HEAD as they were
  local label="$1" why=""
  [ "$rc" = 2 ] || why="exit $rc, wanted 2"
  [ "$(store_paths)" = "$before" ] || why="$why; the store changed"
  stored_is "$live" "$livefile" || why="$why; the live token changed"
  [ "$(cat "$common/HEAD" 2>/dev/null)" = "$head" ] || why="$why; the clone's HEAD changed"
  if [ -z "$why" ]; then ok "$label"; else fail "$label ($why) $err"; fi
}

fresh project
printf 'base\n' >README.md
commit base
top="$PWD"
# Read the way ledger.sh and resume-state.sh read it, since the store being the same file for both
# sides is the whole contract.
common="$(git rev-parse --path-format=absolute --git-common-dir)"
store="$common/do/review-token"
livefile="$store/42-slice"
head="$(cat "$common/HEAD")"

echo "# review-token.sh new: a token nothing can guess, stored where the resume probe reads it"

run new 42-slice
check "minting a token for a run exits 0" 0 "$rc"
first="$out"
expect "the mint prints an unguessable token on stdout, and nothing else" is_token "$first"
expect "what the mint stored under the clone's git common dir is what it printed" \
  stored_is "$first" "$livefile"

run new 42-slice
second="$out"
expect "two mints for the same run never print the same value" differ "$second" "$first"
expect "the token on disk is the newest mint, so an earlier run's value never vouches again" \
  stored_is "$second" "$livefile"

echo "# review-token.sh: the main checkout and a worktree of it reach the one file"

g worktree add -q .claude/worktrees/do-run -b do/run
mkdir -p "$top/.claude/worktrees/do-run/src/deep"
cd "$top/.claude/worktrees/do-run/src/deep" || exit 1
run new run
expect "a mint from inside a worktree stores the token where resume-state.sh reads it back" \
  stored_is "$out" "$store/run"
cd "$top" || exit 1
run revoke run
expect "a revoke from the main checkout removes the token a worktree minted" revoked "$store/run"

echo "# review-token.sh revoke: no token on disk while a fork holds the worktree"

run revoke 42-slice
expect "revoking a run's token exits 0 and leaves nothing on disk for a fork to copy" \
  revoked "$livefile"
run revoke 42-slice
check "revoking a run that has no token exits 0, since the build step revokes on every run" 0 "$rc"

echo "# review-token.sh: a slug is never a path"

run new 42-slice
live="$out"
before="$(store_paths)"

run new ""
refused "the mint refuses an empty slug"
run revoke ""
refused "the revoke refuses an empty slug"

run new a/b
refused "the mint refuses a slug holding a /, which would write outside the store"
run revoke a/b
refused "the revoke refuses a slug holding a /"

run new ..
refused "the mint refuses a slug that is .., which names the store's own parent"
run revoke ..
refused "the revoke refuses a slug that is .."

run new ../review-token/42-slice
refused "the mint refuses a .. slug that climbs back onto a live token"
run revoke ../review-token/42-slice
refused "the revoke refuses a .. slug that climbs back onto a live token"

run new ../../HEAD
refused "the mint refuses a .. slug that reaches the clone's HEAD"
run revoke ../../HEAD
refused "the revoke refuses a .. slug that would delete the clone's HEAD"

echo "# review-token.sh: usage"

run mint 42-slice
check "a mode that is neither new nor revoke is a usage error" 2 "$rc"
run
check "no argument is a usage error" 2 "$rc"
run new
check "a mode with no slug is a usage error" 2 "$rc"
run new 42-slice extra
check "an argument past the slug is a usage error" 2 "$rc"

mkdir -p "$tmp/plain" && cd "$tmp/plain" || exit 1
run new 42-slice
check "outside a git repository there is no store to mint into, and the mint is refused" 2 "$rc"
run revoke 42-slice
check "outside a git repository the revoke is refused" 2 "$rc"

echo
[ "$fails" = 0 ] && echo "all passed" || {
  echo "$fails failed"
  exit 1
}
