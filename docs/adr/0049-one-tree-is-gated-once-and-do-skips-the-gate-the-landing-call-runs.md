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
