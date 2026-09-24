# The fix

What the orchestrator does once there is something to fix: read the `Act on` list, put the Fixers
where they belong, fork them in Waves, each Fixer in a worktree of its own, re-run their work, hold
it to the Diff tests and the Gate, append the record and land.
It is read by the orchestrator alone: whole on a `fix` call, from `## Where the Fixer works` on a
default run whose Review carries an `Act on` Finding, and at `## The landing` on a default run
whose Review carries none and is Green, since a Green Review lands either way. Only a `--no-fix`
run never opens it, and it is never by a reviewer: the reviewers judge a diff and are gone before
any of this runs.

The parts it does not own it links and never restates: the two trees are
[worktrees.md](../../../.agents/worktrees.md), the section it appends is
[review-format.md](../../../.agents/formats/review-format.md), the landing rules are
[ADR 0013](../../../docs/adr/0013-do-code-review-lands-a-green-review-by-fast-forward.md) as
[ADR 0027](../../../docs/adr/0027-the-rebase-runs-in-the-session-before-the-review-and-the-landing-retries-only-the-mechanical-class.md)
amends them for a target that moved, why the default run fixes at all is
[ADR 0015](../../../docs/adr/0015-the-default-review-run-fixes-and-lands-and-the-fixer-corrects-for-every-caller.md),
and why nothing after the one review is reviewed again is
[ADR 0033](../../../docs/adr/0033-the-review-runs-once-per-run-and-what-comes-after-it-lands-through-the-gate-alone.md).

## The door

Three checks, on a `fix` call only, before anything is written. A default run reached this file
with the facts already in hand, from the door script and from the Review it just wrote.

| The check | Fails with |
|---|---|
| the Review at the location the caller named exists | `<the location> not found; nothing fixed` |
| the ref in its `Fixed point:` header still resolves, `git rev-parse --verify <that ref>` | `fixed point <ref> of <review> does not resolve; nothing fixed` |
| the working tree is clean, the door's `dirty=no` line | `working tree has uncommitted changes; commit or stash before fix` |

The ref is the short sha in that header's parentheses, never the whole `Fixed point:` line, which
carries the base name, the sha and an `, inferred` and resolves as no ref at all. The door script
the run calls for its `main_checkout=` and `slug=` lines takes that same short sha, and its own
refusals, which all end `nothing reviewed`, reach the caller ending `nothing fixed`: this call
reviewed nothing.

Each is one line and the run stops there: no worktree, no Fixer, nothing is written, and the reply
is that line alone. The clean check is the door script's `dirty=` line and never a bare status,
because the Review the run is about to append to is untracked in most projects and a bare status
would read the run's own file as the developer's uncommitted work. The tree has to be clean because the Review judged a diff, and a Fixer let
loose on a tree the review never saw would commit work nobody read.

A default run meets the same tree, and answers it the other way, since the Review is worth writing
either way: the file is written, one line says to commit or stash and run `fix` with it, and no
Fixer is forked.

`do` makes a `fix` call of its own after its one review, for what it committed since: the fix of a
red flow, the landing after a `not landed: target moved`, or a rebase a resumed run finished. It
sends the landing target and, when its own gate ran, the Gate after the Review's location, then one
line of its own, `Caller: do`, and the call forks no reviewer. That line decides the mode, once,
here, and nothing else does: not the Gate, which a resumed run has none of to hand, and not the
Review's history, which records what ran and never who calls.

| The call carries | The mode |
|---|---|
| no `Caller:` line | a developer's `fix`: a Finding the branch has not already fixed goes to The Fixer |
| `Caller: do` | `do`'s, after its one review: nothing is forked, no Fixer, no Gate fixer and no `fix/` worktree, and a Finding the branch has not already fixed stays open |
| `Caller:` with any other value | refused before anything is written: `caller <the value> unknown; nothing fixed` |

`do`'s call forks nothing because what `do` committed after its review is code no reviewer read,
per [ADR 0033](../../../docs/adr/0033-the-review-runs-once-per-run-and-what-comes-after-it-lands-through-the-gate-alone.md):
a Fixer's commit on that tree is what turns a red Gate over to the Gate fixer, whose brief is the
red block alone, and its fix would edit the replayed code nobody read and land it. A Finding that
stays open there is the developer's to fix, or to overrule in the Review and call `fix` on, and a
list with nothing left in it comes down to the Gate and the landing in both modes.

## The Act on list

Read the `## Act on` section off the Review on disk, in the file's order, naming each Finding
by its number, with its location, its `Claim:` and the behaviour and target its `Fix:` names. Nothing
under `## Consider`, `## Noted` or `## Cleared` is read, and nothing outside the section reaches
a Fixer.

The file is the hand-off, not the run's memory of what it found. On a `fix` call it was read and
edited by hand: the developer moved a `Consider` they want fixed into `Act on` and deleted an
`Act on` they overrule, so the list is whatever the file says now. A Finding they moved in may
carry no check in its `Fix:` line; that is allowed, and the re-check below reports it.

An empty list, or one whose Findings an earlier fix already settled, forks no Fixer and creates no
worktree. The re-check, the Gate and the append still run, and the section reads `nothing remained`,
so a second `fix` on the same Review is harmless. A Finding is settled when its latest line,
read across every `## Fix run` section and not the last section alone, reads `fixed`: a section
that reads `nothing remained` names no Finding and settles or unsettles none. A Finding whose latest
line reads `not fixed` or `stale` is not settled and goes to a Fixer again, since a Finding no fix
call reads again keeps the Review from ever turning Green. A Finding left
`not fixed: conflicted with Finding <m>` is one of them, with nothing new to call: the new call's
Waves take it like any other, and its re-routes count from zero in the section that call appends.

## Already fixed on the branch

On a `fix` call only, before any Fixer. A Finding the list still holds may already be fixed by a
commit made after the review, by the developer or by `do`, and a Fixer forked for it finds its
location changed, reports it `stale`, and the Review never turns Green. So each unsettled Finding is
first held to the branch as it stands, per
[ADR 0056](../../../docs/adr/0056-the-fix-call-settles-a-finding-whose-fix-is-already-on-the-branch.md).

Run `bash ~/.claude/skills/do-code-review/scripts/unsettled.sh <the tree> <the Review>`, where the
tree is the one the Review judged: `do`'s worktree on a `do` call, and on a plain call the
developer's own checkout, which the door has just found clean. It prints one
`finding=<n> touched=<sha>|none` line per `Act on` Finding whose latest line is not `fixed`, by the
rule above, the sha being the latest commit since the Review's `Commit:` that changed the Finding's
header line or line range, as `git log -L` tracks it: a commit that only touched some other line of
the same file is no touch. What each answer means:

- **Exit 1**: nothing is unsettled, and the run goes on as the paragraph above says for a list with
  nothing left in it.
- **A `touched=<sha>` line whose Finding's `Fix:` names a check**: the check has to have gone red
  against the code the Review judged before it is trusted green now, per
  [prove-it-works](../../../.agents/principles/prove-it-works.md). Add a throwaway worktree at the
  Review's `Commit:`, detached (`git worktree add --detach <a temp path> <Commit:>`), copy the
  `Fix:` target's file as it stands at HEAD over the same path there, and run the check in that
  worktree: it fails on an assertion the check makes about the code, never merely on the check
  failing to load. An unresolved import, a missing export or a `TypeError` on a symbol the code at
  `Commit:` never carried is no red here: the check never ran against the reviewed behaviour, it
  only tripped over a symbol a later commit added, and that same failure would still fire the moment
  anyone pasted that symbol back in with the Finding's own sink left exactly as broken. Treat that
  miss the way a check that never failed at all is treated, below. Remove that worktree (`git
  worktree remove --force <that path>`), then run the same check in the tree at HEAD, the way The
  re-check runs it: it passes. Both hold, and the Finding is settled here: hold `- <n>: fixed <sha>,
  verified (<the check>)` for The append, and fork no Fixer for it. Either miss, the check already
  passing against the Review's own code, never loading at `Commit:` to begin with, or still failing
  at HEAD, and the Finding goes to The Fixer: a check that was never red on an assertion against the
  code the Review judged proves nothing about the fix, whichever file the commit that touched it
  landed in.
- **A `touched=none` line, or a `Fix:` that names no check**: the Finding goes to The Fixer, as it
  did before this step existed. A check that already passed on code no commit has touched since the
  review proves nothing the review did not already see, and a Finding with no check has nothing to
  prove it by, so neither is ever recorded `verified` here. A test file the `Fix:` names that holds
  no test of the behaviour it names is no check yet: the file passing says nothing about the
  Finding, and the Fixer is the one who writes that test.
- **Exit 3**: the Review's `Commit:` is absent or not on the branch. Every line reads
  `touched=none` and every unsettled Finding goes to The Fixer, since a range from a commit off the
  branch would name a sha that never carried the fix.

This step writes nothing. Its held lines reach the Review through The append, in the one new
`## Fix run` section of this call, beside the Fixers' lines, and every earlier section stays as it
was. When it settles every Finding, Where the Fixer works and The Fixer are skipped: no worktree is
created, no Fixer is forked, and the run carries on from The re-check to The landing.

Every Finding this step sends to The Fixer goes there on a developer's call only. On `do`'s call,
the `Caller: do` mode the door decided, Where the Fixer works and The Fixer are skipped whatever
this step settled: a Finding it did not hold stays unsettled, with the reason this step found for
it (its location untouched since the review, its check never red at `Commit:` or still red at HEAD,
no check to re-run, or the Review's `Commit:` off the branch), and the run carries on from The
re-check to The landing with no Fixer commit to check.

## Where the Fixer works

One question decides it: is the branch the Review judged the branch the developer's checkout is on?

- **No.** That is `do` at its review step: the branch is the `do/<slug>` worktree branch, and its
  worktree already exists. It is the reviewed tree, and the run removes nothing it did not create.
  The worktree is `do`'s, it stays for `do`'s flows and its close, and taking it away would end the
  run that called us.
- **Yes.** A plain call on the developer's own branch. The run creates the worktree itself, from
  the branch's HEAD, by [do's mechanics](../../do/references/mechanics.md) and in two steps. First
  the exclude line, when `git check-ignore -q .claude/worktrees` fails: append `.claude/worktrees/`
  to `.git/info/exclude`, never to the project's `.gitignore`, since the ignore file is the
  project's and the exclude list is this clone's. Then
  `git worktree add .claude/worktrees/fix-<slug> -b fix/<slug>`, where `<slug>` is the branch name
  with every slash turned into a dash, the door's `slug=` line. It is the worktrees folder `do`
  uses, so one exclude line covers them all, and the developer's `git status` reads the same before
  the run and after it, which matters because the fix door measures that status. The run removes it
  and its branch on the rules `## The landing` carries.

Either way that is the reviewed tree, and the re-check, the Diff tests, the Gate, the Gate fixer and
the landing all run there, on the reviewed branch as the Waves integrated it. A Fixer works in a
tree of its own, cut beside it for its one Finding by the Wave's `fix-worktrees.sh add` line (see
`## The Fixer`), so two Fixers of one Wave never share an index.

Every Fixer, and the Gate fixer, is forked from the reviewed tree, the run's own working directory,
and its brief names the tree it works in, `Tree: <its absolute path>`: the reviewed tree for the
Gate fixer, its own worktree for a Fixer. A fork's shell starts in the tree it was forked from, but
its file tools take absolute paths, and a Fixer has built them from the main checkout, where the
diff under review is not: it read a line the branch changed as gone and reported a live Finding
`stale`. The run never changes its own working directory and never uses a worktree tool, per the
two-trees contract, and never writes a git command that makes or removes a Fixer's worktree or
branch: `fix-worktrees.sh` composes those names and is the only thing that touches them, so the
run hands back only the branches it printed.

## The Fixer

A default run's step, and a developer's `fix` call's; `do`'s fix call never reaches it, as the door
says. One Fixer per `Act on` Finding, run in Waves, per
[ADR 0053](../../../docs/adr/0053-the-fixers-run-in-waves-each-in-its-own-worktree-on-a-floor-a-script-computes.md):
the Fixers of one Wave run at once, and the Waves run one after another. Each Fixer works and
commits in a worktree and on a branch of its own, per
[separate-before-serializing-shared-state](../../../.agents/principles/separate-before-serializing-shared-state.md):
a test author running its red against another Fixer's half-made edit proves nothing, and two
commits at once in one tree fight over its index. A Fixer holds its one Finding and nothing else,
so its window stays the size of that Finding.

Each is the `do-code-review-fixer` agent this skill ships, forked with the Agent tool as
`subagent_type: do-code-review-fixer` and no `model` key, so it runs on the model and the effort its
definition picks and never on the session's. Its contract is its definition,
[do-code-review-fixer.md](../agents/do-code-review-fixer.md): the four rules, the tree it reads and
writes in, the two ends with no commit and the return file, none of them restated here. Its brief
carries what changes from one call to the next, and nothing else:

- the Review's location;
- `Branch: <the branch its worktree line printed>`, the branch it commits on;
- `Tree: <the path its worktree line printed>`, the tree it works in;
- its one Finding: its number, its location, its `Claim:` and its `Fix:` line;
- `Return file: <the path below>`.

When the harness does not list `do-code-review-fixer` by name, fork `general-purpose` in its place
on `model: sonnet`, the model its definition pins, with that definition read through the shell from
`$(readlink -f ~/.claude/skills/do-code-review)/agents/do-code-review-fixer.md` as the head of the
prompt and the same brief after it. A missing link never blocks the fix: it is the path every
Fixer takes on a machine that linked the skill and not its agents, and under Codex, which registers
no custom agent.

### The Waves

The run is not over until the landing line is written, whatever the Agent tool does. Make one
directory outside every repository before the first Wave,
`mktemp -d "${TMPDIR:-/tmp}/do-code-review-fix.XXXX"`, the directory every return file below goes
in. Its own random suffix is this run's, made fresh by `mktemp` and never read off anything the
Review or the reviewed tree carries, and step 1 below folds it into `<at>`.

Which Findings may share a Wave is a script's output and never the run's reading of the Findings:
run `bash ~/.claude/skills/do-code-review/scripts/fix-waves.sh <the Review's absolute path>` once,
and read its `wave=<k> findings=<n>[,<n>]...` lines, one per Wave, in the order the Waves run. On a
`fix` call where Already fixed on the branch held any Finding, add `--settled <n>[,<n>]...` with the
numbers it held, and leave the flag off otherwise. The script leaves out of every Wave a Finding the
`## The Act on list` rule reads as settled and every one `--settled` names, before it groups the
rest, so no Wave it prints carries a Finding no Fixer should see. Those lines are the floor, per
[ADR 0055](../../../docs/adr/0055-the-review-orchestrator-runs-on-opus-at-high-effort-and-no-router-agent-is-created.md).
Its exit 1 means nothing is left to fork: no worktree is cut, no Fixer is forked, and the run
carries on from The re-check. Its exit 2 on a `--settled` number is a number that is no unsettled
`Act on` Finding of the Review: the list was mistyped, and it is read off the held lines again
before the call is made once more.

The script compares files and sees nothing else, so read each floor Wave of two or more Findings
once more for a coupling no file comparison can see: two Findings whose functions call each other,
or two whose `Fix:` lines send their test authors to the same shared factory, mock or fixture. Where
you find one, cut that Wave into pieces, the coupled Findings in different pieces, and give the cut
one reason naming the coupling, which the record keeps. A Wave with no such coupling runs as the
script printed it: a cut costs a Wave's worth of waiting, so one with no coupling to name is not
made.

The cut runs one way. Never put into one Wave two Findings the script printed in different Waves,
and never move a Finding out of its floor Wave except into a piece of that same Wave, whatever your
reading of the Findings says: the floor is the parallelism the file comparison proved safe, and a
Wave widened past it can run two Fixers at once over one file, where the integration keeps one fix
while the record claims both. Held to the floor, a wrong cut costs time and never a fix.

The pieces of a cut Wave run one after another, in the place the floor Wave held and before the
next floor Wave, each one integrated before the next piece's worktrees are cut, the same rule that
holds between any two Waves below. The Waves as run are numbered from 1 in the order they run, each
piece taking a number of its own, so the `<k>` of the steps below, in `fix-worktrees.sh add`, in a
return file's name and on a `- wave <k>:` line, names one Wave that ran and never a floor Wave a cut
split.

Then, for each Wave `<k>` as run, in order, while no stop below has fired:

1. **Cut the Wave's worktrees.**
   `bash ~/.claude/skills/do-code-review/scripts/fix-worktrees.sh add <the reviewed tree> <slug> <at> <k> <n>...`,
   with the door's `slug=`, the Wave's `<k>` as counted above and its Findings. `<at>` is the short sha the `Date:`
   line records with the run's own `mktemp` suffix appended, `<sha>-<suffix>`, unique to this run
   and never just the reviewed HEAD's sha: a second `fix` run at the same reviewed HEAD gets a fresh
   `mktemp` suffix of its own, so its `<at>` never repeats an earlier run's, and its Wave never
   collides with a Fixer worktree that earlier run kept. It prints one `worktree <n> <path> <branch>`
   line per Finding, each cut from the reviewed tree's HEAD as it stands now. A `failed` line, exit
   3, means no worktree of this Wave exists: every Finding of the Wave reads
   `not fixed: worktree not created`, no further Wave runs, and the run goes to the re-check.
2. **Fork the Wave at once.** One Fixer per Finding of the Wave, every one of them in one message,
   each with the brief above, its `Branch:` and `Tree:` taken from its own `worktree` line, and
   `Return file: <that directory>/fixer-w<k>-<n>.md`.
3. **Wait for the whole Wave.** When the Agent tool returns every Fixer's line, go on. When it
   returns before them, because the harness runs sub-agents in the background, do not end your
   turn: a turn ended there hands the Fixers' results to your caller instead of to you, and the
   re-check, the Gate and the landing never run. Wait for the Wave in one call over every return
   file it forked,
   `bash ~/.claude/skills/do-code-review/scripts/returns.sh 240 <every return file of the Wave>`,
   given the Bash tool's own `timeout` at its maximum, `600000` ms, so the script's window closes
   first, and call it again over the files still `missing=`, three windows and no more. A Fixer
   whose file has not landed after the third reads `not fixed: the Fixer did not return`, and no
   further Wave runs, since it may still be writing in its worktree; every Finding of a later Wave
   reads the same. No Gate fixer is forked from there on, whatever the Diff tests or the Gate read,
   the `fix/<slug>` worktree and its branch stay in place and are named, and the landing line reads
   `not landed: a Fixer did not return`.
4. **Read each returned line**: a commit, a location reported stale, or `not fixed` with what
   stopped it. Two of a Fixer's lines end in no commit, per its definition, and the run reads them
   this way:
   - `not fixed: test author unreachable`, the Agent tool withheld from it. No further Wave runs,
     since each Fixer would meet the same wall, and every Finding of a later Wave reads the same.
   - `not fixed` with a test's reason, a test that would not go green. The Fixer dropped its own
     edits in its own worktree, which stays clean.
5. **Integrate the Wave.** Over the Fixers that returned a commit, and only those,
   `bash ~/.claude/skills/do-code-review/scripts/fix-integrate.sh <the reviewed tree> <n>=<branch>...`,
   each branch the one its `worktree` line printed. It picks them onto the reviewed branch in
   Finding order, whatever order they are given in, and prints one line per Finding:
   - `picked <n> <sha>`: the sha is the one the commit has on the reviewed branch, and the only sha
     the record ever keeps for that Finding, never the Fixer branch's own, which is gone once
     step 6 removes it.
   - `conflicted <n> with <m,...|none> files "<path>"...`: the pick was aborted, and the reviewed
     branch holds every clean pick of the Wave and nothing of this one. The Finding is re-routed,
     never resolved in place, per
     [ADR 0054](../../../docs/adr/0054-a-conflict-between-two-fixers-is-aborted-and-re-routed-never-resolved.md):
     a conflict between two Fixers of one Review means the floor missed a coupling or a Fixer
     touched what its Finding did not name, and a resolution would hide that and let the record
     report two fixes where the merge kept one, so no conflict is classed and no hunk is merged.
     The Finding writes no line yet: its re-route count goes up by one, and it is forked again in
     the Wave that runs next, from a fresh worktree cut over the reviewed branch as this Wave's
     integration left it, which holds the Finding it lost to.

     Twice at most. A Finding already re-routed twice in this run, whose pick conflicts a third
     time, is not re-routed: the run stops paying for a coupling it cannot resolve, and the Finding
     reads `not fixed: conflicted with Finding <m>`, naming every Finding of the line's `with`
     list, `Finding <m>` for one and `Findings <m>, <m>` for several, so the developer reads which
     Findings disagree. A line reading `with none` names no Finding: it reads
     `not fixed: conflicted with no Finding of its Wave` and the files the line quoted.
   - `failed <reason>`, exit 3: nothing of the Wave is picked after it. Every Finding of the Wave
     with no `picked` line reads `not fixed: <that reason>`, and no further Wave runs.
6. **Take the Wave's worktrees back.**
   `bash ~/.claude/skills/do-code-review/scripts/fix-worktrees.sh remove <the reviewed tree> <branch>...`,
   over every branch step 1 printed except a Fixer's that did not return, which may still be
   writing there. `removed <branch> <path>` is gone; `kept <branch> <path> unlanded commit` or
   `kept <branch> <path> dirty tree` stays where it is, and is named in the `## Fix run` section and
   in the reply as a commit the run could not land, per `## The landing`.

   A Finding this Wave's step 5 `picked` may be one an earlier Wave re-routed out of, conflicted:
   that earlier Wave's own branch for the same Finding is still `kept ... unlanded commit`, since
   its commit was aborted, never picked, and `git cherry` never matches an aborted commit against
   the retry that superseded it. Take that branch back too, in the same call, appended to the list
   above as `fix-worktrees.sh remove --superseded <the reviewed tree> <branch>...`, which skips the
   landed check: the orchestrator already knows, by Finding number and not by patch, that the
   Finding it names is on the reviewed branch under a different sha. `removed` there is gone the
   same way a plain `removed` is; `kept ... dirty tree` is the only way it stays, for a worktree its
   own Fixer left dirty, and is named in the `## Fix run` section and the reply like any other kept
   branch. A superseded branch `remove` took back is never named as a commit the run could not
   land: the Finding it names reads `fixed`, not `not fixed`.

The next Wave's worktrees are cut only now, from the reviewed tree's HEAD as this Wave's
integration left it: `fix-integrate.sh` takes a Fixer branch only when it is exactly one commit
ahead of the reviewed branch as it stands, so a Wave cut before the one ahead of it was integrated
could never land. That is also what lets a re-routed Finding's second Fixer start from the fix it
lost to instead of meeting it again: its conflicted branch stays behind as
`kept <branch> <path> unlanded commit`, and its new worktree is cut beside it.

The Findings re-routed out of a Wave do not all run together: a `conflicted` line names the files
that aborted its pick, and two re-routed Findings whose `conflicted` lines name a common file would
only conflict with each other the same way if forked together, which is the coupling the floor
missed in the first place. So they are grouped by that overlap, into as many re-route Waves as it
takes to keep every pair that shares a file apart, one Wave per disjoint set of files its Findings'
`conflicted` lines name; a Finding whose `conflicted` line shares no file with any other re-routed
Finding may share its re-route Wave with them. The re-route Waves run right after the Wave they were
routed out of and before the next Wave `fix-waves.sh` printed; routed out of the last Wave, they are
the new last, in the order the grouping puts them in. Each runs steps 1 to 6 like any Wave, under
its own `<k>`, and each of its Fixers gets the brief every Fixer gets. A re-route Wave is never
merged into a Wave the script printed: joining the next Wave could put two Fixers on one file or
five in one Wave, which the floor exists to prevent. Every branch a re-route Wave integrates is cut
from the same HEAD, so its Findings can conflict only with each other in that Wave, and those it
re-routes are grouped and run the same way as the next re-route Wave.

A stop that ends the Waves early, at step 1, 3, 4 or 5, ends a pending re-route Wave with them. Every
Finding still waiting for a Wave, whether a later Wave of the floor's or a re-route Wave not yet
cut, reads `not fixed` with the reason of the Wave that stopped, as the stop gives the Findings of
that Wave, and a re-routed one keeps its `, re-routed <r>`: every `Act on` Finding carries a line,
and one with none would read neither settled nor unsettled to the next `fix` call.

## The re-check

The orchestrator proves the work itself, in the reviewed tree, on the reviewed branch as the Waves
integrated it, and never the Fixer's word for it, per
[prove-it-works](../../../.agents/principles/prove-it-works.md). Once the last Wave was integrated,
per `Act on` Finding, run the check its `Fix:` line named. A Finding's `<sha>` below is the one its
`picked` line printed. A Finding that Already fixed on the branch settled keeps the line it held
there.

| What the run saw | The Finding reads |
|---|---|
| the Fixer's commit was picked and the check passes | `fixed <sha>, verified` |
| the Fixer's commit was picked and there is no check named | `fixed <sha>, not verified` |
| the Fixer reported the location no longer matches, and the run's own read finds it gone too, in the tree, or in the Spec source the Review's `Spec source:` header names for a quote-located Spec Finding | `stale` |
| the Fixer reported the location no longer matches, and the run's own read finds it there, in the tree, or in the Spec source the header names for a quote-located Spec Finding | `not fixed: reported stale, the location still matches` |
| the Fixer's commit conflicted a third time in this run, after two re-routes | `not fixed: conflicted with Finding <m>`, or the other two forms step 5 gives |
| no commit, for either branch above, or a Fixer that did not return | `not fixed` with the reason |

A Finding the run re-routed ends whichever of those lines it reads with `, re-routed <r>`, per
`## The append`, the state still first.

The two reviewers are not re-run on the Fixers' commits, and never on anything after them: the
review runs once per run. Each Finding's own check, the Diff tests and the Gate are what stand in
for a second one.

## The Diff tests

The fast check, run once the re-check is done: the tests whose files the diff since the fixed
point touched or added, the Fixers' own tests among them. They are the files
`git diff --name-only --diff-filter=d <the fixed point>..HEAD` names, the `d` leaving out the files
the diff deleted since nothing is left of them to run, whose names carry the test-file suffix the
project's own tests use, each run with the unit runner's single-file command from the Testing
Policy's Project facts in `CLAUDE.md`, one file per command, so a red one is named by its file.
They are a slice of the Gate that fails in seconds instead of at the end of a full suite, and the
Gate fixer works against them first.

- Green, and the run goes to the Gate.
- Red, and the Gate fixer takes the red block.
- No single-file command in the facts, no test file in the diff, or no Fixer commit to check: the
  step reads `skip:` with that reason, and the Gate carries the check alone.

## The Gate

The whole set of checks, run once after the Diff tests and before the landing: the unit suite, the
typecheck, the lint and the format check. `do` hands it over as the `command=` line its gate
script printed, and the orchestrator runs the `command=` line the caller handed as it stands, in
the reviewed tree the Fixers' commits were picked onto, and reads its `verdict=` line: it reruns
`do`'s own gate, so the review holds its fixes to the checks `do` held the build to. With no line
handed, on a plain call,
the Gate is each command the Testing Policy's Project facts carry for those four checks, else the
tests the reviewers ran. A `do` call hands no line when the run reached the fix call with no
**Gate** of its own, the resumed run that skipped its own gate, and that call forks no reviewer, so
the Project facts are the whole fallback there and nothing stands behind them. A Review with
nothing in `Act on` runs it too, at the start of the landing.

- Green, and the run goes to the append and the landing.
- Red after a Fixer committed: the Gate fixer takes the red block.
- Red with no Fixer commit: the red is the branch's own and not the fixes', so no Gate fixer runs,
  and the landing line reads `not landed: gate red, <the failing check>`, unless a Finding is still
  open, whose reason `## The landing` puts first.
- `verdict=blocked`: a check failed on its environment and not on the code. Nothing lands, the
  landing line reads `not landed: gate blocked, <its cause= line>`, and nothing is worked around.
- Nothing to run: no `command=` line handed and no Project facts for those four checks, with no
  reviewer's tests behind them on a `do` call. An empty Gate is never a green one, so nothing
  lands, the landing line reads `not landed: no gate to run, no command= line handed and the
  project names no checks`, and the branch and its worktree stay in place. The reply's own line
  says what the landing wants: the gate command the call was to be handed, or the checks the
  project's Project facts have to name.

## The Gate fixer

The `do-code-review-gate-fixer` agent this skill ships, forked when the Diff tests or the Gate come
back red after a Fixer committed, with two attempts in all, shared by both checks. It is forked with
the Agent tool as `subagent_type: do-code-review-gate-fixer` and no `model` key, so it runs on the
model and the effort its definition picks. Its contract is its definition,
[do-code-review-gate-fixer.md](../agents/do-code-review-gate-fixer.md): the four rules, one commit
per attempt and the return file, none of them restated here. Its brief carries what changes from one
attempt to the next, and nothing else:

- the red block as the check printed it, the capped lines, and never the full log or the Review;
- the branch it commits on;
- `Tree: <the absolute path of the tree it works in>`;
- `Return file: <the Fixers' directory>/gate-fixer-<the attempt>.md`.

Nothing of the Review reaches it, not its location and not a Finding: the red block is the whole
of what an attempt is for, and a Gate fixer that read the Findings would widen its edits past it.

`do`'s fix call never forks it: that call forks no Fixer, so no Fixer commit exists for a red to
follow, and the red is the branch's own, as `## The Gate` reads a red with no Fixer commit. When
that call leaves a Finding open and the Diff tests or the Gate read red, the `## Fix run` section
says why nothing was forked for the red, `- gate fixer: not forked, Finding <n>[, <n>]... left to
the developer`; with both green it reads `not needed`, as on any call.

When the harness does not list `do-code-review-gate-fixer` by name, fork `general-purpose` in its
place on `model: sonnet`, the model its definition pins, with that definition read through the
shell from `$(readlink -f ~/.claude/skills/do-code-review)/agents/do-code-review-gate-fixer.md` as
the head of the prompt and the same brief after it, as for a Fixer.

The Gate fixer's return file is waited for the way a Fixer's is, three windows and no more. One whose file never lands ends the attempts, since it may still be
writing in the tree: nothing lands, the `## Fix run` section reads `- gate fixer: no return`, and
the landing line reads `not landed: gate fixer did not return, <the failing check>`, with a
Finding still open named beside it, per `## The landing`.

After each attempt the orchestrator runs every Finding's check, the Diff tests and the Gate again
itself, and never takes the Gate fixer's word for it. Green, and the run goes on. Red after the
second attempt, and the Review is not Green: nothing lands, the landing line reads
`not landed: gate red after the fixes, <the failing check>`, and the branch and its worktree stay
in place, so the developer can read what each Fixer and the Gate fixer did. Two attempts and no
third, since a red that survives both is a diff that is not converging, and one more attempt costs
another window with nothing to show that it will close.

## The append

Write the `## Fix run` section the format fixes, with the date, the commit the fix ran at, one line
per Finding by number, the lines Already fixed on the branch held among them, one
`- wave <k>: <n>[, <n>]...` line per Wave that forked a Fixer, in the
order the Waves ran, naming the Findings forked in it, with one
`- cut: floor wave <k> into <n>[, <n>]... | <n>[, <n>]...: <the reason>` line right above the Wave
lines of each floor Wave you cut, then the Diff tests, the Gate fixer, the Gate and the landing
line. A `nothing remained` section ran no Wave and carries no Wave line. On `do`'s call a Finding
Already fixed on the branch did not hold reads `- <n>: not fixed: left to the developer, <the
reason that step found>`, in the reason's words the format lists, since no Fixer ever reached it.

The orchestrator has no edit tool, on this call as on every other, so appending means writing the
whole file again with the section added, once, with the Write tool and never an edit. Read the Review off disk first:
on a `fix` call the developer edited it, so the file is the truth and the run's own memory of it is
not.

## The landing

The Review is Green when every `Act on` Finding reads `fixed` and `verified`, every Axis ran and
the Gate is green. `Consider`, `Noted` and `Cleared` never block.

A Finding that keeps the Review from Green is named on the landing line by its number, every `Act
on` Finding whose latest line is not `fixed <sha>, verified`, in the file's order:
`not landed: Finding <n>[, <n>]... not fixed or not verified; the branch <name> and its worktree
stay in place`. The same form on every call: `do` reads the landing line and never the Review, so
a line that named no Finding would leave it, and the developer it hands the stop to, guessing
which one is open.

It is the first reason on the landing line, ahead of an Axis `not run`, a red Gate and a target
that moved: a Finding left open is the one blocker only the developer can clear, by a fix or by
overruling it, and a landing line that led with another reason would send `do` to a choice that
cannot clear the Finding, and its next run would stop on it again. The Gate still runs and its
line still reads red when it is, so the record shows whether the Finding was the only thing
keeping the branch from landing.

The one thing it never gets ahead of is a Fixer or the Gate fixer that did not return: that reason
warns a fork may still be writing in the tree, a live hazard the developer has to read before
anything else, so it stays on the landing line whatever Finding is open. A Fixer's non-return, per
step 3 of `## The Waves`, already gives every open Finding of the run the same reason, so the line
names it alone, `not landed: a Fixer did not return`, as it already reads there. The Gate fixer
runs after every Wave, so a Finding may be open for a reason of its own when it does not return,
per `## The Gate fixer`, and the line then names both, the non-return first: `not landed: gate
fixer did not return, <the failing check>; Finding <n>[, <n>]... not fixed or not verified; the
branch <name> and its worktree stay in place`.

Green lands, under ADR 0013's rules as ADR 0027 amends them and no others: the landing target is
fast-forwarded to the reviewed branch, the one the Fixers' commits were picked onto, by
`bash ~/.claude/skills/do-code-review/scripts/land.sh <the main checkout> <the landing target> <that branch>`,
never by a `git merge` of your own, since the script holds the one lock every run landing on this
repository takes, per
[ADR 0043](../../../docs/adr/0043-concurrent-landings-serialize-only-the-fast-forward.md), and a
landing that lost the race to another run reads `moved` from it instead of failing. Its one line
is the verdict: `landed <sha>`, the target fast-forwarded; `moved <sha>`, the target holds a
commit the branch lacks and was left untouched; `failed <reason>`, the main checkout on another
branch than the target, since git would fast-forward that branch instead, or a fast-forward git
refused for any other reason, with git's error line. A protected target is refused and named
before the script runs; `moved` is retried once, as below; `failed` leaves everything in place and
is named with its line. On every one of those paths
nothing is pushed. The reply's last line is the push command, `git push` with the landing target
named, so the developer pushes when they choose and nothing leaves the machine before then.

### A target that moved while the review ran

The developer may commit on the landing target while the review runs, and another run may land on
it. The target is then no longer an ancestor of the branch, which is what `land.sh`'s `moved` line
tells from any other failed fast-forward. The landing retries once,
by rebasing the branch onto the moved target, and only over hunks nobody has to judge. Every command
below runs in the tree the reviewed branch is checked out in, with the Fixers' commits on it when
there are any: `do`'s worktree when `do` called, the `fix/<slug>` worktree on a plain call. That
holds whether or not a re-check ran there, and `git -C <the main checkout>` stays for the
fast-forward alone. Nothing on these paths asks a question: the orchestrator is a fork with nobody
to answer, so a hunk a person must judge ends the landing instead of waiting on one.

1. The rebase runs with git's conflict-resolution reuse off,
   `git -c rerere.enabled=false -c rerere.autoupdate=false rebase <the landing target>`, and so do
   the continue, the skip and the abort below, with the same prefix. The setting is the
   developer's and may be on, and a resolution the cache replays into a stop would be classed in
   place of what git left.
2. At every stop, before anything is resolved, the conflicted hunks are classed by
   `bash ~/.claude/skills/do-code-review/scripts/conflict-class.sh`, whose verdict is the class and
   never the orchestrator's reading of the markers, per
   [ADR 0028](../../../docs/adr/0028-the-conflict-class-is-a-scripts-verdict-never-the-sessions-reading.md).
   It is a verbatim copy of the script `do`'s integration runs, kept in this skill so the review
   classes the same way where `do` is not installed, and `do`'s test of that script fails when the
   two drift.
3. Every hunk `mechanical` and the verdict line reading `trusted=0`: the orchestrator resolves them
   itself by keeping both sides in base order, the rule `do`'s integration applies, restated here for the same reason. The conflicted
   files are the list git left, read NUL-delimited, `git diff --name-only --diff-filter=U -z`, and a
   path never enters a command line as text, since either side of the rebase chose it and a single
   quote in it closes whatever quotes it is pasted into. The two blocks run as they stand, nothing
   pasted into them, each path reaching git through a shell variable or `xargs -0`. The first
   writes every conflicted file's union:

   ```
   stages="$(mktemp -d)"
   git diff --name-only --diff-filter=U -z | while IFS= read -r -d '' file; do
     git show ":1:$file" > "$stages/base" && git show ":2:$file" > "$stages/target" &&
       git show ":3:$file" > "$stages/incoming" &&
       git merge-file --union --diff3 -p "$stages/target" "$stages/base" "$stages/incoming" > "$file"
   done
   rm -rf "$stages"
   ```

   Stage 2 is the landing target and stage 3 the commit being replayed, so the union keeps the
   target's lines above the replayed commit's. The `--diff3` stays, as in `do`'s own union: without
   it git trims the lines both sides' additions share, so two functions appended at the same place
   keep one closing brace between them and the landed file no longer parses. Once every union is read back with the Read tool,
   never through a command line, as step 4 needs, the second block marks the files resolved:

   ```
   git diff --name-only --diff-filter=U -z | xargs -0 git add --
   ```

   Then `rebase --continue`, and every further stop is classed and resolved the same way. A
   replayed commit the resolution left empty is already on the target: `rebase --skip`, and the
   landing line names it.
4. Any hunk `contested`, any `trusted` line, a file the class script found resolved by hand and
   never staged, which step 3's union would overwrite with nobody here to read its name, or a union
   that, read back before its `git add`, defines one key twice in one scope of a file whose reader keeps the last definition it meets (JSON, YAML, TOML, an INI or
   a `.env` file), since both lines would land and the reader would quietly keep one of them. The
   rebase is abandoned with `rebase --abort`, which puts the branch back where it was, and the
   landing returns `not landed: target moved` with the target and the conflicting files: the files
   each as the class script printed it, and the key named when one was defined twice. The branch
   and its worktree stay in place, nothing is pushed, and the caller, who can reach a person, takes
   the question from there.
5. A rebase, a continue or a skip that exits non-zero while the class script prints
   `no conflicted state, nothing classed` stopped on something no hunk carries: git refused to
   start, over a tracked file the Gate rewrote or an untracked file the moved target adds, or
   stopped with nothing conflicted. The script's exit 0 there is not every hunk `mechanical`, and
   a continue would have nothing to continue. The one exception is a continue over a replayed
   commit the resolution left empty, which step 3 skips. The landing returns
   `not landed: rebase onto <target> stopped with nothing conflicted, <git's message>`, with git's
   own error line as it printed it. A rebase still open, the file
   `git rev-parse --git-path rebase-merge/head-name` names existing, is abandoned with
   `rebase --abort`, which puts the branch back where it was, while
   a rebase git refused to start left nothing to abort. The branch and its worktree stay in place,
   and nothing is pushed.
6. When the rebase finishes, the Gate runs again in that tree, since the branch now sits on
   commits the reviewers never read. It is the Gate as `## The Gate` defines it, and it runs
   whether or not a re-check ran before it: a Green Review with nothing in `Act on` reaches the
   landing with no Fixer and no re-check. Red, and the landing returns
   `not landed: gate red after the rebase onto <target>, <the failing check>`. Nothing is fixed,
   since the failure may sit in the developer's own commits, so no Gate fixer runs here, nothing is
   pushed, and the rebased branch and its worktree stay in place. Green, and `land.sh` runs once
   more: `landed` lands; `moved`, another landing reached the target while this Gate ran, returns
   `not landed: target moved` with the target and no conflicting file, for the caller to
   integrate again; `failed` is a failed fast-forward and is named.

The landing line then names the rebase onto the moved target with the hunks it resolved, one line
each, in the shape [review-format.md](../../../.agents/formats/review-format.md) fixes.

After a landing the run removes what it created and only that: the `fix/<slug>` worktree and its
branch, left from the main checkout with a bare `cd`, never `do`'s worktree. A run whose Fixers
made no commit at all removes them on the same rule, the withheld Agent tool included: a
`fix/<slug>` worktree holding no commit of its own sits on a branch identical to the developer's
HEAD and holds nothing to read, and the `## Fix run` section says nothing was fixed and why. What
the run did not create it never removes: on `do`'s worktree it removes nothing, whatever the
Fixers did.

A Fixer or the Gate fixer that never returned is not that case even with no commit of its own: it
may still be writing in the tree, so the run removes nothing, forks no Gate fixer, and the landing
line reads `not landed: a Fixer did not return` or `not landed: gate fixer did not return, <the
failing check>`, per `## The landing`, with the `fix/<slug>` worktree and its branch staying in
place and named the same as a commit the run could not land.

A Fixer or a Gate fixer that committed something the run could not land is the one case that keeps
both: not Green, or a landing refused for any of the reasons above, and the worktree and the branch
stay where they are, named in the `## Fix run` section and in the reply, so the developer can read
what they did.

A Green Review of the branch the developer is already on, with no Fixer commit, has nothing to
land and says so.
