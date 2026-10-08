# do

## What it does

`do` matches a request to one **Playbook** and runs its steps: a **Ticket**'s path or issue
reference builds that Ticket as the last step of the chain, a request in words runs outside it, and
a request that fits no Playbook is sent to the door that owns it in one message. Six Playbooks
exist and one run reads one of them: `ticket`, `setup`, `trivial`, `bug-fix`, `refactoring`, `integrate`. Every reply
opens with the Playbook it matched, so a wrong match costs you one retyped request and nothing
else.

The three Playbooks that build never land their own work and never fix what a review found. Each
builds in a git worktree of its own, one behaviour per green commit, runs the gate, and hands the
branch to [do-code-review](do-code-review.md), which fixes the Findings it marked `Act on` and
fast-forwards your branch when the **Review** is Green, so your branch takes reviewed commits or
none. A `ticket` run of a **Spec** is the one exception: it calls no review, its own gate is its
check, and it lands its branch on the **Spec branch** itself, which is reviewed once after the
Spec's last Ticket lands, so your branch still takes nothing unreviewed. `integrate` rebases or merges your own branches in place, with the same conflict loop, and
stops there: no review, no landing. `trivial` commits in place on your branch, with no worktree and no review, because a change
no test could tell before from after has the existing suite as its whole gate. Nothing is pushed.
The run ends on the `git push` for you to type when something landed on your branch, and on the
next command to type when nothing did.

## When to reach for it

You invoke this by typing `/do <request>`, and the agent won't reach for it on its own.

| Ask | Use |
|---|---|
| build one ticket the chain cut | `/do <the Ticket's path>`, or `/do <issue number or URL>` where the project has a tracker file |
| fix a bug nobody wrote a ticket for | `/do <the bug in words>`: what happened, where, and the error or the wrong output |
| a typo, a doc line, a log wording, a rename inside one file | `/do <the change in words>` |
| reshape code whose behaviour stays where it is | `/do <the reshape in words>`: refactor, rename, extract, inline, dedupe, move a module |
| any of the four above, with the run's own questions answered without you | add `--auto`, before or after the request: `/do --auto <ticket>`, the line `tickets` prints when its own run had the flag. The request routes to the same Playbook with the flag as without it |
| run the Setup ticket `tickets` cut for impeccable | `/do <the Setup ticket's path>`, never with `--auto`: its steps are yours, and the flag is refused in one line |
| build a whole spec | not this skill: [tickets](tickets.md) cuts the spec first, and `do` takes one ticket of the cut |
| decide the plan, or a feature with no ticket | [discuss](discuss.md), or [spec](spec.md) when the conversation already holds the discussion |
| understand code rather than change it | `/how` for the mechanism, `/why` for the rationale, `/teach` to follow it end to end |

One request, one Playbook. `do` takes a single ticket and never a spec, and it never batches two
tickets into one run. Answers arrive in the language you opened the session in; everything written
into the project is in English.

## Prerequisites

Nothing has to be installed for `do` to run, but eleven things in the project change what a run can
do. The Reply's Run section reports one of them, the loop line, with the protected-branch warning
beside it when it applies, so you find how the run was set up in the message it ends with. The
other ten surface at the step that reads them, and each row below names that step.

| In the project | What `do` does with it, and without it |
|---|---|
| the **Ticket** itself, a file under `.scratch/` or an issue on the tracker `docs/agents/issue-tracker.md` describes | the `ticket` Playbook's whole input. The door's lines, the protected-branch warning among them, reach you in the Reply's Run section, and a landing on a protected branch is refused whatever the run wrote. The first run of a Spec cuts its Spec branch, `spec/<feature-slug>`, from the branch you are on and records that branch as its upstream, the branch the Spec integrates into; on a protected branch that first run is refused before anything is claimed or cut, and you switch to a working branch and run `/do <ticket>` again. With no file and no tracker entry there is nothing to match, so the run refuses a bare issue number and asks you for the ticket's path |
| [do-reader](../README.md), the reader `do` ships, linked | the door forks it over the Ticket's Spec and journey to cut the Digest, so neither document enters the session and the Digest is written from what it returns. With the Agent tool withheld, or no `do-reader` agent listed, the session reads both documents itself and says so in one line, `do-reader` by name when it is not linked, with `scripts/link-skills.sh` as the run that links it before your next `/do`, and never forks another agent in its place, since a fork under another name could hold the write tools the reader is denied |
| [do-planner](../README.md), the planner `do` ships, linked | a `ticket` run's Plan step forks it over the Ticket and its Digest, and it writes the Plan itself: the glossary words, the ADR titles, the map of the subsystem, the discover audit line, the behaviours list and the Sketch when the shape step fires. Your session holds the Plan's path and never its text, so the grounding is paid for in the fork's window instead of yours. The Plan sits beside the Ticket as `<ticket>.plan.md`, and the Reply's Plan line names it with every fallback the fork reported. A Plan already there whose `## Sources` section is exactly the two records your door computed, matched on name, path and hash together, is carried, so a second `/do` on the same Ticket forks nobody. One whose section no longer matches, a Ticket, Digest or Spec edited since, is removed and the Planner forked again at the same path, so a moved hash never leaves you a Plan to delete by hand. A resume whose only work left is the landing, on a branch the review already read, skips the Plan step and forks no reader either, so a run that builds nothing reads nothing. The step runs before the run claims your Ticket and before it creates the worktree, so a return naming no Plan, a Plan at some other path, one whose section is not that exact match, or a Ticket or Digest that no longer hashes to what your door recorded once the Planner returns, is refused with the Ticket at the status it had and no `do/<slug>` branch to remove. On a Ticket whose defect's cause is unknown the worktree is cut for the diagnosis before the Planner is forked, and a refusal there removes it and its branch before the refusal reaches you, so a bad grounding costs you a rerun and nothing to undo on every Ticket. With the Agent tool withheld, or no `do-planner` agent listed, the session grounds the Ticket and writes the Plan itself at the same path and says which of the two held, and never forks another agent in its place |
| [do-builder](../README.md), the builder `do` ships, linked | a `ticket` run's build step forks it with the Plan's path and the worktree the run cut, and it runs the whole build loop there: the Plan's behaviours one at a time, each proven by a test author it dispatches itself and closed by one commit carrying its `Behaviour:` line, and the flows your observable criteria earn. What comes back is the lines your Reply owes and one verdict, `built`, `fork` or `stopped`, and never the diff, the test output or a file's contents, so the code it wrote and the red runs it read stay in its window instead of yours. Your session reads the diff it left on the branch, writes its own summary of it and runs the **Gate** before the review, so nothing reaches the reviewers the run itself did not check. A **Design fork** it meets comes back as both sides and is ruled by the `choice-taker` your session forks, since the Ruling is written to the Spec the Builder cannot reach, and an **Extreme fork** still stops the run. With the Agent tool withheld, or no `do-builder` agent listed, the session runs the loop itself in the worktree and says which of the two held, and never forks another agent in its place. When neither the Planner nor the Builder can be forked, the Reply carries one `Planner/Builder: none` line for both instead of two, and the run still finishes. Right before the run's first fork of either, it takes `scripts/harness-hooks.sh`, and the Plan line's `Guard:` line quotes its verdict: `pattern-and-header` when your harness runs the hooks the agents declare, `header-only` on Codex or on a Claude Code whose settings turn hooks off, where the `## Sources` check is the whole guard. Neither verdict stops the run |
| [do-impeccable](../README.md), the agent `do` ships to build a screen with impeccable, linked, with the impeccable skill listed in your session | a `ticket` run on a Front-end ticket of a Spec that reads `Front-end: impeccable` forks it in the Builder's place, and forks no Planner: impeccable builds from the Ticket's acceptance criteria and reads no Plan, so none is written. The brief is the Ticket and the worktree root and nothing else, and the standing rules are in the agent's own definition: it loads the impeccable skill, keeps every write inside the worktree (its own hooks refuse one outside it), runs unattended and code-led, never waiting on a browser or on an answer, and closes each acceptance criterion with one commit whose `Behaviour:` line quotes it. What comes back is what a Builder returns, the lines your Reply owes and one verdict, `built`, `fork` or `stopped`, and your session routes it the same way, a criterion it could not build included. The Reply then has no Plan line, and its behaviours list is the Ticket's acceptance criteria with a commit beside each. When your session lists no impeccable skill, the run stops at the door, before the claim and before any worktree, with `Yours: direction:` and your two choices: install impeccable and reload, or change the Spec's line to `Front-end: builder`. It never falls back to the Builder on its own, since the Spec's line is your choice of who builds the screen. With the Agent tool withheld, or no `do-impeccable` agent listed, the run stops at its build step and says which of the two held, with `scripts/link-skills.sh` as the run that links it before your next `/do` |
| a Testing Policy with its unit test author at `.claude/agents/unit-test-author.md`, or [the global authors](../README.md) `do` ships, linked | the Reply's Run section reads `Loop: policy` and that author writes every new test. With no policy and `global-unit-test-author` linked, it reads `Loop: global`: the run derives a Project map from what the project's own scripts and files say, keeps it in the project's `.scratch/`, and the global authors write the tests and the flows against it. With neither, or with the Agent tool withheld, the line reads `Loop: fallback` and the run writes each failing test itself, red before the fix either way |
| [do-code-review](do-code-review.md) linked in the session | the review fixes its `Act on` Findings and lands the branch. Without it the step reads `skip: do-code-review not listed`, nothing lands, and the reply hands you the worktree, its branch and the review to run yourself |
| [sketch](sketch.md), with its agent linked | it is forked when the work crosses a boundary and nothing in hand carries a shape, so the rival shapes stay out of your context window: by the Planner in a `ticket` run, where the Sketch lands as the Plan's own `## Sketch` section, and by the shape step in a `bug-fix` or `refactoring` run, where your session files it in the **Main checkout** as `.scratch/sketches/do-<slug>.md`, keyed by the run's branch since no Ticket exists to file it beside, and the Reply's Run section names what was handed over and where it is. When `sketch` writes nothing, with the Agent tool withheld, no `sketch` agent listed or a return that is not a usable Sketch, whoever forked it shapes the work itself and says so, the Planner on the fallback line it returns and the session in its Run section |
| [choice-taker](../README.md), the agent `do` ships to rule a Design fork, linked | a `ticket` run that meets a Design fork at its Plan or build step forks it with the two sides, writes the Ruling it returns as one line in the Spec's Implementation Decisions, and carries on over the amended Spec instead of stopping for your confirmation. An Extreme fork, one side weakening a guarantee in a risk class or unable to be undone once landed, still stops the run, whether your session reads it that way or the choice-taker returns `extreme`, and the reply ends on a `/discuss` command you copy. With the Agent tool withheld, or no `choice-taker` agent listed, the run stops at its step and says which of the two held, `choice-taker` by name when it is not linked, with `scripts/link-skills.sh` as the run that links it before your next `/do`. It never forks another agent in its place, since a fork under another name could hold the write tools the choice-taker is denied, and the reply ends on the same `/discuss` command an Extreme fork gives, with that reason in it |
| [ledger-judge](../README.md), the agent `do` ships to judge a **Loss ledger** entry, linked | the integration forks it once the rebase finishes and the ledger holds an entry no run has judged, once for the whole integration and never once per hunk, with the ledger's location, the worktree root and the run's intent. It reads and searches only, and the session writes each `reapply` or `drop` it returns, with its one-line reason, into the ledger, so what a contested hunk set aside is on record as kept or as let go. A rebase that set nothing aside forks nothing and costs what it costs today, and a resumed run judges only the entries still carrying no verdict, so running twice leaves the same ledger. With the Agent tool withheld, or no `ledger-judge` agent listed, the session judges the entries itself and says which of the two held, `ledger-judge` by name when it is not linked, with `scripts/link-skills.sh` as the run that links it before your next `/do`. It never forks another agent in its place, since a fork under another name could hold the write tools the judge is denied |
| the vendored `how`, `why` and `unslop` | a run keeps the grounding out of its own context window, reads the rationale behind the shape a defect sits in, and cleans up the reply. Each is optional and each step says in one line what it does instead, so a `bug-fix` run with neither `how` nor `why` reads the code with search and targeted reads and says so, and a `ticket` run whose Planner does not list `how` has it build the map from search output alone, read no file whole and report the map as thinner on the fallback line the Plan line carries |

The run writes into two places outside your branch: the worktree at `.claude/worktrees/do-<slug>`,
excluded through this clone's `.git/info/exclude` and never through the project's `.gitignore`, and
the Ticket file in the **Main checkout**, which the run edits and never commits. Installing every
skill named here is the same procedure, and [the top-level README](../README.md) carries it once.

## The Playbook

A **Playbook** is one execution model, one file in the skill's `references/` folder, read only when
the router matches it. The skill file itself holds the router, the rules that apply to every run,
and the links, so a run loads one Playbook and never the other five
([ADR 0008](adr/0008-do-is-a-router-and-only-its-ticket-playbook-is-inside-the-chain.md)). `ticket`
builds the chain's Tickets and `setup` runs its Setup ticket, the one Ticket whose steps are yours
([ADR 0076](adr/0076-the-front-end-builders-setup-is-a-ticket-run-by-a-playbook-of-its-own.md));
the other four exist for work that never entered the chain.

| Playbook | Matched by | What the run does |
|---|---|---|
| `ticket` | a Ticket's path, or an issue reference the tracker file resolves | claims the Ticket in your checkout, builds it in a worktree behaviour by behaviour, gates, rebases onto the Spec branch and lands there with no review (a Ticket with no Spec is reviewed and lands on your branch, then its affected flows run), and closes the Ticket with the evidence quoted under it |
| `setup` | a Setup ticket's path, the Ticket numbered `00` whose `**Kind:**` reads `setup`, which `tickets` cuts when a Spec reads `Front-end: impeccable` and impeccable's setup is missing | claims the Ticket in your checkout and runs the setup check, then shows the six steps marked done or missing and the first missing one: what it is, its exact command, where to run it (a terminal, this session or a new agent session), and "Say when it is done." The turn ends there. Whatever you write next, it runs the check again and shows the next missing step, or the same one with what the check found missing, down to the commit of the setup files on your branch. With every step done on the committed tree it resolves the Ticket and ends on `/do` for the next one. No worktree, no Planner, no Builder, no review, and `--auto` is refused in one line naming the plain `/do` |
| `bug-fix` | a defect in words: what happened, where, and the error or the wrong output | reproduces it on the surface it happens on, rules hypotheses out with runtime evidence, commits the failing reproduction before the smallest fix, and verifies on that same surface |
| `refactoring` | a reshape in words whose behaviour stays where it is | pins the behaviour before any structure moves, then commits subtraction, reshape and cleanup in that order, so one revert undoes one slice |
| `integrate` | a rebase of one branch onto another, or a merge of one branch into another, in words | checks the branches exist, that a merge target is not protected, that you stand on the branch written to and that your tree is clean, then runs the operation, resolves the mechanical hunks and takes the target side of the contested ones, leaving what they set aside in a Loss ledger keyed by the branch. No worktree, no Gate, no review, nothing landed or pushed: the reply names the unchecked tree as debt for you to test before the push |
| `trivial` | a change no test could tell before from after | edits in place on your branch, runs the suite that covers the touched files, and lands one commit. No worktree, no review, one message |

## The door a request goes to

A request that matches no Playbook ends the run in one message: the door that owns it and the
command to type, with nothing written and no Playbook file read.

| The request | Where it goes |
|---|---|
| a spec | `/tickets <spec>`, or `/journey <spec>` first when the spec's verdict reads `required` and no journey sits beside it |
| a pasted session summary | `/spec`, since the discussion already happened |
| a feature, or anything else with no ticket | `/discuss`, or `/spec` when the conversation already holds the discussion |
| how something works, or why it was built that way | `/how`, `/why`, `/teach` |
| a runnable throwaway: a layout, a variant to try | `/prototype` |
| an issue number where the project has no tracker file | back to you, for the ticket's path. The number is never guessed against a list in the conversation |

A Playbook has its own door on top of that one, and `trivial` is where it bites. **Trivial** is
judged by structure and never by size, twice: on the request before any edit, and on the diff before
the commit, the second time by a script a reviewer can rerun
([ADR 0010](adr/0010-the-trivial-playbook-takes-only-a-behaviour-preserving-change-judged-by-structure.md)).
A one-character "typo" inside a string the code reads at runtime is a defect, so it leaves for
`bug-fix` and gets a failing test first. A rename that adds or changes an export is a reshape, so it
leaves for `refactoring`. A fifty-line comment sweep stays Trivial. When the check on the diff fires
after the edit, the run restores the touched files and commits nothing.

The `ticket` Playbook's door is one script, `skills/do/scripts/ticket-door.sh <ticket>`, so you
rerun it and get the same answer the run acted on. Before anything is claimed it reads:

- the Ticket's status, and the status of every Ticket its `Blocked by` line names, the Setup ticket
  `00` included. One not `resolved` refuses the run, naming that Ticket and its status, and nothing
  is written.
- the Ticket's kind, from its `Kind:` line: `logic`, `front-end` or `setup`, and `logic` when the
  line is missing, as on every Ticket cut before the line existed.
- the Spec's front-end builder, from the `Front-end:` line of the `spec.md` beside the Ticket's
  `issues/` folder: `none`, `builder` or `impeccable`, and `none` when there is no such line or no
  such Spec.
- the run's worktree, the Testing Policy, your branch and the Spec branch.

A Logic ticket, and a Front-end ticket of a Spec that reads `Front-end: builder`, go through the
Planner and the Builder like any other Ticket. A Front-end ticket of a Spec that reads
`Front-end: impeccable` forks no Planner and is built by `do-impeccable` in the Builder's place,
per [ADR 0078](adr/0078-an-impeccable-front-end-ticket-forks-no-planner-and-do-impeccable-stands-in-for-the-builder.md),
and the door stops it, with nothing claimed, when your session lists no impeccable skill. Two `Kind:` or two `Front-end:` lines, or a word
outside the set, stop the run instead of falling back to a default, since either line decides who
builds the Ticket and a line appended on a tracker is not your choice.

A screen `do-impeccable` built is proven after it exists and never red-first, per
[ADR 0079](adr/0079-an-impeccable-front-end-ticket-is-proven-after-the-build-never-red-first.md): a
test written first would have to guess the selectors and labels impeccable has yet to decide. Three
things prove it, and the reply's Evidence shows each:

- The flows its observable criteria earn, written once the screen is committed by the same
  end-to-end author a Builder's flows go through. A project with no end-to-end command gets one
  line instead, saying that no flow covered the screen and that the scan and the Gate are its
  proof.
- impeccable's detector scan, run by script inside the fork, which fixes what the scan reports
  before it returns. Evidence carries the scan's command line and the count of findings that
  remain. A finding left over does not hold the screen back: the Ticket lands, and each one is
  listed under Pending debt.
- The Gate, then the integration, the landing and the close, exactly as after a Builder, so the
  Ticket ends `resolved` and the last line is the next `/do`.

Before the Gate the run also checks, by script, that your checkout is as it was when the fork
began: a snapshot before the fork, a comparison after it. Nothing guarantees impeccable honours a
worktree, so a builder that wrote in your checkout is caught there. The run then stops with the
files that changed since the fork began, never the work you already had uncommitted, and one
`Yours: direction:` line: move those files into the worktree by hand and run `/do` on the Ticket
again, or discard them and run `/do` again. It removes nothing, and the worktree and its commits
stay for that second run.

## One behaviour, one green commit

The three Playbooks that build share one loop, so the discipline is the same whether the work came
through the chain or not. The run creates a worktree, from the tip of the Spec branch in a `ticket`
run and from your current HEAD otherwise, and takes one behaviour at a
time from a list cut from the Ticket and its spec rather than from the implementation, the Plan's
own `## Behaviours` in a `ticket` run: a failing test first with its expected red stated, the smallest change that turns it green, a
refactor on green, then one commit holding the test and the code. Each commit body carries its
`Behaviour:` line, which is how a second `/do` on the same Ticket reads the run off the branch and
picks up at the first behaviour with no commit beside it instead of starting over.

The gate runs after the last edit and never before it, because "it passed earlier" is stale. It runs
from one script that prints the line to rerun it first, one line per green check and the capped
failing block of a red one with the file holding its full output, so you rerun the gate yourself and
get the same answer, and a red gate goes back to the build loop on the block the gate already printed.
Then, if your branch moved while the run was building, the run rebases onto it and runs the gate
again, so
the diff the reviewers read is the diff that lands rather than one that was true a few commits ago.
What a conflict costs you depends on its class, which a script decides and the session never
guesses:

- A hunk where both sides only added lines, each opening on a line of its own: nothing. The run
  keeps both sides in order and says which hunks it resolved. Two additions that open on the same
  line wrote one text and split, so keeping both would say it twice, and that hunk is contested.
- Any other hunk, a _contested_ one: nothing is asked. A script keeps your branch's side, the
  Target side, and writes the side it set aside, the Incoming side, whole, to the run's Loss ledger,
  one entry per hunk with the file, the location, the shape and the replayed commit. A file one
  side deleted or renamed while the other edited it, a binary file and a file too large to merge
  take your branch's version whole, and a binary side is named in the ledger by its blob and the
  commit your branch was on before the rebase. The ledger sits beside the Ticket, or under
  `.scratch/ledgers/` keyed by the branch in a `bug-fix` or `refactoring` run, and running the step
  again rewrites its entries rather than adding new ones.
- A file you already resolved and never staged, which a second `/do` finds at the stop it resumes:
  when it holds exactly the union of its two sides it is classed hunk by hunk like any other, so a
  contested hunk in it still takes your branch's side; when it holds anything else it is yours,
  kept as you wrote it, staged, never put in the ledger, and named in the reply as taken on trust.
- A run nobody watches, `claude -p` for one, resolves the conflict the same way, since nothing is
  asked.

Once the rebase finishes, each entry of the Loss ledger is judged `reapply` or `drop`, with a
one-line reason written beside it. Each `reapply` comes back as its own commit on top of the
finished integration, titled `reapply: <file>` with the entry's id in its body, so every piece of
work brought back is a diff you can read and revert alone, and the entry records that commit. An
entry whose text the file no longer holds makes no commit and is listed with the dropped ones. The
whole gate then runs once, after the last reapplied commit, and the review is called only when it
is green. A red gate there stops the run as blocked: the reply names the failing check, the
ledger's location and the `git reset --hard` that puts the run's branch back on the commit it held
before the rebase. The run never goes back to the build loop and never edits the branch's code to
make that gate pass.

A second `/do` that finds a rebase the first run left open asks at two more stops. One is a rebase
stopped with nothing conflicted: whatever is staged there carries nobody's recorded answer, so the
run names the commit and every staged file and asks before it continues. The other is a rebase
open onto a commit that is no longer the tip of your branch: the run names both commits and asks
whether to abort and rebase onto the tip, or finish the open rebase first. Nobody there to answer
either question stops the run as blocked. Unlike a fresh run, it leaves that rebase open rather
than aborting it, since the stop may hold a resolution you staged, and the worktree and its branch
stay in place.

In a `ticket` run of a Spec the branch then lands on the Spec branch, with no review. The run
rebases it onto `spec/<slug>`, a contested hunk taking the Spec branch's side and what it sets
aside going into the Loss ledger, and one script call moves the Spec branch's ref forward under the
landing lock, so two Tickets landing at once never both pass. The one that lost reads `moved`,
integrates again onto the new tip, gates and lands, for as long as the tip keeps changing. A Spec
branch checked out in any worktree is refused: the reply reads
`not landed: spec/<slug> is checked out in <worktree>`, the Ticket stays `claimed` with its
worktree in place, and switching that checkout off the branch and running `/do <ticket>` again
resumes at the landing. A landed run's reply carries `landed at <sha> on spec/<slug>` and
`Review: none, the Spec is reviewed once its last Ticket lands`
([ADR 0060](adr/0060-a-ticket-lands-on-its-spec-branch-and-do-lands-it-there-itself.md)).

The run then marks its Ticket `resolved`, and only after that runs the Completion check, a script
that reads the status of every Ticket of the Spec, so the last of two runs landing at once always
sees every Ticket resolved. Then it removes its worktree. When Tickets are still open, the reply
adds an `Open:` line naming each one with its status, and its Next step is `/do` on the first open
Ticket that reads `ready-for-agent`. When every open Ticket is `claimed` by another run, the Next
step says the Spec integrates when those runs land, and there is nothing to type. The same script
tells the gate whether this is the feature's last Ticket, which is when the full suites run.

The run that finds every Ticket `resolved` ships the Spec, in the same run: the Final integration.
It first claims it, by creating `spec.integration.claim` beside the Spec, so two runs that both see
the Spec complete never both integrate it. A run that finds the claim taken ends there: its own
Ticket landed, its reply says the Spec is being integrated by another run, and there is nothing to
type. The run that holds the claim checks `spec/<slug>` out in a worktree of its own,
`.claude/worktrees/spec-<slug>`, and rebases it onto the branch it was cut from, your branch, with
the same conflict rules as any integration: a contested hunk takes your branch's side and what it
sets aside goes into the Loss ledger, here `spec.ledger.md` beside the Spec. The full suites and
the affected flows run on that tree, since this is the only moment your branch changes. Then
`do-code-review` reviews the whole Spec branch against your branch, with the Spec as its spec
source, fixes its `Act on` Findings and lands the Spec branch on your branch by fast-forward when
the Review is Green. Once it landed, the run removes that worktree and `spec/<slug>`, and releases
the claim. The reply reads `Open: none`, the Integration line onto your branch, the review's
return with `landed at <sha>`, and `spec/<slug> removed`, and its Next step is
`git push <your branch>`
([ADR 0061](adr/0061-the-review-runs-once-per-spec-on-its-spec-branch-before-it-lands.md)).

A Final integration that stops (a rebase question nobody answered, a Review that did not land,
`not landed: target moved`) leaves the Spec branch, its worktree and the claim in place, and marks
the claim yielded. The reply says it stopped and why, and `/do <the run's Ticket>`, or a `do` on
any Ticket of the Spec, resumes it.

That second `/do` rebuilds nothing. Its Ticket reads `resolved`, and the door tells three cases
apart:

| The door finds | What the run does |
|---|---|
| the Spec branch there and not landed, every Ticket of the Spec `resolved` | resumes the Final integration, and only that |
| the Spec branch landed, or never there | stops in one line, as on any `resolved` Ticket, and writes nothing |
| a Ticket of the Spec still open | stops in one line the same way: there is no Final integration to resume yet |

The resume takes over the yielded claim, then reads where the integration stopped: a rebase left
open asks you the same `(continue / stop)` or `(abort / continue)` question a Ticket run's open
rebase asks, a Review already written beside the Spec is landed and never written a second time,
and a `not landed: target moved` integrates again for as long as your branch keeps moving. It ends
as the run that ships a Spec ends, with `spec/<slug> removed` and `git push <your branch>`. If it
stops again, the reply says so and why, and the Next step is the same `/do`.

A claim nobody yielded is never taken over: the run that holds it may still be integrating, and two
runs in one tree would both land on your branch. The resume stops in one line and names the holder,
when it claimed, and the command that yields its claim. Run that command only when you know the
holder is dead, then the same `/do` (ADR 0063).

In every other run that builds, the branch goes to the review, once per run: the run hands it the gate's command line too, so
the review's fixes are held to the same checks, and only the outcome comes back, never the Review's
text. When your branch moved while the review ran and its landing met a hunk it does not take, the
review comes back `not landed: target moved` and the same run integrates once more onto your moved
branch: the contested hunks take your branch's side, the ledger is judged and reapplied, the gate
runs whole, and the branch lands through a `fix` call on the same Review. It goes round again each
time your branch moves before the landing, with no fixed count, so several runs landing at once all
land: each lost race means another run landed first
([ADR 0044](adr/0044-the-re-integration-retries-while-the-target-tip-changes.md)). The loop ends
when the integration finds nothing to replay, since then no other landing happened, and the run
does not stop there to ask you for the request again: it takes its own resume path in the same run,
the integration once more and the landing through a `fix` call on the same Review, exactly what a
second `/do` would have done. That resume happens once: if its integration again finds nothing to
replay and the landing again reports your branch moved, the run stops as blocked like any other
landing that did not happen. The affected flows run from your checkout through a script of their own whose command line
comes first, and a red one is fixed in the worktree, gated and landed through a `fix` call on the
same Review, never a second review. The Ticket is closed with the command lines and their
output quoted under `## Evidence`. A run that stops once it has built
leaves the worktree and its branch in place and names both, so nothing is half landed and nothing
is lost. The one run that removes them on a stop is a Ticket whose defect's cause is unknown,
refused during its diagnosis before anything was built: the worktree was cut for the diagnosis
alone, so the run removes it and its branch, and you rerun `/do` with nothing to reset first.

## Common questions

**Why can I not run `/do` on a spec?**
Because the chain is strict. Each skill takes only the artifact of the step before it
([ADR 0003](adr/0003-the-chain-is-strict.md)), and a spec is a whole feature while `do` builds one
demoable slice of it. Cutting the slices is [tickets](tickets.md)'s job, where each one is sized by
the context the `do` session will reach and blocked by the ticket that writes what it reads. Hand
`do` a spec and that cut happens inside the build, where nothing checks it. The router refuses in
one message and names `/tickets <spec>`, or `/journey <spec>` first when the spec's verdict reads
`required` and no journey sits beside the spec. A pasted session summary goes to `/spec` the same
way.

**Why is `trivial` not a size?**
Because size does not predict what a change does. The test is whether a test could tell before from
after. A one-line rename of an export moves a contract other code depends on; a fifty-line comment
sweep moves nothing. The door reads the request that way before any edit, and a script reads the
diff that way before the commit, and a change that fails either one leaves for the Playbook that can
prove it. If your "trivial" requests keep bouncing to `bug-fix`, they were behaviour changes
described as cleanups, which is the check doing its job rather than being strict.

**Why does the session write the code instead of handing it to a subagent?**
Because whoever writes the diff owns it, and a summary is not the diff. A subagent hands back prose
about what it did, and a session that accepted that prose cannot answer for what is on the branch.
So the session writes and commits, and a delegate is forked only where that ownership is not at
stake
([ADR 0009](adr/0009-the-session-writes-a-delegate-is-the-exception-and-no-playbook-depends-on-nesting-depth.md)):
bulk mechanical work with a closed scope, after a script was considered, or exploration whose output
would flood the context window. Even then the session reads the delegate's diff and writes its own
summary. Tests run the other way round on purpose. Every new test goes to a test author, because a
test written by whoever wrote the code tends to assert what the code does rather than what it
should do. An author that cannot land its test does not grind at it either: it runs the test at
most twice, the first run and one fix attempt, then hands back its diagnosis, the hypothesis it
ruled out and the failing run. The run reads the diagnosis, not the verdict: a production fault is
its own change to make, since no test author may touch production code, and a test fault buys one
more dispatch carrying that handback, never a third. The ceiling is counted where the report is
read: the run reads the report's `Run` section before its verdict, and one naming a third run is
refused whole and the behaviour dispatched again, because a forked author's report reaches no hook
([ADR 0051](adr/0051-a-test-author-gets-one-fix-attempt-and-hands-back-what-it-ruled-out.md)).

**Why does the reviewer fix and land, and not `do`?**
Because a run that could fix its own Findings would be grading its own diff. `do` hands over four
things, the spec source, the fixed point, the landing target and the gate's command line, and then
stops. The review writes the Review, forks one Fixer per `Act on` Finding in Waves, the Fixers of
one Wave at once, each in its own worktree and each turning its Finding into its own commit
([ADR 0053](adr/0053-the-fixers-run-in-waves-each-in-its-own-worktree-on-a-floor-a-script-computes.md)),
re-runs each Finding's check, the tests the diff touched
and the whole gate, with a Gate fixer on a red one, and fast-forwards your branch only when the
Review is Green
([ADR 0013](adr/0013-do-code-review-lands-a-green-review-by-fast-forward.md),
[ADR 0015](adr/0015-the-default-review-run-fixes-and-lands-and-the-fixer-corrects-for-every-caller.md)).
That is also why `do` never patches a Finding by hand: a Finding the Fixer left standing is the
reason nothing landed, and the run stops on it with the worktree intact. The stop names the
Finding by its number and hands you two ways out on its `Yours: direction:` line: fix it in the
worktree and run `/do` again, whose `fix` call finds your commit and records the Finding fixed, or
overrule it by editing the Review and running `/do` again, whose `fix` call lands the branch once
the Review is Green. The run itself never opens the Review.

**Why is the fix of a red flow not reviewed again?**
Because the review runs once per run
([ADR 0033](adr/0033-the-review-runs-once-per-run-and-what-comes-after-it-lands-through-the-gate-alone.md)).
Whatever the run commits after it, the fix of a red flow or the rebase it runs again when your branch
moved during the review, is held to the gate and lands through a `fix` call on the same Review, which forks no
reviewer. A second full review cost the session more than any other step, and what it would have
read that the first did not is code the gate already checks.

**What do I do with a Digest a stopped run left behind?**
Delete it before your next `/do` on that Ticket. A run that stopped inside the reader's window,
before [ADR 0032](adr/0032-a-fork-that-reads-a-strangers-text-holds-no-write-tool.md) removed that
check, could leave a `*.digest.md` on disk, and the gate judges a Digest by its record alone: one
you don't trust is served again while its hashes still match, whether it sits beside the Ticket
that stopped or beside a sibling Ticket the stop's own line named. Delete every `*.digest.md` such
a stop named, and the next run on that Ticket forks the reader fresh.

**How do I overrule a Ruling I disagree with?**
Edit its line in the Spec's Implementation Decisions and type `/do` on the Ticket again, while it
still reads `claimed`. A Ruling is the Spec's, not the run's
([ADR 0037](adr/0037-a-choice-takers-ruling-amends-the-spec-and-a-ticket-criterion-only-when-it-is-the-losing-side.md)),
so nothing new is needed: the resume already picks up an amended Spec, the same way it does after
`discuss` answers an Extreme fork. It rebuilds only what the edit changed, and every later Ticket of
the feature reads your line. Once the review has read the branch, the resume only lands it and
reads no Spec, and once the Ticket is `resolved`, `/do` stops on it: either way the reversal is a
new Ticket you write
([ADR 0038](adr/0038-a-ruling-reversed-after-its-ticket-landed-is-built-by-a-new-ticket-the-developer-writes.md)).

**What happens when I come back after a setup step?**

Anything you write sends the run back to the setup check: it proves the step by script and never
takes your word for it. With the step done, you see the next missing one in the same shape, and a
step the project already carries is skipped with its `done` mark. When the step did not take, you
read the check's own line for it, `build-path=missing` for example, and the same command again. A
question is answered first, then the check runs anyway and the step you were on is shown again in
full.

The reload is the one step no script reads. There the message tells you to reload the coding tool
and type `/do` on the Setup ticket again, and the new session proves the step by listing the
impeccable skill: listed, it shows the next missing step, and not listed, it shows the reload again
and says the skill is still not listed.

You can leave at any step. The Setup ticket stays `claimed`, and a later `/do` on it, in the same
session or a new one, runs the check and shows the step the project stands on. The last step is
the commit of the setup files, one command that names those files only, on the branch you have
checked out: you run it, `do` never commits there. Only when the check passes on the committed
tree does the Ticket read `resolved`, with the six steps done, the check's lines as the evidence,
and `/do` on the next Ticket as the last line
([ADR 0077](adr/0077-the-setup-is-committed-on-the-developers-branch-before-the-spec-branch-is-cut.md)).

**What does `/do --auto` still ask me?**
Whatever cannot be undone or leaves your machine
([ADR 0045](adr/0045-auto-hands-direction-to-the-choice-taker-and-four-classes-still-stop.md)).
The flag hands the run's direction to the `choice-taker`: a question about how the run goes, which
changes nothing the Ticket builds, is ruled and the run follows the Ruling in the same turn, with
no message asking you to confirm it. A Design fork is ruled as it is without the flag. These are
the questions handed over:

| The question | Where it comes up |
|---|---|
| continue or stop, when a resumed integration finds its rebase open with no conflicted file | a `ticket` run you resumed |
| whether a full suite or a remote run runs | the verification, in every Playbook that reaches it |
| whether a harness that cannot stay inside its bound runs | `refactoring` |
| which of two homes a reshape goes to, when it fits both equally | `refactoring` |
| which of two files, when the request fits both equally | `trivial` |

A Setup ticket takes no flag at all: its steps are yours to run, so `/do --auto` on it is refused
in one line naming the plain `/do` command, and nothing is claimed.

Four classes stay yours, each asked in the same place and the same words as without the flag:

| Class | Where a `do` run meets it |
|---|---|
| an Extreme fork | the run stops on its `/discuss` command and records the fork beside the Ticket, so typing `/do` again stops on the same command and never rules it |
| discarding uncommitted work | a resume that finds uncommitted work in the worktree, each change named one line per file |
| an abort that drops commits | abort or continue when the target moved under an open rebase, and the revert that deletes a `refactoring` branch whose exit test failed |
| a write to a remote tracker | a claim or a close on a Ticket that is an issue, every write your yes makes listed |

Each of the last three shows, above the question, what the `choice-taker` answered: the side it
took with its norm, or its `extreme` return with the reason, so you confirm or overrule an answer
instead of deciding from scratch. Nothing is discarded, aborted, reverted or written to the tracker
until you answer. Three more things reach you unchanged, since the flag has no question there to
hand over:

- a request to drive a surface the session cannot reach, in a `bug-fix` run: it asks for an
  observation only you can make;
- `/do --auto` on a Ticket that reads `resolved`: the same one-line stop, with nothing written;
- a question no `choice-taker` could answer (the Agent tool withheld, the agent not linked, or a
  return that is no usable Ruling): it comes to you with one line saying why and no answer shown,
  and a Design fork then stops the run as it does without the flag.

Afterwards the reply's `Rulings` section lists what was ruled, on a run that finished and on one
that stopped alike: a question about the run under `On the run:`, which changed no file, and a
Design fork under `On the Spec:`.

## It's working if

- The first line of every reply names the Playbook it matched, and it is the one you expected.
- `git status` in your checkout is what you left it, plus the files the run leaves for you.
  Your work in progress is unchanged, was never staged, and the worktree folder does not show up.
  The Ticket and the Review are in that list only where git does not ignore the path they sit on:
  nothing new under a `.scratch/` the project's `.gitignore` carries, both of them in a project
  that never got that line or that keeps its tickets on a tracked path, where they are yours to
  commit or drop. Either way, the reply's `Left uncommitted` section is where they are named.
- The branch history reads one commit per behaviour, each body carrying a `Behaviour:` line, with
  the review's fix commits on top and nothing pushed.
- The review ran once. A run that fixed a red flow, or that you resumed after the review, shows one
  review call and a `fix` call after it, never two reviews.
- Every number and output line in the reply has a command line beside it, and that command ran
  after the run's last edit.
- A run that stopped names its worktree and its branch, and the Ticket still reads `claimed`, so
  typing `/do` on it again picks up where it stopped rather than starting over. A `bug-fix` or
  `refactoring` run has no Ticket, so typing the same request again, in the same words, picks it up
  on its own branch the same way. A review that could
  not land because your branch moved while it ran needs no second `/do`: the same run rebases
  again, the contested hunks taking your branch's side and landing in the ledger, and lands through
  a `fix` call on the Review it already has, as many times as the branch keeps moving. An
  integration that finds nothing to replay does not stop the run: it takes its own resume path in
  the same run, the integration once more and the landing through a `fix` call on the same Review,
  and only stops as blocked if that resume also finds nothing to replay and the landing again
  reports your branch moved. The reply lists every entry that later
  integration dropped, marked as coming after the review, since no reviewer reads it.
- A run whose branch moved says so: the step names what it rebased onto and how many commits
  replayed, and the gate's output after it is quoted like any other.
- A contested conflict reaches you in the reply rather than as a question: the file and the
  location of each hunk that kept your branch's side, and the Loss ledger that holds what was set
  aside. Each entry of that ledger comes back judged, `reapply` or `drop` with a one-line reason
  written beside it, so you read what was let go rather than finding it gone.
- Each `reapply` is a commit of its own on the branch, `reapply: <file>`, naming the ledger entry in
  its body. The reply gives the counts of mechanical and contested hunks, then one line per reapplied
  commit and one per dropped entry with its reason, and the gate's output after the last reapplied
  commit is quoted like any other.
- A `ticket` run that met a Design fork says so in one line naming both sides, then goes on: the
  Spec's Implementation Decisions gain one line marked as the choice-taker's, and a Ticket criterion
  changes only when it was the side that lost. The reply's `Rulings` section, right after
  `Principles`, has two groups. `On the Spec:` lists in one line each Ruling the Spec carries for
  the Ticket, whichever session wrote it: the fork, the side taken, and the norm or "no norm".
  `On the run:` lists each Ruling that only steered a run under `--auto` and changed no file: both
  options, the one taken and the norm. A group reads `none` when it has no Ruling. Only an Extreme
  fork, or a fork no choice-taker could rule, stops the run.
- A Ruling line you edited while the Ticket is `claimed` is picked up by the next `/do` on it: the
  run names the Spec as changed, reads it again, keeps every commit that still matches, and builds
  the side your line takes. A criterion the old Ruling had rewritten is ruled back to your side, and
  `Rulings` lists your line and that new Ruling.
- When the Spec and the Ticket are issues on your tracker, a Design fork still goes on without a
  question, and nothing is written to the tracker mid-run. The run keeps the Ruling itself and
  hands it to the review, so the build is held to a rewritten criterion the Ticket issue does not
  show yet. The close's one question lists every write your yes makes: the rewritten criterion in
  the Ticket issue's body, the Ruling as a comment on the Spec issue under
  `## Implementation Decisions`, where the next Ticket's run finds it, and the evidence on the
  Ticket issue before it is closed. On a no nothing reaches the tracker, and the `Rulings` section
  carries the Ruling whole, with the old and the new criterion, for you to carry over by hand.
- A fork no choice-taker could rule stops the run like an Extreme fork, on the same kind of
  `/discuss` command. The reason is in the reply: the Agent tool withheld, `choice-taker` not
  listed, or the choice-taker's return quoted whole when it came back with no usable Ruling. The
  Spec and the Ticket's criteria are untouched, and typing `/do` again once the choice-taker can be
  forked meets the fork again and rules on it.
- A run that stopped on an Extreme fork names the step, both sides and the guarantee the weaker side
  would lose with its risk class, or what could not be undone once landed. The Ticket stays
  `claimed`, the worktree and its branch are named with the commits made so far, and nothing is
  written to the Spec or the Ticket's criteria. The last line is a complete `/discuss` command you
  copy. Typing `/do` on the Ticket again before `discuss` amended the Spec gives the same stop and
  the same command.
- To reverse a Ruling, edit its side in the Spec line, or in its comment on the Spec issue. A
  Ticket not yet built reads the edited line when it runs. A Ticket already `resolved` is never
  reopened: `/do` on it stops in one line, writes nothing, and names the way forward. You write a
  new Ticket by hand, numbered after the feature's last one and marked `ready-for-agent`. Its
  criteria come from the edited line, and its `Blocked by` names every resolved Ticket that took
  the old side. On a tracker you open it as an issue with its Parent, its Blocked by and the label.
  `/tickets` stops on a feature that already has Tickets only while one is still open: every local
  Ticket file counts, but on a tracker only an open Ticket issue does, and a reversal's Tickets are
  all `resolved`, so that stop will not fire here. You write this one Ticket yourself regardless.
  `/do` on it builds it like any other, and the Ticket that ruled keeps its status, its
  ticks and its evidence
  ([ADR 0038](adr/0038-a-ruling-reversed-after-its-ticket-landed-is-built-by-a-new-ticket-the-developer-writes.md)).
- A `trivial` request costs you one message, start to finish.

## Where it fits

`do` is the last step of a strict chain, and a standalone you reach for any time outside it.
[discuss](discuss.md) settles the plan, [spec](spec.md) writes it down, [journey](journey.md) walks
it when the spec's verdict asks for one, [tickets](tickets.md) cuts it into tickets, and `do` builds
one of them. Only `ticket` is in that line. `trivial`, `bug-fix` and `refactoring` sit outside it,
for work no spec was ever written for.

- [tickets](tickets.md), because it cuts the tickets this skill takes one at a time, and its closing
  line hands you the exact `/do <ticket>` to type next.
- [do-code-review](do-code-review.md), because every Playbook that builds stops at its review step,
  and that skill is what fixes the `Act on` Findings and lands the branch on yours.
- [discuss](discuss.md), because a request with no ticket behind it is refused at the door and sent
  there.

The grouped list of every skill is in [the top-level README](../README.md).
