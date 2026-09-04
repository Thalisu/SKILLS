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

**Playbook**:
One execution model `do` routes a request to, kept under the skill's `references/` and read only
on match.
_Avoid_: mode, workflow, checklist (the checklist is a playbook's steps copied into the run's todo
list), route (the route is the match, the playbook is what runs)

**Trivial**:
A change no test could tell before from after, so the existing suite is its whole gate: a typo, a
doc or a comment, formatting, log wording, a rename inside one file, dead code, a lint fix.
_Avoid_: small, quick, minor, one-liner (size is never the test)

**Axis**:
One independent question `do-code-review` puts to a diff, reported apart from the others so that a
pass on one never hides a fail on another: correctness, spec fidelity, repo standards, principles,
blast radius, security.
_Avoid_: lens (a lens is one principle turned into a question, inside the principles axis),
category, check, branch (the two reviewers are agents, not axes)

**Finding**:
One thing the review claims about a diff: its **Axis**, its **Bucket**, where it is (`file:line`,
a spec line quoted, or a place outside the diff), the claim in one line, the evidence in the shape
its axis takes, its **Rung**, a risk class when one applies (security, privacy, data loss, auth,
billing, migration, idempotency, race), and the fix as a behaviour to prove plus its target.
_Avoid_: issue, comment, suggestion, nit

**Bucket**:
Where a **Finding** lands in the report: `Act on` (fix before landing), `Consider` (a judgment
call, the reader decides), `Noted` (an observation, no action), `Cleared` (suspected, then refuted
by evidence; shown so the reader can override).
_Avoid_: severity, priority, dismissed (the caller's word for a finding it chose not to act on)

**Rung**:
How far the review climbed to back a **Finding**, on the ladder of `blast-radius`: 1 said so, 2
pointed at `file:line`, 3 walked the failure, 4 ran it, 5 reproduced it in the app.
_Avoid_: confidence, score, certainty

**Review**:
The file `do-code-review` writes for one diff: the intent, the one safety fact, the **Findings** by
**Bucket**, one line per **Axis**, and, after a `fix` run, what was fixed and what was verified.
Always a local markdown file, whatever the tracker. It belongs to one **Ticket** and lives beside
it, naming it; outside the chain it names the branch and the fixed point instead.
_Avoid_: report (the message returned to the caller, not the file), task review, PR comments

## Relationships

- A **Spec** has one or more **Paths**, read off its user stories
- A **Spec** carries one **Verdict**, read off the structure of its **Paths**: `required` when it
  introduces a new screen or route, has more than one **Path**, or has a **Path** of more than one
  step; `not needed` otherwise
- A **Journey** walks every **Path** of exactly one **Spec**
- **Tickets** are cut only from a **Spec** whose **Verdict** is met: `not needed`, or `required`
  with the **Journey** written beside it
- `do` routes a request to exactly one **Playbook**; the `ticket` **Playbook** builds exactly one
  **Ticket**, never a **Spec** and never a session summary, and is the only **Playbook** inside
  the chain
- A **Playbook** outside the chain never builds a feature; a request that fits no **Playbook** is
  sent to `discuss` or `spec`
- The `trivial` **Playbook** takes only a **Trivial** change, in place and in one commit, and
  dispatches no test author; a bug, a new exported symbol, a changed signature or a user-observable
  effect re-routes
- `do` ships four **Playbooks**: `ticket` inside the chain; `trivial`, `bug-fix` and `refactoring`
  outside it. A question is `how`, `why` or `teach`; a feature is the chain; a sketch is `prototype`
- `do` calls `do-code-review` once per run, before landing: on the diff of one **Ticket** after its
  gate in the `ticket` **Playbook**, on the branch's diff in `bug-fix` and `refactoring`, never in
  `trivial`; every **Axis** is put to that diff
- A **Finding** belongs to exactly one **Axis** and sits in exactly one **Bucket**
- Five **Axes** are put to the diff by the technical reviewer and the Security **Axis** by the
  security reviewer, whose posture is the attacker's: attack surface first, then STRIDE and OWASP.
  Security covers spoofing and auth, tampering and injection, secrets and privacy, permission
  boundaries, input-driven cost and privilege elevation; migration, idempotency, race, billing and
  data loss stay risk classes on technical **Findings**
- A **Finding** at the same location in both reviewers' reports is the security reviewer's; the
  technical one is dropped as a duplicate, never merged and never reranked
- A Security **Finding** always carries a risk class and never lands in `Noted`: it is `Act on`,
  `Consider` or `Cleared`, so nothing on that **Axis** is set aside without a reader seeing it
- An **Axis** whose reviewer did not return after one retry reads `not run` in the **Review**,
  never `0 findings`; the other reviewer's **Findings** are still written
- A **Review** belongs to exactly one **Ticket** when one exists and is the only file
  `do-code-review` writes; a `fix` run reads it, forks the fixer with its `Act on` list, then
  appends what was fixed and what was verified to the same file
- `Act on` takes only a **Finding** at **Rung** 3 or above with its check named; **Rung** 1 and 2
  stop at `Consider`, whatever the severity
- `do` turns every `Act on` **Finding** into one unit of its build loop, and never dismisses a
  **Finding** with a risk class silently: that one goes to the user

## Example dialogue

> **Dev:** "The **Spec** adds an export button to the orders list. Does it get a **Journey**?"
> **Domain expert:** "No. One **Path** of one step on a screen that exists: the **Verdict** is
> `not needed`, straight to **Tickets**."
> **Dev:** "And the new reports page, with filters, a create form and a delete confirmation?"
> **Domain expert:** "A new route and three **Paths**, one of them several steps long. The
> **Verdict** is `required`: **Journey** first, then **Tickets** cut from its paths."
> **Dev:** "Can I run `do` on that spec directly? It is small."
> **Domain expert:** "No. A **Spec** fits no **Playbook**: the `ticket` **Playbook** takes a
> **Ticket**, and **Tickets** wait for the **Journey**."
> **Dev:** "The review is sure the null path throws, but it only read the code. `Act on`?"
> **Domain expert:** "**Rung** 2. It stops at `Consider` until the review walks or runs the
> failure. Climb the ladder, then move it."

## Flagged ambiguities

- "large" was the word for a spec that needs a journey. Resolved: size is never measured; the
  **Verdict** reads the structure of the **Paths** (a new screen or route, more than one path, or a
  path of more than one step).
- "ticket" and "tickets" were both used for the skill. Resolved: the skill is `tickets`, it
  produces the set; a single unit is a **Ticket**.
- "task" was used for the unit a **Review** belongs to. Resolved: it is the **Ticket**; the review
  lives beside the **Ticket** it reviews and names it.
- "trivial" and "small" were used as a size. Resolved: **Trivial** is a structure, a change no test
  could tell before from after; a small bug is not trivial.
