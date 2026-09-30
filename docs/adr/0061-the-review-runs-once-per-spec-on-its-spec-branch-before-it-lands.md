# The review runs once per Spec, on its Spec branch, before the branch lands

A `do` ticket run no longer calls `do-code-review`: the Ticket's own Gate is its check before it
lands on the Spec branch (ADR 0060). After each such landing a script's completion check reads
whether every Ticket of the Spec is `resolved`, and the run that finds them all rebases the Spec
branch onto its upstream in the session, then calls `do-code-review` on it with that upstream as
the fixed point, which reviews, fixes and lands it on the developer's branch when Green. The review
reads the local diff, so no pull request is opened for it. This supersedes the "once per run" rule
of ADR 0033 for the ticket Playbook and narrows the Review, which now belongs to a Spec rather than
to one Ticket; the other Playbooks keep one review per run.

## Considered options

- A review per Ticket, as until now: every diff read before it lands, at the price of one reviewer
  fan-out per Ticket and no reviewer ever reading the Spec whole.
- The Spec branch landed first and reviewed after: `Act on` Findings would sit on the developer's
  branch and their fixes land with nothing left to block them.
- A pull request opened for the Spec branch and reviewed there: the same diff the local fixed point
  already gives, behind a remote.

## Consequences

Each run writes its own `resolved` before it runs the completion check, so the last of two
concurrent runs always sees every Ticket resolved, and the final integration is claimed by creating
a file, so two runs that both see it never both integrate. An integration that stops (a contested
hunk unanswered, a review that does not land, `not landed: target moved`) is resumed by a new `do`
on any Ticket of the Spec, whose door takes a `resolved` Ticket whose Spec branch has not landed and
runs only the final integration.
