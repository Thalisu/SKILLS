# A choice-taker's ruling amends the Spec, and a Ticket criterion only when it is the losing side

The ticket format kept the Spec read-only from a Ticket and let `do` write only the Status line,
the ticks and the Evidence. A ruling now writes one line into the Spec's Implementation Decisions,
naming the side, the norm it cites or "no norm: the side easiest to undo", and marked as the
choice-taker's, and rewrites a Ticket criterion only when that criterion is the side that lost. The
Spec is shared by every Ticket of the feature, so the next Ticket's reader finds the ruling rather
than a second choice-taker ruling the same fork the other way; the Spec's hash moves, and the resume
path that already re-forks the reader over an amended Spec picks the run up unchanged. A developer
reverses a ruling by editing that line and running `/do` again.

## Considered options

- The ruling in the Ticket alone: each Ticket of one feature can carry a different ruling on the
  same fork, and the feature ends up with two rules for one thing.

## Consequences

On a remote tracker the Spec is an issue and every write to it waits for the developer's yes. The
run goes on with the ruling in the Ticket's Evidence and the reply, and the ruling rides the
close's yes as a comment on the Spec issue, which the reader reads; a no leaves it in the reply.

Amended: per ADR 0113, the reasons `mechanics.md` gave beside the held Rulings live here. A run that
holds a Ruling sends the held Rulings to the review as one block of text, so the review holds the
build to the Ruling and to a rewritten criterion the Ticket issue does not carry yet. The block is
the last argument of the call, since every line after its first is a Ruling, so a single-line
argument never sits behind it, and the review token goes before the Loss ledger so the block never
swallows it. The fix call carries no block, since the Review it fixes was already held to the
rewritten text. On a remote tracker each held Ruling is posted verbatim under an
`## Implementation Decisions` heading on the Spec issue, so the next Ticket's reader finds it where
a local Spec keeps it.
