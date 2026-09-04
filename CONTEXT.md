# Skill chain

The sequence of skills a piece of work walks through in this repo, from a plan to a built unit:
`discuss`, then `spec`, then `journey` when the spec's verdict requires it, then `tickets`, then
`do`, one ticket at a time. The chain is strict: each skill takes only the artifact of the step
before it. This glossary holds the words those skills share.

## Language

**Spec**:
The decided description of one feature, synthesised from a `discuss` session: problem, solution,
user stories, implementation and testing decisions, and what is out of scope.
_Avoid_: brief, PRD, plan

**Path**:
One thing the actor sets out to do, end to end, walked in steps: arrive, see, act, the system
answers, or it fails.
_Avoid_: flow, journey (the journey is the document, a path is one entry in it), user story (the
story is the sentence, the path is the walk)

**Verdict**:
The `Journey:` line under a spec's title: `required`, or `not needed` with the condition; replaced
by the journey's location once the journey is written.
_Avoid_: flag, journey needed

**Journey**:
The document that walks every path of one spec from the actor's seat, kept where the spec's
**Verdict** line points once it is written: beside the spec as a file, or linked from the issue.
_Avoid_: user flow, UX doc

**Ticket**:
One demoable slice cut from a spec, and from its journey when it has one, sized to fit one session.
The skill that cuts the set is `tickets`.
_Avoid_: issue (only when quoting a tracker that calls them issues), slice, task

## Relationships

- A **Spec** has one or more **Paths**, read off its user stories
- A **Spec** carries one **Verdict**, read off the structure of its **Paths**: `required` when it
  introduces a new screen or route, has more than one **Path**, or has a **Path** of more than one
  step; `not needed` otherwise
- A **Journey** walks every **Path** of exactly one **Spec**
- **Tickets** are cut only from a **Spec** whose **Verdict** is met: `not needed`, or `required`
  with the **Journey** written beside it
- `do` builds exactly one **Ticket**, never a **Spec** and never a session summary

## Example dialogue

> **Dev:** "The **Spec** adds an export button to the orders list. Does it get a **Journey**?"
> **Domain expert:** "No. One **Path** of one step on a screen that exists: the **Verdict** is
> `not needed`, straight to **Tickets**."
> **Dev:** "And the new reports page, with filters, a create form and a delete confirmation?"
> **Domain expert:** "A new route and three **Paths**, one of them several steps long. The
> **Verdict** is `required`: **Journey** first, then **Tickets** cut from its paths."
> **Dev:** "Can I run `do` on that spec directly? It is small."
> **Domain expert:** "No. `do` takes a **Ticket**, and **Tickets** wait for the **Journey**."

## Flagged ambiguities

- "large" was the word for a spec that needs a journey. Resolved: size is never measured; the
  **Verdict** reads the structure of the **Paths** (a new screen or route, more than one path, or a
  path of more than one step).
- "ticket" and "tickets" were both used for the skill. Resolved: the skill is `tickets`, it
  produces the set; a single unit is a **Ticket**.
