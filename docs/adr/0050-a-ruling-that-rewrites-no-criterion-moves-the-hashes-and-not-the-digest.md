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

Amended: per ADR 0113, the reasons `forks.md` gave beside its rules live here. That the slice did
not move is an assertion about this Spec write alone and never a fact the run may skip checking:
the same window, from the door's pre-fork hash to the Ruling, is open to a sibling Ticket's Ruling
on the same Spec, a `/discuss` amendment or a developer's own edit, none of which appends only that
one line. The journey's hash has to match with no exception, since no Ruling ever touches the
journey, and the loop continues at the first behaviour without a commit since the criteria it was
written from did not move. A kept quote's `L<line>` is never recomputed although the appended line
moves it, and a developer who opens a quote cut from below Implementation Decisions finds the text
one line off. The rewrite touches this Ticket's Digest alone, since left stale its `## Sources`
lines would send its own next run into a reader, and a Digest is keyed by its own Ticket's slug, so
a sibling's Digest is untouched. A Ruling that rewrote a criterion re-forks the reader over the Spec
and the journey both, since a Digest cut from the Spec alone would come back with no Journey Path.
