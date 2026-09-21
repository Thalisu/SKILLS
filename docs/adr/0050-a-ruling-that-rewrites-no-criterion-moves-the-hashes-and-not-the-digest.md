# A Ruling that rewrites no criterion moves the hashes and not the Digest

A `settled` Ruling on a local Spec is one line appended to the Spec's Implementation Decisions, and
the Digest carries no Implementation Decisions section, so a reader forked again over the amended
Spec returns the same text under a new hash. The run now keeps the Digest it holds and rewrites
only its `## Sources` lines, and forks the reader again only when the Ruling rewrote a Ticket
criterion, which is what the reader's brief carries. The remote path already worked this way,
continuing on the Digest it held because the Spec it was cut from did not change.

## Considered options

- Re-forking the reader on every amended Spec, as the local path did: a fork and about 2k tokens
  spent to reproduce a document character for character.
- Leaving the `## Sources` lines stale: the reuse gate would then fork a reader on the next run of
  every sibling Ticket of the feature.

## Consequences

The Digest's "replaced whole" rule takes one exception, the `## Sources` lines the session rewrites
in place, and those hashes stay the door's own reading of the Spec as the Ruling left it. ADR 0037
is unchanged: the Ruling still amends the Spec, and still rewrites a Ticket criterion only when
that criterion is the losing side.
