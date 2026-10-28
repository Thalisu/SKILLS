# The resume of a ticket run

Read by the session of a `ticket` run, from these places of [ticket.md](ticket.md): the Door, when
the door prints `verdict=resume` (a `claimed` Ticket whose `do/<slug>` worktree exists); the review
step, through not-landed.md, when `review-route.sh` prints `route=resume`, for the all-ticked bullet
in the same run; the build step, when a Builder's return fails its checks, to pick the stretch up
from what `resume-state.sh` printed; and the stopped Final integration, when `final-state.sh` prints
`verdict=integration` (for the mid-rebase bullet, with the Spec branch as the branch that moves) or
`verdict=ask` (for the discard question). A run none of them sends here never opens it. The steps
named below are the steps of [ticket.md](ticket.md).

## Resume

The run reads `resume-state.sh`, as below, before the Digest decision of the Door of
[ticket.md](ticket.md). On `verdict=land` the run forks no reader, and neither does it on any resume
whose `review=` line names a Review, whatever the verdict printed, `land` or `integration` on a
rebase stopped after that review, and whatever the Digest's state, a hash that differs or no Digest
at all: only the integration and the landing are left, and nothing they run opens a Digest. A
resume whose `review=` line reads `none` goes on to the Digest decision.

A resumed Ticket is a Ticket of a Spec when its door printed `spec_exists=yes` as well as a
`spec_branch=` other than `none`. A resumed `claimed` Ticket whose door printed `spec_exists=no`
keeps the review and the landing on the developer's branch, as a Ticket with no Spec does: its
`do/<slug>` worktree was cut from the developer's branch before Spec branches existed and no Spec
branch was ever cut, so it finishes on the old flow, nothing migrates it, and `resume-state.sh`
prints the developer's branch as its `base=`, the same key read in both places.

A `claimed` Ticket whose `do/<slug>` worktree exists, an entry of `git worktree list` at that path,
is picked up where the last run stopped and never restarted. The state a resume reads is
the branch and its worktree, never a run-state file: the commits since the developer's branch,
`git log <base>..do/<slug>` with `<base>` their merge base, each with the `Behaviour:` line its
body carries per the build loop in [build-loop.md](build-loop.md), and the working tree,
`git status --short` in the worktree. The run reads all of it from one script,
`bash <skill-dir>/scripts/resume-state.sh <the Ticket's path>`: `worktree=` and `branch=`, one
`commit=` line per commit with the `behaviour=` line its body carries under it, one `uncommitted=`
line per file, `review=`, the Review beside the Ticket or `none`, with a `review_skipped=` line
before it when a Review there does not count (`stale`, a Review of a commit this branch was never
at, left by a run that started over; `axis-not-run`, a review that never finished; `unmarked`, a
Review with no `.review.marker` beside it naming the same commit, so nothing ties the file to a
review the run's own review step ran), since only a
finished review of this branch spares a second one, and a `verdict=` line, `build`
(exit 0), `ask` (exit 1, uncommitted work), `integration` (exit 3, a rebase left open, with the
`stopped=`, `onto=`, `tip=`, `staged=` and `stop=` lines that say what it holds), `land`
(exit 4, the review already read the branch) or `extreme` (exit 5, the sidecar an Extreme stop
left is beside the Ticket, with the `extreme=` and `discuss=` lines that carry it). The Ticket is
not written: the claim stands.
Exit 2 after the door's `resume` is a worktree on a detached HEAD with no rebase open:
the run stops as blocked in one line naming the worktree and the script's reason, writes nothing,
and leaves the worktree as it is, since no branch can be read from it to build on.

- The run records the resume line for the Run report's Run section, per [reply.md](reply.md): it says
  the run resumed, names the worktree and its branch, and lists the commits found, one line each
  with its `Behaviour:` line, off the script's lines. The claim line is not written again. The
  Run report's Run section carries the checklist with steps 0 and 2 reading `done: resumed`.
- The worktree is entered, never created: a second worktree is never made.
- An `extreme=` line means an earlier run stopped on an Extreme fork and left its sidecar, per the
  forks in [forks.md](forks.md). It is read on `verdict=extreme` and on `verdict=ask` alike, since
  the script prints `ask` first and a Builder stopped mid-behaviour can leave uncommitted work. The
  door's Digest decision settles it before anything below runs, the `extreme=` value passed to the
  digest check as its fourth argument:

  ```sh
  bash <skill-dir>/scripts/grounding.sh digest <root> <ticket=> <the Digest's path> <the extreme= value>
  ```

  - `verdict=extreme` (exit 5): the run stops again as blocked, by the blocked shape.
    Read [blocked-reply.md](blocked-reply.md) when the run stops again as blocked here. The reply names what the Extreme stop names, the fork's
    own facts read off the `discuss=` line and the commits off the script's `commit=` lines, and
    its last line is the `discuss=` line whole. The run forks no Planner, no Builder and no
    `choice-taker`, since judging the fork a second time could read it the other way, and it asks
    nothing about uncommitted work, since a stopped run discards none.
  - `extreme=removed`, with `verdict=fork` (exit 1): the Spec was amended, by `discuss` or by hand,
    and the check removed the sidecar. The run forks the reader as on any `verdict=fork` and goes
    on as the amended-Spec bullet below says, with `verdict=extreme` read as `build` and
    `verdict=ask` handled by its own bullet.
- On every verdict but `land`, the Plan step runs again as step 1 says, unless `review=` names a
  Review, which skips it as the `verdict=land` bullet says: the run runs `grounding.sh plan` as
  step 1 says and reuses the Plan beside the Ticket on `verdict=carried`, and on `verdict=fork`
  the script has removed a stale Plan and the Planner is forked again, per step 1, which writes
  the Plan anew at the same path. That is the state of a
  Ticket an earlier run stopped on mid-build for work in another repository, once its new blocker
  is `resolved`: `tickets` moved a criterion out of it, so its hash changed. Before that fork, the
  run calls `bash <skill-dir>/scripts/resume-tick.sh built <the Ticket's path>` and puts each
  `built=` value under the brief's `Built:` key, one per line, in the order printed, per
  [plan.md](plan.md). `built=none` is an empty list. The session strips and filters nothing itself.
- Once the Plan is at its path, reused or written anew, the run calls
  `bash <skill-dir>/scripts/resume-tick.sh tick <the Ticket's path> <the Plan's path>`. The list
  the loop works through is the Plan's `## Behaviours` section either way, and the script reads it
  there. The run quotes every `item=` line as the ticks, an `item=<n> <sha>` ticked and an
  `item=<n> open` not, and names every `stray=` line on the resume line. It never ticks a line or
  matches two texts itself.
- On exit 0, `route=build`: the Builder is forked at the item `next=` names, per step 3, and from
  there the run is a first run: the diff, the gate, the review, the close, the reply. On exit 1,
  `route=resumed`, every line of the list is ticked, and the run takes the route the bullets
  below give for that case.
- On `verdict=land`, the review already read this branch, and so it did whenever `review=` names a
  Review, whatever the verdict printed, `land` or `integration` on a rebase stopped after that
  review: its Review is the script's `review=` line, and the review runs once per run, per
  [ADR 0033](../../../docs/adr/0033-the-review-runs-once-per-run-and-what-comes-after-it-lands-through-the-gate-alone.md),
  so the resume is never a second review. Only the landing is left, so the Plan step is skipped:
  the run forks no Planner, and no Plan is hashed, checked or opened, whatever state the one beside
  the Ticket is in, carried, stale or absent. The Run report's Run section carries the checklist with
  step 1 reading `skip: resumed, only the landing left`, and step 3 is never reached, so its second
  reading of the Plan never runs either. The one part of step 1 that still runs is its context
  reading, `bash <skill-dir>/scripts/context-usage.sh`, taken where the skipped step would have
  ended, so the close still has a `grounded` figure for its `Context:` line. The loop is skipped, the integration runs with no
  **Gate** of the run's own after it,
  and the branch lands through the fix call on that Review, as the review in
  [mechanics.md](mechanics.md) says for a branch the review already read.
  Read [not-landed.md](not-landed.md) when the run lands through the fix call on a Review it already has.
- On a Ticket of a Spec, one whose door printed `spec_exists=yes`, the script prints
  `base=spec/<feature-slug>` and reads `merge_base`, `tip`
  and `stop=` against that branch, so wherever a bullet of this section says the developer's
  branch, the Spec branch is meant. No Review is ever written beside such a Ticket, so the verdict
  is never `land`. When every line of the list is ticked, as after a landing refused with
  `checked-out` or a run stopped at its Gate, step 3 reads `done: resumed`, no Builder is forked,
  and the run goes on at step 4, then the **Gate** of step 5, the integration of step 6 onto the
  Spec branch and the landing of step 7. That is how a run requested again after a refused landing
  resumes at the landing.
- When every line of the list is ticked on a Ticket with no Spec, as on the branch a moved target
  leaves right after an integration that ticked as a no-op (Read [not-landed.md](not-landed.md)
  when the review route sends the run here in the same run),
  whether a later run finds it or the same run takes this path at step 7 without a second request,
  step 3 reads `done: resumed` and the run never waits on a Builder with nothing left to build. It
  goes on at step 4 as a first run does, reading the diff already on the branch, its flows counting
  as authored, then the integration with no
  **Gate** of the run's own, which resolves each contested hunk the review's landing left to the
  **Target** side and writes its **Incoming** side to the Loss ledger beside the Ticket, then the
  landing through the fix call on the Review that return names, never a second review,
  as the bullet above says.
- On `verdict=ask`, the run asks before discarding the uncommitted changes in the worktree, since
  the discard is the one irreversible act on this path. The question is the turn's final message:
  it says the run resumes, names the worktree and its branch, and names the changes one line per
  file from the script's `uncommitted=` lines, which are `git status --short`'s.
  Nothing is discarded without the answer: no stash, no commit and no restore comes before it, and
  the run does not answer its own question or go on building. A yes discards them,
  `git restore --staged --worktree .` then `git clean -fd` in the worktree, and the first
  behaviour without a commit restarts red-first;
  a no stops the run with the worktree as it is, the reply naming it and its branch.
  Under `--auto` the question is still asked of the developer, in the same place and the same
  words, and still nothing is stashed, committed or restored before their answer. It carries what
  the `choice-taker` would have answered: the agent is forked on the question first and its return
  rides above the question as it came back, per the questions still asked under the flag in
  [forks.md](forks.md). The brief's `Options:` are `yes: discard the uncommitted changes and
  restart the first behaviour without a commit` and `no: stop the run with the worktree as it
  is`, and its `Context:` carries the `uncommitted=` lines. The run discards nothing on that
  return.
- A worktree the integration left mid-rebase is resumed like any other, and never started over: the
  stop leaves a detached HEAD, so `git worktree list` names the path without the branch and
  `git branch --show-current` in it comes back empty, while the branch itself is still there and a
  second `git worktree add <path> -b do/<slug>` would die on it. The branch is read from the rebase
  state, `cat "$(git rev-parse --git-path rebase-merge/head-name)"`, which holds
  `refs/heads/do/<slug>` while the rebase is open, never from `git branch --show-current`. The
  resume line the Run report's Run section carries names the worktree and that branch, lists the commits
  found, says the rebase is open, names the files git left conflicted, and names each file the
  conflict class printed `trusted` as the hand resolution the run kept, and the run picks up at the
  integration in [mechanics.md](mechanics.md) rather than at the build loop. What it does there is
  the script's `stop=` line, read before it touches the rebase, and never the session's own reading
  of the rebase state:
  - `stop=conflicted`: the rebase is open onto the tip of the developer's branch with a file still
    unmerged. The run classes the stop with the door script before it touches anything, and the
    stop is resolved as at any stop of the integration.
  - `stop=resolved`: the rebase is open onto that tip with no conflicted file. Whatever is staged
    for the commit it stopped at was staged with nobody's answer recorded, so it is not the run's
    to land. The question is the turn's final message and nothing is continued before the answer:

    ```
    The integration's rebase is stopped at <stopped> with no conflicted file, and this is staged for it:
    <one staged= path per line, or: nothing staged>
    Nobody's answer is recorded for it. Continue the rebase, committing it as staged, or stop here? (continue / stop)
    ```

    `continue` runs the continue with the integration's prefix, and every further stop is classed as
    in any run. `stop`, or nobody there to answer, stops the run as blocked with the rebase left
    open, `git rebase --abort` named as the undo, the worktree and its branch in place and named and
    the Ticket left `claimed`.

    Under `--auto` the question is not the turn's final message and the developer is not asked: it
    is a run question the `choice-taker` rules, per [forks.md](forks.md), and still nothing is
    continued before its return. The brief's `Question:` is the question above in one line, its
    `Options:` are `continue: continue the rebase, committing what is staged for <stopped>` and
    `stop: leave the rebase open and stop the run as blocked`, its `Recommendation:` is `none`,
    and its `Context:` carries the `staged=` lines. A Ruling for `continue` runs the continue as
    above and the run carries on to its close, and one for `stop` stops the run as blocked, as
    above.
  - `stop=moved`: the rebase is open onto a commit that is no longer the tip of the developer's
    branch, whatever else it holds. Finished as it stands, the branch would still sit behind that
    tip and could not land by fast-forward. The `moved=` line after it is the script's verdict on
    what the run does, never the run's own reading of the `dropped=` lines. On `moved=continue` the
    developer's branch only moved forward, as it does when another run landed while this one was
    cut short: the run takes `continue` below without asking, since it lands again nothing the
    branch no longer holds and keeps the hand resolution the stop holds, which an abort would throw
    away, and its resume line says it continued onto `<tip>`. On `moved=ask` at least one
    `dropped=` line is printed and a continue would land again commits the developer removed, which
    cannot be undone once landed, so the question is the turn's final message and nothing is
    continued or aborted before the answer:

    ```
    The integration's rebase is open onto <onto>, but <base> has moved to <tip>.
    abort: drop this rebase and rebase once onto <tip>. The abort drops what the stop at <stopped> holds:
    <one line per staged= and conflicted= path, per uncommitted= entry and per committed= commit>
    continue: finish this rebase onto <onto>, then integrate onto <tip>, which replays the branch again. The continue lands again what <base> no longer holds:
    <one line per dropped= commit>
    (abort / continue)
    ```

    A `dropped=` line is a commit `<onto>` holds and `<tip>` lacks, `git rev-list <tip>..<onto>`,
    printed when the developer rewound their branch past `<onto>`. The continue replays each one onto
    `<tip>` and the landing takes it with no second review, so the question names every one of them.

    `abort` runs `git -c rerere.enabled=false -c rerere.autoupdate=false rebase --abort`, which puts
    the branch back where it was before that rebase; the gate runs on the branch as it was, and a
    green gate goes on to the integration onto the tip, a fresh rebase whose stops are classed and
    whose contested hunks are handled as in any run. `continue` finishes the open rebase onto
    `<onto>`, each of its stops classed and resolved as in any run, then runs the integration again,
    which replays the branch onto the tip, and the gate runs after that replay. Nobody there to
    answer stops the run as blocked, the rebase left open, the worktree and its branch in place and
    named, the Ticket left `claimed`.

    Under `--auto` this question is still asked of the developer, in the same place and the same
    words, each side's drops named line by line as above: unlike the `(continue / stop)` question
    of `stop=resolved`, an abort drops work and a continue lands again what cannot be undone, so
    neither is taken on a Ruling. It carries what the `choice-taker` would have answered: the
    agent is forked on the question first and its return rides above the question as it came
    back, per the questions still asked under the flag in [forks.md](forks.md). The brief's
    `Options:` are `abort: drop this rebase and rebase once onto <tip>` and `continue: finish this
    rebase onto <onto>, then integrate onto <tip>`, and its `Context:` carries the lines the
    question shows. Nothing is aborted or continued on that return.

  A `review=` line that names a Review means the rebase came after the review: once it finishes,
  the branch lands through the fix call on that Review with no **Gate** of the run's own before it,
  and is never reviewed a second time. Read [not-landed.md](not-landed.md) when the run lands through the fix call on a Review it already has.
- A Spec amended while the Ticket is `claimed` is resumed the same way whoever amended it: `discuss`
  after a run stopped on an Extreme fork (the forks in [forks.md](forks.md)), or the
  developer editing a Ruling line in the Spec's Implementation Decisions to reverse it. No
  mechanism is added for either, and the rule does not fire on `verdict=land`: the review already
  read the branch and it lands as the `verdict=land` bullet says, and a Ruling reversed after that
  is built by a new Ticket, per
  [ADR 0038](../../../docs/adr/0038-a-ruling-reversed-after-its-ticket-landed-is-built-by-a-new-ticket-the-developer-writes.md).
  On every other verdict the digest check prints `moved=spec` and `verdict=fork`, so the run
  prints the one line naming the Spec as changed, and the reader is forked again over the amended Spec and
  the journey both, never over the Spec alone, whose Digest would come back with no Journey Path
  for step 1 to read. The list is re-derived from the Digest that comes back, every commit whose
  `Behaviour:` line still matches a line of it is kept, and the loop continues at the first
  behaviour without a commit, building the side the Spec now takes. A criterion an earlier Ruling
  rewrote to the side the developer's edit reversed is met at step 1 as a Design fork against the
  edited line, as the forks in [forks.md](forks.md) say. After an Extreme stop with the Spec
  unchanged, the digest check prints `verdict=extreme` and the resume stops on the sidecar's
  `discuss=` line, as the
  `extreme=` bullet above says.
