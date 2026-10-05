---
name: do
description: "Match a request to one Playbook and run its steps: a Ticket's path or issue reference builds that Ticket as the last step of the chain, a request in words runs outside it, and a request that fits no Playbook is sent to the door that owns it in one message."
disable-model-invocation: true
argument-hint: "[--auto] [a Ticket's path, an issue reference, or the request in words]"
model: opus
effort: medium
disallowed-tools: EnterWorktree
hooks:
  PreToolUse:
    - matcher: EnterWorktree
      hooks:
        - type: command
          command: "printf '%s' '{\"hookSpecificOutput\": {\"hookEventName\": \"PreToolUse\", \"permissionDecision\": \"deny\", \"permissionDecisionReason\": \"EnterWorktree isolates the session, and a do run needs two trees: the door of do-code-review is bash <script>, the landing is git against the main checkout, and an isolated session refuses both. Create the worktree and enter it the way the worktree step of mechanics.md says: git worktree add .claude/worktrees/do-<slug> -b do/<slug>, then a bare cd into it.\"}}'"
---

# Do

`$ARGUMENTS` is the request, typed by a developer who wants one piece of work carried through to
a reviewed branch. `do` is a router: it matches the request to one Playbook, and that Playbook's
reference under Links is the run. The `ticket` Playbook is the last step of the chain and builds
one Ticket; every other Playbook runs outside the chain and never builds a feature
([ADR 0008](../../docs/adr/0008-do-is-a-router-and-only-its-ticket-playbook-is-inside-the-chain.md)).
A run can last an hour and never waits on the developer, so they read it afterwards, through the
Reply.

Every reply opens with `Playbook: <name>` on its first line, so a wrong match shows at once and
costs one retyped request.

## Router

1. Drop an `--auto` token from `$ARGUMENTS` wherever it sits, before or after the request, and
   read what is left as the argument: the token puts the run under `--auto` and takes no part in
   the match, so the same path, issue reference or words route to the same Playbook with the flag
   as without it. Then read the argument's shape first (empty, a path, an issue reference), then
   its words.
2. Read the table's rows in order; the first row that matches wins. Each row sits above any
   broader row it could shadow.
3. An argument that opens with a Playbook's name matches that Playbook, subject to that Playbook's
   own door checks.
4. On a match, read that Playbook's reference and the references it links, and never another
   Playbook's, with the one exception Links names: a run carries one Playbook's context, not all of
   them.
5. On a row that matches no Playbook, end the run in one message: `Playbook: none` on the first
   line, then the door with the command to type. Nothing is written and no reference is read, since
   the skill that owns the request does that work better than a run that was never meant to.

| The argument | Match |
|---|---|
| empty | `Playbook: none`; one message asking for the task: a Ticket's path, an issue reference, or the request in words |
| a path that does not exist | `Playbook: none`; one line saying so |
| a path to a Ticket, in the format of [ticket-format.md](../../.agents/formats/ticket-format.md), or an issue reference (a number or a URL) resolved through the tracker file, `docs/agents/issue-tracker.md` | `ticket` |
| an issue reference the tracker's CLI cannot open | `Playbook: none`; one line saying so |
| an issue number or URL with no tracker file | `Playbook: none`; one message asking for the Ticket's path. The number is never matched against a list in the conversation |
| a Spec's path, in the format of [spec-format.md](../../.agents/formats/spec-format.md), or a pasted session summary | `Playbook: none`; one line saying a Spec fits no Playbook, since `do` takes one Ticket, with the command: `/tickets <spec>`, or `/journey <spec>` first when the Spec's `Journey:` line reads `required` and no journey sits beside it; `/spec` for a summary, since the discussion already happened |
| a question: how something works, why it was built that way | `Playbook: none`; `/how` for the mechanism, `/why` for the rationale, `/teach` to understand it end to end |
| a runnable throwaway: a layout, a variant to try | `Playbook: none`; `/prototype` |
| an integration of branches in words: rebase one branch onto another, or merge one branch into another, a conflict to resolve along the way included, or an argument opening with `integrate` | `integrate` |
| a bug in words: what happened, where, and the error or the wrong output. A defect a test can tell before from after, however small | `bug-fix` |
| a change in words that no test could tell before from after: a typo, a doc line, a comment, a formatting fix, a log wording, a rename inside one file, dead code, a lint fix. Never a bug, a new exported symbol, a changed signature or a change the user sees, whatever its size | `trivial` |
| a reshape of existing code in words, its behaviour unchanged: refactor, rename, extract, inline, dedupe, move this module. Never a request that moves behaviour a caller or a user observes | `refactoring` |
| a feature, and any other request with no Ticket | `Playbook: none`; `/discuss`, or `/spec` when the conversation already holds the discussion |

A Ticket's path is matched on that file alone: a Ticket its `Blocked by` line names is never opened
before the `ticket` door, whose script reads a blocker's `**Status:**` line and never its body.

A request in words turns on one question: could a test tell before from after? A defect it could
tell is `bug-fix` however small, and new behaviour is a feature. A change it could not tell is
`trivial` when it is one of the kinds that row lists, and `refactoring` when it reshapes code past
them: a rename that crosses files, an extract, a module moved.

<examples>
<example>
`the total shows 9.99 instead of 10.00 after a discount`: `bug-fix`, not `trivial`. A one-line
defect is still a defect a test can tell.
</example>
<example>
`fix the typo "recieve" in the README`: `trivial`. No test could tell before from after.
</example>
<example>
`rename getUser to fetchUser everywhere`: `refactoring`, not `trivial`. The rename reaches past one
file, and the behaviour its callers observe stays the same.
</example>
<example>
`add an archive button to the notes list`: `Playbook: none`, then `/discuss`. A feature with no
Ticket; the chain builds it once it is one.
</example>
</examples>

A matched Playbook whose reference is missing from Links is not installed in this session:
`Playbook: none`, one line naming the Playbook and the missing reference, nothing written.

## Non-negotiables

Each holds in every Playbook. Each carries its reason, and a case none of them names is judged by
those reasons.

- Every line a step names is carried by the Reply, per [reply.md](references/reply.md), and none is required as text written mid-run: a session that writes text as it goes is free to, and nothing depends on it. A headless session writes a line meant for the moment as thinking, which nobody reads ([ADR 0039](../../docs/adr/0039-a-do-runs-lines-reach-the-developer-through-the-reply-never-through-text-written-mid-run.md)).
- The matched Playbook's steps are copied verbatim as the checklist, the run's own todo list, before any task-specific item, and the Reply's Run section carries it with every step the run reached ticked `done:` or visible as `skip: <reason>`. A skipped step left visible is one the developer can question; a dropped one is not.
- A principle is named in the reply only with the decision it changed. A name with no decision is a citation the reader cannot check.
- A question is classified before it is asked: a fact a script can observe goes to a probe, and only a product or preference call goes to the human, since that call is the one answer the run cannot produce itself.
- The data shape and its organising structure are named before any logic, since logic written first fixes a shape nobody chose.
- Every delegate's diff is read by the session, which writes its own summary. A delegate's summary is its claim, and the diff is the evidence.
- A pause comes only before an irreversible write; reversible work is presented instead, since it can be undone after the developer reads it.
- "no" is an acceptable answer. A recommendation is a judgment, not a validation of the request.
- The worktree is created with `git worktree add` and entered with a bare `cd`; the frontmatter above denies the harness's worktree tool for the session, per [worktrees.md](../../.agents/worktrees.md).
- The run never lands and never fixes a Finding; the review does both, so what reaches the target branch has one owner ([ADR 0005](../../docs/adr/0005-do-code-review-owns-the-whole-review.md)). The one landing the run makes is a Ticket's branch on its Spec branch, through `scripts/land-spec.sh`, and never on the developer's branch ([ADR 0060](../../docs/adr/0060-a-ticket-lands-on-its-spec-branch-and-do-lands-it-there-itself.md)).
- The reply is in the language the session opened in, and everything written into the project is in English.

## Where a turn ends

A message with no tool call ends the turn, and the run stands still until the developer comes
back, which can be an hour later. The run ends a turn in three places only: its last message (the
Reply, or the one message of `Playbook: none`), whether the checklist ran through or a step's own
route ended the run early; a pause before an irreversible write; and a product or preference call
with nothing left to do that does not depend on its answer. It never ends one on any of these, all
met while work is still owed:

- a summary of what was done that announces the next step instead of taking it;
- an offer to carry on unless the developer would rather not;
- a list of decisions for the developer when none of them blocks the rest of the work;
- a milestone reached, or a long turn, taken as a good place to report.

A status note is welcome in the same message as the next tool call.

## Links

One per reference. A Playbook's reference is read only when a router line names it, with one
exception: a `ticket` run whose Ticket carries a defect with no named cause reads the
reproduce and cause steps of [bug-fix.md](references/bug-fix.md), those two and nothing else of
that Playbook. The reply reference is read last by every Playbook.

- [ticket.md](references/ticket.md): the `ticket` Playbook, which links the shared mechanics and the reply reference.
- [integrate.md](references/integrate.md): the `integrate` Playbook: its door script, its steps, and the link to the conflict loop it runs at every stop.
- [bug-fix.md](references/bug-fix.md): the `bug-fix` Playbook, which links the shared mechanics and the reply reference.
- [mechanics.md](references/mechanics.md): the shared mechanics the Playbooks that build in a worktree read through their steps: the worktree, the protected branch, the Ticket file, the reader, the delegates, the gate, the integration, the review, the verification, the close.
- [build-loop.md](references/build-loop.md): the build loop and its test authors, read by the Builder in a `ticket` run, by the step that is about to build in `bug-fix` and `refactoring`, and by the resume step for the `Behaviour:` line the loop's commits carry, so those readers carry none of the rest of the shared mechanics.
- [forks.md](references/forks.md): the forks, read by the step that reaches one, the shape step, the behaviours step or the build step, by the Resume step for the fork a resume meets again, and by the close step and the reply for a held Ruling: the probe that settles an empirical fork, the `choice-taker` that rules on a Design fork, and the Extreme fork that stops the run.
- [conflict-loop.md](references/conflict-loop.md): the conflict loop every stop of a replay runs, read by the step that reaches a stop and by the no-op state of the integration step, `A rebase that replays no commit.`, for an unapplied ledger entry's reapply, and by no other: the class the script reads, the mechanical and contested resolutions, the Loss ledger judged and reapplied, and the states git refuses.
- [digest.md](references/digest.md): the Digest the session writes from the reader's text and the run derives
  its behaviours from: the reader's brief, what the Digest holds, and where it is written.
- [plan.md](references/plan.md): the Plan the `do-planner` fork writes and the build loop builds from,
  read by the Plan step that forks it: the fork's brief, what the Plan holds, and where it is written.
- [builder.md](references/builder.md): the Builder the `ticket` Playbook's build step forks and the
  session fills the brief for, read by that step and by the fork itself: the brief's keys, the
  return's line set, what the Builder builds from and where it picks up.
- [tdd-fallback.md](references/tdd-fallback.md): the TDD fallback the build loop reads when the loop line reads `Loop: fallback`, with no unit test author in the project and no global one that can be dispatched, and a second way in under `Loop: global`, build-loop.md's `BLOCKED` route when the global unit test author comes back `BLOCKED` naming a run command the project map lacks: the run writes the failing test itself, and no test author is dispatched.
- [trivial.md](references/trivial.md): the `trivial` Playbook: its door checks, its steps and the door script they run.
- [refactoring.md](references/refactoring.md): the `refactoring` Playbook: its door checks, its steps and the pin it holds the reshape against.
- [reply.md](references/reply.md): the reply every Playbook writes last, its sections in order.
- [ticket-format.md](../../.agents/formats/ticket-format.md): the Ticket the `ticket` line matches, and the fields a run reads and writes.
- [spec-format.md](../../.agents/formats/spec-format.md): the Spec the door recognises, and its `Journey:` line.
