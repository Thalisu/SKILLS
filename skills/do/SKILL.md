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
A run waits on the developer only where "Where a turn ends" below says, and a long build spans
several Stretches of the Builder, each returning to the session on a time budget, so a run can
outlast an hour and they read it afterwards, through the Reply.

Every reply opens with `Playbook: <name>` on its first line, so a wrong match shows at once and
costs one retyped request.

## Router

1. Drop an `--auto` token from `$ARGUMENTS` wherever it sits, before or after the request, and
   read what is left as the argument: the token puts the run under `--auto` and takes no part in
   the match, so the same path, issue reference or words route to the same Playbook with the flag
   as without it. Then read the argument's shape first (empty, a path, an issue reference), then
   its words. For a path that exists, read the Ticket's kind before the table, with
   `bash <skill-dir>/scripts/ticket-kind.sh <path>`, where `<skill-dir>` is this skill's folder
   (`${CLAUDE_SKILL_DIR}` in Claude Code): the kind is a fact a script reads, and a duplicated or
   unknown `**Kind:**` line has to read as ambiguous rather than be taken by eye.
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
| a pull request URL, whatever words sit around it, as in `acompanhe esse PR <url>`, or words naming a pull request with its number, as in `PR 12` or `pull request #12`, a request to fix that pull request's CI included, or words asking for a pull request from one branch into another, as in `faça um PR de dev para prod`, the branch it comes from its head and the one it goes into its base, words naming one branch only included, as in `abra um PR de dev`. A bare number (`12`, `#12`) with no word naming a pull request goes on to the rows below. Above `integrate`, which would rebase or merge the pair itself, and above `bug-fix`, since that run never pushes to the pull request nor follows it to green | `pr` |
| an issue number or URL with no tracker file, `docs/agents/issue-tracker.md`. Above `setup` and `ticket`, which open an issue only through that file | `Playbook: none`; one message asking for the Ticket's path. The number is never matched against a list in the conversation |
| an issue reference the tracker's CLI cannot open, read with the tracker file's own command. Above `setup` and `ticket`, which both read an issue through that command | `Playbook: none`; one line saying so |
| a Ticket's path whose `ticket-kind.sh` output is `kind=setup` alone, with no `ambiguous=` line, or an issue reference whose `Kind` reads `setup`, read the way the tracker file describes. Any other kind, an ambiguous one included, goes on to the next row | `setup` |
| a path to a Ticket, in the format of [ticket-format.md](../../.agents/formats/ticket-format.md), or an issue reference (a number or a URL) resolved through the tracker file, `docs/agents/issue-tracker.md` | `ticket` |
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
`acompanhe esse PR https://github.com/acme/notes/pull/12`: `pr`, not `ticket`. The URL names a pull
request, so its row above the issue rows takes it first.
</example>
<example>
`follow pull request #12 to green`: `pr`, not `ticket`. The words name a pull request with its
number, so number 12 is never read as an issue.
</example>
<example>
`fix the CI of PR 12`: `pr`, not `bug-fix`. The fix is pushed to the pull request and followed to
green, which a `bug-fix` run never does.
</example>
<example>
`faça um PR de dev para prod`: `pr`, not `integrate`. The words ask for a pull request from `dev`
into `prod`, which the run opens or finds already open and follows, where `integrate` would rebase
or merge `dev` into `prod` itself.
</example>
<example>
`#12`: `ticket`, not `pr`. A bare number with no word naming a pull request is an issue number, as
it always was.
</example>
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

- The Reply is five parts, per [reply.md](references/reply.md): the Plan, For whom, Pending debt, the `Yours:` line when the run hands something over, and the Next step. Every other line a step names goes to the Run report, a file written under `--auto` alone ([ADR 0091](../../docs/adr/0091-the-do-reply-is-five-parts-and-the-run-report-is-written-only-under-auto.md)), and none is required as text written mid-run: a session that writes text as it goes is free to, and nothing depends on it. A headless session writes a line meant for the moment as thinking, which nobody reads ([ADR 0039](../../docs/adr/0039-a-do-runs-lines-reach-the-developer-through-the-reply-never-through-text-written-mid-run.md)).
- The matched Playbook's steps are copied verbatim as the checklist, the run's own todo list, before any task-specific item, and under `--auto` the Run report's Run section carries it with every step the run reached ticked `done:` or visible as `skip: <reason>`. A skipped step left visible is one the developer can question; a dropped one is not.
- A principle is named in the Run report only with the decision it changed. A name with no decision is a citation the reader cannot check.
- A question is classified before it is asked: a fact a script can observe goes to a probe; an observation of a surface only the developer can reach, which no script or probe can make (a device, a production-only dataset, a third-party callback), goes to the developer as a request to drive it and report what they see; and of the calls, only a product or preference call goes to the human, since those are the answers the run cannot produce itself ([ADR 0106](../../docs/adr/0106-an-observation-only-the-developer-can-make-is-a-place-a-do-turn-ends.md)).
- The data shape and its organising structure are named before any logic, since logic written first fixes a shape nobody chose.
- Every delegate's diff is read by the session, which writes its own summary. A delegate's summary is its claim, and the diff is the evidence.
- A pause comes only before an irreversible write; reversible work is presented instead, since it can be undone after the developer reads it.
- "no" is an acceptable answer. A recommendation is a judgment, not a validation of the request.
- The worktree is created with `git worktree add` and entered with a bare `cd`; the frontmatter above denies the harness's worktree tool for the session, per [worktrees.md](../../.agents/worktrees.md).
- The run never lands and never fixes a Finding; the review does both, so what reaches the target branch has one owner ([ADR 0005](../../docs/adr/0005-do-code-review-owns-the-whole-review.md)). The one landing the run makes is a Ticket's branch on its Spec branch, through `scripts/land-spec.sh`, and never on the developer's branch ([ADR 0060](../../docs/adr/0060-a-ticket-lands-on-its-spec-branch-and-do-lands-it-there-itself.md)). A landing puts a branch the chain built onto the branch it was built for. The `integrate` Playbook's rebase or merge is no landing: it is the one operation the developer named, over their own branches, written to the branch they stand on, per [integrate.md](references/integrate.md). The one push a run makes is the `pr` Playbook's: its own fixers' commits onto its pull request's head branch, by fast-forward only, never `--force`, never a merge and never to any other branch ([ADR 0086](../../docs/adr/0086-the-pr-playbook-pushes-fast-forward-only-to-its-pull-requests-head-shared-or-not.md)). The one rerun a check gets is the `pr` Playbook's `gh run rerun --failed` on the run of the pull request's head, after its fixer could not reproduce the failure, once per check per run ([ADR 0089](../../docs/adr/0089-the-pr-playbook-reruns-a-check-once-after-its-fixer-could-not-reproduce-it.md)).
- The reply is in the language the session opened in, and everything written into the project is in English.

## Where a turn ends

A message with no tool call ends the turn, and the run stands still until the developer comes
back, which can be an hour later. The run ends a turn in five places only:

1. its last message (the Reply, or the one message of `Playbook: none`), whether the checklist ran
   through or a step's own route ended the run early;
2. a pause before an irreversible write;
3. a product or preference call with nothing left to do that does not depend on its answer;
4. the `setup` Playbook's step message, which shows the developer the first missing setup step to
   run by hand
   ([ADR 0076](../../docs/adr/0076-the-front-end-builders-setup-is-a-ticket-run-by-a-playbook-of-its-own.md));
5. a request for an observation of a surface only the developer can reach, which no script or
   probe can make, asked with nothing left to do that does not depend on it, as the `bug-fix`
   Playbook asks it at its reproduce and verify steps, and the `ticket` Playbook after its Gate
   for a defect it diagnosed. It is asked under `--auto` as without the
   flag: it offers no options, so no `choice-taker` has a side to take
   ([ADR 0106](../../docs/adr/0106-an-observation-only-the-developer-can-make-is-a-place-a-do-turn-ends.md)).
It never ends one on any of these, all met while work is still owed:

- a summary of what was done that announces the next step instead of taking it;
- an offer to carry on unless the developer would rather not;
- a list of decisions for the developer when none of them blocks the rest of the work;
- a milestone reached, or a long turn, taken as a good place to report.

A status note is welcome in the same message as the next tool call.

## Links

One per reference. A Playbook's reference is read only when a router line names it, with one
exception: a `ticket` run whose Ticket carries a defect with no named cause reads the
reproduce and cause steps of [bug-fix.md](references/bug-fix.md), those two and nothing else of
that Playbook. The reply reference is read last by every Playbook but `setup`, which writes its own messages.

- [ticket.md](references/ticket.md): the `ticket` Playbook, which links the shared mechanics and the reply reference.
- [setup.md](references/setup.md): the `setup` Playbook, which runs a Setup ticket in the main checkout one step at a time. It links no other reference and writes its own messages.
- [pr.md](references/pr.md): the `pr` Playbook, which follows one pull request: its steps, and the read-back of the pull request it follows.
- [integrate.md](references/integrate.md): the `integrate` Playbook: its door script, its steps, and the link to the conflict loop it runs at every stop, the one shared reference it reads besides the reply.
- [bug-fix.md](references/bug-fix.md): the `bug-fix` Playbook, which links the shared mechanics and the reply reference.
- [mechanics.md](references/mechanics.md): the shared mechanics the Playbooks that build in a worktree read through their steps: what no step does, the worktree, the protected branch, the Ticket file, the reader, the delegates, the gate, the integration, the landing on the Spec branch, the final integration, the review, the verification, the close.
- [not-landed.md](references/not-landed.md): a review return that did not land and the fix call, read only when the review route script prints a `route=` line other than `route=verify`, on the first review's return or a fix call's, by the review step of each Playbook and of the shared mechanics, by the Final integration's review step, its stop and its resume, by the Resume paths that land through the fix call on a Review the run already has, and by the verification's red flow handed to the fix call: the routes, the moved target integrated again, the blocked stop and its `Yours:` direction, and the fix call's lines.
- [build-loop.md](references/build-loop.md): the build loop and its test authors, read by the Builder in a `ticket` run or by the session in its place when no Builder can be forked, by the step that is about to build in `bug-fix` and `refactoring`, and by the resume step for the `Behaviour:` line the loop's commits carry, so those readers carry none of the rest of the shared mechanics.
- [forks.md](references/forks.md): the forks of a `ticket` run, read by its Plan step and its build step when one reaches a fork, by its Resume for the fork a resume meets again, by a step of that run whose question the `choice-taker` rules under `--auto`, and by its close and the reply for a held Ruling: the probe that settles an empirical fork, the `choice-taker` that rules on a Design fork, the Extreme fork that stops the run, and the run question `--auto` hands to the `choice-taker`. The `bug-fix`, `refactoring` and `trivial` Playbooks carry their own forks and run questions in their own references and never read this one ([ADR 0105](../../docs/adr/0105-forks-md-is-the-ticket-playbooks-and-each-outside-chain-playbook-carries-its-own-forks.md)).
- [conflict-loop.md](references/conflict-loop.md): the conflict loop every stop of a replay runs, read by the step that reaches a stop and by the no-op state of the integration step, `A rebase that replays no commit.`, for an unapplied ledger entry's reapply, and by no other: the class the script reads, the mechanical and contested resolutions, the Loss ledger judged and reapplied, and the states git refuses.
- [digest.md](references/digest.md): the Digest the session writes from the reader's text and the run derives
  its behaviours from: the reader's brief, what the Digest holds, and where it is written.
- [plan.md](references/plan.md): the Plan the `do-planner` fork writes and the build loop builds from,
  read by the Plan step that forks it and by the resume that fills its `Built:` key, by the fork as its
  contract, and by the session in its place when no Planner can be forked: the fork's brief, what the
  Plan holds, and where it is written.
- [builder.md](references/builder.md): the Builder the `ticket` Playbook's build step forks and the
  session fills the brief for, read by that step and by the fork itself: the brief's keys, the
  return's line set, what the Builder builds from and where it picks up.
- [impeccable.md](references/impeccable.md): the `do-impeccable` fork the same build step makes in
  the Builder's place for a Front-end ticket of a Spec reading `Front-end: impeccable`, read only
  when the door prints `kind=front-end` with `front_end=impeccable`, by the Door, the Plan step, the
  build step, the close and the Reply of that run: the Door's stop for a session with no impeccable
  skill, the skipped Planner, the fork and the main checkout check around it, the brief's four keys,
  how its return reads beside a Builder's, and the Reply lines proper to that run.
- [stand-in.md](references/stand-in.md): the session in the place of `do-reader` or `do-builder` when the Agent tool is withheld from it or lists no such agent, read then and only then by the `ticket` door that forks the reader, by every run that forks it again (a second run that finds a document moved, a Ruling that rewrote a Ticket criterion, the resume after `discuss`), by the build step that forks the Builder and by the Resume that forks it at the first behaviour without a commit.
- [elsewhere.md](references/elsewhere.md): the stop on work for another repository, read only when a `ticket` run meets it, by its Plan step when the verified Plan's `## Behaviours` carry an `Elsewhere:` item and by its build step when the Builder's return carries a `stopped: work for another repository:` line: the move told from a change of direction, the finding `spec-finding.sh` writes into the Spec, the `outward` class and the Reply `reply-lines.sh elsewhere` prints.
- [tdd-fallback.md](references/tdd-fallback.md): the TDD fallback the build loop reads when the loop line reads `Loop: fallback`, with no unit test author in the project and no global one that can be dispatched, and a second way in under `Loop: global`, build-loop.md's `BLOCKED` route when the global unit test author comes back `BLOCKED` naming a run command the project map lacks: the run writes the failing test itself, and no test author is dispatched.
- [trivial.md](references/trivial.md): the `trivial` Playbook: its door checks, its steps and the door script they run.
- [trivial-escape.md](references/trivial-escape.md): what a `trivial` run does when its door on the diff fails, read by step 5 of that Playbook, the door on the diff, when `trivial-door.sh diff` exits other than 0, and by no other: the restore and re-route of a diff that is not Trivial, the blocked stop, and the run's own judgment where the script has no pattern.
- [refactoring.md](references/refactoring.md): the `refactoring` Playbook: its door checks, its steps and the pin it holds the reshape against.
- [refactoring-design-fork.md](references/refactoring-design-fork.md): the Design fork of a
  `refactoring` run, read by its step 4, Structure, and step 6, Reshape, when the step meets two
  shapes it cannot settle, and by its step 15, Reply, for the line of a Ruling the `choice-taker`
  made: the `choice-taker`'s brief, the return check, the Ruling's line and the unruled stop.
- [refactoring-extreme-stop.md](references/refactoring-extreme-stop.md): the Extreme stop of a
  `refactoring` run, read by its Design fork procedure when a side reads as Extreme, when the
  `choice-taker` returns `extreme`, and when the fork goes unruled: the blocked reply, its
  `Yours: direction:` line and the `/discuss` command `next-step.sh` prints.
- [refactoring-auto.md](references/refactoring-auto.md): the run questions of a `refactoring` run
  under `--auto`, read by its step 1, step 2, step 3, step 8 and step 13 when the run carries
  `--auto` and reaches the step's question: the `choice-taker`'s brief and return check, the three
  questions it rules, and the discard and the revert still asked of the developer.
- [reply.md](references/reply.md): the reply every Playbook writes last, its five parts in order, and the Run report written under `--auto`.
- [ticket-format.md](../../.agents/formats/ticket-format.md): the Ticket the `ticket` line matches, and the fields a run reads and writes.
- [spec-format.md](../../.agents/formats/spec-format.md): the Spec the door recognises, and its `Journey:` line.
