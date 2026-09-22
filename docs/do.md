# do

## What it does

`do` matches a request to one **Playbook** and runs its steps: a **Ticket**'s path or issue
reference builds that Ticket as the last step of the chain, a request in words runs outside it, and
a request that fits no Playbook is sent to the door that owns it in one message. Five Playbooks
exist and one run reads one of them: `ticket`, `trivial`, `bug-fix`, `refactoring`, `integrate`. Every reply
opens with the Playbook it matched, so a wrong match costs you one retyped request and nothing
else.

The three Playbooks that build never land their own work and never fix what a review found. Each
builds in a git worktree of its own, one behaviour per green commit, runs the gate, and hands the
branch to [do-code-review](do-code-review.md), which fixes the Findings it marked `Act on` and
fast-forwards your branch when the **Review** is Green, so your branch takes reviewed commits or
none. `integrate` rebases or merges your own branches in place, with the same conflict loop, and
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
| build a whole spec | not this skill: [tickets](tickets.md) cuts the spec first, and `do` takes one ticket of the cut |
| decide the plan, or a feature with no ticket | [discuss](discuss.md), or [spec](spec.md) when the conversation already holds the discussion |
| understand code rather than change it | `/how` for the mechanism, `/why` for the rationale, `/teach` to follow it end to end |

One request, one Playbook. `do` takes a single ticket and never a spec, and it never batches two
tickets into one run. Answers arrive in the language you opened the session in; everything written
into the project is in English.

## Prerequisites

Nothing has to be installed for `do` to run, but nine things in the project change what a run can
do. The Reply's Run section reports one of them, the loop line, with the protected-branch warning
beside it when it applies, so you find how the run was set up in the message it ends with. The
other eight surface at the step that reads them, and each row below names that step.

| In the project | What `do` does with it, and without it |
|---|---|
| the **Ticket** itself, a file under `.scratch/` or an issue on the tracker `docs/agents/issue-tracker.md` describes | the `ticket` Playbook's whole input. The door's lines, the protected-branch warning among them, reach you in the Reply's Run section, and a landing on a protected branch is refused whatever the run wrote. With no file and no tracker entry there is nothing to match, so the run refuses a bare issue number and asks you for the ticket's path |
| [do-reader](../README.md), the reader `do` ships, linked | the door forks it over the Ticket's Spec and journey to cut the Digest, so neither document enters the session and the Digest is written from what it returns. With the Agent tool withheld, or no `do-reader` agent listed, the session reads both documents itself and says so in one line, `do-reader` by name when it is not linked, with `scripts/link-skills.sh` as the run that links it before your next `/do`, and never forks another agent in its place, since a fork under another name could hold the write tools the reader is denied |
| [do-planner](../README.md), the planner `do` ships, linked | a `ticket` run's Plan step forks it over the Ticket and its Digest, and it writes the Plan itself: the glossary words, the ADR titles, the map of the subsystem, the discover audit line, the behaviours list and the Sketch when the shape step fires. Your session holds the Plan's path and never its text, so the grounding is paid for in the fork's window instead of yours. The Plan sits beside the Ticket as `<ticket>.plan.md`, and the Reply's Plan line names it with every fallback the fork reported. A Plan already there whose recorded hashes still match the Ticket and the Digest is carried, so a second `/do` on the same Ticket forks nobody. The step runs before the run claims your Ticket and before it creates the worktree, so a return naming no Plan, a Plan at some other path, or one whose recorded hashes are not the ones your door computed, is refused with the Ticket at the status it had and no `do/<slug>` branch to remove, except on a Ticket whose defect's cause is unknown, where the worktree already cut for the diagnosis is named in that refusal instead of left unnamed: a bad grounding costs you a rerun and, on every other Ticket, nothing to undo. With the Agent tool withheld, or no `do-planner` agent listed, the session grounds the Ticket and writes the Plan itself at the same path and says which of the two held, and never forks another agent in its place |
| a Testing Policy with its unit test author at `.claude/agents/unit-test-author.md`, or [the global authors](../README.md) `do` ships, linked | the Reply's Run section reads `Loop: policy` and that author writes every new test. With no policy and `global-unit-test-author` linked, it reads `Loop: global`: the run derives a Project map from what the project's own scripts and files say, keeps it in the project's `.scratch/`, and the global authors write the tests and the flows against it. With neither, or with the Agent tool withheld, the line reads `Loop: fallback` and the run writes each failing test itself, red before the fix either way |
| [do-code-review](do-code-review.md) linked in the session | the review fixes its `Act on` Findings and lands the branch. Without it the step reads `skip: do-code-review not listed`, nothing lands, and the reply hands you the worktree, its branch and the review to run yourself |
| [sketch](sketch.md), with its agent linked | it is forked when the work crosses a boundary and nothing in hand carries a shape, so the rival shapes stay out of your context window: by the Planner in a `ticket` run, where the Sketch lands as the Plan's own `## Sketch` section, and by the shape step in a `bug-fix` or `refactoring` run, where it is filed beside the Ticket and the Reply's Run section names what was handed over and where it is. When `sketch` writes nothing, with the Agent tool withheld or no `sketch` agent listed, whoever forked it shapes the work itself and says so, the Planner on the fallback line it returns and the session in its Run section |
| [choice-taker](../README.md), the agent `do` ships to rule a Design fork, linked | a `ticket` run that meets a Design fork at its Plan or build step forks it with the two sides, writes the Ruling it returns as one line in the Spec's Implementation Decisions, and carries on over the amended Spec instead of stopping for your confirmation. An Extreme fork, one side weakening a guarantee in a risk class or unable to be undone once landed, still stops the run, whether your session reads it that way or the choice-taker returns `extreme`, and the reply ends on a `/discuss` command you copy. With the Agent tool withheld, or no `choice-taker` agent listed, the run stops at its step and says which of the two held, `choice-taker` by name when it is not linked, with `scripts/link-skills.sh` as the run that links it before your next `/do`. It never forks another agent in its place, since a fork under another name could hold the write tools the choice-taker is denied, and the reply ends on the same `/discuss` command an Extreme fork gives, with that reason in it |
| [ledger-judge](../README.md), the agent `do` ships to judge a **Loss ledger** entry, linked | the integration forks it once the rebase finishes and the ledger holds an entry no run has judged, once for the whole integration and never once per hunk, with the ledger's location, the worktree root and the run's intent. It reads and searches only, and the session writes each `reapply` or `drop` it returns, with its one-line reason, into the ledger, so what a contested hunk set aside is on record as kept or as let go. A rebase that set nothing aside forks nothing and costs what it costs today, and a resumed run judges only the entries still carrying no verdict, so running twice leaves the same ledger. With the Agent tool withheld, or no `ledger-judge` agent listed, the session judges the entries itself and says which of the two held, `ledger-judge` by name when it is not linked, with `scripts/link-skills.sh` as the run that links it before your next `/do`. It never forks another agent in its place, since a fork under another name could hold the write tools the judge is denied |
| the vendored `architect`, `how`, `why` and `unslop` | `bug-fix` and `refactoring` sketch the shape with `architect` before they cross a boundary, and a run keeps the grounding out of its own context window, reads the rationale behind the shape a defect sits in, and cleans up the reply. Each is optional and each step says in one line what it does instead, so a `bug-fix` run with neither `how` nor `why` reads the code with search and targeted reads and says so, and a `ticket` run whose Planner does not list `how` has it build the map from search output alone, read no file whole and report the map as thinner on the fallback line the Plan line carries |

The run writes into two places outside your branch: the worktree at `.claude/worktrees/do-<slug>`,
excluded through this clone's `.git/info/exclude` and never through the project's `.gitignore`, and
the Ticket file in the **Main checkout**, which the run edits and never commits. Installing every
skill named here is the same procedure, and [the top-level README](../README.md) carries it once.

## The Playbook

A **Playbook** is one execution model, one file in the skill's `references/` folder, read only when
the router matches it. The skill file itself holds the router, the rules that apply to every run,
and the links, so a run loads one Playbook and never the other four
([ADR 0008](adr/0008-do-is-a-router-and-only-its-ticket-playbook-is-inside-the-chain.md)). Only
`ticket` is inside the chain; the other four exist for work that never entered it.

| Playbook | Matched by | What the run does |
|---|---|---|
| `ticket` | a Ticket's path, or an issue reference the tracker file resolves | claims the Ticket in your checkout, builds it in a worktree behaviour by behaviour, gates, reviews, runs the affected flows, and closes the Ticket with the evidence quoted under it |
| `bug-fix` | a defect in words: what happened, where, and the error or the wrong output | reproduces it on the surface it happens on, rules hypotheses out with runtime evidence, commits the failing reproduction before the smallest fix, and verifies on that same surface |
| `refactoring` | a reshape in words whose behaviour stays where it is | pins the behaviour before any structure moves, then commits subtraction, reshape and cleanup in that order, so one revert undoes one slice |
| `integrate` | a rebase of one branch onto another, or a merge of one branch into another, in words | checks the branches exist, that a merge target is not protected, that you stand on the branch written to and that your tree is clean, then runs the operation, resolves the mechanical hunks and takes the target side of the contested ones, leaving what they set aside in a Loss ledger keyed by the branch. No worktree, no review, nothing landed or pushed |
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

## One behaviour, one green commit

The three Playbooks that build share one loop, so the discipline is the same whether the work came
through the chain or not. The run creates a worktree from your current HEAD and takes one behaviour at a
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

Then the branch goes to the review, once per run: the run hands it the gate's command line too, so
the review's fixes are held to the same checks, and only the outcome comes back, never the Review's
text. When your branch moved while the review ran and its landing met a hunk it does not take, the
review comes back `not landed: target moved` and the same run integrates once more onto your moved
branch: the contested hunks take your branch's side, the ledger is judged and reapplied, the gate
runs whole, and the branch lands through a `fix` call on the same Review. It goes round again each
time your branch moves before the landing, with no fixed count, so several runs landing at once all
land: each lost race means another run landed first
([ADR 0044](adr/0044-the-re-integration-retries-while-the-target-tip-changes.md)). It stops only
when the integration finds nothing to replay, since then no other landing happened. The affected flows run from your checkout through a script of their own whose command line
comes first, and a red one is fixed in the worktree, gated and landed through a `fix` call on the
same Review, never a second review. The Ticket is closed with the command lines and their
output quoted under `## Evidence`. A run that stops for any
reason leaves the worktree and its branch in place and names both, so nothing is half landed and
nothing is lost.

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
stops. The review writes the Review, forks one Fixer per `Act on` Finding, one at a time, each
turning its Finding into its own commit, re-runs each Finding's check, the tests the diff touched
and the whole gate, with a Gate fixer on a red one, and fast-forwards your branch only when the
Review is Green
([ADR 0013](adr/0013-do-code-review-lands-a-green-review-by-fast-forward.md),
[ADR 0015](adr/0015-the-default-review-run-fixes-and-lands-and-the-fixer-corrects-for-every-caller.md)).
That is also why `do` never patches a Finding by hand: a Finding the Fixer left standing is the
reason nothing landed, and the run stops on it with the worktree intact.

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
the feature reads your line. Once the Ticket is `resolved`, `/do` stops on it, and the reversal is
a new Ticket you write
([ADR 0038](adr/0038-a-ruling-reversed-after-its-ticket-landed-is-built-by-a-new-ticket-the-developer-writes.md)).

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
  a `fix` call on the Review it already has, as many times as the branch keeps moving. Only an
  integration that finds nothing to replay stops it, and typing the request again then recovers it
  the same way. The reply lists every entry that later
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
  `Principles`, lists in one line each Ruling the Spec carries for the Ticket, whichever session
  wrote it: the fork, the side taken, and the norm or "no norm". It reads `none` only when there is
  no such Ruling. Only an Extreme fork, or a fork no choice-taker could rule, stops the run.
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
