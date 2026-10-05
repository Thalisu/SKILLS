# discuss

## What it does

`discuss` interviews you about a plan before any code is written. It reads what the repository
already knows (the glossary in `CONTEXT.md`, the ADRs, the code the plan touches), lays the plan
out as a tree of decisions, and walks that tree one question at a time, each question carrying a
recommended answer and the failure it hunts. A resolved term is written into `CONTEXT.md` the
moment it lands. A decision stays on its branch until the close, where the ones that are hard to
reverse, surprising without context and the result of a real trade-off are written into `docs/adr/`
for you, without a question, and every candidate the close dropped is named in the summary with the
reason. The session closes with a summary of every decision, default and deferral.

It never asks what the repository can answer. A branch the code or the docs already settle is
closed with the evidence and never put to you, and a claim about how the code works is read in the
code before it is accepted.

## When to reach for it

You invoke this by typing `/discuss`, and the agent won't reach for it on its own.

| Ask | Use |
|---|---|
| stress-test a plan, a feature, a refactor or a fix before building it | `/discuss <the plan>` |
| have the plan's branches settled without you, for one run | `/discuss --auto <the plan>`; the flag can sit before, after or inside the plan |
| understand how a subsystem works, with no plan on the table | a walkthrough, or read the code |
| settle the shape (types, signatures, module boundaries) once the decisions are made | an architect-style skill; the closing summary names the moment for it |
| turn the decisions into a spec once the session closes | [spec](spec.md), typed by you; the closing summary is its input and ends by naming it |
| check whether something already exists in the repo | [discover](discover.md); the grounding runs it for the symbols the plan names |
| see a screen or drive a state model before you can decide | the interview marks that branch _runnable_ and forks [prototype](prototype.md) for it |

The plan is asked for when it is left out. Answers arrive in the language you opened the session
in; everything written into the repository is in English.

## Prerequisites

The skill writes into the project: `CONTEXT.md` (at the root, or the context's own when a
`CONTEXT-MAP.md` names one) and numbered ADRs under `docs/adr/`. Both are created lazily, on the
first term and the first ADR the close writes, and left uncommitted for you. Nothing else in the
project is written, and no code is edited. A runnable branch adds the prototype's own files, marked
throwaway, kept out of version control (a temp directory, or the repository's local exclude plus a
two-line mount) and listed in the closing summary. `--auto` needs the `choice-taker` agent linked,
which `scripts/link-skills.sh` does with the rest; without it the run asks you every branch, saying
why.

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

A decision is not written the moment it lands. Each decided branch keeps its choice, its reason
and the alternative it beat in one line, and at the close every branch that passes the three gates
of an ADR (hard to reverse, surprising without context, the result of a real trade-off) is listed
as a **candidate**, one line per gate, and every candidate that survives the filter below is
written into `docs/adr/`, without asking you first. Everything else goes to the closing summary,
and from there into the spec's Implementation Decisions, which is where a decision scoped to one
feature belongs. Three things never make the list:

| Looks like a decision | Where it lives instead |
|---|---|
| a rule `CONTEXT.md` already carries | the glossary |
| the modules, interfaces and contracts of this feature | the spec's Implementation Decisions |
| a choice whose alternative lost only because a repo rule forbids it | the summary; nothing was traded off |

One more drop applies to what is left: a candidate on the list because its branch took the longest
argument of the session, rather than because a future reader will look for it, goes to the summary
too, with the reason it was dropped.

A branch whose answer depends on seeing or driving the thing is marked **runnable**. Instead of a
question you cannot answer from words, the session forks the [prototype](prototype.md) agent with a
brief and, when its report lands, puts the question to you against the artifact: where to open it,
what to look at, the recommendation and the tell. Talking stays the default; a prototype is built
only for such a branch, or when you say you need to see it. When the agent stops with an ask
instead, on a part of the brief it could neither read off the code nor infer safely, the session
answers it from the repository when it can and otherwise puts it to you as an ordinary question,
then resumes the same agent with the answer. A second prototype is never started for it.

## Under `--auto`

`/discuss --auto <the plan>` hands the interview over for one run
([ADR 0045](adr/0045-auto-hands-direction-to-the-choice-taker-and-four-classes-still-stop.md)).
The token is dropped wherever it sat and the rest is the plan. The repository still answers first.
Every branch it cannot close, the one question that branch would have been, goes to the
`choice-taker` agent, which rules it from the norms the repository writes down, and the run reaches
its close without waiting on you.

- Each branch is sent on its own, in walk order, with the plan, the grounding note and every branch
  closed so far, so no branch is ruled against a decision the session already took.
- A branch ruled that way closes in a fourth state, **ruled**, holding the option taken, the norm
  behind it and the options it beat.
- A runnable branch is ruled unseen, from a description of its candidates. No prototype is built,
  since nobody is there to open it, and its line carries the `/prototype` command that would show
  it.
- A contradiction between the plan and the code is ruled like any other branch and listed as
  ruled, never as your pick.

What you find afterwards:

| Where | The mark |
|---|---|
| the closing summary | a `Rulings` section apart from the decisions, one line per ruled branch; a ruled branch never appears among the decisions, which reach the spec as yours |
| an ADR written from a ruled branch | the line `Ruled by the choice-taker under --auto: <norm>` directly under its title; an ADR from a branch you decided never carries it |
| the last line of the summary | `/spec --auto`, so pasting it keeps the mode at the next skill |

Of the four classes ADR 0045 keeps for you, a `discuss` run can meet one, the Extreme fork: it
discards no work, drops no commit and writes to no tracker. These still reach you under the flag:

| What happened | What reaches you |
|---|---|
| the plan was left out | the ask for it, as without the flag |
| the `choice-taker` returned `extreme`: an option weakens a guarantee in a risk class or cannot be undone | that branch as one question, carrying what the agent returned: the tell names the weaker side and the guarantee it gives up, and the recommendation is the side that keeps it. The walk resumes under the flag at the next branch |
| its return was no ruling: a broken shape, an option it was never handed, or a term your glossary does not define | that branch as one question, with the reason in one line before it. It is never sent to the agent a second time |
| it could not be forked: the agent is not linked, or the Agent tool is withheld | that branch and every one after it, asked as without the flag, with the reason said once |

No other agent, and never the session itself, rules in the `choice-taker`'s place.

## Common questions

**I ran it with `--auto` and it still asked me something. Why?**
The line before the question, or its tell, says which row of the table above it was: an `extreme`
return, a return that was no ruling, or an agent that could not be forked. Answer it and the branch
closes as yours, decided, default or deferred, with no `ruled` row.

**Why did it not ask me about something the plan clearly depends on?**
Either the repository answered it, in which case the grounding note or the tree names the evidence
with a file and line, or it was a reversible detail and the skill took a default and said so. A
question is spent on direction, trade-offs and things that are hard to undo.

**It contradicted what I said about the code. Who is right?**
The code was read before your claim was accepted, and the contradiction is shown with a file and
line. You decide which side is right; the skill records the decision and never edits code to
settle it.

**It used to write an ADR the moment a branch closed. Why only at the end now?**
One ADR per decided branch turned a single feature into a shelf of them, most restating what the
spec was about to say, and every later step of the chain reads `docs/adr/` for the area it touches,
so each weak ADR is context spent on every run after it. The three gates are judged better with
the whole tree closed, when a later branch may have swallowed an earlier decision, and the
candidate list is filtered once, in one place. Nothing is lost in between: the ADR is written from
the line the branch kept, not from memory of the interview.

**Why does it write the ADRs instead of asking me which ones?**
The three gates and the tells are the filter, and the session has already applied them to reach the
candidate list; a question about which ones to write puts the same filter to you a second time, at
the point the session is closing. What it writes is uncommitted and listed in the summary with its
path, so an ADR you did not want is a file to delete rather than a question you had to answer, and
the summary names every candidate the filter dropped and why, so its judgement stays yours to
reverse.

## It's working if

- Every question reaches you alone, with a recommended answer and the failure it hunts.
- A branch the code settles never reaches you as a question; the grounding note names it with a
  file and line.
- `CONTEXT.md` grows during the session; `docs/adr/` changes only at the close, and only with the
  candidates the filter left standing. The working tree is clean apart from them.
- The close names every ADR candidate with its three gates filled, says which ones it wrote and
  which it dropped and why, and asks you nothing.
- A branch about what a screen should look like reaches you as something to open, with the
  question put against it, never as a request to describe a layout in words.
- A prototype that had to ask reaches you as one ordinary question, and the same prototype carries
  on after your answer.
- The closing summary lists every branch as decided, default or deferred, and names the next step.
- After an `--auto` run, every branch you were not asked about has a line under `Rulings` in the
  summary, each ADR written from one opens with `Ruled by the choice-taker under --auto:` under its
  title, and the last line reads `/spec --auto`.

## Where it fits

`discuss` is a reach-for-it-anytime standalone at the start of a piece of work: run it before the
shape is settled and before any code is written.

- [discover](discover.md), because the grounding runs one batch for the symbols the plan names,
  so no branch is opened for something that already exists.
- [prototype](prototype.md), because a runnable branch forks its agent; [journey](journey.md) does
  the same for a runnable fork.
- [spec](spec.md), because the closing summary is its input: the session ends by naming it.
- The [`choice-taker`](../skills/do/agents/choice-taker.md) agent, because under `--auto` it rules
  every branch you would have been asked.
- The principles under [`.agents/principles/`](../.agents/principles/README.md), because every
  lens is one of them turned into a question.

The grouped list of every skill is in [the top-level README](../README.md).
