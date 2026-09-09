# The fix

What the orchestrator does once there is something to fix: read the `Act on` list, put the Fixer
where it belongs, brief it, re-run its work, append the record and land.
It is read by the orchestrator alone, and only when its argument is `fix` or when the Review it has just written
carries an `Act on` Finding. A `--no-fix` run and a Review with nothing to act on never open it,
and it is never by a reviewer: the reviewers judge a diff and are gone before any of this runs.

The parts it does not own it links and never restates: the two trees are
[worktrees.md](../../../.agents/worktrees.md), the section it appends is
[review-format.md](../../../.agents/formats/review-format.md), the landing rules are
[ADR 0013](../../../docs/adr/0013-do-code-review-lands-a-green-review-by-fast-forward.md), and why
the default run fixes at all is
[ADR 0015](../../../docs/adr/0015-the-default-review-run-fixes-and-lands-and-the-fixer-corrects-for-every-caller.md).

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

## The Act on list

Read the `## Act on` section off the Review on disk, in the file's order, naming each Finding
by its number, with its location, its `Claim:` and the behaviour and target its `Fix:` names. Nothing
under `## Consider`, `## Noted` or `## Cleared` is read, and nothing outside the section reaches
the Fixer.

The file is the hand-off, not the run's memory of what it found. On a `fix` call it was read and
edited by hand: the developer moved a `Consider` they want fixed into `Act on` and deleted an
`Act on` they overrule, so the list is whatever the file says now. A Finding they moved in may
carry no check in its `Fix:` line; that is allowed, and the re-check below reports it.

An empty list, or one whose Findings an earlier fix already settled, forks no Fixer and creates no
worktree. The re-check and the append still run, and the section reads `nothing remained`, so a
second `fix` on the same Review is harmless.

## Where the Fixer works

One question decides it: is the branch the Review judged the branch the developer's checkout is on?

- **No.** That is `do` at its review step: the branch is the `do/<slug>` worktree branch, and its
  worktree already exists. The Fixer works there, and the run removes nothing it did not create.
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

Either way the Fixer is forked from the tree it works in, so it needs no path argument: a fork runs
where it was forked. The run never changes its own working directory and never uses a worktree
tool, per the two-trees contract.

## The Fixer

One general-purpose sub-agent, forked with the Agent tool. It has no definition of its own: its
whole contract is the brief below, which is why this file exists. It gets the Review's location,
the branch it commits on, the `Act on` list in the file's order, and four rules.

1. **Follow the Testing Policy when one is installed.** Per Finding, dispatch the project's unit
   test author with the behaviour to prove and the target from the Finding's `Fix:` line, with
   origin `bugfix`, and the Finding's failure scenario as the expected red. Then implement, and commit the
   test and the fix as one commit whose body names the Finding by number. With no Testing Policy
   installed, write the failing test first yourself and commit the same way.
2. **Touch nothing else.** Nothing in `Consider`, `Noted` or `Cleared`, and nothing outside the
   `Act on` list, however tempting it looks on the way past. Those Buckets are the developer's
   judgment calls and this run does not make them.
3. **Leave what no longer matches.** Check the Finding's location against the tree before touching
   it. A location that has moved or gone is reported and left alone: no commit, and no guess at
   where the code went.
4. **Report each commit.** One line per Finding, by its number: the sha, or what stopped it.

Two branches end in no commit and are reported, never worked around:

- The Agent tool is withheld, so no test author can be dispatched. The Fixer writes nothing at all
  and says so, and every Finding comes back `not fixed: test author unreachable`. A fix that
  nothing proved is worse than no fix.
- A Finding whose test will not go green. The Fixer drops its own edits for that Finding,
  `git restore` over the paths it touched for it, makes no commit, and reports `not fixed` with the
  test's reason. Half a fix never reaches a commit.

## The re-check

The orchestrator proves the work itself, in the worktree, and never the Fixer's word for it,
per [prove-it-works](../../../.agents/principles/prove-it-works.md). Per `Act on` Finding, run the
check its `Fix:` line named; then run the project's suite once, the gate the Testing Policy names,
else the tests the reviewers already ran.

| What the run saw | The Finding reads |
|---|---|
| the Fixer committed it and the check passes | `fixed <sha>, verified` |
| the Fixer committed it and there is no check named | `fixed <sha>, not verified` |
| the Fixer reported the location no longer matches | `stale` |
| no commit, for either branch above | `not fixed` with the reason |

The two reviewers are not re-run on the Fixer's commits. A fresh review is another call, and each
Finding's own check plus the suite is what stands in for one.

## The append

Write the `## Fix run` section the format fixes, with the date, the commit the fix ran at, one line
per Finding by number, the suite's result and the landing line.

The orchestrator has no edit tool, on this call as on every other, so appending means writing the
whole file again with the section added, once, with the Write tool and never an edit. Read the Review off disk first:
on a `fix` call the developer edited it, so the file is the truth and the run's own memory of it is
not.

## The landing

The Review is Green when every `Act on` Finding reads `fixed` and `verified`, every Axis ran and
the suite is green. `Consider`, `Noted` and `Cleared` never block.

Green lands, under ADR 0013's rules and no others: the landing target is fast-forwarded to the
branch the Fixer committed on, `git -C <the main checkout> merge --ff-only <that branch>`; a
protected target is refused and named; the branch is rebased first when the target moved, and a
rebase conflict is aborted with the conflicting files named; a fast-forward that fails leaves
everything in place and is named. On every one of those paths nothing is pushed. The reply's last line is the push
command, `git push` with the landing target named, so the developer pushes when they choose and
nothing leaves the machine before then.

After a landing the run removes what it created and only that: the `fix/<slug>` worktree and its
branch, left from the main checkout with a bare `cd`, never `do`'s worktree. Not Green, or a
landing refused for any of the reasons above, and both stay in place, named in the `## Fix run`
section and in the reply, so the developer can read what the Fixer did.

A Green Review of the branch the developer is already on, with no Fixer commit, has nothing to
land and says so.
