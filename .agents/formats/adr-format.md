# ADR format

ADRs live in `docs/adr/` (at the root, or in the context's own `docs/adr/` when `CONTEXT-MAP.md`
names one) with sequential numbering: `0001-slug.md`, `0002-slug.md`. The directory is created
when the first ADR is needed. Written in English.

## Template

```md
# {Short title of the decision}

{One to three sentences: the context, what was decided, and why.}
```

That is the whole ADR. A single paragraph is enough: the value is in recording that a decision was
made and why, not in filling out sections.

## Optional sections

Only when they add something. Most ADRs need none of them.

- **Status** frontmatter (`proposed | accepted | deprecated | superseded by ADR-NNNN`): useful when
  decisions get revisited.
- **Considered options**: only when the rejected alternatives are worth remembering.
- **Consequences**: only when a downstream effect is not obvious.

## Numbering

Scan the target `docs/adr/` for the highest existing number and add one.

## When a decision earns an ADR

All three must hold:

1. **Hard to reverse**: changing your mind later has a real cost.
2. **Surprising without context**: a future reader will look at the code and wonder why it was
   done this way.
3. **The result of a real trade-off**: there were genuine alternatives and one was picked for
   specific reasons.

A decision that is easy to reverse gets reversed, not recorded. One that is not surprising leaves
nobody wondering. One with no real alternative has nothing to record beyond "the obvious thing was
done". Any of the three missing: no ADR; the closing summary carries the decision, and the
spec's Implementation Decisions keep it from there.

### What qualifies

- **Architectural shape.** "The write model is event-sourced; the read model is projected into
  Postgres."
- **Integration patterns between contexts.** "Ordering and Billing communicate through domain
  events, not synchronous HTTP."
- **Technology choices that carry lock-in.** Database, message bus, auth provider, deployment
  target. Not every library; the ones that would take a quarter to swap out.
- **Boundary and scope decisions.** "Customer data is owned by the Customer context; other
  contexts reference it by id only." The explicit noes are as valuable as the yeses.
- **Deliberate deviations from the obvious path.** "Manual SQL instead of the ORM because X."
  Anything a reasonable reader would assume the opposite of. These stop the next engineer from
  "fixing" what was deliberate.
- **Constraints not visible in the code.** "No AWS, for compliance reasons." "Responses under 200ms
  because of the partner contract."
- **Rejected alternatives when the rejection is not obvious.** GraphQL considered and REST picked
  for subtle reasons: record it, or someone suggests GraphQL again in six months.

### What does not

Three things look like decisions and are not ADRs, whatever the weight of the conversation behind
them:

- **A rule the glossary already carries.** `CONTEXT.md` is its home; an ADR would be a second copy.
- **The artifact the spec is about to describe.** The modules, interfaces and contracts of one
  feature belong in the spec's Implementation Decisions.
- **A choice whose alternative lost only to a rule of the repository.** Nothing was traded off, so
  there is nothing to record beyond the rule, which is already written.
