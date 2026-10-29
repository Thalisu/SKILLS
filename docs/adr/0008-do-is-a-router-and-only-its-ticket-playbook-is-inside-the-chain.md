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

Amended: per ADR 0113, the reasons `skills/do/SKILL.md` gave beside its Router, its
Non-negotiables, its turn endings and its references list live here. Every reply opens with
`Playbook: <name>` so a wrong match shows at once and costs one retyped request. A `--auto` request
routes as it would without the flag, so the same path, issue reference or words reach the same
Playbook either way. A Ticket's kind is read by a script because it is a fact a script can read,
and a duplicated or unknown `**Kind:**` line has to read as ambiguous rather than be taken by eye.
A request the Router sends to another skill reads no reference and writes nothing, since the skill
that owns the request does that work better than a run that was never meant to. The `pr` row sits
above `integrate`, which would rebase or merge the pair itself, and above `bug-fix`, which never
pushes to the pull request nor follows it to green. The rows for an issue with no tracker file and
for an issue the tracker's CLI cannot open sit above `setup` and `ticket`, since both open an issue
only through that file and its command. A Spec fits no Playbook since `do` takes one Ticket, and a
pasted summary goes to `/spec` since the discussion already happened. The `ticket` Playbook builds
in several Stretches so a run can outlast an hour, with the developer reading it afterwards through
the Reply. A turn ends in a few named places only, because a message with no tool call leaves the
run standing still until the developer comes back, which can be an hour later. The data shape and
its organising structure are named before any logic, since logic written first fixes a shape
nobody chose. A pause comes only before an irreversible write, since reversible work can be undone
after the developer reads it. A Non-negotiable is applied to a case none of them names by what it
protects. `build-loop.md` is a reference of its own so the readers of the build loop carry none of
the rest of the shared mechanics.
