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
