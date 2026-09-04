---
name: tickets
description: "Cut a spec, and the journey its verdict points at, into tracer-bullet tickets: one demoable vertical slice per ticket, each declaring the tickets that block it, published one file per ticket locally or one issue per ticket on the project's tracker. Stops before writing anything when the journey is required but missing, contested, or already ticketed."
disable-model-invocation: true
argument-hint: "[the spec: a path, the feature slug, or an issue reference]"
---

# Tickets

Every message to the user is written in the language the user opened the session in. Everything
written into the repository or the tracker is in **English**.

Ground → stop on a broken input → explore → draft the slices → quiz → publish → close.

Vocabulary, used consistently: _ticket_ (one demoable slice cut from a spec, and from its journey
when it has one: a narrow but complete path through every layer, sized to fit one session),
_blocking edge_ (a ticket that must complete before another can start), _frontier_ (every ticket
whose blockers are all done), _path_ (one thing the actor sets out to do end to end, as the journey
walked it), _verdict_ (the `Journey:` line under the spec's title: `required`, `not needed` with
the condition, or the journey's location once it is written), _tracker file_
(`docs/agents/issue-tracker.md`, which says where specs and tickets live in this project), _parent_
(the spec the tickets hang from), _stop_ (the run ending on a broken input, with one message and
nothing written).

## 1. Ground

`$ARGUMENTS` is the spec and it is mandatory: the chain is strict, `tickets` takes a spec and never
the conversation. Empty: one message asking for it, nothing else. Resolve it as `spec` publishes
it: a path is read as a file; a bare slug resolves to `.scratch/<slug>/spec.md` when the tracker
file says local markdown or is absent; an issue number or URL is read through the tracker the file
describes, body and comments. Nothing readable: one message asking for the path.

The tracker file says where tickets are published and which triage labels exist. Without it, the
tickets are published as local markdown under `issues/` in the spec's directory, the thread says
so in one line, and no setup skill is ever demanded.

Read the spec fully, in the format of
[.agents/formats/spec-format.md](../../.agents/formats/spec-format.md): its User Stories are the
candidate paths when there is no journey; its Implementation Decisions, Testing Decisions and Out
of Scope are constraints every ticket respects.

**The verdict.** The `Journey:` line under the spec's title says whether there is a journey:

| The line | What happens |
|---|---|
| a location: `./journey.md`, `docs/journeys/<slug>.md`, or a link | the journey is read, fully; a relative location resolves from the spec file in local mode and from the repository root in a remote tracker |
| `not needed, <condition>` | the User Stories are the paths, said in one line |
| `required` | a stop: the journey was never walked |
| no line | the spec did not come from `spec`; the User Stories are the paths, said in one line |

A `journey.md` beside the spec that the verdict does not name is an orphan: named in that same
line, never read.

The journey is read in the format of
[.agents/formats/journey-format.md](../../.agents/formats/journey-format.md). `tickets` reads
these parts of it and nothing else:

| Section | What it gives the cut |
|---|---|
| each path section: the story it realises, the outcome, the step table, the failure branches, its `Settled by prototype:` line | one ticket per path: its "What to build", its acceptance criteria, and a snippet when one settled a fork |
| `## States` | the order of the tickets and their blocking edges |
| `## Cut`, `## Deferred` | what is never ticketed |
| `## Reopen in discuss` | a stop when it lists anything |

`## Spec changes applied` is already in the spec and needs nothing. `## Defaults taken` is context,
not a constraint.

Then read `CONTEXT.md` (the root one, or the context `CONTEXT-MAP.md` names) and the ADR titles
under `docs/adr/`, bodies for the ones the spec touches; and `git status --short` with the branch,
since dirty files are the user's work in progress.

**Stops.** Each ends the run before the code is explored and before anything is written, with one
message naming the problem and nothing else. There is no override in the conversation: the way past
a stop is to fix the input and run again.

| Condition | The message |
|---|---|
| the verdict is `required` and names no journey | the verdict, and that `/journey` walks the spec before tickets are cut; a `journey.md` beside the spec that the verdict does not name is mentioned |
| the verdict names a file that does not exist | the line, and the location it named |
| the journey's `## Reopen in discuss` lists a branch | each branch, and that `/discuss` settles them before the journey is walked again |
| tickets for this feature already exist: files under `issues/` beside the spec in local mode, or open issues naming the spec as their parent in remote mode | each existing ticket; whoever wants a recut closes or deletes them first |

## 2. Explore the code

Explore the codebase the spec touches, unless the conversation already did: enough to name the
modules a slice crosses, to write every title and description in the glossary's words, and to
respect the ADRs in that area. Large outputs go to a subagent; the thread keeps the summary.

Look for prefactoring that makes the slices easier to land: make the change easy, then make the
easy change. Prefactoring is its own ticket, and comes first.

## 3. Draft the slices

Cut the work into tracer-bullet tickets.

- Each slice cuts a narrow but complete path through every layer (schema, API, UI, tests):
  vertical, never a horizontal slice of one layer.
- A completed slice is demoable or verifiable on its own.
- Each slice is sized to fit in a single fresh context window.
- Any prefactoring comes first.

**With a journey**, one path is one ticket, as the starting cut. The path's outcome is its "What to
build", opening with the path's name. Its step table rows and its failure branches are the
acceptance criteria, in the actor's words. `## States` orders the tickets and draws the blocking
edges: a path that needs state another path creates is blocked by it (create before edit before
delete). `## Cut` and `## Deferred` are never ticketed, and are listed in the quiz message under
what was left out. A path's `Settled by prototype:` line, when the journey carries one, may be
inlined under the snippet rule in step 5. A path too large for one context window is split along
its steps, every piece still demoable.

**Without a journey**, the User Stories are the paths, cut by the same rules.

Give each ticket its blocking edges: the tickets that must complete before it can start. A ticket
with no blockers can start immediately.

**Wide refactors are the exception to vertical slicing.** A wide refactor is one mechanical change
(rename a column, retype a shared symbol) whose blast radius fans across the whole codebase, so a
single edit breaks thousands of call sites at once and no vertical slice can land green. Sequence
it as expand and contract instead. Expand: add the new form beside the old, so nothing breaks.
Migrate: move the call sites over in batches sized by blast radius (per package, per directory),
each batch its own ticket blocked by the expand, CI green from batch to batch because the old form
still exists. Contract: delete the old form once no caller remains, in a ticket blocked by every
migrate batch. When even the batches cannot stay green alone, keep the sequence but let them share
an integration branch that all block a final integrate-and-verify ticket; green is promised only
there.

## 4. Quiz the user

Present the breakdown as a numbered list. For each ticket:

- **Title**: short, in the glossary's words
- **Path**: the journey path it realises, when there is a journey
- **Blocked by**: the tickets that must complete first, or none
- **What it delivers**: the end-to-end behaviour this ticket makes work

After the list, what was left out: the journey's cut and deferred items, and the spec's Out of
Scope.

Ask the user:

- Does the granularity feel right? (too coarse / too fine)
- Are the blocking edges correct: does each ticket depend only on tickets that genuinely gate it?
- Should any tickets be merged or split further?

Iterate until the user approves the breakdown. Nothing is published before that.

## 5. Publish

Publish the approved tickets the way the tracker file describes. The tickets are the same either
way; only the shape of the blocking edges changes.

- **Local markdown**: one file per ticket under `.scratch/<feature-slug>/issues/<NN>-<slug>.md`
  (or `issues/` beside a spec that lives elsewhere), numbered from `01` in dependency order
  (blockers first), in the local template below. Each file's "Blocked by" lists the numbers and
  titles it depends on. Never a single combined file.
- **A real tracker (GitHub, GitLab, Linear)**: one issue per ticket in dependency order (blockers
  first), so each ticket's blocking edges reference real identifiers, in the issue template below.
  Use the platform's native blocking or sub-issue relationship where it has one; otherwise
  "Blocked by" names the blocking issues. Apply the `ready-for-agent` triage label unless told
  otherwise: the tickets are agent-grabbable by construction.

Never close or modify the parent.

<local-ticket-template>

# <NN>: <Ticket title>

**What to build:** the end-to-end behaviour this ticket makes work, from the actor's perspective, not a layer-by-layer implementation list.

**Blocked by:** the numbers and titles of the tickets that gate this one, or "None (can start immediately)".

**Status:** ready-for-agent

- [ ] Acceptance criterion 1
- [ ] Acceptance criterion 2

</local-ticket-template>

<issue-template>

## Parent

A reference to the parent spec on the tracker (omit when the source was not an issue).

## What to build

The end-to-end behaviour this ticket makes work, from the actor's perspective, not layer by layer.

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2

## Blocked by

- A reference to each blocking ticket, or "None (can start immediately)".

</issue-template>

In either form, no file paths and no code snippets: they go stale fast. The one exception is a
snippet a prototype produced, or the journey's `Settled by prototype:` line, when it encodes a
decision more precisely than prose can (a state machine, a reducer, a schema, a type shape):
inline the decision-rich part, trimmed, and say in a line where it came from.

## 6. Close

In the thread: every ticket published, with its identifier and its blocking edges; the frontier;
what was left out. Nothing is committed. The next step is one ticket at a time from the frontier
(stand-in until /do exists: none; the chain ends at the tickets, and the line becomes
`/do <ticket>`).

## Hard rules

- The spec is the only input, and it is mandatory: never the conversation, never a session summary.
- The four stops write nothing and end the run with one message. No override in the conversation.
- Nothing is published before the user approves the breakdown.
- One ticket per file or per issue, never a combined file. The parent is never closed or modified.
- Ticket text in the glossary's words, with no file paths and no code, except a snippet that
  encodes a decision.
- Never commit, never push.
- Prose written into the project or the tracker carries no em-dash.
- Every message to the user in the session's opening language; every write in English.
