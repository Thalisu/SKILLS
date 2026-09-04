---
name: journey
description: "Walk every path of a spec from the actor's seat: how they arrive, what they see, what they do, what the system answers, what happens when it fails. Each path is drafted from the app's precedent and shown once; only the forks the precedent leaves open become questions, one per message. Writes the journey beside the spec and points the spec at it."
disable-model-invocation: true
argument-hint: "[the spec: a path, the feature slug, or an issue reference]"
---

# Journey

Every message to the user is written in the language the user opened the session in. Everything
written into the project (the journey, its file name, the spec's edits, `CONTEXT.md`) is in
**English**; UI copy the journey quotes stays in the product's language.

Ground → tree → draft each path, one question per open fork → capture as it lands → close.

Vocabulary, used consistently: _actor_ (who walks the path), _path_ (one thing the actor sets out
to do, end to end; the unit of the tree), _step_ (what the actor sees, what they do, and what the
system answers), _fork_ (a step the precedent does not settle; the unit of a question),
_precedent_ (a sibling page or flow in the app that already answers a fork), _failure branch_ (a
step that ends somewhere other than the outcome, and what the actor sees there), _cut_ (a step or
control deliberately left out). From `discuss`: _tell_ (the answer that fails a lens), _default_
(an answer taken and stated instead of asked), _deferral_ (a fork parked with the condition that
reopens it), _runnable_ (a fork only a screen can settle: a throwaway prototype is built and the
question is put against it).

The interview is about the journey only. Data shape, boundaries, seams and delivery order are
`discuss` and `spec` decisions the journey takes as given, and no message to the user asks a
technical question.

## 1. Ground

- `$ARGUMENTS` is the spec and it is mandatory. Empty: one message asking for it, nothing else.
  Resolve it as `spec` publishes it:

  | The argument | Read as |
  |---|---|
  | a path | the file at that path |
  | a bare slug | `.scratch/<slug>/spec.md`, when `docs/agents/issue-tracker.md` says local markdown or is absent |
  | an issue number or URL | the issue, body and comments, through the CLI the tracker file names |

  Nothing readable: one message asking for the path.
- Read the spec fully, in the format of
  [.agents/formats/spec-format.md](../../.agents/formats/spec-format.md). Its User Stories are the
  candidate paths. Its Implementation Decisions, Testing Decisions and Out of Scope are constraints
  the journey never reopens on its own. The `Journey:` line under the title is the verdict `spec`
  wrote: `required` is the normal case here, and a spec that says `not needed` is still walked when
  the user asks. Either way the line is replaced at the close.
- A journey already where the table in step 4 puts it (a rerun, or a run that stopped before its
  close) is precedent too: a path whose story is unchanged stays closed with its rows, only new or
  changed stories are walked, and the file is rewritten in place.
- Read `CONTEXT.md` (the root one, or the context `CONTEXT-MAP.md` names) and the titles under
  `docs/adr/`, bodies for the ones the spec names. Labels, statuses and messages use the glossary's
  words.
- Find the precedent: the sibling pages and flows that already do what the stories do (a list with
  filters, a create form, a delete confirmation, an empty state, an error line, a status label).
  One subagent explores; the thread keeps a precedent note of three to six lines with `file:line`,
  plus every contradiction between a story and the app as it is. A contradiction found here is the
  first fork of the path it belongs to.
- `git status --short` and the branch: dirty files are the user's work in progress and part of the
  picture.

## 2. Build the tree

One branch per path, read off the User Stories. A story that is a step of another folds into it. A
path the spec's Out of Scope excludes closes at once, with the line that excludes it. Order the walk
by the actor: the path they walk first, then the ones that need state it creates (create before
edit before delete), so every path lands as one demoable slice
([sequence-verifiable-units](../../.agents/principles/sequence-verifiable-units.md)); `tickets`
reads that order back from `## States`.

Tag each fork with the lenses from step 5 that apply, and mark it _runnable_ when only a screen
can settle it: a step with no precedent anywhere in the app, or one the user answers with "I need
to see it".

Show the tree once, compact, with each path's state: `open`, `decided`, `default`, `deferred`.
Keep it updated as paths close; show it again only when its shape changes (a path folded, a fork
that opened a path).

## 3. Interview, one path at a time

For the first open path, in walk order:

1. **Draft first.** Write the path's step table from the precedent and the spec, every default
   taken and marked as such, and show it once. This is the explore-first rule: a fork the precedent
   settles is closed with `file:line` and never asked. A path with no open fork closes here.
2. **Talk before running.** A prototype is built only for a fork marked _runnable_. For that fork,
   call the Agent tool with `subagent_type: prototype` and a brief: the question in one line, the
   shape (`ui`, unless the fork is about how a state model behaves across the steps, which is
   `logic`), the page or route the path lives on (from the precedent note; a screen with no home
   says so, and the agent gives it a throwaway route), the data the step renders or the actions it
   takes, and every constraint the spec and this session have already decided. The agent builds in
   the background and reaches nobody while it does, so the brief is complete: a thin brief buys an
   assumption, or costs a round trip. Keep walking the forks that do not depend on it; when the
   six-line report lands, put the question against the artifact in the shape of item 3, with where
   to open it and what to look at. A report that opens with `PROTOTYPE ask` is the agent stopped
   before writing anything, on one part of the brief it could neither read off the code nor infer
   without changing what the prototype settles. Answer it from the spec, the precedent or a fork
   already closed when any of them can, and only otherwise put it to the user as one message in the
   shape of item 3, with the report's `readings:` line supplying the recommendation. Then resume
   the same agent by calling the SendMessage tool with the answer, never the Agent tool again,
   which would start a second agent with none of what the first one read.
3. **One question per message.** The message carries three things and nothing else: the question,
   the tell it hunts in one line, and the recommended answer with its reason. Never a list of
   questions, never a second question in the same message.
4. **Wait for the answer.**
5. **Check the answer.** Against the glossary: a label or a status in a sense `CONTEXT.md` does
   not give is called out at once ("your glossary defines X as ..., the screen would say ..."), and
   a fuzzy or overloaded word gets a proposed canonical term. Against the spec: an answer that
   contradicts a decision is named as a spec change and handled by step 4. Against the precedent:
   a claim about how a sibling page behaves is read in the code before it is accepted, and a
   contradiction is surfaced with `file:line`. Against a scenario: one concrete case at the
   boundary ("the actor deletes the last item on page three: what do they see?"). Push back once,
   with the evidence; the user's repeat is the decision.
6. **Close the fork.** `decided` (the user chose), `default` (a reversible detail: state the choice
   and its reason instead of asking), or `deferred` (parked, with the condition that reopens it, in
   one line). The path closes when its last fork does.
7. **Capture** (step 4), then update the tree.

A reversible detail (a label, a column order, a control's position where the precedent has one) is
never a question. The question budget goes to what the actor sees and does at a fork with no
precedent, to what is cut, and to what happens when the path fails.

## 4. Capture as it lands

Never batched: each item is written the moment its fork or path closes, before the next question.

- **A closed path** goes to the journey in the format of
  [.agents/formats/journey-format.md](../../.agents/formats/journey-format.md): its rows, its
  failure branches, and the one-line answer of a prototype when there was one. The file is created
  on the first closed path, where the tracker file puts it:

  | Tracker file says | The journey is | The spec's `Journey:` line becomes, at the close |
  |---|---|---|
  | local markdown, or no tracker file | `.scratch/<feature-slug>/journey.md`, beside the spec | `Journey: ./journey.md` |
  | GitHub or GitLab | `docs/journeys/<feature-slug>.md` in the repository, plus a comment on the spec issue that links it | `Journey: docs/journeys/<feature-slug>.md`, edited into the issue body through the CLI the tracker file names |

  The spec's `Status:` line is never touched. `tickets` finds the journey through the `Journey:`
  line and stops on a `## Reopen in discuss` that lists anything.
- **A resolved term** goes to `CONTEXT.md` (the root one, or the context's own when the map names
  it) in the format of
  [.agents/formats/context-format.md](../../.agents/formats/context-format.md). The file is
  created on the first term. Labels and statuses the actor sees are the terms a journey resolves
  most; no implementation detail.
- **A spec change**, when a path proves the spec wrong:

  | The change | What happens |
  |---|---|
  | reversible: a field the actor needs to see, a step order, a missing story, a message | the matching section of the spec is edited in place, in the format of [.agents/formats/spec-format.md](../../.agents/formats/spec-format.md), and the change is listed in the journey under `## Spec changes applied` |
  | hard to reverse, or touching an ADR: a new entity state, a schema change, an interaction an ADR forbids | the path stops; one message asks which side wins, with the evidence; when the spec loses, the branch is recorded under `## Reopen in discuss` and the walk moves on |

  `journey` never writes an ADR and never edits code.
- **A contradiction** between a story and the app as it is, is never resolved by editing code
  here: the user says which side is right, and the path and the summary record it.
- **A prototype** is never captured, only its answer: the decision, and the variant or scenario
  that settled it, in one line of the path. Its files stay where the agent left them, outside
  version control, listed in the closing summary.

## 5. Lenses, in walk order

Each lens is the question it makes the session ask, read from the actor's seat, and the tell that
fails it; the recommended answer comes from the principle's stance applied to the precedent. A lens
fires at most one question per fork, unless the answer opens a new fork. A lens that does not apply
to the path is skipped without comment. The linked principle carries the full rationale; this table
is the operative part.

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

Three principles shape how the session runs rather than what it asks.
[never-block-on-the-human](../../.agents/principles/never-block-on-the-human.md): reversible
details get a default; questions are spent on what the actor sees at a fork and on what is cut.
[guard-the-context-window](../../.agents/principles/guard-the-context-window.md): the precedent
search and the prototype builds run in subagents; the thread holds the drafts, the decisions, the
six-line report and, when the agent had to ask, its four-line ask. The feedback loop of
[encode-lessons-in-structure](../../.agents/principles/encode-lessons-in-structure.md): a
correction the user makes twice in the session becomes a rule, written into `CONTEXT.md` as a
flagged ambiguity; a precedent found once becomes a default for every later fork it settles, never
a question.

## 6. Close

The session ends when every path is `decided`, `default` or `deferred`. Then the spec's `Journey:`
line is replaced as the table in step 4 says, and the thread gets the summary:

- paths: each one with the story it realises and its state, one line each;
- decisions: fork, lens, choice, reason, one line each;
- defaults taken;
- deferrals, each with the condition that reopens it;
- the cut list;
- spec changes applied, and branches to reopen in `discuss`;
- files written: the journey's location, terms added to `CONTEXT.md`, the spec's edited sections;
- prototypes built: the fork each settled and the files it left (a temp directory, or excluded
  files plus a mount), for the user to delete;
- contradictions between a story and the app, and which side the user picked;
- the durability line, when `git check-ignore -q .scratch` succeeds: the journey is unversioned,
  so commit `.scratch/` or keep it under `docs/journeys/`;
- as the last line, the exact next command:

  | The journey | Last line |
  |---|---|
  | `## Reopen in discuss` says `none` | `/tickets <spec path or issue reference>` |
  | it lists a branch | `/discuss <the branch>`, then `/journey` on the spec again; `tickets` stops on that list |

`tickets` cuts one ticket per path and orders them by `## States`, so every path is written to be
cut that way: one thing the actor does end to end, never one layer of every path. The chain ends at
the tickets (stand-in until /do exists: the line after them becomes `/do <ticket>`). Nothing is
committed.

## Hard rules

- One question per message, carrying a recommendation and the tell. Never a list of questions.
- Never a technical question, and never a spec decision reopened on the skill's own: a path proves
  the spec wrong, or the spec stands.
- Never ask what the precedent settles: the draft closes it with `file:line`. Never ask about a
  reversible detail: take the default and say so.
- A claim about how the app behaves is read in the code before it is accepted.
- Captures are never batched. The session writes only the journey, `CONTEXT.md`, and the spec's
  own sections and `Journey:` line; never an ADR, never code. A prototype's files belong to the
  prototype agent: new files marked throwaway and kept out of version control, at most one mount
  in a host page, each listed in its report and in the closing summary.
- A prototype is built only for a runnable fork, never for one a description can settle, and only
  by calling the Agent tool with `subagent_type: prototype`. An ask from that agent is answered by
  resuming it with the SendMessage tool, never by starting a second one.
- The skill runs inline, in the main thread: a subagent cannot interview. Only the precedent search
  and the prototype builds leave the thread.
- Never commit, never push.
- Prose written into the project carries no em-dash.
- Every message to the user in the session's opening language; every write into the project in
  English, UI copy in the product's language.
