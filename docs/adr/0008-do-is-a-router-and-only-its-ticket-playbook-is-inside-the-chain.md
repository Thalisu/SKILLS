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

Amended: per ADR 0113, the reasons `mechanics.md` gave for its own shape live here. The worktree
Playbooks link the section of the shared mechanics a step needs and never copy it, so a fix to a
mechanic is made once. A part a step reads on its own is a file beside it, so a step that reaches
for it carries none of the rest. The run is unattended: the developer reads it afterwards, through
the Reply, and nobody watches a step while it runs, so the costly errors are the ones that land
before anyone looks, and every rule of the mechanics guards against one of three: work reaching the
developer's branch unread or red, the run touching work that is not its own, and a stop that leaves
nothing to act on.
