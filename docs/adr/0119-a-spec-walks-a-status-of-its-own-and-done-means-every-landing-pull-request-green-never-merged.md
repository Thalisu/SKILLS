# A Spec walks a status of its own, and done means every Landing pull request green, never merged

The **Spec status** walks `ready-for-agent`, `in-progress`, `waiting-pr`, `done`, apart from a
**Ticket**'s walk, and is a view for people and the tracker only: no script reads it to decide
anything, since landed is still read off the refs (ADR 0084). `spec` writes `ready-for-agent`, `do`
writes `in-progress` when it cuts the **Spec branch** and `waiting-pr` when the last repository's
review returns `proposed <url>`, and the `pr` **Playbook** writes `done` when it ends green and finds
every other **Landing pull request** of the **Spec**, read from the URLs in the **Reviews** beside it,
green too. The `pr` **Playbook** finds the **Spec** through a `Spec:` line `do-code-review` writes in
the pull request body (the spec's path, or its issue key), parsed at the door: a pull request with no
such line, or a path absent on this machine, gets no write and the **Reply** says so, since the head
name alone cannot reach a **Spec** that lives in another repository's feature folder (ADR 0081).
`done` means green and mergeable, never merged, because no step of the chain observes a merge; on
Jira each word maps to a named status of the team's workflow, as ADR 0100 does for a **Ticket**, so
`done` never forces the Done category.

This amends ADR 0100.

## Considered options

- `done` only once the pull request is merged: nothing in the chain sees the merge.
- `done` when the last pull request in landing order turns green, ignoring the others: a **Spec**
  reading `done` with the provider's pull request, the one merged first, still red.
- Finding the **Spec** from the head name `spec/<slug>`: fails in every repository but the home one.
