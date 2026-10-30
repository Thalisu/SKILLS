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

Amended: per ADR 0113, the reasons `mechanics.md` and `final-stopped.md` gave beside the landing
record live here. Each repository's state is read from its own refs at the moment of the call, so no
file says a repository landed and no run remembers it. The record is read again after the release,
and after the yield at a stop, and the Reply's lines are printed from that read, so a partial landing
is never silent. The claim of a Ticket that carries a `**Build repository:**` line is keyed by that
repository, so each repository of a feature holds a claim of its own and one landing never reads
`taken` to the next, and its Review file is named for that repository, since each repository writes
a Review of its own beside the one Spec and a Review at the Spec's own name would be overwritten by
the next repository to land. A stop moves no ref in a repository that landed before it, reverts
nothing and removes nothing, since what landed was reviewed and is already the developer's to push.
The landing command of a later repository runs a first Final integration there, since nothing
stopped in that repository: its Final integration never started.

Amended: per ADR 0113, the reasons `final-stopped.md` gave beside what a stopped Final integration
leaves landed live here. What landed before the stop stays landed, with no ref moved, nothing
reverted and nothing removed, since it was reviewed and is already the developer's to push. The run
reads the landing record once more after the yield so that a partial landing is never silent. A
repository whose Final integration never started has nothing stopped in it.

Amended by ADR 0118: a repository is landed once its Landing pull request is open, and the landing order becomes the merge order the consumer's Reply names.
