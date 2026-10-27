# The Debt file format is shared, and a tracker Ticket's Debt file is not gathered

Ruled by the choice-taker: ADR 0096, "On Jira the tracker holds what the team reads, and the Feature folder keeps the rest"

The Debt file is written by `do` and read by `debt`'s `gather.sh`, so its shape moves out of `do`'s
`reply.md` into `.agents/formats/debt-format.md`, per ADR 0004. A tracker Ticket's Debt file stays
beside its Plan, `.scratch/plans/<issue>.debt.md`, and `/debt` does not gather it: `/debt` takes a
feature slug, a tracker Ticket of a remote Spec sits in no feature folder, and ADR 0096 already
names the feature folder as the one remedy for what such a Ticket loses. The developer reads that
file by hand.

## Considered options

- **`gather.sh` also reads `.scratch/plans/*.debt.md`**: those files name no feature, so every
  feature's `/debt` would judge every tracker Ticket's debt.
- **`do` writes it into a feature folder's `issues/`**: a remote Spec has no folder, and only
  `spec` allocates one (`.agents/scratch.md`).
- **`/debt` accepts a Spec issue reference**: a new argument form, a header line naming the Spec,
  and a Debt review with no local Spec to sit beside (ADR 0093).
