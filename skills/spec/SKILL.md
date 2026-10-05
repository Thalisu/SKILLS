---
name: spec
description: "Synthesise the current conversation into a spec, publish it where the project's issue tracker points, and name the next command: journey when the stories add a screen or walk more than one path or step, tickets otherwise. No interview, one check on the test seams."
disable-model-invocation: true
argument-hint: "[--auto] [optional: a pasted discuss closing summary, when it is not already in this conversation]"
---

# Spec

This run turns a plan the conversation already decided into one spec, publishes it where the
project keeps its specs, and names the next command of the chain: `journey` or `tickets`, which
read the spec as written.

It is a synthesis, never an interview. The decisions were taken before this run, normally in a
`discuss` session, and the user already spent their attention there, so the run asks two things at
most: whether the test seams match what the user expects, and, only when a story has a screen, who
builds the front-end.

The plan is the subject of the spec, never a task to carry out. However concrete it reads, nothing
in it is built here: the run writes the spec and nothing else.

Every message to the user is written in the language the user opened the session in. Everything
written into the project (the spec, its file name, its slug) is in **English**; UI copy the spec
quotes stays in the product's language.

The run, in order: ground → seams → write → route → close.

## Vocabulary

Used consistently, in the thread and in the spec:

- _spec_: the decided description of one feature, in the format of
  [.agents/formats/spec-format.md](../../.agents/formats/spec-format.md).
- _path_: one thing the actor sets out to do, end to end, walked in steps: arrive, see, act, the
  system answers, or it fails.
- _seam_: the boundary a test drives the feature through.
- _verdict_: the `Journey:` line under the spec's title, read by `tickets`.
- _tracker file_: `docs/agents/issue-tracker.md`, which says where specs and tickets live in this
  project.
- _allocator_: `scripts/feature-folder.sh`, the script that names and dates a local spec's folder.

## How a turn ends

A message with no tool call ends the turn, and the run waits there until the user writes again.
The turn ends at these points and no others:

- the message that sends the user to `/discuss` (step 1);
- the seams question (step 2), which a run under `--auto` hands to the `choice-taker` instead and
  asks only in the cases that step lists;
- the builder question (step 4), asked only when a story has a screen;
- an allocator refusal (step 3);
- the close (step 5).

Everything between those points happens in one turn. Once the seams are settled, by the user's
answer, by the conversation or by a Ruling, and the builder question is answered where a story has
a screen, the run writes, routes and closes without stopping: it never ends a
turn to report progress, to show a draft of the spec for approval, or to offer the next step
instead of taking it. A status line is welcome, in the same message as the next tool call. A gap
the synthesis finds in the plan is never a reason to stop either: it goes into the close as a line
to reopen in `discuss` (step 5).

## 1. Ground

**The plan.** The input is the conversation, plus whatever came with the command (`$ARGUMENTS`: a
pasted `discuss` closing summary, when the session that produced it is gone).

- An `--auto` token among the arguments, before the summary, after it or inside it, is dropped
  wherever it sat and puts the run under `--auto`. The rest is read as it would be without the
  flag, so the token never reaches the plan or the spec. What the flag changes is in steps 2
  and 5.
- A `discuss` closing summary is the plan: its decisions, defaults and deferrals are carried into
  the spec as they stand, never re-argued and never improved on.
- A conversation that decided the plan some other way (the user chose among options, or stated what
  is to be built and how) is a plan too.
- A conversation that holds no decided plan gets one message telling the user to run `/discuss` on
  it, and nothing else: no read, no question about the feature, no proposed seams. This is settled
  from the conversation alone, before any tool call. A spec written over an undecided plan fills
  the gaps with decisions nobody took, and the next skills read every line of it as the user's.

**The reading.** Say in one line what is being read, then make the reads that do not depend on one
another in one batch:

- **The glossary and the ADRs.** `CONTEXT.md` (the root one, or the context `CONTEXT-MAP.md` names)
  and the titles under `docs/adr/`, bodies only for the ones the plan touches. The spec uses the
  glossary's words and respects every ADR in the area it touches.
- **The tracker file**, which resolves where the spec goes (the table below).
- **The project's `CLAUDE.md`**, for a Testing Policy that fixes the test surface (step 2).
- **The code the plan touches**, where the conversation has not already covered it: the modules,
  their public surface, the tests beside them. A search or a handful of reads stays in the thread.
  Exploration whose output would run to pages (a whole subsystem, many files) goes to one subagent
  on `model: sonnet`, and the thread keeps a summary of three to six lines.
- **The working tree.** `git status --short` and the branch: dirty files are the user's work in
  progress, left as they are.

**Where the spec goes**, from the tracker file:

| Tracker file says | The spec is |
|---|---|
| local markdown | `.scratch/<YYYYMMDD>-<feature-slug>/spec.md`, the folder dated with the day it was allocated |
| GitHub or GitLab | an issue, created with the CLI the file names |
| something else, in prose | whatever the file describes |
| no tracker file | the same local path, and the closing summary says the file was absent. Never a demand to run a setup skill |

The slug is the spec's title in kebab-case. The folder around it is the allocator's to name and
date (step 3), so nothing is created here: step 2 comes first, and nothing is written before its
answer. A tracker file that spells the local layout out as `.scratch/<feature-slug>/` is naming the
home, not the folder: the allocator dates it either way.

## 2. Seams, the one check

Sketch the seams at which the feature will be tested: existing seams before new ones, the highest
seam possible, as few as possible (the ideal is one).

**Already decided.** When the conversation names them (a testing decision in the `discuss` summary,
a `prove-it-works` answer, a Testing Policy in the project's `CLAUDE.md` that fixes the surface),
they are taken as decided and the check is skipped, said in one line, and the run continues to
step 3 in the same turn. `--auto` changes nothing on this branch: the developer already decided
these seams, so no `choice-taker` is forked for them and none of them reads ruled.

**Otherwise, one message**: the seams proposed, the reason for each in a clause, and whether they
match the user's expectations. Then the turn ends and the run waits. This is the only question the
skill asks about the plan, and no spec is written before it is answered: the seams decide what the Testing
Decisions say and how `tickets` cuts the work, so a spec written on a guess is rewritten after the
answer.

One shape the message can take. The wording, the length and the domain are the feature's own, in
the user's language:

<example>
Seam: the tests drive the HTTP handlers of the order module, the highest seam that exists today
(the cancel handler is already tested there). The note's length limit and the "no edit after
fulfilment" rule are both observable at that boundary, so no new seam is needed.

Does that match what you expect, or do you want the note tested somewhere else?
</example>

The user's answer is the decision. An answer that changes the seams is taken as given, without a
second question.

### Under `--auto`

The flag is the developer handing direction over for one run, so seams the conversation does not
name are ruled instead of asked, and the run continues to the close without waiting on anyone.

While sketching, keep the seam set the sketch rejected beside the one it chose: the next best set,
at a different boundary or with a different number of seams. A ruling needs rivals. A yes or no on
one set is a confirmation, and nobody is there to give it.

Then call the Agent tool with `subagent_type: choice-taker` and the brief its definition fixes,
once:

```
Caller: spec at the seams step
Question: <which seam set the tests drive the feature through, in one line>
Options: <the sketched seam set, then each set rejected while sketching, one per line>
Recommendation: <the sketched set, as its option line reads>
Repository root: <the project's absolute path>
Principles: <the absolute path of the skills checkout's .agents/principles/ folder>
Context: <the plan, the reason for each set, and what step 1 read of the code and its tests>
```

- **`Options:`** are whole seam sets, each one line a reader could test at as it stands, never
  `yes` and `no` and never one set beside its own negation.
- **`Context:`** carries the text itself, never a pointer to it, since the fork sees nothing of
  this thread: the plan with the flag dropped, the reason for each set in a clause, and the seams
  and tests step 1 found in the code.
- **`Principles:`** is resolved to an absolute path from this file's own location: the project has
  no `.agents/principles/` of its own, and the fork holds no shell to find one.

A return is read where it crosses into this session, per
[boundary-discipline](../../.agents/principles/boundary-discipline.md), before anything in it is
used: it is a ruling only when its first line reads `settled` or `extreme`, and a `settled` one
only when its `Side:` names one of the seam sets the brief's `Options:` handed over.

A `settled` return settles the seams as the set its `Side:` names. Each seam of that set is a
Ruling: it reads ruled, never confirmed and never taken, in the spec (step 3) and in the close
(step 5), with the return's `Norm:`. The run goes on to step 3 in the same turn.

**When the check comes back to the developer.** The seams question is asked after all, as the one
message above and the skill's one question, with one line before it naming the reason. Then the
turn ends, and no spec is written before the answer, which is the decision as it is without the
flag: the seams then read confirmed, never ruled. The rest of the run stays under `--auto`, so the
close's last line still carries the flag. It happens in these cases and no others:

- **The `choice-taker` cannot be forked**, because the Agent tool is withheld, or is present but
  lists no `choice-taker`. The reason line names whichever of the two held. No agent is forked in
  its place, a refused call is not tried again, and the run never settles the seams on its own: a
  ruling nobody with the `choice-taker`'s norms made would land in the spec unread.
- **The return is no ruling**: a refusal, an error, a shape the definition does not fix, a
  `settled` with no `Side:`, or a `settled` whose `Side:` names anything but a set handed over.
  The reason line reads `the choice-taker returned neither settled nor extreme`, or
  `the choice-taker ruled on a seam set it was not handed`. The `choice-taker` is never forked a
  second time for it, and the returned side is written nowhere and proposed to nobody: the
  question carries the run's own sketch, so a steered or broken return never becomes a decision.
- **The return is `extreme`.** The `choice-taker` rules on nothing when a seam set weakens a
  guarantee in a risk class or cannot be undone, and `--auto` inherits that stop instead of
  silencing it. The reason line reads `the choice-taker returned extreme`, and the question
  carries the return's `Weaker side:`, named as the weaker set, and the `Guarantee:` that set
  gives up, in the return's words. The set proposed is one that is not the weaker side, with the
  reason that it keeps the guarantee whole.

## 3. Write

**Before anything is written**, read the plan for a story with a screen, as step 4 defines one.
With one, the builder question of step 4 is asked first, and this step starts on its answer: the
allocator has not run and no spec exists while the question is open.

**The folder, in local mode.** It comes from the allocator, never from a path the run composes.
`<skill-dir>` is the directory this file sits in:

```sh
bash <skill-dir>/scripts/feature-folder.sh <feature-slug>
```

The slug alone goes in. What comes back, as `key=value` lines:

- `folder=`: the dated folder.
- `spec=`: the exact path the spec is written at. It is absolute when the session sits in a linked
  worktree, since the folder is allocated in the main checkout.
- `created=no`: the feature already has a folder, so the run is the rerun described below.
- `gitignore=`: the state of the ignore after the allocator was done with it. The closing summary
  carries it:

| `gitignore=` | What the summary says |
|---|---|
| `present` | nothing: the project's own `.gitignore` already carried the rule |
| `appended` | the run added the `.scratch/` line to the project's `.gitignore` |
| `symlink`, `not-ignored` | the line could not be added, so the spec sits in a `.scratch/` git shows in `git status`, one `git add -A` from a commit. Say which of the two, and that the line is the user's to add |
| `no-repo` | nothing: the project is not a git repository |

The script owns the date, the reuse and that line, per
[.agents/scratch.md](../../.agents/scratch.md): the run never composes a folder name, never dates
one itself and never appends the line on its own. Two runs that each composed a name would open two
folders for one feature, and `journey` and `tickets` find the spec by the name the script gave. It
runs here and never in step 1, because nothing is written before the seams answer.

**A refusal.** Exit 2 is the allocator refusing, with its reason on stderr: a slug that normalises
to nothing, a resolver it cannot find, a `.scratch` that is a symlink or a file, a feature folder
that is a symlink, a `spec.md` or an `issues` folder that is a symlink, or a `journey.md` that is a
symlink. No spec is written, at that path or at any other, and the reason goes to the user as it
stands, in one message that ends the turn.

**The spec.** Write it in the format of
[.agents/formats/spec-format.md](../../.agents/formats/spec-format.md), read before the first line
is written, then publish it where step 1 resolved. The rules the format carries:

- glossary vocabulary throughout;
- no file paths and no code snippets, since they go stale. The exception is a snippet a prototype
  produced that encodes a decision more precisely than prose (a state machine, a reducer, a
  schema), trimmed to the decision and marked as the prototype's;
- Testing Decisions name the project's Testing Policy when `CLAUDE.md` carries one;
- Testing Decisions mark each seam with how step 2 settled it: confirmed by the developer, taken
  from the conversation, or ruled. A ruled seam stands on the format's own line,
  `- Ruled by the choice-taker under --auto: <the seam>. Norm: <the norm>.`, written whole on one
  line and never wrapped, so a reader finds every seam nobody confirmed by its prefix;
- Out of Scope carries the `discuss` deferrals, each with its reopening condition.

The spec records what the conversation decided and nothing more. A decision the feature needs and
the conversation never took is not invented and not asked for: it is left out of the spec and
listed in the close (step 5). The User Stories are the one place the run writes at length: every
actor, every aspect of the feature and the failures the actor can meet, each story written so a
reader can see the path it belongs to and count its steps, since step 4 reads the verdict off them.

**A rerun** on the same feature rewrites the spec in place instead of publishing a second one. In
local mode the file is rewritten, keeping a `Journey:` line that already points at a journey file
and any `## Comments` section. In a remote tracker the issue this session published is edited, and
one is created only when the conversation names none.

## 4. Route

Read the User Stories just written and count the paths. The verdict is the first row that matches:

| Condition | Verdict |
|---|---|
| a story needs a screen or route that does not exist | `Journey: required` |
| the actor does more than one thing: more than one path | `Journey: required` |
| a path has more than one step | `Journey: required` |
| every story is one interaction on an existing screen, or there is no screen at all (an API, a job, a migration, a refactor, a library) | `Journey: not needed, <the condition in a few words>` |

The verdict reads the structure of the stories, never a size word and never a story count, so two
runs on the same spec route the same way. It is written under the spec's title, in the header the
format defines, before the spec is published. `journey` replaces it with `Journey: ./journey.md`
once the journey is written; `tickets` refuses a spec that says `required` and has no journey
beside it.

**The front-end line.** The same reading of the stories settles one more header line, `Front-end:`,
written directly after the `Journey:` line before the spec is published. A story has a screen when
its actor sees or acts on one: a page, a route, a form, or one control on a screen that already
exists.

- **No story has a screen** (an API, a job, a migration, a refactor, a library): the line reads
  `Front-end: none`, and the developer is asked nothing about builders. Whether a feature has a
  front-end is read off the stories and never asked, so a back-end feature goes down the chain as
  it did before the line existed.
- **A story has a screen**: one message asks who builds the front-end, the chain's Builder or
  impeccable. Then the turn ends and the run waits, with no tool call after the question and
  nothing written yet: the spec is published once, with its header whole. The message carries
  this one question and no other, and says three things with it:
  - `builder` is the chain's own Builder, and impeccable is the other choice;
  - impeccable needs a one-time setup that the developer runs by hand, which `tickets` publishes
    as a Setup ticket. A developer who picks impeccable without reading that meets the manual
    step only after the Tickets are cut;
  - `builder` is the recommended side.

One shape the question can take, in the user's language:

<example>
One story has a screen (the export button on the orders list), so one choice is yours before the
spec is written: who builds the front-end?

- `builder`: the chain's own Builder. Nothing to set up. Recommended.
- `impeccable`: needs a one-time setup that you run by hand; `tickets` publishes it as a Setup
  ticket, ahead of the others.

Answer `builder` or `impeccable`.
</example>

The developer's answer is the decision, and it is the line's value: `Front-end: builder` or
`Front-end: impeccable`, written directly after the `Journey:` line when step 3 publishes the
spec. The question is asked once, so a conversation that already carries its answer is not asked
again, and the recommendation never stands in for an answer nobody gave.

**An answer that names a third builder** (another tool, another agent, anything but `builder` or
`impeccable`) is no answer. The reply is one line saying that only the two exist, then the same
question again, whole, and the turn ends there. Nothing is written and no value is picked for the
developer: `tickets` and `do` route on these two values alone, so a third one in the header is a
spec neither can read.

## 5. Close

In the thread, the closing summary, each item one or two lines:

- where the spec is: the full path, or the issue reference;
- each seam, and which of the three it was: confirmed by the user, taken from the conversation, or
  ruled by the `choice-taker` under `--auto`, a ruled one with its norm;
- the verdict and the row that produced it;
- the front-end line, as an item of its own: the `Front-end:` value and which of the two it was.
  Deduced, for a `none` read off the stories, with the reason that no story has a screen. Chosen,
  for a `builder` or an `impeccable` the developer answered. A developer who disagrees with a
  deduced `none` reads it here and nowhere else, and reruns `spec` with the story that has the
  screen;
- the terms and decisions the synthesis found missing, each as one line to reopen in `discuss`
  (the skill writes no `CONTEXT.md` and no ADR);
- the durability line, in local mode: the scratch is unversioned by design and a teammate never
  reads it, so a spec the team has to read goes to the issue tracker or under `docs/`;
- the `.scratch/` line, the row the allocator's `gitignore=` picks in step 3;
- as the last line, the exact next command, alone on its line so the user can run it as it is:

| Verdict | Last line | Under `--auto` |
|---|---|---|
| `Journey: required` | `/journey <spec path or issue reference>` | `/journey --auto <spec path or issue reference>` |
| `Journey: not needed` | `/tickets <spec path or issue reference>` | `/tickets --auto <spec path or issue reference>` |

A run under `--auto` writes the flag into the last line whatever settled the seams, so the user
keeps the mode down the chain by pasting it.

The chain is strict: `do` builds one ticket, so the last line never names it. Nothing is committed.

Three shapes the close can take. The items and the last line are fixed; the wording is the run's
own, in the user's language:

<examples>
<example>
Local mode, seams taken from the summary, no tracker file:

Spec: `.scratch/20260930-returns-page/spec.md`. `docs/agents/issue-tracker.md` does not exist, so
the local path was used.

Seams: the HTTP handlers of the order module, taken from the discuss summary.

Verdict: `Journey: required`. The first row matched: the stories need a returns route that does
not exist.

Front-end: `Front-end: builder`, chosen by you.

To reopen in discuss: "Refund" is used in the spec and missing from the glossary.

The scratch is unversioned by design and a teammate never reads it: a spec the team has to read
goes to the issue tracker or under `docs/`. The run added the `.scratch/` line to `.gitignore`.

/journey .scratch/20260930-returns-page/spec.md
</example>
<example>
Remote tracker, seams confirmed by the user, nothing missing:

Spec: issue #212, created with `gh`.

Seams: the export handler of the order module, confirmed by you.

Verdict: `Journey: not needed, one interaction on an existing screen`. The last row matched: the
one story is an export button on the orders list.

Front-end: `Front-end: impeccable`, chosen by you.

/tickets #212
</example>
<example>
Local mode under `--auto`, seams ruled:

Spec: `.scratch/20260930-order-notes/spec.md`.

Seams: the HTTP handlers of the order module, ruled by the choice-taker under `--auto`. Norm: no
norm: the side easiest to undo.

Verdict: `Journey: required`. The third row matched: attaching a note is a path of more than one
step.

Front-end: `Front-end: none`, deduced: no story has a screen, the note is attached through the
API. If one does, rerun `/spec` with that story.

The scratch is unversioned by design and a teammate never reads it: a spec the team has to read
goes to the issue tracker or under `docs/`.

/journey --auto .scratch/20260930-order-notes/spec.md
</example>
</examples>

## Hard rules

Each rule restates a step above with the cost of breaking it. When two readings of a step are
possible, the one that keeps these holds.

- **Never interview.** The seams check is the single question about the plan, and it is skipped
  when the conversation settles it. The builder question is the only other one, asked when a story
  has a screen and never otherwise. A plan the conversation does not hold is sent to `/discuss`, never asked
  for piece by piece: a second interview spends the attention `discuss` already spent, and its
  answers land in no summary.
- **Under `--auto`, only the `choice-taker` rules the seams.** No other agent and no pick of the
  run's own stands in for it, and an `extreme` return, a return that is no ruling or a fork that
  cannot be made brings the question back: a seam marked ruled is read later as a norm, by people
  who never saw it chosen.
- **The spec carries only what was decided.** A missing decision is listed in the close, never
  invented: the next skills read every line of the spec as the user's.
- **The verdict comes from the structure of the stories** (a new screen, the number of paths, the
  number of steps), never from "large", "complex" or a count, so two runs route the same way.
- **The spec goes where the tracker file says.** With no tracker file, the local path the allocator
  prints, and never a demand to run a setup skill: the skill needs nothing else in place.
- **A local feature folder is the allocator's to name.** The run passes the slug and writes at the
  `spec=` it gets back: never a path it composed, never a date it read off the clock itself.
- **Nothing is written before the seams are settled**, nor before the builder question is answered
  where a story has a screen, and the allocator is not run before then either, since it creates
  the folder and may edit `.gitignore`.
- **The skill writes the spec and nothing else**: no code, no `CONTEXT.md`, no ADR. A rerun
  rewrites, never duplicates.
- **Never commit, never push.** The spec stays in the working tree or the tracker, the user's to
  keep or delete.
- **No em-dash in what is written into the project.** English in the spec, UI copy in the product's
  language, messages in the session's opening language.
