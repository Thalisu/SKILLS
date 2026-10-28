# bug-fix: the resume

A second run on a bug whose `do/<slug>` worktree or branch already exists continues that run and
never starts a second, per
[make-operations-idempotent](../../../.agents/principles/make-operations-idempotent.md). There is
no Ticket and no claim here, so the state a resume reads is the branch and its worktree alone,
never a run-state file: an entry of `git worktree list` on `do/<slug>`, then
`git branch --list do/<slug>` when no entry is there, the commits since the branch the first run
started from (`git log <base>..refs/heads/do/<slug>` with `<base>` the merge base of the developer's
branch and `refs/heads/do/<slug>`, qualified so a same-named tag can never shadow the branch), each with the
`Behaviour:` line its body carries per the build loop in [build-loop.md](build-loop.md), and
`git status --short` in the worktree.

- Step 1 probes before it creates. An existing worktree is entered with a bare `cd`: it is
  never created again. An existing branch with no worktree gets its worktree back on that
  branch, `git worktree add .claude/worktrees/do-<slug> do/<slug>`, without `-b`: `-b` on a
  branch that exists fails, and that failure is the state to read, not an error to work around
  with a second slug.
- The run records the resume line for the Run report's Run section, per [reply.md](reply.md): it says
  the run resumed, names the worktree and its branch, and lists the commits found, one line each
  with its `Behaviour:` line. Step 0's read-back, surface, predicate and loop line are recorded
  again from the request for the Run report's Run section, since nothing on the branch carries them,
  and the Run report's Run section carries the checklist with step 1 and every
  step the commits show as already done before the step the run resumes at, each ticked
  `done: resumed`: the worktree is never the only step ticked when the commits evidence more.
- The run continues at the first step the branch does not evidence: no commit resumes at step 2,
  with step 1 alone ticked `done: resumed`; the reproduction commit alone resumes at step 6, with
  steps 1 through 5 ticked `done: resumed`; the reproduction and its fix resume at step 7, with
  steps 1 through 6 ticked `done: resumed`. The reproduction is never committed twice, and from the
  step it resumes at the run is a first run.
- A Review of the branch, `.scratch/reviews/<the branch, each slash a dash>.md` in the main
  checkout, evidences the review step only when it read this branch and finished: the commit its
  `Commit:` header names is one the branch has been at,
  `git log -g --format=%H refs/heads/do/<slug>`, which a rebase does not erase; it is not reachable
  from the commit the branch was created at, the oldest entry of that reflog, since a branch made
  again from an unmoved HEAD has been at the commit an earlier branch's Review names; and none of
  its Axis lines reads `not run`. Any other Review there is an earlier branch's of the same name, or
  a review that never finished, and the review runs as on a first run. A Review that counts means
  the review already read the branch, and it runs once per run, per
  [ADR 0033](../../../docs/adr/0033-the-review-runs-once-per-run-and-what-comes-after-it-lands-through-the-gate-alone.md),
  so the run integrates and lands through the fix call on that Review with no **Gate** of the
  run's own before it, never a second review.
- Uncommitted changes in the worktree are asked about before they are discarded, since the discard
  is the one irreversible act on this path. The question is the turn's final message: it says the
  run resumes, names the worktree and its branch, and names the changes one line per file from
  `git status --short`. A yes discards them, `git restore --staged --worktree .` then
  `git clean -fd` in the worktree; a no stops the run with the worktree as it is, the blocker's line
  naming it and its branch, and hands the changes over as work the run did not make:
  `Yours: destroy: discard the uncommitted changes in <worktree>, or commit or move them yourself, then type the request again`.
  Under `--auto` the question is still asked of the developer, in the same place and the same
  words, with the `choice-taker`'s return shown above it as it came back, per the questions still
  asked under the flag in [Run questions under `--auto`](bug-fix.md#run-questions-under---auto),
  and nothing is discarded on that return.
- A run that stopped as blocked resumes the same way once its reason is gone, since every stop on
  this path but one leaves the worktree and its branch in place and named: the developer's no at
  step 2 or step 7, a `discuss` stop at step 4 once the design is settled. The one is a bug that
  does not reproduce at step 2: nothing was built, so that stop removes what it cut, and the next
  run on the bug is a first run.
