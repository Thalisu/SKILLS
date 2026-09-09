---
name: do
description: "Match a request to one Playbook and run its steps: a Ticket's path or issue reference builds that Ticket as the last step of the chain, a request in words runs outside it, and a request that fits no Playbook is sent to the door that owns it in one message."
disable-model-invocation: true
argument-hint: "[a Ticket's path, an issue reference, or the request in words]"
---

# Do

`$ARGUMENTS` is the request. The router matches it to one Playbook, the Playbook's reference under
Links is the run, and the non-negotiables hold in every run. Every reply opens with
`Playbook: <name>`, so a wrong match costs one retyped request.

## Router

The argument's shape is read first, then its words. The lines are read in order and the first
matching line wins, so each line sits above any broader condition it could shadow. An argument
that opens with a Playbook's name is matched to that Playbook, subject to that Playbook's own door
checks. A match reads that Playbook's reference, and the references it links, and never another
Playbook's. A line that matches no Playbook
ends the run in one message: `Playbook: none` on the first line, then the door with the command
to type; nothing is written and no reference is read.

| The argument | Match |
|---|---|
| empty | `Playbook: none`; one message asking for the task: a Ticket's path, an issue reference, or the request in words |
| a path that does not exist | `Playbook: none`; one line saying so |
| a path to a Ticket, in the format of [ticket-format.md](../../.agents/formats/ticket-format.md), or an issue reference (a number or a URL) resolved through the tracker file, `docs/agents/issue-tracker.md` | `ticket` |
| an issue reference the tracker's CLI cannot open | `Playbook: none`; one line saying so |
| an issue number or URL with no tracker file | `Playbook: none`; one message asking for the Ticket's path. The number is never matched against a list in the conversation |
| a Spec's path, in the format of [spec-format.md](../../.agents/formats/spec-format.md), or a pasted session summary | `Playbook: none`; one line saying a Spec fits no Playbook, since `do` takes one Ticket, with the command: `/tickets <spec>`, or `/journey <spec>` first when the Spec's `Journey:` line reads `required` and no journey sits beside it; `/spec` for a summary, since the discussion already happened |
| a question: how something works, why it was built that way | `Playbook: none`; `/how` for the mechanism, `/why` for the rationale, `/teach` to understand it end to end |
| a sketch, a layout, a variant to try | `Playbook: none`; `/prototype` |
| a change in words that no test could tell before from after: a typo, a doc line, a comment, a formatting fix, a log wording, a rename inside one file, dead code, a lint fix. Never a bug, a new exported symbol, a changed signature or a change the user sees, whatever its size | `trivial` |
| a reshape of existing code in words, its behaviour unchanged: refactor, rename, extract, inline, dedupe, move this module. Never a request that moves behaviour a caller or a user observes | `refactoring` |
| a feature, and any other request with no Ticket | `Playbook: none`; `/discuss`, or `/spec` when the conversation already holds the discussion |

A matched Playbook whose reference is missing from Links is not installed in this session:
`Playbook: none`, one line naming the Playbook and the missing reference, nothing written.

## Non-negotiables

Each holds in every Playbook.

- The matched Playbook's steps are copied verbatim as the checklist before any task-specific item, and a skipped step stays visible as `skip: <reason>`.
- A principle is named in the reply only with the decision it changed.
- A question is classified before it is asked: a fact a script can observe goes to a probe, and only a product or preference call goes to the human.
- The data shape and its organising structure are named before any logic.
- Every delegate's diff is read by the session, which writes its own summary.
- A pause comes only before an irreversible write; reversible work is presented instead.
- "no" is an acceptable answer.
- The run never lands and never fixes a Finding; the review does both.
- The reply is in the language the session opened in, and everything written into the project is in English.

## Links

One per reference. A Playbook's reference is read only when a router line names it; the reply reference is read last by every Playbook.

- [ticket.md](references/ticket.md): the `ticket` Playbook, which links the shared mechanics and the reply reference.
- [mechanics.md](references/mechanics.md): the shared mechanics the Playbooks that build in a worktree read through their steps: the worktree, the protected branch, the Ticket file, the build loop, the gate, the review, the verification, the close.
- [tdd-fallback.md](references/tdd-fallback.md): the TDD fallback the build loop reads when the project has no unit test author, and never otherwise: the run writes the failing test itself, and no test author is dispatched.
- [trivial.md](references/trivial.md): the `trivial` Playbook: its door checks, its steps and the door script they run.
- [refactoring.md](references/refactoring.md): the `refactoring` Playbook: its door checks, its steps and the pin it holds the reshape against.
- [reply.md](references/reply.md): the reply every Playbook writes last, its sections in order.
- [ticket-format.md](../../.agents/formats/ticket-format.md): the Ticket the `ticket` line matches, and the fields a run reads and writes.
- [spec-format.md](../../.agents/formats/spec-format.md): the Spec the door recognises, and its `Journey:` line.
