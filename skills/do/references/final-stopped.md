# A stopped Final integration

Read by the session of a `ticket` run, from these places: the Door of [ticket.md](ticket.md), when
`ticket-door.sh` prints `verdict=resume-final` (a `resolved` Ticket whose Spec branch exists, has
not landed, in a Spec the door counts complete); and the Final integration, the final integration
of [mechanics.md](mechanics.md) and step 9a of [ticket.md](ticket.md), when it stops: a rebase
question nobody answered, a red gate, a Review that did not land, or a stop of the review's own. A
run none of them sends here never opens it.

## The stop

A rebase question nobody answered, a red gate, a Review that did not land, or a stop of the
review's own (Read [not-landed.md](not-landed.md) when the review's `route=` line reads anything
but `route=verify`): the run stops as blocked and makes no `release` call. The tree, the Spec
branch and the claim file all stay in place, since they are what a later run resumes from, and the
run's own Ticket stays `resolved`. Before its Reply, at every stop the run controls, a first run's
or a resume's, it yields the claim, so the `/do` that resumes can take it over:

```
bash <skill-dir>/scripts/final-claim.sh yield <the Ticket's path> | tee <state>/yield
```

The yield marks the claim as given up and leaves the claim file as it was written, so the claim
still keeps a first run out while a resume can take it over, per ADR 0063. A run that died yields
nothing, and its claim reads `taken` to every resume until the developer yields it by hand. The
Reply says the Final integration stopped and why, and that `/do <the run's Ticket>`, or a `do` on
any Ticket of the Spec, resumes it, per [reply.md](reply.md).

A stop touches this repository's landing and no other's. A repository of the feature that landed
before it stays landed: the run moves no ref there, reverts nothing and removes nothing, since
what landed was reviewed and is already the developer's to push, per ADR 0084. So that a partial
landing is never silent, the run reads the landing record once more after the yield, the same
`landing-order.sh` call saved over `<state>/order`, on a first run and on a resume alike, and the
Reply's lines are printed from that read.

A resume that stops again yields the claim it holds before its Reply, as every stop of the Final
integration does, so the next `/do` can take it over. Its blocker is the lines step 9a of
[ticket.md](ticket.md) has `reply-lines.sh final` print, with `--state <state>/state` added, and
its Next step is the same `/do`.

## The resume

Entered on the door's `verdict=resume-final` and on nothing else. The Ticket handed over is
`resolved` and stays as the close left it: it is only the way in, and any Ticket of the Spec leads
to the same Spec branch, the same tree, the same ledger and the same claim. The run walks the final
integration of [mechanics.md](mechanics.md) from where it stopped, and nothing before it: no Digest,
no Plan, no Builder, no `do/<slug>` worktree. Steps 1 to 9 of the checklist are never reached, so
they are neither ticked nor skipped, and the Run report's Run section carries steps 0, 9a and 10.

The same entry is the landing command of a feature across repositories: a `do` on a `resolved`
Ticket built in the session's repository, typed there once every repository it consumes from has
landed, per
[ADR 0084](../../../docs/adr/0084-a-feature-across-repositories-lands-in-sequence-and-what-landed-stays.md).
Nothing stopped in that repository, since its Final integration never started, and the steps are
the same: the claim is fresh, the state reads `verdict=restart` with `worktree=absent`, and from
there the run is a first Final integration of this repository and of no other, with the **Gate**
of this project's facts and the Review at the `review_file=` path the claim prints.

1. **The landing record.** `bash <skill-dir>/scripts/landing-order.sh <the Ticket's path> | tee <state>/order`, before
   the claim and in a call of its own, as step 9a of [ticket.md](ticket.md) reads it on the run that completes the feature.
   The record's lines are kept as printed, `repositories=` among them, and handed, as printed, to
   `bash <skill-dir>/scripts/landing-route.sh resume` on stdin. The run routes on the one `route=`
   line it prints and chooses no route from the record itself:
   - `route=claim`: the run goes on to the claim of step 2.
   - `route=out-of-order`: the run stops here, before the claim, as below.
   - `route=skip-landed`, `route=skip-elsewhere`, `route=skip-open`, `route=blocked-ambiguous`,
     `route=blocked-unordered` or `route=blocked-no-spec`: the run takes the route step 9a gives
     the same `route=` line, and claims nothing.
   - An exit 2 stops the run as blocked with the script's stderr line quoted, and claims nothing.

   On `route=out-of-order` a repository this one consumes from has not landed: the landing command was
   typed out of order, and the run stops here, before the claim. Nothing is integrated and
   nothing is written: no claim file under this repository's key, no `spec-<feature-slug>`
   worktree, no rebase, no review, no ref moved in any repository. The message is the first line,
   then the lines `bash <skill-dir>/scripts/reply-lines.sh final --door <state>/door --order <state>/order`
   printed, then the lines `reply-lines.sh repositories` printed from the same two files, copied
   as they stand, and carries no section of a Reply, no `Yours:` line, since there is nothing to
   choose, and no shell line. Under `--auto` the stop is the same lines, with no `choice-taker`
   forked.
2. **The claim.** `bash <skill-dir>/scripts/final-claim.sh claim <the Ticket's path> | tee <state>/claim`, before
   anything is read from the tree, so two resumes never both walk it.
   - `claim=claimed` with `takeover=yes`: the run that stopped yielded its claim and this run holds
     it now. Of two resumes at once exactly one reads `claimed`. The `previous_ticket=`, `previous_claimed_at=` and `yielded_at=` lines are recorded
     for the Run report. `takeover=no` means no claim file was there, and the run holds a fresh one.
   - `claim=taken`, exit 1: a claim nobody yielded. Its holder is either still integrating or died
     without yielding, and the script cannot tell which, so the run stops in one line and writes
     nothing, per ADR 0063. The blocker is the line `reply-lines.sh final` prints from `<state>`,
     the Reply quotes `yield_command=` as the script printed it, and carries `Yours: direction:`, per [reply.md](reply.md): wait for that run, or, when
     it is dead, run the yield command and then the same `/do` again. The run composes no command
     of its own for it and never yields another holder's claim itself.
   - `claim=failed`, exit 3: the run stops as blocked with the `reason=` line quoted.
3. **Where it stopped.** `bash <skill-dir>/scripts/final-state.sh <the Ticket's path> | tee <state>/state`, read once,
   the Final integration's counterpart of `resume-state.sh`: the paths the claim printed, the
   `token_slug=` the review token is stored under, the claim as it now stands, `worktree=`, and for
   a tree that is there `rebase=`, the `uncommitted=` lines, the stop record of an open rebase in
   the keys a Ticket run's resume reads, and `review=` for the Review beside the Spec, with a
   `review_skipped=` line before it when one is there and does not count. The run routes on its
   verdict:
   - `verdict=restart`, exit 0: nothing is open. With `worktree=absent` the run adds the tree, step
     2 of the final integration, then rebases; with `worktree=present` it enters the tree and goes
     to the rebase, step 3, whose ancestor check ticks as a no-op when the stop came after it. From
     there the run is a first Final integration: the gate, the review, the release.
   - `verdict=integration`, exit 3: a rebase is open in the tree.
     Read [resume.md](resume.md) when final-state.sh prints verdict=integration: the run reads the `stop=` line
     before it touches the rebase and does what its mid-rebase bullet says for each class,
     with the Spec branch as the branch that moves and `spec_upstream` as the developer's branch:
     `stop=conflicted` is classed and resolved as at any stop, `stop=resolved` asks
     `(continue / stop)`, `stop=moved` continues on `moved=continue` and asks
     `(abort / continue)` on `moved=ask`, each question in the words of that bullet.
     Under `--auto` the `(abort / continue)` question is still asked of the developer, with the
     `choice-taker`'s return above it as that bullet says, per [forks.md](forks.md).
     A `review=`
     line naming a Review means the rebase came after the review, so the branch lands through the
     fix call once it finishes. Read [not-landed.md](not-landed.md) when the run lands through the fix call on a Review it already has.
   - `verdict=ask`, exit 1: uncommitted work in the tree with no rebase open.
     Read [resume.md](resume.md) when final-state.sh prints verdict=ask: the run asks before
     discarding it, as its `verdict=ask` bullet says, naming the tree and the Spec branch. A
     yes discards it and the run goes on as `verdict=restart` with the tree present; a no stops the
     run. Under `--auto` the question is still asked of the developer, with the `choice-taker`'s
     return above it as that bullet says, per [forks.md](forks.md), and nothing is discarded on
     that return.
   - `verdict=land`, exit 4: the Review beside the Spec counts, so the review already read the
     Spec branch. The run integrates with no **Gate** of its own and lands through the fix call on
     that Review, as the review in [mechanics.md](mechanics.md) says for a branch the review
     already read, never a second review of the Spec. Read [not-landed.md](not-landed.md) when the run lands through the fix call on a Review it already has.
   - Exit 2: the tree is on a detached HEAD or on another branch with no rebase open. The run stops
     as blocked in one line naming the tree and the script's reason.
4. **The rest of the final integration**, from the step the verdict named, ending in the release on
   `landed at <commit>`. Read [not-landed.md](not-landed.md) when the review's `route=` line reads
   anything but `route=verify`: a moved target is answered there as on a first Final integration,
   for as long as the target's tip keeps changing. After `claim=released`, when the record of step 1 printed `repositories=` above 1,
   the same `landing-order.sh` call a second time, as step 9a of [ticket.md](ticket.md) makes it, saved over
   `<state>/order`: the Reply's lines are printed from this second read, which counts this
   repository as landed, and never from the first.

A resume that finishes ends as the run that ships a Spec ends: the Spec branch landed and removed, the claim released, the Reply and the Next
step of the landed Final integration in [reply.md](reply.md). On a feature of more than one
repository it reads the landing record after the release, the `landing-order.sh` call of step 9a of [ticket.md](ticket.md),
and its Reply's lines are printed by the `reply-lines.sh` calls of step 9a, with
`--state <state>/state` added to `final`. It lands this repository and no other: one that landed before the stop is read by
that record and never claimed, rebased or reviewed again.
