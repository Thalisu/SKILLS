---
name: journey
description: "Walk every path of a spec from the actor's seat: how they arrive, what they see, what they do, what the system answers, what happens when it fails. Each path is drafted from the app's precedent and shown once; only the forks the precedent leaves open become questions, one per message. Writes the journey beside the spec and points the spec at it."
disable-model-invocation: true
argument-hint: "[--auto] [the spec: a path, the feature slug, or an issue reference]"
---

# Journey

This session is an interview about a spec, held from the actor's seat before any ticket is cut. Its product is the journey: every path the spec's stories describe, written as the steps the actor walks, with what they see, what they do, what the system answers and what happens when it fails. `tickets`, the next skill in the chain, cuts one ticket per path, so a step left vague here becomes a ticket built on a guess.

The spec is the subject of the interview, never a task to carry out. However concrete a story reads, nothing in it is built here: the session writes the journey, `CONTEXT.md` and the spec's own sections, and edits no code.

The interview is about the journey only. Data shape, boundaries, seams and delivery order are decisions `discuss` and `spec` already made. The journey takes them as given, and no message to the user asks a technical question.

The user's attention is the scarce resource. The app already answers most of a path: a sibling page lists, creates, confirms and fails the way the story needs. So each path is drafted from that precedent and shown, and only what the precedent leaves open becomes a question. A question the app could have answered, or one about a detail that is cheap to change, spends attention the real forks need, so every rule below either saves a question or makes the ones that remain easier to answer.

Every message to the user is written in the language the user opened the session in. Everything written into the project (the journey, its file name, the spec's edits, `CONTEXT.md`) is in **English**; UI copy the journey quotes stays in the product's language.

The run, in order: ground → tree → draft each path, one question per open fork → capture as it lands → close.

## Vocabulary

Used consistently, in the thread and in what the session writes:

- _actor_: who walks the path.
- _path_: one thing the actor sets out to do, end to end. The unit of the tree, and later the unit `tickets` cuts.
- _step_: what the actor sees, what they do, and what the system answers.
- _precedent_: a sibling page or flow in the app that already answers a step.
- _fork_: a step the precedent does not settle. The unit of a question.
- _failure branch_: a step that ends somewhere other than the outcome, and what the actor sees there.
- _cut_: a step or control deliberately left out.
- _lens_: a principle turned into a question, read from the actor's seat.
- _tell_: the answer that fails a lens.
- _default_: an answer taken and stated instead of asked.
- _deferral_: a fork parked with the condition that reopens it.
- _runnable_: a fork only a screen can settle. A throwaway prototype is built and the question is put against it.

## How a turn ends

A message with no tool call ends the turn, and the session waits there until the user writes again. The turn ends at these points and no others:

- the ask for a spec that is missing or cannot be read (step 1);
- a question to the user (step 3): an open fork, a spec change that is hard to reverse (step 4), or a prototype's ask that only the user can answer;
- a wait on a prototype, when every fork still open depends on its report: one line naming the fork it is being built for, and nothing guessed about what the report will say;
- the close (step 6).

Under `--auto` (step 3) an open fork is ruled, never asked, so the turn ends at the ask for the spec and at the close only. Nobody is watching that run: a turn that ends anywhere else stops the walk with paths still open.

Everything between those points happens in one turn. The precedent note, the tree, the first path's draft and the first question arrive together: the session never stops after the note or the tree to ask whether to begin. A path that closes with no open fork is captured and the next path is drafted in the same turn. After an answer, the check, the capture and the next question are one turn too. A status line is welcome, in the same message as the next tool call. A turn that ends on a progress summary, on an announcement of the next path, or on an offer to carry on leaves the user to type "go on" for work that needed nothing from them. When a message is about to end that way, make the next tool call instead.

## 1. Ground

**The spec.** `$ARGUMENTS` is the spec and it is mandatory. An `--auto` token among the arguments, before the spec, after it or inside it, is dropped wherever it sat and puts the run under `--auto` (step 3); the spec is the rest, with no flag in it, resolved exactly as it is without the flag. Empty → ask for it, in one message that carries nothing else. Otherwise resolve it as `spec` publishes it:

| The argument | Read as |
|---|---|
| a path | the file at that path |
| a bare slug | the file the resolver names (below). Local markdown or no tracker file only |
| an issue number or URL | the issue, body and comments, through the CLI the tracker file names |

A bare slug goes through the one executable form of the rule that says which feature folder a slug names, per [.agents/scratch.md](../../.agents/scratch.md):

```
bash <skill-dir>/../../.agents/scripts/resolve-feature-folder.sh <slug>
```

The spec is the file its `spec=` line names. The run never lists `.scratch/` to pick a folder by its own reading of the names, and never falls back to a rule of its own: a slug can carry several dated folders, and a folder that only ends in the slug is another feature.

Nothing readable → one message asking for the spec's path, and nothing else. These are nothing readable too: a resolver that answers `spec=none`, one that exits 2, and one the session cannot find at that path, since a machine may have linked `skills/` without the rest of this repo.

**The reading.** Before any draft, read what the project already knows. Say in one line what is being read, then make the reads that do not depend on one another in one batch:

- **The spec**, fully, in the format of [.agents/formats/spec-format.md](../../.agents/formats/spec-format.md). Its User Stories are the candidate paths. Its Implementation Decisions, Testing Decisions and Out of Scope are constraints the journey never reopens on its own. The `Journey:` line under the title is the verdict `spec` wrote: `required` is the normal case here, and a spec that says `not needed` is still walked when the user asks. Either way the line is replaced at the close.
- **A journey already there**, where the table in step 4 puts it (a rerun, or a run that stopped before its close). It is precedent too: a path whose story is unchanged stays closed with its rows, only new or changed stories are walked, and the file is rewritten in place.
- **The glossary and the ADRs.** `CONTEXT.md` (the root one, or the context `CONTEXT-MAP.md` names) and the titles under `docs/adr/`, bodies for the ones the spec names. Labels, statuses and messages use the glossary's words.
- **The working tree.** `git status --short` and the branch: dirty files are the user's work in progress and part of the picture.
- **The precedent.** The sibling pages and flows that already do what the stories do: a list with filters, a create form, a delete confirmation, an empty state, an error line, a status label, the navigation they hang from. A handful of sibling files is read in the thread. A search whose output would run to pages (many pages, several candidate siblings per story) goes to one subagent, briefed with the patterns the stories need and asked for one `file:line` per pattern found and a plain "none" for each one missing; the thread keeps what it returns, never the files.

**The precedent note.** Output, in the thread, a precedent note of three to six lines: which sibling settles which pattern, each with `file:line`, and every contradiction between a story and the app as it is. A contradiction found here is the first fork of the path it belongs to, and the question it becomes is which side wins, never whether the app really is that way: that part was read.

One shape the note can take. The wording is the project's own; the `file:line` on every claim is not optional:

<example>
Precedent: the Members page.
- List, search box and empty state "No members yet": src/pages/members/list.tsx:18, :31, :52
- Add form opens in place, Save and Cancel, confirmation line "Member added": src/pages/members/form.tsx:9, :44
- Remove asks in a dialog, "Remove this member?": src/pages/members/list.tsx:74
- No sibling shows a status label or filters by one: none found under src/pages/
- Contradiction: story 3 says a revoked invite is "archived"; nothing in the app archives, Members removes outright (src/pages/members/list.tsx:74)
</example>

## 2. Build the tree

One branch per path, read off the User Stories.

- **Fold.** A story that is a step of another folds into it.
- **Out of Scope.** A path the spec's Out of Scope excludes closes at once, with the line that excludes it.
- **Order.** Order the walk by the actor: the path they walk first, then the ones that need state it creates (create before edit before delete), so every path lands as one demoable slice ([sequence-verifiable-units](../../.agents/principles/sequence-verifiable-units.md)); `tickets` reads that order back from `## States`.
- **Lenses.** Tag each fork with the lenses from step 5 that apply to it.
- **Runnable.** Mark a fork _runnable_ when only a screen can settle it: a step with no precedent anywhere in the app, or one the user answers with "I need to see it".

Show the tree once, compact, with each path's state: `open`, `decided`, `default`, `deferred`, and `ruled` under `--auto` (step 3). Keep it updated as paths close; show it again only when its shape changes (a path folded, a fork that opened a path). A path closing is not a shape change.

One shape the tree can take. The layout is free; the state on every row and the stories it realises are not:

<example>
1. [default] See the pending invites (story 1): the Members list, nothing open
2. [open] Invite a teammate (stories 2, 5): how the role is chosen · laziness-protocol; an email already invited · make-operations-idempotent
3. [open] Revoke an invite (story 3): "archived" against a page that removes · redesign-from-first-principles
4. [open, runnable] Review the access before accepting (story 4): no sibling screen · exhaust-the-design-space
</example>

## 3. Interview, one path at a time

For the first open path, in walk order:

1. **Draft first.** Write the path's step table from the precedent and the spec, every default taken and marked as such, and show it once. This is the explore-first rule: a fork the precedent settles is closed with `file:line` and never asked. A path with no open fork closes here, is captured (step 4), and the next path is drafted. The shape is under "The draft" below.
2. **Talk before running.** A prototype is built only for a fork marked _runnable_; a fork the user can answer from a description never gets one. The mechanics are under "A runnable fork" below.
3. **One question per message.** The message carries three things and nothing else: the question, the tell it hunts in one line, and the recommended answer with its reason. Never a list of questions, never a second question in the same message: one question gets a considered answer, and a list gets the first item answered and the rest skimmed. The first question of a path rides under its draft, since the draft is what the question is about.
4. **Wait for the answer.**
5. **Check the answer.** Push back once, with the evidence; the user's repeat is the decision.
   - Against the glossary: a label or a status in a sense `CONTEXT.md` does not give is called out at once ("your glossary defines X as ..., the screen would say ..."), and a fuzzy or overloaded word gets a proposed canonical term.
   - Against the spec: an answer that contradicts a decision is named as a spec change and handled by step 4.
   - Against the precedent: a claim about how a sibling page behaves is read in the code before it is accepted, and a contradiction is surfaced with `file:line`.
   - Against a scenario: one concrete case at the boundary ("the actor deletes the last item on page three: what do they see?").
6. **Close the fork.**
   - `decided`: the user chose.
   - `default`: a reversible detail. State the choice and its reason instead of asking.
   - `deferred`: parked, with the condition that reopens it, in one line.

   The path closes when its last fork does.
7. **Capture** (step 4), then update the tree.

A reversible detail (a label, a column order, a control's position where the precedent has one) is never a question. The question budget goes to what the actor sees and does at a fork with no precedent, to what is cut, and to what happens when the path fails.

### The draft

The step table has the columns the journey keeps: Step, Actor sees, Actor does, System answers, with the failure branches under it. In the thread every cell the precedent settles carries its `file:line`, so the user can check a default instead of trusting it, and every fork is named where it sits, so the user sees what is still open before the first question. The journey file is another reader: there a step names the sibling page by its name and carries no path and no code, as its format says.

One shape the draft can take. The steps, the copy and the number of forks are the path's own:

<example>
Path 2: Invite a teammate (stories 2, 5)
Outcome: the invite tops the pending list as "Pending", under the line "Invite sent to ana@example.com".

| Step | Actor sees | Actor does | System answers |
|---|---|---|---|
| 1 | The Invites list, "Invite teammate" above it (default: where Members puts "Add member", list.tsx:22) | Presses "Invite teammate" | The form opens in place, email focused (default: form.tsx:9) |
| 2 | Email and Role, "Send invite" and "Cancel" (default: form.tsx:44) | Types the email, picks the role (**fork A**: how the role is chosen), presses "Send invite" | The form closes, the invite tops the list as "Pending", the line "Invite sent to {email}" (default: form.tsx:61) |

Failure branches:
- an email that is not one: the error beside the field, before submit (default: form.tsx:30)
- an email already invited: **fork B**, no sibling refuses a duplicate
</example>

### The question message

Three parts, in this order, in the user's language (the labels are translated with the rest). The examples show the shape on three kinds of fork; the wording, the length and the domain are the fork's own.

<examples>
<example>
An ordinary fork:

On the invite form, is the role picked on every invite, or does every invite start as Member?

Tell: a required field carrying a decision the actor makes the same way nearly every time.

Recommendation: preselect Member and keep the field visible. The common invite is one field and one press, and an admin invite costs one more click on the same form.
</example>
<example>
A runnable fork, put against the prototype's report:

Open `http://localhost:3000/invites/accept?proto=1` and switch between the three variants with the bar at the top. On which one can you say what the invite lets you do before you press Accept?

Tell: the screen lists every permission the role has, and the invitee accepts without reading any of them.

Recommendation: variant C, the three lines of what changes for you. A and B print the whole permission table, which is the admin's view of a role, not the invitee's.
</example>
<example>
A story the app contradicts:

Story 3 says a revoked invite is "archived", and nothing in the app archives: Members removes outright behind a confirmation (src/pages/members/list.tsx:74). Does revoking remove the invite from the list, as removing a member does, or keep it under an Archived filter?

Tell: one page with its own archive pattern beside siblings that all remove.

Recommendation: remove it, with the same confirmation and the line "Invite revoked". The actor already knows that pattern, and an archive is a new state the spec's decisions do not name.
</example>
</examples>

### A runnable fork

1. **Fork.** Call the Agent tool with `subagent_type: prototype` and a brief:
   - the question in one line;
   - the shape: `ui`, unless the fork is about how a state model behaves across the steps, which is `logic`;
   - the page or route the path lives on, from the precedent note; a screen with no home says so, and the agent gives it a throwaway route;
   - the data the step renders or the actions it takes;
   - every constraint the spec and this session have already decided.

   The agent builds in the background and reaches nobody while it does, so the brief is complete: a thin brief buys an assumption, or costs a round trip.
2. **Keep walking** the forks that do not depend on this one.
3. **The report.** When the six-line report lands, put the question against the artifact in the shape of item 3, with where to open it and what to look at.
4. **An ask instead.** A report that opens with `PROTOTYPE ask` is the agent stopped before writing anything, on one part of the brief it could neither read off the code nor infer without changing what the prototype settles. Treat it as a fork:
   - answer it from the spec, the precedent or a fork already closed when any of them can;
   - only otherwise put it to the user as one message in the shape of item 3, with the report's `readings:` line supplying the recommendation.

   Then resume the same agent by calling the SendMessage tool with the answer, never the Agent tool again, which would start a second agent with none of what the first one read.

### Under `--auto`

The flag is the developer handing direction over for one run. No fork is put to the user, and the run continues to the close without waiting on anyone.

Each path is still drafted first (item 1): the precedent closes what it settles, and a reversible detail still takes a default. A fork the draft leaves open is ruled in place of items 3 to 6. To rule a fork, call the Agent tool with `subagent_type: choice-taker` and the brief its definition fixes, filled from the question item 3 would have asked:

```
Caller: journey at the interview step
Question: <the fork's question, in one line>
Options: <two or more options, one per line>
Recommendation: <the recommended answer item 3 would have carried>
Repository root: <the project's absolute path>
Principles: <the absolute path of the skills checkout's .agents/principles/ folder>
Context: <the spec, the precedent note and the journey so far>
```

- **`Context:`** hands over three things, since the fork sees nothing of this thread:
  - the spec, by its absolute path, or as text (the issue's body and comments) when it lives on a tracker, since the fork holds no shell to fetch one;
  - the precedent note of step 1, as text;
  - the journey so far: the journey file's absolute path once a path has been written to it, and, as text, the draft of the path the fork sits in with the side every fork of that path already took, whatever closed it. A fork is then never ruled against a side the walk already took.
- **`Principles:`** is the folder the lenses of step 5 link, resolved to an absolute path from this file's own location: the project being walked has no `.agents/principles/` of its own, and the fork holds no shell to find one.
- **One fork at a time**, in walk order, never two briefs in one batch: each brief carries the sides the earlier ones took, and a brief sent beside another carries none of them.

A `settled` return closes the fork as `ruled`: the side its `Side:` line names goes into the path's rows as a chosen one would. The path closes when its last fork does and reads `ruled` in the tree when any fork of it was ruled, which is not a shape change (step 2). It is captured (step 4) before the next path's first fork is sent, so the next brief can name the journey file, and the next path is drafted in the same turn.

## 4. Capture as it lands

Never batched: each item is written the moment its fork or path closes, before the next question. A session can stop at any question, and what was only in the thread is lost with it. Nothing is written before something closes: a draft and a proposed term live in the thread until then.

- **A closed path** goes to the journey in the format of [.agents/formats/journey-format.md](../../.agents/formats/journey-format.md): its rows, its failure branches, and the one-line answer of a prototype when there was one. The file is created on the first closed path, where the tracker file puts it:

  | Tracker file says | The journey is | The spec's `Journey:` line becomes, at the close |
  |---|---|---|
  | local markdown, or no tracker file | `journey.md` in the spec's own folder, beside it, never a folder of its own | `Journey: ./journey.md` |
  | GitHub or GitLab | `docs/journeys/<feature-slug>.md` in the repository, plus a comment on the spec issue that links it | `Journey: docs/journeys/<feature-slug>.md`, edited into the issue body through the CLI the tracker file names |

  The spec's `Status:` line is never touched. `tickets` finds the journey through the `Journey:` line and stops on a `## Reopen in discuss` that lists anything. In the local row, the project's `.gitignore` carries the `.scratch/` line before the first write, per [.agents/scratch.md](../../.agents/scratch.md).
- **A resolved term** goes to `CONTEXT.md` (the root one, or the context's own when the map names it) in the format of [.agents/formats/context-format.md](../../.agents/formats/context-format.md). The file is created on the first term. Labels and statuses the actor sees are the terms a journey resolves most; no implementation detail.
- **A spec change**, when a path proves the spec wrong:

  | The change | What happens |
  |---|---|
  | reversible: a field the actor needs to see, a step order, a missing story, a message | the matching section of the spec is edited in place, in the format of [.agents/formats/spec-format.md](../../.agents/formats/spec-format.md), and the change is listed in the journey under `## Spec changes applied` |
  | hard to reverse, or touching an ADR: a new entity state, a schema change, an interaction an ADR forbids | the path stops; one message asks which side wins, with the evidence; when the spec loses, the branch is recorded under `## Reopen in discuss` and the walk moves on |

  `journey` never writes an ADR and never edits code.
- **A contradiction** between a story and the app as it is, is never resolved by editing code here: the user says which side is right, and the path and the summary record it.
- **A prototype** is never captured, only its answer: the decision, and the variant or scenario that settled it, in one line of the path. Its files stay where the agent left them, outside version control, listed in the closing summary.

## 5. Lenses, in walk order

Each lens is the question it makes the session ask, read from the actor's seat, and the tell that fails it; the recommended answer comes from the principle's stance applied to the precedent. A lens fires at most one question per fork, unless the answer opens a new fork. A lens that does not apply to the path is skipped without comment. The linked principle carries the full rationale; this table is the operative part.

### Actor

| Lens | Ask | Tell |
|---|---|---|
| [experience-first](../../.agents/principles/experience-first.md) | Who is the actor, and how do they arrive (menu, link, deep link, notification)? What is the outcome from their seat? Which controls are cut so the rest is polished, and what does each step feel like: the feedback, the empty state, the error state? | A screen laid out from the table's columns; every control the schema allows, shown |

### Subtraction

| Lens | Ask | Tell |
|---|---|---|
| [subtract-before-you-add](../../.agents/principles/subtract-before-you-add.md) | Which existing screen, step or control does this path replace or delete? Which story has no observed usage? | Pure addition; a control kept "in case" |
| [laziness-protocol](../../.agents/principles/laziness-protocol.md) | What is the shortest walk from intent to outcome, in screens and decisions? Which step exists only to feed the next one? | A confirmation or a wizard step carrying one field; a detour through a page the actor did not ask for |

### Shape

| Lens | Ask | Tell |
|---|---|---|
| [model-the-domain](../../.agents/principles/model-the-domain.md) | Which states does the entity pass through as the actor sees them, and what can the actor do in each? Which state the actor sees is missing from the spec's decisions? | A status the screen shows that no decision names; two flags the actor has to read together |
| [minimize-reader-load](../../.agents/principles/minimize-reader-load.md) | What must the actor hold in their head between steps (a mode, a selection, unsaved changes, a filter)? Can they answer "where am I" and "what happens if I leave" in one glance? | A hidden mode; state lost on back or refresh without a word |
| [boundary-discipline](../../.agents/principles/boundary-discipline.md) | Where does the actor's input enter, what is checked there, and what does the actor read when it fails? Are labels and messages in the glossary's words? | A message in transport or storage words (a code, a constraint name); validation the actor discovers only after submit |

### Alternatives

| Lens | Ask | Tell |
|---|---|---|
| [exhaust-the-design-space](../../.agents/principles/exhaust-the-design-space.md) | For a step with no precedent, what is the second structurally different screen, and why is it worse? | One layout, or a restyle of the first. A fork that has to be seen is runnable (step 3) |
| [redesign-from-first-principles](../../.agents/principles/redesign-from-first-principles.md) | If this page had been in the app from day one, where would it sit in the navigation, and which sibling pattern would it share? How does the path differ from that? | A page with its own list, filter, confirm or empty-state pattern beside siblings that share one |

### Failure branches

| Lens | Ask | Tell |
|---|---|---|
| [make-operations-idempotent](../../.agents/principles/make-operations-idempotent.md), seeded by [references/crud-grid.md](references/crud-grid.md) when the stories create, edit or delete | What does the actor see when they submit twice, refresh mid-save, hit back, lose the network, or retry after an error? Does every branch end in a state the actor can read? | "It depends on what got saved"; a duplicate the actor cannot see; a spinner with no exit |

### Delivery

| Lens | Ask | Tell |
|---|---|---|
| [prove-it-works](../../.agents/principles/prove-it-works.md) | At the end of the path, what does the actor see that proves it worked, and what would an end-to-end test drive to see the same? | "The request returned 200"; success inferred from the absence of an error |

### Conduct, not lenses

Three principles shape how the session runs rather than what it asks:

- [never-block-on-the-human](../../.agents/principles/never-block-on-the-human.md): reversible details get a default; questions are spent on what the actor sees at a fork and on what is cut.
- [guard-the-context-window](../../.agents/principles/guard-the-context-window.md): a precedent search that would run to pages and the prototype builds run in subagents; the thread holds the drafts, the decisions, the six-line report and, when the agent had to ask, its four-line ask.
- The feedback loop of [encode-lessons-in-structure](../../.agents/principles/encode-lessons-in-structure.md): a correction the user makes twice in the session becomes a rule, written into `CONTEXT.md` as a flagged ambiguity; a precedent found once becomes a default for every later fork it settles, never a question.

## 6. Close

The session ends when every path is `decided`, `default`, `deferred` or `ruled`. The close is two moves in this order, in one turn: the spec's `Journey:` line is replaced as the table in step 4 says, then the thread gets the summary:

- paths: each one with the story it realises and its state, one line each;
- decisions: fork, lens, choice, reason, one line each;
- defaults taken;
- deferrals, each with the condition that reopens it;
- the cut list;
- spec changes applied, and branches to reopen in `discuss`;
- files written: the journey's location, terms added to `CONTEXT.md`, the spec's edited sections;
- prototypes built: the fork each settled and the files it left (a temp directory, or excluded files plus a mount), for the user to delete;
- contradictions between a story and the app, and which side the user picked;
- the durability line, when the journey landed in the scratch: it is unversioned by design and a teammate never reads it, so a journey the team has to read goes under `docs/journeys/`;
- the `.scratch/` line, when the write added it to the project's `.gitignore`, per [.agents/scratch.md](../../.agents/scratch.md);
- as the last line, the exact next command:

  | The journey | Last line |
  |---|---|
  | `## Reopen in discuss` says `none` | `/tickets <spec path or issue reference>` |
  | it lists a branch | `/discuss <the branch>`, then `/journey` on the spec again; `tickets` stops on that list |

`tickets` cuts one ticket per path and orders them by `## States`, so every path is written to be cut that way: one thing the actor does end to end, never one layer of every path. After the tickets the chain continues one ticket at a time, `/do <ticket>`, the line `tickets` ends on. Nothing is committed.

## Hard rules

Each rule restates a step above with the cost of breaking it. When two readings of a step are possible, the one that keeps these holds.

- **One question per message**, carrying a recommendation and the tell, never a list of questions. A list gets one considered answer and several skimmed ones.
- **Never a technical question, and never a spec decision reopened on the skill's own**: a path proves the spec wrong, or the spec stands. Those decisions were settled in `discuss` and `spec` with the whole plan in view, and a journey that relitigates them sends the chain backwards.
- **The precedent answers first.** Never ask what it settles: the draft closes it with `file:line`. A claim about how the app behaves is read in the code before it is accepted. A question the app settles costs the user a turn and risks a path that contradicts the page beside it.
- **Reversible details get a default**, stated with its reason, never a question. The question budget is for forks with no precedent, for what is cut and for what happens when the path fails.
- **Under `--auto` no fork is put to the user.** Every fork the precedent leaves open goes to the `choice-taker`, one brief at a time, and the session never picks a side in its place: a side nobody with the `choice-taker`'s norms took would land in the journey unread.
- **Captures are never batched, and nothing is written before something closes.** A path only in the thread is lost when the session stops; a path written before its forks closed is a guess `tickets` would cut from.
- **The session writes only the journey, `CONTEXT.md`, and the spec's own sections and `Journey:` line**; never an ADR, never code. The stories are built later, from the tickets.
- **A prototype is built only for a runnable fork**, never for one a description can settle, and only by calling the Agent tool with `subagent_type: prototype`. Its files belong to that agent: new files marked throwaway and kept out of version control, at most one mount in a host page, each listed in its report and in the closing summary. An ask from that agent is answered by resuming it with the SendMessage tool, never by starting a second one.
- **The skill runs inline, in the main thread**: a subagent cannot interview. Only a precedent search too large for the thread, the prototype builds and, under `--auto`, the `choice-taker`'s rulings leave it.
- **Never commit, never push.** What the session wrote stays in the working tree, so a path the user did not want is an edit to undo.
- **Prose written into the project carries no em-dash.**
- **Every message to the user in the session's opening language; every write into the project in English**, UI copy in the product's language.
