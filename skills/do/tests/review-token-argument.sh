#!/usr/bin/env bash
# review-token-argument.sh: the secret the review step stores and hands to `do-code-review`, which
# is the only thing tying a Review beside a Ticket to a review this run actually paid for.
# `resume-state.sh`'s `marked()` reads a token under the clone's git dir and lets a Review spare the
# next run a second review only when the marker beside it holds that same value, treating a missing
# token as a miss. So the writer's side has to be written down in the two files that own it: where
# `do` stores the token and how it reaches the call (mechanics.md's `## The review`), and that the
# marker the reviewer writes is that token and that a call naming no token writes no marker at all
# (do-code-review's AGENT.md). Without the writer's side every real review leaves a Review no resume
# trusts, and a `/do-code-review` a developer ran by hand would vouch for itself.
# Run: bash skills/do/tests/review-token-argument.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
mech="$here/../references/mechanics.md"
builder="$here/../references/builder.md"
agent="$here/../../do-code-review/AGENT.md"
ticket="$here/../references/ticket.md"
fails=0

echo "# mechanics.md / ## The review: the run stores a token and sends it to the call"

# The token is the subject of whichever paragraphs of the review section carry it, and "after the
# Gate" is already said of the ledger argument elsewhere in the same section: read the token's own
# paragraphs alone, flattened the way $flat is, so a check about the token cannot pass on a sentence
# about another argument.
token_text="$(awk '
  index($0, "## The review") == 1 { on = 1; next }
  on && /^## / { exit }
  on && $0 == "" { if (keep) printf "%s", para; para = ""; keep = 0; next }
  on {
    para = para $0 " "
    if (tolower($0) ~ /token/) keep = 1
  }
  END { if (keep) printf "%s", para
}' "$mech" | tr -s ' ')"
expect "mechanics.md's review step names the token it stores for this run" test -n "$token_text"
flat="$token_text"

# Where the token lives is a contract with `resume-state.sh`, which opens exactly this path: under
# the clone's git dir, which no Builder's worktree reaches, and named for the run's slug, so one
# run's token never vouches for another run's Review.
carries "the token is stored at the path the resume probe reads it from" "do/review-token/"
carries_any "the token file is named for the run, not shared across runs" \
  "review-token/<slug>" "review-token/<the slug>" "review-token/<the run's slug>" \
  "review-token/<the Ticket's slug>"
carries_any "the token lives under the clone's git dir, out of every worktree a fork holds" \
  "git common dir" "--git-common-dir" "common git dir" "git dir"

# A value a fork could guess, or recompute from the branch, would let anything with a shell write a
# marker of its own: the proof is that only the review step could have known it.
carries_any "the token is a value nothing else can guess" \
  "cannot be guessed" "can't be guessed" "unguessable" "not guessable" "guesses" \
  "nobody can guess" "no one can guess" "nothing can guess" "random"

# The one moment a fork holds a shell in the worktree is the build, so a token written before that
# is a token the Builder could have copied.
carries_any "the token is written only once the Builder has returned" \
  "after the Builder has returned" "once the Builder has returned" "after the Builder returns" \
  "after the Builder returned" "never before the Builder" "not before the Builder"

# The call's own line. A labelled single-line argument, sent where the reviewer can read it: after
# the Gate and ahead of the ledger, so it never sits behind the held Rulings block, which runs to
# the end of the call and would swallow it.
carries "the call carries the token as its own labelled line" "Review token:"
carries_any "the token line is sent after the Gate" "after the Gate" "following the Gate"
carries_any "the token line comes before the ledger, so the held Rulings block never swallows it" \
  "before the Loss ledger" "before the ledger" "ahead of the ledger" "ahead of the Loss ledger" \
  "before the held Rulings" "never behind the held Rulings" "before the block"

# The Builder is dispatched with the keys of this block and nothing else. A token key here would
# hand the secret straight to the one fork that holds a shell in the worktree, and its marker would
# then vouch for a Review the review step never wrote.
brief="$(blocks_of "$builder" "## The brief")"
expect "builder.md carries the block the Builder is dispatched with" test -n "$brief"
# shellcheck disable=SC2034  # lib.sh's absent reads $out
out="$(tr '[:upper:]' '[:lower:]' <<<"$brief")"
absent "the token is never a key of the Builder's brief" "token"

echo "# do-code-review/AGENT.md / ## The arguments: the token is an argument the table carries"

# The row alone, found by the argument it is about rather than by its place in the table: other rows
# say "after the Gate" of their own argument.
row="$(grep '^| ' "$agent" | grep -F 'Review token' | tr '\n' ' ' | tr -s ' ')"
expect "AGENT.md's argument table carries a row for the review token" test -n "$row"
flat="$row"
carries "the row names the argument by the line the call carries" "Review token:"
carries_any "the row says where among the arguments \`do\` sends it" \
  "after the Gate" "before the Loss ledger" "before the ledger" "before the held Rulings"

echo "# do-code-review/AGENT.md: the marker holds the token the call named, and nothing else"

# Everything the file says about the marker, paragraph by paragraph: the write itself and the rule
# about a call that names no token both belong to it, wherever the writer puts them.
marker_text="$(awk '
  $0 == "" { if (keep) printf "%s", para; para = ""; keep = 0; next }
  {
    para = para $0 " "
    if (index($0, "marker")) keep = 1
  }
  END { if (keep) printf "%s", para
}' "$agent" | tr -s ' ')"
expect "AGENT.md says what the marker beside the Review holds" test -n "$marker_text"
# shellcheck disable=SC2034  # lib.sh's carries_each reads $flat
flat="$marker_text"

carries_each "the marker's one line is the token the call named" \
  "token" \
  -- \
  "one line" "single line" "one-line"
# The commit the header names is a fact the branch itself carries, which anything with a shell can
# read and copy: a marker holding it proves the Review's age and never who wrote it.
# shellcheck disable=SC2034  # lib.sh's absent reads $out
out="$marker_text"
absent "the marker no longer holds the commit the Review's own header names" "one line is the commit"

# A review a developer ran by hand carries no token, and a marker it wrote would make the next run
# trust a Review nothing vouched for.
carries_each "a call that names no token writes no marker" \
  "no token" "without a token" "no \`Review token\`" "named no token" \
  -- \
  "writes no marker" "no marker" "never writes the marker" "leaves the marker out" "writes none"

echo "# ticket.md / the build step: the token is revoked before the fork that could copy it"

# The build step is the one moment a fork holds a shell in the worktree, so the revoke belongs to
# it. Found by the agent the step forks and never by the step's number: a Playbook renumbers its
# steps whenever one is added or absorbed.
build="$(item_holding "$ticket" '\*\*[0-9]+\.' "do-builder")"
expect "ticket.md carries the step that forks the Builder" test -n "$build"

# The token's own paragraphs of that step, not the whole step: the step already says "before the
# fork" of the Plan it re-reads and "vouch" of the door's hashes, so a check about the token read
# over the whole step would pass on a sentence about the grounding.
revoke_text="$(paragraph_with <(printf '%s' "$build") "token" all | tr -s ' ')"
expect "the build step names the token it revokes" test -n "$revoke_text"
# Read in lower case: every phrasing below is a clause a writer may open a sentence with, and a
# capital there says nothing about the rule the clause carries.
# shellcheck disable=SC2034  # lib.sh's carries reads $flat
flat="$(tr '[:upper:]' '[:lower:]' <<<"$revoke_text")"

carries "the build step revokes the run's review token" "revoke"

# Storing the token out of the worktree is not the guarantee on its own, since the Builder holds a
# shell there: the guarantee is the window, and it closes only if the revoke lands before the fork.
carries_any "the token is revoked before the Builder is forked" \
  "before the fork" "before that fork" "before this fork" "before any fork" "before another fork" \
  "before forking" "before it forks" "before the builder" "ahead of the fork" "ahead of that fork"

# A revoke the step runs only when it believes a token is there is a revoke that asks a question
# about the store, and a wrong answer hands a live value to the one fork the guard exists for.
carries_each "the token is revoked on every run, a run that stored none included" \
  "every run" "always" "whether or not" "never asks" "unconditional" "regardless" "each run" \
  -- \
  "no token" "nothing stored" "nothing to revoke" "first run" "none stored" "never stored" \
  "has none" "stored none"

# Why the step cannot skip it: the value is what a forged marker beside a Review must carry for the
# next run's `marked()` to spare it a review, so a live token during the build buys an unreviewed
# branch that lands.
carries_each "the step says what a live token would buy the fork: a marker the next run honours" \
  "marker" \
  -- \
  "skip" "spare" "second review" "another review" "unreviewed" "without a review" \
  "never reviewed" "past its review" "trusts" "vouch" "honours" "honors"

# The store's path is the script's own, and `resume-state.sh` reads the file back from it: a step
# that resolved `--git-common-dir` itself would be a second spelling of that path to keep in step
# with the reader, and the revoke is the half that must never quietly miss.
carries "the revoke runs the script that owns the token store" "review-token.sh"
carries_any "the revoke names the script's revoke mode" \
  "review-token.sh revoke" '`revoke` mode' 'mode `revoke`' 'with `revoke`' 'its `revoke`'
# shellcheck disable=SC2034  # lib.sh's absent reads $out
out="$build"
absent "the build step never resolves the token store's path itself" "--git-common-dir"

echo "# mechanics.md / ## The review: the mint runs the same script the revoke does"

# One script owns both ends of the window. A mint spelled into a shell line here and a revoke
# spelled into another in ticket.md can drift apart, and the pair that drifts leaves the token on
# disk exactly when a fork holds the worktree.
# shellcheck disable=SC2034  # lib.sh's carries reads $flat
flat="$token_text"
carries "the mint runs the script that owns the token store" "review-token.sh"
carries_any "the mint names the script's new mode" \
  "review-token.sh new" '`new` mode' 'mode `new`' 'with `new`' 'its `new`'

exit $((fails > 0))
