# The rebase runs in the session before the review, and the landing retries only the mechanical class

`do` rebases its worktree branch onto the developer's branch after the gate and before it calls
`do-code-review`, because a contested conflict has to reach a human and `do-code-review` is a
forked agent with no channel to one, so an interactive resolution placed there degrades into a
stall or a guess. The review's landing keeps a rebase only for the hunks its door script certifies
as `mechanical`, and returns `not landed: target moved` with the conflicting files for anything
`contested`, which a second `/do` resumes and resolves with the developer present. `do` still never
lands.

This amends [ADR 0013](0013-do-code-review-lands-a-green-review-by-fast-forward.md): its landing
rule "the branch rebased first when the developer's branch moved" now covers the mechanical class
only, and its "a rebase conflict aborted with the conflicting files named" is the floor rather than
the whole answer.

## Considered options

- The resolver inside `do-code-review`, where the rebase already runs: no path to the human, so
  every contested conflict ends the run as blocked, which is the behaviour this change exists to
  remove.
- No retry in the landing at all: any failed fast-forward returns `not landed` and the developer
  re-runs `/do`. One less shared script, and it stops the run on the one case that needs nobody.

## Consequences

The review now reads the diff that actually lands. Until now the branch could be rebased after the
reviewers had read it, so the reviewed diff and the landed diff were not guaranteed to be the same
bytes.

[ADR 0033](0033-the-review-runs-once-per-run-and-what-comes-after-it-lands-through-the-gate-alone.md)
narrows this to a first run: a rebase a resumed run resolves after the review is held to the Gate
and lands through `fix`, and is never reviewed a second time.

Amended: per ADR 0113, the reasons `mechanics.md` gave beside the integration's rules live here. The
rebase runs after a green gate and before the review, so the diff the reviewers read is the diff
that lands. A protected developer's branch does not stop it, since a rebase onto a branch writes
nothing to it and the step lands nothing; the landing stays the review's, which refuses a protected
target. The commit the branch is on is recorded before the rebase starts, since the command that
undoes the rebase is not the same once the rebase has finished, and the recorded commit is what that
command names. Every command that can meet a conflict runs with conflict-resolution reuse off, since
the setting is the developer's own and may be on: a resolution recorded at one stop would be
replayed into the next stop of the same shape, the class would be read from what the cache put back
instead of from what git left, and the run's own resolutions would land in a cache that outlives it.
The ledger's location is fixed before the rebase starts, so a resumed run is never handed it back.
The gate that was green before a replay is stale, since the run's commits now sit on code the branch
had not seen, and the review's fixed point is the commit the branch was rebased onto, since the
commit the worktree was created from is behind the developer's own commits and a review given it
would read their work as part of the diff under review. A red gate after a replay stops the run and
never goes back to the build loop, since the replay brought in code the developer's branch carries,
and a run that loops on it edits their work.
