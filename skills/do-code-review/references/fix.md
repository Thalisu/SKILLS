# The fix

What the orchestrator does once there is something to fix: read the `Act on` list, put the Fixers
where they belong, fork them one at a time, re-run their work, hold it to the Diff tests and the
Gate, append the record and land.
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
red flow, or a rebase a resumed run finished. It sends the landing target and the Gate after the
Review's location, and the call forks no reviewer: a Finding the first call left `not fixed` goes to
a Fixer again, and a list with nothing left in it comes down to the Gate and the landing.

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
so a second `fix` on the same Review is harmless.

## Where the Fixer works

One question decides it: is the branch the Review judged the branch the developer's checkout is on?

- **No.** That is `do` at its review step: the branch is the `do/<slug>` worktree branch, and its
  worktree already exists. The Fixers work there, and the run removes nothing it did not create.
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

Either way every Fixer, and the Gate fixer, is forked from the tree it works in, so it needs no
path argument: a fork runs where it was forked. The run never changes its own working directory and
never uses a worktree tool, per the two-trees contract.

## The Fixer

One Fixer per `Act on` Finding, one at a time, in the file's order: each is a general-purpose
sub-agent forked with the Agent tool, and the next is forked only once the one before it returned.
They all write in the one tree, so they are never two at once, per
[separate-before-serializing-shared-state](../../../.agents/principles/separate-before-serializing-shared-state.md):
a test author running its red against another Fixer's half-made edit proves nothing, and two
commits at once fight over the index. A Fixer holds its one Finding and nothing else, so its
window stays the size of that Finding. It has no definition of its own: its whole contract is the
brief below, which is why this file exists. It gets the Review's location, the branch it commits
on, its one Finding with its number, location, `Claim:` and `Fix:` line, and four rules.

1. **Follow the Testing Policy when one is installed.** Dispatch the project's unit test author
   with the behaviour to prove and the target from the Finding's `Fix:` line, with
   origin `bugfix`, and the Finding's failure scenario as the expected red. Then implement, and commit the
   test and the fix as one commit whose body names the Finding by number. With no Testing Policy
   installed, write the failing test first yourself and commit the same way.
2. **Touch nothing else.** Nothing outside its Finding: not another `Act on` Finding, which has a
   Fixer of its own, and nothing in `Consider`, `Noted` or `Cleared`, however tempting it looks on
   the way past. Those Buckets are the developer's judgment calls and this run does not make them.
3. **Leave what no longer matches.** Check the Finding's location against the tree before touching
   it. A location that has moved or gone is reported and left alone: no commit, and no guess at
   where the code went.
4. **Report each commit.** One line for its Finding, by its number: the sha, or what stopped it.

Two branches end in no commit and are reported, never worked around:

- The Agent tool is withheld, so no test author can be dispatched. The Fixer writes nothing at all
  and says so, and its Finding comes back `not fixed: test author unreachable`. No further Fixer is
  forked, since each would meet the same wall, and every Finding left reads the same. A fix that
  nothing proved is worse than no fix.
- A Finding whose test will not go green. The Fixer drops its own edits for that Finding,
  `git restore` over the paths it touched for it, makes no commit, and reports `not fixed` with the
  test's reason. Half a fix never reaches a commit, and the next Fixer starts on a clean tree.

## The re-check

The orchestrator proves the work itself, in the worktree, and never the Fixer's word for it,
per [prove-it-works](../../../.agents/principles/prove-it-works.md). Once the last Fixer returned,
per `Act on` Finding, run the check its `Fix:` line named.

| What the run saw | The Finding reads |
|---|---|
| the Fixer committed it and the check passes | `fixed <sha>, verified` |
| the Fixer committed it and there is no check named | `fixed <sha>, not verified` |
| the Fixer reported the location no longer matches | `stale` |
| no commit, for either branch above | `not fixed` with the reason |

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
the tree the Fixers committed in, and reads its `verdict=` line: it reruns `do`'s own gate, so the
review holds its fixes to the checks `do` held the build to. With no line handed, on a plain call,
the Gate is each command the Testing Policy's Project facts carry for those four checks, else the
tests the reviewers ran. A Review with nothing in `Act on` runs it too, at the start of the landing.

- Green, and the run goes to the append and the landing.
- Red after a Fixer committed: the Gate fixer takes the red block.
- Red with no Fixer commit: the red is the branch's own and not the fixes', so no Gate fixer runs,
  and the landing line reads `not landed: gate red, <the failing check>`.
- `verdict=blocked`: a check failed on its environment and not on the code. Nothing lands, the
  landing line reads `not landed: gate blocked, <its cause= line>`, and nothing is worked around.

## The Gate fixer

One general-purpose sub-agent, forked when the Diff tests or the Gate come back red after a Fixer
committed, with two attempts in all, shared by both checks. Its brief is the red block as the check
printed it, the capped lines and never the full log or the Review, the branch it commits on, and
four rules:

1. **Fix the code, never the check.** Never a skipped test, a weakened assertion or a sleep. A
   test whose assertion it would have to change to pass is reported, never changed: an assertion
   is the test author's under the Testing Policy.
2. **Keep every Finding's test green.** The tests the Fixers committed prove the Findings, and an
   attempt that turns one of them red has broken a fix.
3. **Touch nothing the red block does not point at.**
4. **One commit per attempt**, its body naming the check it turned green, and one line back: the
   sha, or what stopped it.

After each attempt the orchestrator runs every Finding's check, the Diff tests and the Gate again
itself, and never takes the Gate fixer's word for it. Green, and the run goes on. Red after the
second attempt, and the Review is not Green: nothing lands, the landing line reads
`not landed: gate red after the fixes, <the failing check>`, and the branch and its worktree stay
in place, so the developer can read what each Fixer and the Gate fixer did. Two attempts and no
third, since a red that survives both is a diff that is not converging, and one more attempt costs
another window with nothing to show that it will close.

## The append

Write the `## Fix run` section the format fixes, with the date, the commit the fix ran at, one line
per Finding by number, the Diff tests, the Gate fixer, the Gate and the landing line.

The orchestrator has no edit tool, on this call as on every other, so appending means writing the
whole file again with the section added, once, with the Write tool and never an edit. Read the Review off disk first:
on a `fix` call the developer edited it, so the file is the truth and the run's own memory of it is
not.

## The landing

The Review is Green when every `Act on` Finding reads `fixed` and `verified`, every Axis ran and
the Gate is green. `Consider`, `Noted` and `Cleared` never block.

Green lands, under ADR 0013's rules as ADR 0027 amends them and no others: the landing target is
fast-forwarded to the branch the Fixers committed on,
`git -C <the main checkout> merge --ff-only <that branch>`; a protected target is refused and
named; a target that moved while the review ran is retried once, as below; a fast-forward that
fails for any other reason leaves everything in place and is named. On every one of those paths
nothing is pushed. The reply's last line is the push command, `git push` with the landing target
named, so the developer pushes when they choose and nothing leaves the machine before then.

### A target that moved while the review ran

The developer may commit on the landing target while the review runs. The target is then no longer
an ancestor of the branch, which is what tells this case from any other failed fast-forward:
`git merge-base --is-ancestor <the landing target> <that branch>` fails. The landing retries once,
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
3. Every hunk `mechanical`: the orchestrator resolves them itself by keeping both sides in base
   order, the rule `do`'s integration applies, restated here for the same reason. The conflicted
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
       git merge-file --union -p "$stages/target" "$stages/base" "$stages/incoming" > "$file"
   done
   rm -rf "$stages"
   ```

   Stage 2 is the landing target and stage 3 the commit being replayed, so the union keeps the
   target's lines above the replayed commit's. Once every union is read back with the Read tool,
   never through a command line, as step 4 needs, the second block marks the files resolved:

   ```
   git diff --name-only --diff-filter=U -z | xargs -0 git add --
   ```

   Then `rebase --continue`, and every further stop is classed and resolved the same way. A
   replayed commit the resolution left empty is already on the target: `rebase --skip`, and the
   landing line names it.
4. Any hunk `contested`, or a union that, read back before its `git add`, defines one key twice in
   one scope of a file whose reader keeps the last definition it meets (JSON, YAML, TOML, an INI or
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
   pushed, and the rebased branch and its worktree stay in place. Green, and the target is
   fast-forwarded as above, once: a second failure is a failed fast-forward and is named.

The landing line then names the rebase onto the moved target with the hunks it resolved, one line
each, in the shape [review-format.md](../../../.agents/formats/review-format.md) fixes.

After a landing the run removes what it created and only that: the `fix/<slug>` worktree and its
branch, left from the main checkout with a bare `cd`, never `do`'s worktree. A run whose Fixers
made no commit at all removes them on the same rule, the withheld Agent tool included: a
`fix/<slug>` worktree holding no commit of its own sits on a branch identical to the developer's
HEAD and holds nothing to read, and the `## Fix run` section says nothing was fixed and why. What
the run did not create it never removes: on `do`'s worktree it removes nothing, whatever the
Fixers did.

A Fixer or a Gate fixer that committed something the run could not land is the one case that keeps
both: not Green, or a landing refused for any of the reasons above, and the worktree and the branch
stay where they are, named in the `## Fix run` section and in the reply, so the developer can read
what they did.

A Green Review of the branch the developer is already on, with no Fixer commit, has nothing to
land and says so.
