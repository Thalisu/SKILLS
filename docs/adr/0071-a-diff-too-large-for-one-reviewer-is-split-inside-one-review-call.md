# A diff too large for one reviewer is split inside one review call

Since ADR 0061 the review reads a whole Spec branch at once, a diff that can exceed one reviewer's
window, which is the condition ADR 0007 left the size fan-out waiting on. The split happens inside
`do-code-review`: `do` still makes one call and reads one return, and the orchestrator measures the
diff, forks its reviewers per **Shard** and writes one Review, so the Review per Spec, its token
and marker, the Waves over one `Act on` list, the one Gate and the one lander of ADR 0013 and ADR
0060 all stand. The reviewers of every Shard are forked at once, since they only read and each
writes its own return file.

## Considered options

- `do` measuring the diff and calling `do-code-review` once per part: one orchestrator, one Review,
  one round of Fixers, one Gate and one landing per part, more agents for the same diff, and `do`
  left to join Reviews it never opens today.
- A ceiling on concurrent reviewers with rounds above it: the same tokens spent either way, a
  lower peak bought with wall time and a round state the fan-out would have to carry. Reopened
  when a run meets a rate limit or the harness refuses the fan-out.
