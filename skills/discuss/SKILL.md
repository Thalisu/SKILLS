---
name: discuss
description: "Interview the user about a plan before code is written: one question at a time, each with a recommended answer and the failure it hunts, answered from the repository whenever the repository can answer it, with terms recorded in CONTEXT.md and hard-to-reverse decisions in docs/adr/ as they land."
disable-model-invocation: true
argument-hint: "[the plan, feature or change to discuss]"
---

# Discuss

Every message to the user is written in the language the user opened the session in. Everything written into the repository (`CONTEXT.md`, ADRs, file names) is in **English**.

Ground → tree → one question at a time → capture as it lands → close.

Vocabulary, used consistently: _branch_ (one decision the plan needs), _tree_ (the branches and the dependencies between them), _lens_ (a principle turned into a question), _tell_ (the answer that fails a lens), _default_ (an answer taken and stated instead of asked), _deferral_ (a branch parked with the condition that reopens it), _runnable_ (a branch only a running artifact can settle: a throwaway prototype is built and the question is put against it).

## 1. Ground

The plan is `$ARGUMENTS`. Empty → ask for it, in one message that carries nothing else.

Before any question, read what the repository already knows:

- `CONTEXT-MAP.md` at the root, when it exists, names the contexts and where each lives: pick the one the plan touches, ask when it is unclear. Otherwise the root `CONTEXT.md`. Neither existing is fine; nothing is created until the first term is resolved (step 4).
- `docs/adr/*` at the root and, when the map names one, the context's own `docs/adr/`: titles first, bodies only for the ones the plan touches.
- The code the plan touches. Symbols the plan names get one `discover` batch: call the Skill tool with "discover", every candidate in one call. When the session lists a skill named `how` or `why`, call the Skill tool with it for the subsystem the plan reshapes; otherwise explore with `rg` and targeted reads. Large outputs go to a subagent; the thread keeps the summary.
- `git status --short` and the branch: dirty files are the user's work in progress and part of the picture.

Output, in the thread, a grounding note of three to six lines: what already exists, what the docs already decided, and every contradiction between the plan and the code or the glossary, each with `file:line`. A contradiction found here is the first branch of the tree.

## 2. Build the tree

List the branches: every decision the plan needs, one line each. Mark the dependencies (a branch whose answer changes another branch's answer comes first) and order the walk by them. Tag each branch with the lenses from step 5 that apply to it, and mark it _runnable_ when its answer depends on seeing or driving the thing rather than on describing it: what a screen should look like, or how a state model behaves across a sequence too long to hold in the head.

A branch the repository already answers is closed here, with the evidence, and is never asked.

Show the tree once, compact, with each branch's state: `open`, `decided`, `default`, `deferred`. Keep it updated as branches close; show it again only when its shape changes (a new branch, a reorder).

## 3. Interview, one branch at a time

For the first open branch, in walk order:

1. **Explore first.** Whatever can still be settled from the repository is settled there: close the branch, say so in one line, move on.
2. **Talk before running.** A prototype is built only for a branch marked _runnable_ in the tree, or for one the user answers with "I need to see it"; a branch the user can answer from a description never gets one. For that branch, call the Agent tool with `subagent_type: prototype` and a brief: the question in one line, the shape (`ui` for what a screen should look like, `logic` for whether a state model holds up), the page or module it lives next to, the data or actions it has, and every constraint this session has already decided. The agent builds in the background and cannot ask anything, so the brief is complete. Keep walking the branches that do not depend on this one; when the six-line report lands, put the question against the artifact in the shape of item 3, with where to open it and what to look at.
3. **One question per message.** The message carries three things and nothing else: the question, the tell it hunts in one line, and the recommended answer with its reason. Never a list of questions, never a second question in the same message.
4. **Wait for the answer.**
5. **Check the answer.** Against the glossary: a term used in a sense `CONTEXT.md` does not give is called out immediately ("your glossary defines X as ..., you seem to mean ..."). Against the code: a claim about how something works is read in the code before it is accepted, and a contradiction is surfaced with `file:line`. Against a scenario: a domain relationship gets one concrete scenario that probes its boundary ("a Customer with two open Orders cancels one: what happens to the Invoice?"). A fuzzy or overloaded word gets a proposed canonical term. Push back once, with the evidence; the user's repeat is the decision.
6. **Close the branch.** `decided` (the user chose), `default` (a reversible detail: state the choice and its reason instead of asking), or `deferred` (parked, with the condition that reopens it, in one line).
7. **Capture** (step 4), then update the tree. A branch the answer opened joins the tree at its dependency position.

A reversible execution detail is never a question. The question budget goes to direction, trade-offs and anything hard to undo.

## 4. Capture as it lands

Never batched: each item is written the moment its branch closes, before the next question.

- **A resolved term** goes to `CONTEXT.md` (the root one, or the context's own when the map names it) in the format of [references/context-format.md](references/context-format.md). The file is created on the first term. Only terms a domain expert would recognise; no implementation detail.
- **A decision** gets an ADR under `docs/adr/` in the format of [references/adr-format.md](references/adr-format.md) when all three hold: hard to reverse, surprising without context, the result of a real trade-off. Any one missing → no ADR; the closing summary carries the decision. The directory is created on the first ADR.
- **A contradiction** between the user's answer and the code is never resolved by editing code here: the user says which side is right, and the branch and the summary record it.
- **A prototype** is never captured, only its answer: the decision, and the variant or scenario that settled it, in one line of the ADR or the summary. Its files stay in the working tree, listed in the closing summary.

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

Three principles shape how the session runs rather than what it asks. [never-block-on-the-human](../../.agents/principles/never-block-on-the-human.md): reversible details get a default; questions are spent on direction and irreversibles. [guard-the-context-window](../../.agents/principles/guard-the-context-window.md): exploration and prototype builds run in subagents; the thread holds decisions and the six-line report. The feedback loop of [encode-lessons-in-structure](../../.agents/principles/encode-lessons-in-structure.md): a correction the user makes twice in the session becomes a rule, written into `CONTEXT.md` as a flagged ambiguity or proposed as a mechanism.

## 6. Close

The session ends when every branch is `decided`, `default` or `deferred`. Then, in the thread, the decision summary:

- decisions: branch, lens, choice, reason, one line each;
- defaults taken;
- deferrals, each with the condition that reopens it;
- files written: terms added to `CONTEXT.md`, ADR paths;
- prototypes built: the branch each settled and the files it left, for the user to delete or park on a throwaway branch;
- contradictions between the plan and the code, and which side the user picked;
- next step: implement; or settle the shape first through an architect-style skill when the plan crosses a function boundary and the second shape was never built; or write the brief when a brief-writing skill is available. The summary is that skill's input.

Nothing is committed. `CONTEXT.md` and everything under `docs/adr/` stay in the working tree for the user.

## Hard rules

- One question per message, carrying a recommendation and the tell. Never a list of questions.
- Never ask what the repository answers. Never ask about a reversible detail: take the default and say so.
- A claim about how the code works is read in the code before it is accepted.
- Captures are never batched. The session writes only `CONTEXT.md` and files under `docs/adr/`, and edits no code. A prototype's files belong to the prototype agent: new files marked throwaway, at most one mount in a host page, each listed in its report and in the closing summary.
- A prototype is built only for a runnable branch, never for one a description can settle, and only by forking the `prototype` agent.
- Never commit, never push.
- Prose written into the project carries no em-dash.
- Every message to the user in the session's opening language; every write into the repository in English.
