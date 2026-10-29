# One tree is gated once, and `do` skips the Gate the landing call is about to run

`do` runs its Gate after the build loop and again over every commit it makes after the review,
where `do-code-review`'s `fix` call runs the same Gate over the same tree at the start of its
landing. The second run is dropped: after the review, and on every re-integration a
`not landed: target moved` return asks for, `do` hands the tree to the `fix` call, which gates it
and refuses to land it red. The Gate before the first review call stays, because a red tree there
would fork two reviewers at `xhigh` before anything checked it.

## Considered options

- Caching a gate verdict by tree hash and reusing it in the landing call: the review is the
  independent verifier, and a cache would have it trust the run's own report of a check it never
  saw.
- Dropping `do`'s Gate everywhere, the first review call included: the reviewers would read a tree
  nothing ran.

## Consequences

Nothing lands ungated, since the Gate that authorizes a landing is the one the landing call runs.
ADR 0033 stands as it is: this narrows only where `do` runs a Gate of its own, never where the
landing runs one.

Amended: per ADR 0113, the reasons `mechanics.md` and `not-landed.md` gave beside the gate and the
fix call live here. The gate runs after the last edit and never earlier, per `prove-it-works`. A red
check's block is capped at its last twenty lines with the full output in a file, so the session's
window holds the lines to act on and never the whole output. The gate's `command=` line goes to the
review, so the review holds its fixes to the checks the run held its own work to. A branch the run
commits to after the review goes to the fix call with no Gate of the run's own over it, since the
fix call gates the same tree itself and refuses to land it red, and the retry after a moved target
has no fixed count, so a Gate there would pay for the suite twice on every lap. A run that reaches
the fix call having run no gate of its own hands it no `command=` line, since the session that
printed one was another run's, and a fix call handed none runs the Gate from the Testing Policy's
Project facts.
