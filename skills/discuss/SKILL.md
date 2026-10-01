---
name: discuss
description: "Interview the user about a plan before code is written: one question at a time, each with a recommended answer and the failure it hunts, answered from the repository whenever the repository can answer it, with terms recorded in CONTEXT.md as they land and the hard-to-reverse decisions written as ADRs at the close, without asking."
disable-model-invocation: true
argument-hint: "[--auto] [the plan, feature or change to discuss]"
---

# Discuss

This session is an interview about a plan, held before any code is written. Its product is decisions: read what the repository already knows, lay the plan out as a tree of decisions, settle each one with the user, and hand the result to `spec`, the next skill in the chain, which builds from the closing summary.

The plan is the subject of the interview, never a task to carry out. However concrete it reads, nothing in it is implemented here: the session writes `CONTEXT.md` and files under `docs/adr/`, and edits no code.

The user's attention is the scarce resource. A question the repository could have answered, or one about a detail that is cheap to change, spends attention the real trade-offs need, so every rule below either saves a question or makes the ones that remain easier to answer.

Every message to the user is written in the language the user opened the session in. Everything written into the repository (`CONTEXT.md`, ADRs, file names) is in **English**.

The run, in order: ground → tree → one question at a time → capture as it lands → write the ADRs → close.

## Vocabulary

Used consistently, in the thread and in what the session writes:

- _branch_: one decision the plan needs.
- _tree_: the branches and the dependencies between them.
- _lens_: a principle turned into a question.
- _tell_: the answer that fails a lens.
- _default_: an answer taken and stated instead of asked.
- _deferral_: a branch parked with the condition that reopens it.
- _runnable_: a branch only a running artifact can settle. A throwaway prototype is built and the question is put against it.
- _candidate_: a decided or ruled branch that passes the three gates of an ADR. Every candidate the close does not drop is written.

## How a turn ends

A message with no tool call ends the turn, and the session waits there until the user writes again. The turn ends at these points and no others:

- the ask for a missing plan (step 1);
- a question to the user (step 3), which includes the two exceptions under `--auto`;
- the close (step 6).

Everything between those points happens in one turn. The grounding note, the tree and the first question arrive together: the session never stops after the note or the tree to ask whether to begin. A status line is welcome, in the same message as the next tool call. Under `--auto` nobody is watching the run, so a turn that ends on a progress summary, on an announcement of the next branch, or on an offer to carry on stops the walk with branches still open. When a message is about to end that way, make the next tool call instead.

## 1. Ground

**The plan.** The plan is `$ARGUMENTS`.

- An `--auto` token among them, before the plan, after it or inside it, is dropped wherever it sat and puts the run under `--auto` (step 3). The plan is the rest, with no flag in it, and it is that plan the run grounds and hands on.
- Without the token the plan is `$ARGUMENTS` as typed.
- Empty → ask for it, in one message that carries nothing else.

**The reading.** Before any question, read what the repository already knows. Say in one line what is being read, then make the reads that do not depend on one another in one batch:

- **The glossary.** `CONTEXT-MAP.md` at the root, when it exists, names the contexts and where each lives: pick the one the plan touches, ask when it is unclear. Otherwise the root `CONTEXT.md`. Neither existing is fine; nothing is created until the first term is resolved (step 4).
- **The ADRs.** `docs/adr/*` at the root and, when the map names one, the context's own `docs/adr/`: titles first, bodies only for the ones the plan touches.
- **The code the plan touches.** Symbols the plan names get one `discover` batch: call the Skill tool with "discover", every candidate in one call. When the session lists a skill named `how` or `why`, call the Skill tool with it for the subsystem the plan reshapes; otherwise explore with `rg` and targeted reads. A search or a handful of reads stays in the thread. Exploration whose output would run to pages (a whole subsystem, many files) goes to a subagent, and the thread keeps the summary.
- **The working tree.** `git status --short` and the branch: dirty files are the user's work in progress and part of the picture.

**The grounding note.** Output, in the thread, a grounding note of three to six lines: what already exists, what the docs already decided, and every contradiction between the plan and the code or the glossary, each with `file:line`. A contradiction found here is the first branch of the tree.

## 2. Build the tree

List the branches: every decision the plan needs, one line each.

- **Order.** Mark the dependencies (a branch whose answer changes another branch's answer comes first) and order the walk by them.
- **Lenses.** Tag each branch with the lenses from step 5 that apply to it.
- **Runnable.** Mark a branch _runnable_ when its answer depends on seeing or driving the thing rather than on describing it: what a screen should look like, or how a state model behaves across a sequence too long to hold in the head.
- **Closed here.** A branch the repository already answers is closed here, with the evidence, and is never asked.

Show the tree once, compact, with each branch's state: `open`, `decided`, `default`, `deferred`, and `ruled` under `--auto` (step 3). Keep it updated as branches close; show it again only when its shape changes (a new branch, a reorder). A branch closing, a `ruled` one included, is not a shape change.

One shape the tree can take. The layout is free; the state on every row is not:

<example>
1. [decided] Where a reminder's due time is stored: a UTC column, already there (src/reminders/schema.ts:14)
2. [open] What snoozing a recurring reminder moves: the occurrence or the series · model-the-domain
3. [open] After 2: how a snoozed occurrence reaches the daily digest · boundary-discipline
4. [open, runnable] What the snooze picker looks like · experience-first
5. [default] Snooze presets of 10 minutes, 1 hour, tomorrow: a list that is cheap to change
</example>

## 3. Interview, one branch at a time

For the first open branch, in walk order:

1. **Explore first.** Whatever can still be settled from the repository is settled there: close the branch, say so in one line, move on.
2. **Talk before running.** A prototype is built only for a branch marked _runnable_ in the tree, or for one the user answers with "I need to see it"; a branch the user can answer from a description never gets one. The mechanics are under "A runnable branch" below.
3. **One question per message.** The message carries three things and nothing else: the question, the tell it hunts in one line, and the recommended answer with its reason. Never a list of questions, never a second question in the same message: one question gets a considered answer, and a list gets the first item answered and the rest skimmed.
4. **Wait for the answer.**
5. **Check the answer.** Push back once, with the evidence; the user's repeat is the decision.
   - Against the glossary: a term used in a sense `CONTEXT.md` does not give is called out immediately ("your glossary defines X as ..., you seem to mean ...").
   - Against the code: a claim about how something works is read in the code before it is accepted, and a contradiction is surfaced with `file:line`.
   - Against a scenario: a domain relationship gets one concrete scenario that probes its boundary ("a Customer with two open Orders cancels one: what happens to the Invoice?").
   - A fuzzy or overloaded word gets a proposed canonical term.
6. **Close the branch.**
   - `decided`: the user chose. The branch keeps the choice, its reason and the alternative it beat, in one line.
   - `default`: a reversible detail. State the choice and its reason instead of asking.
   - `deferred`: parked, with the condition that reopens it, in one line.
7. **Capture** (step 4), then update the tree. A branch the answer opened joins the tree at its dependency position.

A reversible execution detail is never a question. The question budget goes to direction, trade-offs and anything hard to undo.

### The question message

Three parts, in this order, in the user's language (the labels are translated with the rest). The examples show the shape on three kinds of branch; the wording, the length and the domain are the branch's own.

<examples>
<example>
An ordinary branch:

Does snoozing a recurring reminder move only the next occurrence, or shift the whole series?

Tell: one `snoozedUntil` field read as both, so the digest and the scheduler disagree about what was snoozed.

Recommendation: only the next occurrence, stored as an override on that occurrence. The series rule stays the single source of the schedule, and undoing a snooze is deleting one row.
</example>
<example>
A runnable branch, put against the prototype's report:

Open `/tmp/proto-snooze/index.html` and switch between the three variants with the bar at the top. Which picker lets you snooze to "tomorrow morning" without reading a label twice?

Tell: the variant that is easiest to build wins over the one that is fastest to use.

Recommendation: variant B, the preset row with one custom field. It covers the three presets in one tap, and A hides them behind a menu.
</example>
<example>
An `extreme` return under `--auto`:

Does an unsubscribe link carry a signed token, or the bare subscriber id?

Tell: the bare id is the weaker side. It gives up the auth guarantee that only the subscriber can change their own subscription, since ids are sequential.

Recommendation: the signed token, because it keeps that guarantee whole at the cost of one column.
</example>
</examples>

### A runnable branch

1. **Fork.** Call the Agent tool with `subagent_type: prototype` and a brief:
   - the question in one line;
   - the shape: `ui` for what a screen should look like, `logic` for whether a state model holds up;
   - the page or module it lives next to;
   - the data or actions it has;
   - every constraint this session has already decided.

   The agent builds in the background and reaches nobody while it does, so the brief is complete: a thin brief buys an assumption, or costs a round trip.
2. **Keep walking** the branches that do not depend on this one.
3. **The report.** When the six-line report lands, put the question against the artifact in the shape of item 3, with where to open it and what to look at.
4. **An ask instead.** A report that opens with `PROTOTYPE ask` is the agent stopped before writing anything, on one part of the brief it could neither read off the code nor infer without changing what the prototype settles. Treat it as a branch:
   - answer it from the repository or from a branch already closed when either can;
   - only otherwise put it to the user as one message in the shape of item 3, with the report's `readings:` line supplying the recommendation.

   Then resume the same agent by calling the SendMessage tool with the answer, never the Agent tool again, which would start a second agent with none of what the first one read. The six-line report follows, and the answer is captured (step 4) like any other.

### Under `--auto`

The flag is the developer handing direction over for one run. No branch is put to the user, save the two exceptions below, and the run continues to the close without waiting on anyone.

For each open branch, in walk order, item 1 still runs first. A branch it cannot close is ruled in place of items 3 to 6: call the Agent tool with `subagent_type: choice-taker` and the brief its definition fixes, filled from the question item 3 would have asked.

```
Caller: discuss at the interview step
Question: <the branch's question, in one line>
Options: <two or more options, one per line>
Recommendation: <the recommended answer item 3 would have carried>
Repository root: <the repository's absolute path>
Principles: <the absolute path of the skills checkout's .agents/principles/ folder>
Context: <the plan, the grounding note and the row of every branch already closed>
```

- **`Context:`** carries the text itself, never a pointer to it, since the fork sees nothing of this thread: the plan with the flag dropped, the grounding note of step 1, and the one-line row of every branch closed so far in this session, whatever closed it, so a branch is never ruled against a decision the session already took.
- **`Principles:`** is the folder the lenses of step 5 link, resolved to an absolute path from this file's own location: the project under discussion has no `.agents/principles/` of its own, and the fork holds no shell to find one.
- **One fork at a time**, in walk order, since each brief carries the rows the earlier ones closed.

A return is read where it crosses into this session, per [boundary-discipline](../../.agents/principles/boundary-discipline.md), before anything in it is written: a return is a ruling only when its first line reads `settled` or `extreme`, and a `settled` one only when its `Side:` names one of the options the brief's `Options:` lines handed over and neither its `Side:` nor its `Norm:` leans on a domain term the glossary step 1 read does not define. A project with no glossary at all (no `CONTEXT.md`, and no `CONTEXT-MAP.md` naming one) skips that last check, and every term passes, so `--auto` still rules there. Any other return is no ruling: a refusal, an error, a shape the definition does not fix, a `settled` with no `Side:`, a `settled` whose `Side:` names anything else, or one ruled in a term the glossary never defined, so a broken return never closes a branch, a steered `choice-taker` never gets a side nobody offered read into a row, the `Rulings` section, an ADR or the contradictions list, and no decision reaches `spec` in words nobody sharpened. The session never picks an option in its place. A branch whose return is no ruling writes no row and is never forked to the `choice-taker` a second time: it is put to the developer as one message in the shape item 3 fixes, with one line before it naming the reason, `the choice-taker returned neither settled nor extreme`, `the choice-taker ruled on an option it was not handed` with the side it returned, or `the choice-taker ruled in a term the glossary does not define` with the term. Wait for the answer and check it (items 4 and 5), close the branch (item 6) as `decided`, `default` or `deferred` like any other, and item 7 follows; the walk resumes under `--auto` at the next open branch, as it does after an `extreme` return.

A `settled` return closes the branch as `ruled`, its row holding the side taken, the norm the return named and the options it beat, in one line, and, for a _runnable_ branch, the mark `runnable, ruled unseen` with the command that would show it: `/prototype <the branch's question> <ui or logic> <the page or module it lives next to>`, the brief item 2 would have sent, in the `prototype` skill's own arguments. The row reads `ruled` in the tree, which is not shown again for it (step 2). Then item 7, and the next open branch.

**First exception: an `extreme` return** closes no branch and writes no row. The `choice-taker` rules on nothing when an option weakens a guarantee in a risk class or cannot be undone, and `--auto` inherits that stop rather than silencing it.

1. Put the branch to the developer as one message in the shape item 3 fixes: the question, the tell naming the return's `Weaker side:` and the `Guarantee:` it gives up, and the recommended answer, the option that is not the weaker side, with the reason that it keeps the guarantee whole.
2. Wait for the answer and check it the way item 3 does (items 4 and 5).
3. Close the branch (item 6) as `decided`, `default` or `deferred` like any other; item 7 follows.
4. Only that branch leaves `--auto` for a question. The walk resumes under `--auto` at the next open branch, still forking the `choice-taker` for the ones that are not `extreme`, unless the second exception applies.

**Second exception: the `choice-taker` cannot be forked**, because the Agent tool is withheld, or is present but lists no `choice-taker`. That branch and every branch after it, in walk order, are put to the developer exactly as they would be without the flag (items 3 to 7 of the interview), with one line before the first of them naming the reason: the `choice-taker` cannot be forked. No other agent is forked in its place, and the session never answers the branch on its own: a ruling nobody with the `choice-taker`'s norms made would land unread. No row reads `ruled` for a branch closed this way; each closes `decided`, `default` or `deferred` like any other.

## 4. Capture as it lands

A term is never batched: it is written the moment its branch closes, before the next question. A decision is held on its branch until the close (step 6), where the whole tree is in view and the ones that earn an ADR are written.

- **A resolved term** goes to `CONTEXT.md` (the root one, or the context's own when the map names it) in the format of [.agents/formats/context-format.md](../../.agents/formats/context-format.md). The file is created on the first term. Only terms a domain expert would recognise; no implementation detail.
- **A decision** stays on its branch, in one line: the choice, its reason, and the alternative it beat. Nothing is written under `docs/adr/` before the close. That line is what an ADR is written from when the branch becomes one, and what the summary carries otherwise; a decision scoped to this feature (a module, an interface, a contract) is the spec's to keep, in its Implementation Decisions, and reaches it through the summary.
- **A contradiction** between the user's answer and the code is never resolved by editing code here: the user says which side is right, and the branch and the summary record it. Under `--auto`, a contradiction the `choice-taker` rules instead (step 3) is captured the same way: the branch and the summary hold the side its return took and the norm, never the user's pick.
- **A prototype** is never captured, only its answer: the decision, and the variant or scenario that settled it, in the branch's line, carried into the ADR or the summary at the close. Its files stay where the agent left them, outside version control, listed in the closing summary.

## 5. Lenses, in walk order

Each lens is the question it makes the session ask and the tell that fails it; the recommended answer comes from the principle's stance applied to what the grounding found. A lens fires at most one question per branch, unless the answer opens a new branch. A lens that does not apply to the plan is skipped without comment. The linked principle carries the full rationale; this table is the operative part.

### Target

| Lens | Ask | Tell |
|---|---|---|
| [experience-first](../../.agents/principles/experience-first.md) | Who consumes this (end user, importing colleague, next maintainer), and what does it look like from their seat? Which features are cut so the rest can be polished? | Implementer convenience wins over the consumer |

### Subtraction

| Lens | Ask | Tell |
|---|---|---|
| [subtract-before-you-add](../../.agents/principles/subtract-before-you-add.md) | What is deleted first? Which existing thing does this replace? | Pure addition |
| [laziness-protocol](../../.agents/principles/laziness-protocol.md) | What is the smallest change that solves it? Why must the new signal thread through those layers, and what is the direct path? | An abstraction with one caller; a signal threaded through types, schemas and pipelines |

### Shape

| Lens | Ask | Tell |
|---|---|---|
| [foundational-thinking](../../.agents/principles/foundational-thinking.md) | What are the core types and data structures? What is scaffold (every later phase benefits from it) and what is feature? | Logic planned before the data shape |
| [model-the-domain](../../.agents/principles/model-the-domain.md) | Which rule is about to become scattered booleans or one more branch, and what structure (state machine, union, registry, reducer) encodes it once? Which structure does each glossary term map to? | A second boolean that must stay in sync with the first |
| [type-system-discipline](../../.agents/principles/type-system-discipline.md) (typed languages) | Which illegal states can the proposed shape represent? Which primitives share a type but mean different things? | A comment is needed to explain when a field combination is valid |
| [boundary-discipline](../../.agents/principles/boundary-discipline.md) | Where does external data enter, and where is it parsed into domain types? Does the public surface leak transport, storage or framework types? | Validation deep in business logic; a wire type re-exported |

### Alternatives

| Lens | Ask | Tell |
|---|---|---|
| [exhaust-the-design-space](../../.agents/principles/exhaust-the-design-space.md) | What is the second structurally different shape, and why is it worse? | One candidate, or a variant of the first. Candidates that have to be seen make the branch runnable (step 3); candidates that are function shapes go to an architect-style skill in the closing summary |
| [redesign-from-first-principles](../../.agents/principles/redesign-from-first-principles.md) | If this requirement had existed on day one, what would have been built, and how does the plan differ from that? | An adapter, a flag or a special case bolted on |

### Failure modes

Each fires only on the condition named with it.

| Lens | Ask | Tell |
|---|---|---|
| [fix-root-causes](../../.agents/principles/fix-root-causes.md), when the plan is a fix | Is the fix at the root cause, or is it a guard that silences a symptom? Where else does the same pattern occur? | A nil check; a workaround that needs a paragraph to justify |
| [make-operations-idempotent](../../.agents/principles/make-operations-idempotent.md), when the plan mutates state, runs jobs or migrates data | What happens if it runs twice? If the previous run crashed halfway? | The answer depends on state left behind |
| [separate-before-serializing-shared-state](../../.agents/principles/separate-before-serializing-shared-state.md), when more than one actor writes | Who else writes this file, branch, key or object? Can each actor own its own, merged at the read boundary? If sharing is real, what serializes it structurally? | "They will take turns" |
| [migrate-callers-then-delete-legacy-apis](../../.agents/principles/migrate-callers-then-delete-legacy-apis.md), when an API is replaced | Which callers exist, when does each migrate, and when does the old path die? | The old API survives "for now" |
| [outcome-oriented-execution](../../.agents/principles/outcome-oriented-execution.md), when the plan is a migration or a rewrite | What is the verified end state? Where is breakage allowed, and is it scoped and reversible? | Throwaway compatibility code kept so every intermediate step stays green |

### Delivery

| Lens | Ask | Tell |
|---|---|---|
| [sequence-verifiable-units](../../.agents/principles/sequence-verifiable-units.md) | What is the first unit and its check? What order makes the sequence prove itself to a reviewer (failing test first, fix on top; subtraction before reshape)? Which bulk work gets a script a reviewer can rerun? | Build it all, verify at the end; a sweep applied by hand |
| [prove-it-works](../../.agents/principles/prove-it-works.md) | How will we know it works, against the real artifact (the feature exercised, the value read, the diff inspected)? Can the check be a script? | "It compiles"; a proxy |

### Maintenance

| Lens | Ask | Tell |
|---|---|---|
| [minimize-reader-load](../../.agents/principles/minimize-reader-load.md) | How many layers sit between a new reader's question and the answer, and what hidden state must they hold? Can they answer "where does X come from" and "what can change X" in thirty seconds? | One-caller wrappers; pass-through layers |
| [encode-lessons-in-structure](../../.agents/principles/encode-lessons-in-structure.md) | Which rules in this plan are text (instructions, conventions, comments) that could be a lint, a type or a runtime check? | Guidance added where a mechanism fits |

### Conduct, not lenses

Three principles shape how the session runs rather than what it asks:

- [never-block-on-the-human](../../.agents/principles/never-block-on-the-human.md): reversible details get a default; questions are spent on direction and irreversibles.
- [guard-the-context-window](../../.agents/principles/guard-the-context-window.md): page-long exploration and prototype builds run in subagents; the thread holds decisions, the six-line report and, when the agent had to ask, its four-line ask.
- The feedback loop of [encode-lessons-in-structure](../../.agents/principles/encode-lessons-in-structure.md): a correction the user makes twice in the session becomes a rule, written into `CONTEXT.md` as a flagged ambiguity or proposed as a mechanism.

## 6. Close

The session ends when every branch is `decided`, `default`, `deferred` or `ruled`. The close is two moves in this order, in one turn: the ADRs, then the summary.

### The ADRs

1. **List the candidates**: every `decided` or `ruled` branch that passes the three gates of [.agents/formats/adr-format.md](../../.agents/formats/adr-format.md) (hard to reverse, surprising without context, the result of a real trade-off), one line per candidate with each gate filled in one clause.
2. **Drop the false ones**, without comment. Those decisions are the spec's.
   - A gate that cannot be filled in one clause drops the branch from the list.
   - So does any of the format's three tells of a false candidate: a rule `CONTEXT.md` already carries, the artifact the spec is about to describe, an alternative that lost only to a rule of the repository.
3. **One last tell** over what is left: a candidate that reaches the list because its branch was argued at length, rather than because a future reader will look for it, is dropped with its reason in one line.
4. **Write every candidate still standing, without asking.** The user is never put a question about which ones, and the close reaches them as a statement of what was written and what was dropped: the gates are the filter, and asking would put the same filter to the user a second time. Each ADR is written in the format of adr-format.md from its branch's line, never from memory of the interview; the directory is created on the first ADR.
5. **A candidate from a `ruled` branch** is written in the shape of the format's `A Ruled ADR`: the line `Ruled by the choice-taker under --auto: <norm>` directly under its title, the norm the one on the branch's row, since that line is how every later reader, the `choice-taker` included, tells an ADR the user never decided from one they did. An ADR from a `decided` branch never carries it.

An empty list is one line in the summary. The dropped candidates stay in the summary and reach the spec from there.

### The summary

In the thread:

- decisions: branch, lens, choice, reason and the alternative it beat, one line each, for the `decided` branches only; this is what `spec` carries into Implementation Decisions;
- `Rulings`, under `--auto`: a section apart from the decisions, one line per `ruled` branch with the option taken, its norm and the options it beat; a _runnable_ branch's line also reads `runnable, ruled unseen` and carries its `/prototype` command, so the developer can see it before `spec`. A ruled branch never also appears among the decisions: those reach the spec as the user's, and the user chose none of these;
- defaults taken;
- deferrals, each with the condition that reopens it;
- files written: terms added to `CONTEXT.md`, ADR paths, and beside them each candidate the close dropped, with its reason, in one line;
- prototypes built: the branch each settled and the files it left (a temp directory, or excluded files plus a mount), for the user to delete;
- contradictions between the plan and the code: the side the user picked, or, for one the `choice-taker` ruled under `--auto`, the side its return took and the norm, listed as ruled and never as the user's pick;
- next step: the user runs `spec` on this conversation, and this summary is its input; when the plan crosses a function boundary and the second shape was never built, an architect-style skill settles the shape first, and `spec` follows it. Under `--auto` the summary's last line reads `/spec --auto`, so the user keeps the mode down the chain by pasting it; without the flag this item is unchanged.

Nothing is committed. `CONTEXT.md` and everything under `docs/adr/` stay in the working tree for the user.

## Hard rules

Each rule restates a step above with the cost of breaking it. When two readings of a step are possible, the one that keeps these holds.

- **One question per message**, carrying a recommendation and the tell, never a list of questions. A list gets one considered answer and several skimmed ones.
- **The repository answers first.** Never ask what it answers, and read a claim about how the code works in the code before accepting it. A question the code settles costs the user a turn and risks a decision made against the facts.
- **Reversible details get a default**, stated with its reason, never a question. The question budget is for direction and what is hard to undo.
- Under `--auto` no branch is put to the user, save three exceptions: a branch whose `choice-taker` fork returns `extreme` is put to the developer as the "Under `--auto`" section describes, carrying the return's weaker side and the guarantee it gives up; a branch whose return is no ruling is put to the developer with the reason named, and never forked to the `choice-taker` a second time; and, when the Agent tool is withheld or lists no `choice-taker`, that branch and every branch after it are put to the developer as that section's second exception describes, with one line naming the reason and no agent forked in the `choice-taker`'s place. Every other branch the `choice-taker` rules, and the session writes its row.
- **A term is never batched; an ADR is never written before the close.** At the close every candidate the filter leaves standing is written without asking, and a decision scoped to the feature never becomes one.
- **The session writes only `CONTEXT.md` and files under `docs/adr/`, and edits no code.** The plan is built later, from the spec.
- **A prototype is built only for a runnable branch**, never for one a description can settle, and only by forking the `prototype` agent. Its files belong to that agent: new files marked throwaway and kept out of version control, at most one mount in a host page, each listed in its report and in the closing summary. An ask from that agent is answered by resuming it with the SendMessage tool, never by forking a second one.
- **Never commit, never push.** What the session wrote stays in the working tree, so an ADR the user did not want is a file to delete.
- **Prose written into the project carries no em-dash.**
- **Every message to the user in the session's opening language; every write into the repository in English.**
