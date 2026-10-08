# A feature across repositories lands in sequence, and what landed stays

Each **Build repository** of a feature holds its own **Spec branch**, and git has no landing atomic
across repositories. The **Completion check** stays feature-wide, so no repository lands while a
**Ticket** is open in another, and each **Final integration** then runs in a session of its own
repository, in the order `Blocked by` gives, a provider before what consumes it. One that stops
leaves the earlier ones landed, its **Reply** names which repositories landed and which did not,
and running it again skips the landed ones. A provider landed without its consumer is a capability
nobody calls yet, and the landing is local, so the partial state is cheap to undo.

## Considered options

- Two phases, every repository rebased and reviewed first and fast-forwarded only when all are
  **Green**: a narrower window for a partial landing, paid for with a coordinator across sessions
  that the chain does not have.
- Each repository landing as soon as its own **Tickets** are `resolved`: a repository reaches the
  developer's branch while the rest of the feature may still change what it needs.
