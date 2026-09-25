# Skill chain

The sequence of skills a piece of work walks through in this repo, from a plan to a built unit:
`discuss`, then `spec`, then `journey` when the spec's verdict requires it, then `tickets`, then
`do`, one ticket at a time. The chain is strict: each skill takes only the artifact of the step
before it. This glossary holds the words those skills share.

## Language

**Spec**:
The decided description of one feature, synthesised from a `discuss` session: problem, solution,
user stories, implementation and testing decisions, and what is out of scope.
_Avoid_: brief, PRD, plan

**Path**:
One thing the actor sets out to do, end to end, walked in steps: arrive, see, act, the system
answers, or it fails.
_Avoid_: flow, journey (the journey is the document, a path is one entry in it), user story (the
story is the sentence, the path is the walk)

**Verdict**:
The `Journey:` line under a spec's title: `required`, or `not needed` with the condition; replaced
by the journey's location once the journey is written.
_Avoid_: flag, journey needed

**Journey**:
The document that walks every path of one spec from the actor's seat, kept where the spec's
**Verdict** line points once it is written: beside the spec as a file, or linked from the issue.
_Avoid_: user flow, UX doc

**Ticket**:
One demoable slice cut from a spec, and from its journey when it has one, sized by the peak context
the `do` session reaches while building it: small under 150k tokens, medium up to 200k, large
beyond that. The skill that cuts the set is `tickets`.
_Avoid_: issue (only when quoting a tracker that calls them issues), slice, task, "fits one
session" (a session is not a number; the peak context is), total tokens (the agents `do` forks
hold their own windows; only the session's context counts)

**Playbook**:
One execution model `do` routes a request to, kept under the skill's `references/` and read only
on match.
_Avoid_: mode, workflow, checklist (the checklist is a playbook's steps copied into the run's todo
list), route (the route is the match, the playbook is what runs)

**Trivial**:
A change no test could tell before from after, so the existing suite is its whole gate: a typo, a
doc or a comment, formatting, log wording, a rename inside one file, dead code, a lint fix.
_Avoid_: small (a small **Ticket** is a size band, never a Trivial change), quick, minor,
one-liner (size is never the test)

**Reply**:
The one message a `do` run ends with, and the record every line a step names reaches the developer
through: the read-back, the checklist, the audit line, what was handed to a fork and what came back.
_Avoid_: the thread (a line written mid-run, before a tool call, is never where a line has to be),
narration, first message

**Digest**:
The slice of a **Ticket**'s **Spec** and **Journey** that a `do` run needs, read out of both by a
forked agent at the run's door and returned quoted, with the location of every quote.
_Avoid_: summary (a summary paraphrases, a **Digest** quotes), brief, extract, context pack,
handoff

**Map**:
What a `do` run's ground step takes the subsystem as, in place of its code: where things live, what
calls what, and where the seams are, returned by a fork so the exploration stays out of the
session.
_Avoid_: overview, walkthrough, summary, the code itself, **Project map** (that one names a
project's run commands and test layout for a test author)

**Sketch**:
The shape a **Ticket**'s work takes before any logic: the caller's usage, the types, the
signatures and the module boundaries, with unimplemented bodies. Written by the `sketch` skill.
_Avoid_: design, design doc, blueprint, architecture, prototype (a prototype is runnable and
throwaway, a **Sketch** is the contract the build is held to), **Plan** (a **Sketch** is one
section of a **Plan**)

**Plan**:
The file a `do` ticket run's **Planner** writes before the build: the grounding it read, the
behaviours list cut from the **Ticket** and its **Digest**, and the **Sketch** when the shape step
fires. The **Builder** builds from it, and a resume reads it instead of grounding again.
_Avoid_: todo, checklist, roadmap, **Spec** (the **Spec** is the feature's, and comes from
`discuss`), brief (a brief is what a fork is dispatched with, not what it leaves behind)

**Planner**:
The sub-agent a `do` ticket run forks first: it grounds the run and writes the **Plan**, so that
neither the grounding nor the behaviours list is derived in the session's own window.
_Avoid_: architect, designer, orchestrator, delegate

**Builder**:
The sub-agent a `do` ticket run forks once per **Ticket**: it runs the whole build loop in the
worktree from the **Plan**, dispatches its own test authors, and commits one behaviour at a time.
_Avoid_: executor, implementer, coder, delegate (the delegate was the exception writer of the
shape before this one), **Fixer** (a **Fixer** belongs to the review)

**Design fork**:
Two shapes a `do` run's work could take that neither the **Ticket**, its **Spec** nor the code
settles.
_Avoid_: blocker, gap, open question, empirical fork (a fact a probe script can observe is never a
**Design fork**)

**Extreme fork**:
A **Design fork** one of whose sides weakens a guarantee in a risk class (security, privacy, data
loss, auth, billing, migration, idempotency, race) or cannot be undone once landed.
_Avoid_: dangerous, harmful, big decision, sensitive (each is a judgment a run makes differently
every time; the test is whether a side weakens a guarantee or cannot be undone)

**Ruling**:
What the `choice-taker` returns on a question it settles, a **Design fork** a `do` run met or a
question a chain skill run with `--auto` would otherwise put to the developer: the side taken, and
the norm that backs it or "no norm: the side easiest to undo". A **Design fork**'s Ruling is
written as one line in the **Spec**'s Implementation Decisions and listed under `Rulings` in the
run's reply, read back from that line. A Ruling on a question that is not a **Design fork** amends
no file: it is listed under `Rulings` alone, in a group of its own, so the two are never read as
one.
_Avoid_: verdict (the **Verdict** is a spec's `Journey:` line), decision (the **Spec**'s decisions
come from `discuss`; a **Ruling** is appended to them and marked as the `choice-taker`'s), answer

**Ruled ADR**:
An ADR a `discuss` run with `--auto` wrote from a **Ruling** rather than from the developer's
choice, marked by a `Ruled by the choice-taker under --auto: <norm>` line under its title. It is a
norm like any ADR, and it yields to every ADR the developer decided when the two disagree.
_Avoid_: auto ADR, draft ADR (it is written and binding until a developer's ADR or a deletion
overrides it), provisional decision

**Scratch**:
The unversioned folder a project keeps its local chain artifacts in, `.scratch/`: a **Spec**, its
**Journey**, its **Tickets** and the **Reviews** beside them. Always ignored by git, so it is one
developer's own workspace and never reaches a teammate; what the team has to read goes to the
issue tracker or under `docs/`.
_Avoid_: temp, workspace, drafts folder

**Feature folder**:
The directory in the **Scratch** that holds one feature's artifacts, `.scratch/<YYYYMMDD>-<feature-slug>/`,
dated with the day it was allocated. A bare slug names the folder called `<slug>` or
`<YYYYMMDD>-<slug>` and no other, the newest when a slug carries more than one, and an undated
folder from before the dated rule over every dated one.
_Avoid_: spec folder, slug folder, feature directory

**Main checkout**:
The working tree a `do` run is invoked from, the one every artifact outside version control lives
in: the **Ticket**, its **Spec**, its **Journey** and the **Review** beside it. A build runs in a
git worktree created from its HEAD, a second working tree of the same repository that starts
without any of them, so a step inside the worktree reaches them by the main checkout's absolute
path.
_Avoid_: main branch, current branch (an ignored file is on no branch and survives every switch),
root, primary repo

**Axis**:
One independent question `do-code-review` puts to a diff, reported apart from the others so that a
pass on one never hides a fail on another: correctness, spec fidelity, repo standards, principles,
blast radius, security.
_Avoid_: lens (a lens is one principle turned into a question, inside the principles axis),
category, check, branch (the two reviewers are agents, not axes)

**Finding**:
One thing the review claims about a diff: its **Axis**, its **Bucket**, where it is (`file:line`,
a spec line quoted, or a place outside the diff), the claim in one line, the evidence in the shape
its axis takes, its **Rung**, a risk class when one applies (security, privacy, data loss, auth,
billing, migration, idempotency, race), and the fix as a behaviour to prove plus its target.
_Avoid_: issue, comment, suggestion, nit

**Bucket**:
Where a **Finding** lands in the report: `Act on` (fix before landing), `Consider` (a judgment
call, the reader decides), `Noted` (an observation, no action), `Cleared` (suspected, then refuted
by evidence; shown so the reader can override).
_Avoid_: severity, priority, dismissed (the caller's word for a finding it chose not to act on)

**Rung**:
How far the review climbed to back a **Finding**, on the ladder of `blast-radius`: 1 said so, 2
pointed at `file:line`, 3 walked the failure, 4 ran it, 5 reproduced it in the app.
_Avoid_: confidence, score, certainty

**Review**:
The file `do-code-review` writes for one diff: the intent, the one safety fact, the **Findings** by
**Bucket**, one line per **Axis**, and, after the **Fixers** ran, what was fixed and what was
verified. Always a local markdown file, whatever the tracker. It belongs to one **Ticket** and
lives beside it, naming it; outside the chain it names the branch and the fixed point instead.
_Avoid_: report (the message returned to the caller, not the file), task review, PR comments

**Fixer**:
The sub-agent `do-code-review` forks for one `Act on` **Finding** of a **Review**, writing that
**Finding**'s one commit in a worktree and on a branch of its own; one **Fixer** per **Finding**,
and the **Fixers** of one **Wave** at once.
_Avoid_: fix agent, implementer, delegate (a delegate is `do`'s exception writer, not the review's)

**Wave**:
The `Act on` **Finding**s whose **Fixers** run at once: a script's floor, where two **Finding**s
share a **Wave** only when the files they name are disjoint and a **Finding** whose files cannot be
read is a **Wave** of its own, which the review may cut finer, with one reason per cut, and which
nothing may widen.
_Avoid_: batch, group, round, phase (a phase is a `do` build step, a **Wave** is the review's)

**Gate fixer**:
The sub-agent `do-code-review` forks when the **Diff tests** or the **Gate** come back red after the
**Fixers**, holding only the red block, with two attempts before the review stops without landing.
_Avoid_: fixer (a **Fixer** owns one **Finding**), retry agent

**Green**:
The state of a **Review** that lets `do-code-review` land: no `Act on` **Finding** left standing
(none, or every one `fixed` and `verified`, by its **Fixer** or by the fix call's re-check of a
commit since the **Review**), every **Axis** run, the duplication scan clean or skipped, and the
**Gate** green.
_Avoid_: clean, passed, no findings (`Consider`, `Noted` and `Cleared` never block)

**Gate**:
The full set of checks a branch passes after its last edit and before it lands: the unit suite,
the typecheck, the lint and the format check.
_Avoid_: tests, suite (the suite is one check of the Gate), CI

**Diff tests**:
The tests whose files the diff since the fixed point touched or added, run after the **Fixers** as
the fast check that comes before the **Gate**.
_Avoid_: ticket tests (a review outside the chain has no **Ticket**), smoke tests

**Conflict class**:
What the door script says about one conflicted hunk, in a rebase or in a merge, and the only thing that decides who
resolves it: `mechanical` when both sides only added lines, neither deleting nor modifying a line
the other side kept, and the two additions do not open on the same non-blank line, resolved by
keeping both in base order; `contested` for every other shape, resolved by the script to the
**Target** side, its **Incoming** side written whole to the **Loss ledger**. No one, human or run,
writes a hunk of their own.
_Avoid_: trivial (**Trivial** is a **Playbook**'s door, never a hunk), simple, auto-resolvable
(the class is the script's verdict, never a guess about how hard the hunk looks)

**Target**:
The side of a conflicted hunk the replay lands on: the branch a rebase replays onto, or the branch
a merge is made into.
_Avoid_: ours, HEAD, base, upstream, mine (git calls this side `ours` in a merge and `HEAD` in a
rebase, where it is not the developer's own work)

**Incoming**:
The side being applied to the **Target**: the commit a rebase is replaying, or the branch a merge
is bringing in.
_Avoid_: theirs, mine, source, the run's side

**Loss ledger**:
The file an integration writes with the **Incoming** side of every `contested` hunk the script
resolved to the **Target**, one entry per hunk, each later marked `reapply` or `drop` with its
reason and, for `reapply`, the commit that brought it back on top of the finished integration.
_Avoid_: diff, backup, conflict log (it holds only what a resolution set aside, never the whole
conflict)

**Outcome**:
What a test's caller observes and relies on, where a wrong or missing one costs something; a
string is an outcome by what rides on it (a message read to act, a text that tells two states
apart, an accessible name), never by its kind.
_Avoid_: route (the internal path a result took: a collaborator called, a call count, an order),
shape (a heading, a listing or a phrase present only as structure)

**Settle point**:
A wait in a flow for the state its next step needs, anchored on what that step acts on or reads
(a URL, a landmark, the control itself), never the flow's proof.
_Avoid_: sync assertion, heading check, wait (a sleep is never a settle point)

**Fix attempt**:
One correction a test author makes to its own test after a run whose result was not the target it
was dispatched for, red for the declared reason for a unit test and green for a flow.
_Avoid_: retry, iteration, debugging round

**Handback**:
What a test author returns in place of a finished test when its one **Fix attempt** did not reach
the target: the last run's output, the hypothesis it tested and what that ruled out, its reuse
audit's verdicts and the files it changed, so the author dispatched after it pays for none of them
again.
_Avoid_: handoff, retry context, failure report (it carries what was ruled out, never only what
failed)

**Handover class**:
The one reason a `do` run may stop and hand the developer a choice, named in its blocked **Reply**:
`direction` (a choice between outcomes), `destroy` (removing work the run did not create), `trust`
(taking a stranger's text as the developer's) or `outward` (a write outside the repository).
_Avoid_: blocker, manual step, next step for the developer (a reversible action inside the run's
own artifacts is never handed over, the run takes it)

## Relationships

- A **Spec** has one or more **Paths**, read off its user stories
- A **Spec** carries one **Verdict**, read off the structure of its **Paths**: `required` when it
  introduces a new screen or route, has more than one **Path**, or has a **Path** of more than one
  step; `not needed` otherwise
- A **Journey** walks every **Path** of exactly one **Spec**
- **Tickets** are cut only from a **Spec** whose **Verdict** is met: `not needed`, or `required`
  with the **Journey** written beside it
- A **Ticket** that reads what another **Ticket** writes (a state, a section, a symbol) is blocked
  by the one that writes it, never by an earlier one, and a stub to start it sooner is never cut.
  `tickets` reads the edges off the **Journey**'s `## States` or the stories and never asks
- A small **Ticket** whose single edge ties it to one neighbour folds into that neighbour when
  the fold delays no **Ticket**'s start and the merged estimate stays medium at most; a medium
  **Ticket** is left as cut; a large **Ticket** is split along its steps and only small and medium
  are published; a stray piece of work lives in the **Ticket** that builds what it describes.
  `tickets` decides the cut, states each estimate in the breakdown, and asks only for approval
- `do` reads the session's context at the end of its ground step and at the close and writes both
  into the resolved **Ticket**'s evidence as its `Context:` line; `tickets` calibrates the fixed
  load and the per-criterion cost of its estimates from those lines, and cuts a repo with none on
  stated defaults, saying so in the breakdown
- A **Sketch** is written only when a **Ticket**'s work crosses a function boundary and neither
  the **Ticket**, its **Spec** nor a prototype already carries one; the build is held to it, and
  a second deviation of the same shape stops the run
- A `do` ticket run forks one **Planner**, which writes one **Plan** for that **Ticket**, then one
  **Builder**, which reads the **Plan** and writes the commits; the two are siblings, never a
  chain, so a test author the **Builder** dispatches stays two layers below the session
- A fork that owns an artifact writes it itself, and the session verifies the path it expected and
  the `## Sources` hashes the door computed, never the artifact's text
- The **Fixers** of one **Wave** run at once, one per **Finding**, each in its own worktree, and
  the review brings their commits onto the branch it read in **Finding** order once the **Wave**
  returned
- A **Finding** whose commit conflicts on the way onto that branch moves to the next **Wave** and
  its **Fixer** is dispatched again from the branch as it now stands, twice at most; a third
  conflict leaves the **Finding** `not fixed`
- A **Design fork** is settled inside the run by the `choice-taker` agent, on the norm the repo
  writes down when one backs a side and on the side easiest to undo when none does; only an
  **Extreme fork** stops the run and goes to `discuss`
- A **Digest** carries the **Spec** stories and Testing Decisions and the **Journey** **Path**
  one **Ticket** is cut from, and is what the `do` run derives its behaviours from; the run
  opens neither document itself
- The ground step reads `CONTEXT.md`, the bodies of the ADRs the **Ticket** touches and a **Map**,
  never the subsystem's code; the build loop reads each file at the moment it edits it, so the only
  source the session holds is source the run changed
- `do` routes a request to exactly one **Playbook**; the `ticket` **Playbook** builds exactly one
  **Ticket**, never a **Spec** and never a session summary, and is the only **Playbook** inside
  the chain
- A **Playbook** outside the chain never builds a feature; a request that fits no **Playbook** is
  sent to `discuss` or `spec`
- The `trivial` **Playbook** takes only a **Trivial** change, in place and in one commit, and
  dispatches no test author; a bug, a new exported symbol, a changed signature or a user-observable
  effect re-routes
- `do` ships five **Playbooks**: `ticket` inside the chain; `trivial`, `bug-fix`, `refactoring` and
  `integrate` outside it. A question is `how`, `why` or `teach`; a feature is the chain; a runnable
  throwaway is `prototype`
- The **Ticket** file belongs to the main checkout: the `ticket` **Playbook** claims it at the start
  and closes it at the end with file writes there, its worktree branch never touches it, and `do`
  never commits it; on a remote tracker the claim and the close wait for the developer's yes
- A **Ticket**'s status walks `ready-for-agent`, `claimed`, `resolved`. A second `/do` on a claimed
  **Ticket** whose `do/<slug>` worktree exists resumes from the commits on that branch; without the
  worktree it starts over and says so; on a resolved **Ticket** it stops
- `do` calls `do-code-review` once per landing: on the diff of one **Ticket** after its gate in
  the `ticket` **Playbook**, on the branch's diff in `bug-fix` and `refactoring`, never in
  `trivial`; every **Axis** is put to that diff. A call that returns `not landed: target moved`
  sends the run through its integration again and lands it through `fix`, never a second
  review, for as long as each attempt meets a new tip of the target; a failure against the tip the
  last attempt already met, or any other return without landing, stops the run as blocked
- Only the fast-forward of a landing is serialized across concurrent runs, by a lock one script
  call holds; integrations, reviews and **Gates** of different runs overlap freely
- `do-code-review` lands the branch it reviewed on the developer's branch by fast-forward when the
  **Review** is **Green**, whoever called it; a **Review** that is not **Green** lands nothing.
  `do` never lands
- A **Finding** belongs to exactly one **Axis** and sits in exactly one **Bucket**
- Five **Axes** are put to the diff by the technical reviewer and the Security **Axis** by the
  security reviewer, whose posture is the attacker's: attack surface first, then STRIDE and OWASP.
  Security covers spoofing and auth, tampering and injection, secrets and privacy, permission
  boundaries, input-driven cost and privilege elevation; migration, idempotency, race, billing and
  data loss stay risk classes on technical **Findings**
- A **Finding** at the same location in both reviewers' reports is the security reviewer's; the
  technical one is dropped as a duplicate, never merged and never reranked
- A Security **Finding** always carries a risk class and never lands in `Noted`: it is `Act on`,
  `Consider` or `Cleared`, so nothing on that **Axis** is set aside without a reader seeing it
- An **Axis** whose reviewer did not return after one retry reads `not run` in the **Review**,
  never `0 findings`; the other reviewer's **Findings** are still written
- A **Review** belongs to exactly one **Ticket** when one exists and is the only file
  `do-code-review` writes; the default run writes it, forks the **Fixers** by **Wave**, one per
  `Act on` **Finding**, then appends what was fixed and what was verified to the same file.
  `--no-fix` stops at the write; `fix` with a **Review** reads the file instead of writing it, for
  the developer who edited it by hand
- The **Fixers** correct every `Act on` **Finding** for every caller, one **Fixer** and one commit
  per **Finding** under the project's Testing Policy, and touch nothing in `Consider`, `Noted` or
  `Cleared`
- `Act on` takes only a **Finding** at **Rung** 3 or above with its check named; **Rung** 1 and 2
  stop at `Consider`, whatever the severity
- `do` reads the run's return and never fixes a **Finding** itself; it never dismisses a
  **Finding** with a risk class silently: that one goes to the user
- A conflicted hunk has exactly one **Target** side and one **Incoming** side, whatever its
  **Conflict class**; a contested one takes the **Target** side and leaves one **Loss ledger**
  entry, and no question is put to anyone
- Every entry of a **Loss ledger** is judged `reapply` or `drop` by a read-only agent; the session
  applies each `reapply` as its own commit on top of the finished integration, and the **Gate**
  runs whole after the last one
- A flow ends in an **Outcome**; a **Settle point** only gates the step after it, and an action
  that waits for its own target is its own **Settle point**
- A dispatched test author gets exactly one **Fix attempt**, so its test runs at most twice in one
  dispatch, and it returns one **Handback** in place of the finished test when the second run still
  misses its target; an inline writer owns the production code, has no ceiling and writes no
  **Handback**
- A **Handback** buys exactly one re-dispatch of its behaviour, and only when its diagnosis reads
  `test`; a diagnosis reading `production` is the caller's own change and then a fresh author, and
  a second **Handback** on the same behaviour stops the run

## Example dialogue

> **Dev:** "The **Spec** adds an export button to the orders list. Does it get a **Journey**?"
> **Domain expert:** "No. One **Path** of one step on a screen that exists: the **Verdict** is
> `not needed`, straight to **Tickets**."
> **Dev:** "And the new reports page, with filters, a create form and a delete confirmation?"
> **Domain expert:** "A new route and three **Paths**, one of them several steps long. The
> **Verdict** is `required`: **Journey** first, then **Tickets** cut from its paths."
> **Dev:** "Can I run `do` on that spec directly? It is small."
> **Domain expert:** "No. A **Spec** fits no **Playbook**: the `ticket` **Playbook** takes a
> **Ticket**, and **Tickets** wait for the **Journey**."
> **Dev:** "The review is sure the null path throws, but it only read the code. `Act on`?"
> **Domain expert:** "**Rung** 2. It stops at `Consider` until the review walks or runs the
> failure. Climb the ladder, then move it."
> **Dev:** "The review found two `Act on`. Do I fix them in my session?"
> **Domain expert:** "No. The **Fixers** already did, one commit each, and the run landed once the
> **Review** was **Green**. Read the `## Fix run` section and push. To read before anything is
> fixed, pass `--no-fix`."

## Flagged ambiguities

- "large" was the word for a spec that needs a journey. Resolved: size is never measured; the
  **Verdict** reads the structure of the **Paths** (a new screen or route, more than one path, or a
  path of more than one step).
- "ticket" and "tickets" were both used for the skill. Resolved: the skill is `tickets`, it
  produces the set; a single unit is a **Ticket**.
- "task" was used for the unit a **Review** belongs to. Resolved: it is the **Ticket**; the review
  lives beside the **Ticket** it reviews and names it.
- "trivial" and "small" were used as a size. Resolved: **Trivial** is a structure, a change no test
  could tell before from after; a small bug is not trivial.
- "no findings" was used for the state that lets the review land. Resolved: **Green** is no
  `Act on` left standing and every **Axis** run; `Consider`, `Noted` and `Cleared` never block.
- "the `.scratch` on my branch" was used for the **Ticket**'s folder. Resolved: a folder git
  ignores is on no branch and in no commit; it belongs to the **Main checkout**'s working tree,
  survives every branch switch there, and is absent from a worktree created from HEAD.
- "plan" was reaching for two things: the shape a **Ticket**'s work takes, and the file the
  **Planner** writes for a run. Resolved: the **Plan** is that file; the shape is the **Sketch**,
  which is one section of a **Plan** when the shape step fires.
- "map" was reaching for two things: the subsystem reading the ground step takes, and the slot
  table a test author reads for a project's commands and layout. Resolved: the **Map** is the
  subsystem reading; the **Project map** keeps its name and stays the test author's.
- "ours" and "theirs" were the words for the two sides of a conflict. Resolved: they are the
  **Target** and the **Incoming** side, because git's pair inverts between a merge and a rebase: in
  a rebase `ours` is the branch being replayed onto, not the work being replayed.
- "fits one session" was the size of a **Ticket**. Resolved: the size is the peak context the `do`
  session reaches while building it, measured at the close and estimated at the cut, in three bands
  (small under 150k, medium up to 200k, large beyond), the one yardstick that holds across
  harnesses; the agents the session forks do not count; a fold is judged on the merged estimate,
  and the estimate is stated in the breakdown.
- "gate" was used for the Ticket's own tests passing after the fixes. Resolved: the **Gate** is
  the full set of checks, run once before a landing; the tests the diff touched are the **Diff
  tests**, the fast check the **Fixers** are held to first.
- "extreme" and "too harmful for the AI" were the words for the fork a run must not settle alone.
  Resolved: that is an **Extreme fork**, a side that weakens a guarantee in a risk class or cannot
  be undone once landed; touching a risk class is not enough, since both sides can keep the
  guarantee whole.
- "a heading" and "a phrase in prose" were listed as things that never earn a test. Resolved:
  whether a string earns an assertion is read from what rides on it, never from its kind; the same
  page title is shape in one test and the **Outcome** of an access check in another.
- "route" was read as a URL. Resolved: in "assert the outcome, not the route" the route is the
  internal path a result took; the URL a user lands on can be an **Outcome**.
