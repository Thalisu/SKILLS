# do is a router, and only its ticket playbook is inside the chain

`/do` matches a request to one playbook and runs its steps. The playbooks live under the skill's
`references/`, one file each, read only when matched, so `SKILL.md` stays the router and the
non-negotiables and the context cost of a run is one playbook, not all of them. The `ticket`
playbook is the last step of the chain and keeps the input ADR 0003 fixed: one Ticket, never a spec
and never a session summary. Every other playbook runs outside the chain and never builds a
feature: what it accepts is a structural rule written in the playbook, never a size judged in the
moment, and a request that fits no playbook is sent to `discuss` or `spec`. This supersedes the `do`
clause of ADR 0003; the rest of ADR 0003 stands.

## Considered options

- `/do` stays ticket-only and trivial work gets a second skill: two entry points for "build this",
  with the routing question answered by the human at the prompt instead of by the skill.
- Every playbook inlined in `SKILL.md`: each call loads every playbook, and the router grows with
  each one added.
