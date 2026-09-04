# discuss

## What it does

`discuss` interviews you about a plan before any code is written. It reads what the repository
already knows (the glossary in `CONTEXT.md`, the ADRs, the code the plan touches), lays the plan
out as a tree of decisions, and walks that tree one question at a time, each question carrying a
recommended answer and the failure it hunts. A resolved term is written into `CONTEXT.md` and a
hard-to-reverse decision into `docs/adr/` the moment it lands, and the session closes with a
summary of every decision, default and deferral.

It never asks what the repository can answer. A branch the code or the docs already settle is
closed with the evidence and never put to you, and a claim about how the code works is read in the
code before it is accepted.

## When to reach for it

You invoke this by typing `/discuss`, and the agent won't reach for it on its own.

| Ask | Use |
|---|---|
| stress-test a plan, a feature, a refactor or a fix before building it | `/discuss <the plan>` |
| understand how a subsystem works, with no plan on the table | a walkthrough, or read the code |
| settle the shape (types, signatures, module boundaries) once the decisions are made | an architect-style skill; the closing summary names the moment for it |
| check whether something already exists in the repo | [discover](discover.md); the grounding runs it for the symbols the plan names |
| see a screen or drive a state model before you can decide | the interview marks that branch _runnable_ and forks [prototype](prototype.md) for it |

The plan is asked for when it is left out. Answers arrive in the language you opened the session
in; everything written into the repository is in English.

## Prerequisites

The skill writes into the project: `CONTEXT.md` (at the root, or the context's own when a
`CONTEXT-MAP.md` names one) and numbered ADRs under `docs/adr/`. Both are created lazily, on the
first term and the first ADR, and left uncommitted for you. Nothing else in the project is written,
and no code is edited. A runnable branch adds the prototype's own files, marked throwaway, kept out
of version control (a temp directory, or the repository's local exclude plus a two-line mount) and
listed in the closing summary.

## Branch, lens, tell

A plan is a **tree** of **branches**, one per decision it needs, ordered so that a branch whose
answer changes another comes first. The session grounds itself in the repository, closes every
branch the repository already answers, shows the tree once, and then walks the open branches.

Each open branch is put to you through a **lens**: a design principle turned into a question, with
the **tell** that fails it. The lenses run in a fixed order, and the ones a plan does not need are
skipped without comment:

| Group | Lenses |
|---|---|
| Target | experience-first |
| Subtraction | subtract-before-you-add, laziness-protocol |
| Shape | foundational-thinking, model-the-domain, type-system-discipline, boundary-discipline |
| Alternatives | exhaust-the-design-space, redesign-from-first-principles |
| Failure modes, each only when the plan matches | fix-root-causes, make-operations-idempotent, separate-before-serializing-shared-state, migrate-callers-then-delete-legacy-apis, outcome-oriented-execution |
| Delivery | sequence-verifiable-units, prove-it-works |
| Maintenance | minimize-reader-load, encode-lessons-in-structure |

The full text of each principle is in [`.agents/principles/`](../.agents/principles/README.md);
the skill carries the question and the tell inline, so it works on its own.

A branch closes in one of three states:

| State | Meaning |
|---|---|
| decided | you chose, and the choice was checked against the glossary, the code and one concrete scenario |
| default | a reversible detail; the skill states the choice and its reason instead of spending a question on it |
| deferred | parked, with the condition that reopens it |

Only a decision that is hard to reverse, surprising without context and the result of a real
trade-off becomes an ADR. Everything else lives in the closing summary.

A branch whose answer depends on seeing or driving the thing is marked **runnable**. Instead of a
question you cannot answer from words, the session forks the [prototype](prototype.md) agent with a
brief and, when its report lands, puts the question to you against the artifact: where to open it,
what to look at, the recommendation and the tell. Talking stays the default; a prototype is built
only for such a branch, or when you say you need to see it. When the agent stops with an ask
instead, on a part of the brief it could neither read off the code nor infer safely, the session
answers it from the repository when it can and otherwise puts it to you as an ordinary question,
then resumes the same agent with the answer. A second prototype is never started for it.

## Common questions

**Why did it not ask me about something the plan clearly depends on?**
Either the repository answered it, in which case the grounding note or the tree names the evidence
with a file and line, or it was a reversible detail and the skill took a default and said so. A
question is spent on direction, trade-offs and things that are hard to undo.

**It contradicted what I said about the code. Who is right?**
The code was read before your claim was accepted, and the contradiction is shown with a file and
line. You decide which side is right; the skill records the decision and never edits code to
settle it.

## It's working if

- Every question reaches you alone, with a recommended answer and the failure it hunts.
- A branch the code settles never reaches you as a question; the grounding note names it with a
  file and line.
- `CONTEXT.md` and `docs/adr/` grow during the session, not at the end, and the working tree is
  clean apart from them.
- A branch about what a screen should look like reaches you as something to open, with the
  question put against it, never as a request to describe a layout in words.
- A prototype that had to ask reaches you as one ordinary question, and the same prototype carries
  on after your answer.
- The closing summary lists every branch as decided, default or deferred, and names the next step.

## Where it fits

`discuss` is a reach-for-it-anytime standalone at the start of a piece of work: run it before the
shape is settled and before any code is written.

- [discover](discover.md), because the grounding runs one batch for the symbols the plan names,
  so no branch is opened for something that already exists.
- [prototype](prototype.md), because a runnable branch forks its agent, and nothing else does.
- The principles under [`.agents/principles/`](../.agents/principles/README.md), because every
  lens is one of them turned into a question.

The grouped list of every skill is in [the top-level README](../README.md).
