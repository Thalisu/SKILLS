# Not landed

## The routes

- `route=fix`, exit 1: the run integrates again, as `## Not landed: target moved` says, then makes
  the fix call from the `fix=`, `gate=` and `caller=` lines as printed, and routes its return with
  `last=fix`.
- `route=resume`, exit 3: the run takes its in-run Resume path once, as that section says, makes
  its fix call from the same lines, and routes its return with `last=resume`.
- `route=blocked`, exit 4: the run stops as blocked, as `## Not landed for any other reason`
  says, with the `reason=` line quoted, the `yours=` and `by_hand=` lines as printed, and the
  `undo=` line when one is printed.

## Not landed: target moved

On `not landed: target moved`, the developer's branch moved while the review ran, by the
developer's hand or by another run's landing, and the landing's own rebase met a hunk it does not
take or the branch moved again while its Gate ran. The run answers that return in the same run, per
[ADR 0034](../../../docs/adr/0034-a-contested-hunk-takes-the-target-side-and-what-it-sets-aside-is-reapplied-after-the-integration.md),
so the developer never types the request again only so that a human is present. It runs its
integration once more, in the worktree, onto the moved branch, as the integration of [mechanics.md](mechanics.md) says: every
contested hunk takes the **Target** side and its **Incoming** side goes to the same Loss ledger,
the Loss ledger judged and the reapplies brought back, with no **Gate** of the run's own after the
last of them. Each reapply goes through `check-reapply.sh` with its `replace` and `with` exactly as
[conflict-loop.md](conflict-loop.md) says,
and on this integration that check is the only reading its `with` text gets, since no reviewer
reads a commit made after the review: a block the script refuses writes nothing, is recorded
`none`, and is listed among this integration's drops, marked as coming after the review, as a line
of the Reply's Pending debt with or without `--auto`, and in the Run report under `--auto`. The integration hands the branch straight to the fix call on the Review the run already
has, as the paragraph below says for what the run commits after the review, never a second review:
the fix call gates the same tree itself and refuses to land it red, and this retry has no fixed
count, so a **Gate** here would pay for the suite twice on every lap, per
[ADR 0049](../../../docs/adr/0049-one-tree-is-gated-once-and-do-skips-the-gate-the-landing-call-runs.md).
The call is made whatever the Review holds and whatever the `Act on:` line of the return before it
read, and the run opens the Review neither to decide it nor to settle a Finding: a Finding a
commit on the branch already fixed is settled by the fix call's own re-check, per
[ADR 0056](../../../docs/adr/0056-the-fix-call-settles-a-finding-whose-fix-is-already-on-the-branch.md),
and one it cannot settle comes back in the call's landing line, which the run routes like any other
`not landed`. The call carries `Caller: do` and forks no Fixer, as the paragraph on what the
run commits after the review says, so a red **Gate** on that tree comes back as
`not landed: gate red` with its failing check, never the Gate fixer, and it stops the run as
blocked the way a red **Gate** after the first integration's reapplied commits stops it: the
failing check named, the ledger's location, and the `undo=` line the review route script prints,
`git reset --hard <the commit recorded before it started>`, which undoes the whole integration. The
worktree and its branch stay in place and are named, the Ticket stays `claimed`, nothing lands and
nothing is pushed. A blocked state of that integration stops the run as it stops it before the
review, with its own undo command. The retry has no fixed count, per
[ADR 0044](../../../docs/adr/0044-the-re-integration-retries-while-the-target-tip-changes.md): it
repeats for as long as each return routes `route=fix`, a `not landed: target moved` after an
integration whose `check` read `rebase` or `reapply`. A `not landed: target moved` right after an
integration that ticked as a no-op routes `route=resume` and ends the loop.

The run does not stop on it. It takes its own Resume path in the same run, the path a second run
request would have taken, since everything that path needs is a reversible action inside the run's
own artifacts, per
[ADR 0057](../../../docs/adr/0057-a-do-run-stops-only-on-a-handover-class-its-reply-names.md), and
the developer never types the request again only so that a human is present. The run already holds
what that path reads off `resume-state.sh`, every behaviour committed and the Review its own review
wrote, so it reads neither again. In `ticket` the path is the all-ticked bullet of the Resume of
[ticket.md](ticket.md): the integration run again, which resolves each contested hunk the review's
landing left to the **Target** side and writes its **Incoming** side to the ledger, the Loss ledger
judged and the reapplies brought back, with no **Gate** of the run's own, then the landing through
the fix call on the Review the run already has, never a second review. In `bug-fix` and
`refactoring` the path is the Resume of [bug-fix.md](bug-fix.md), the one step 2 of
[refactoring.md](refactoring.md) hands its resume to: the Review the run already has counts, so the run integrates again, its Loss ledger
keyed by the branch, and lands through the fix call on that Review. The run lands or stops on
that path's own outcome, and the integration line of the Run report's Run section carries the lines of
both integrations, per [reply.md](reply.md), never the resume as a next step.

That resume's fix call is routed with `last=resume`: a `not landed: target moved` after its
integration ticked as a no-op again routes `route=blocked`, and the run stops as blocked like every
other `not landed`; one after an integration that replayed commits routes `route=fix`, back in the
loop above.

## Not landed for any other reason

On `route=blocked` the run stops as blocked: the `reason=` line quoted, the worktree and its branch
left in place and named in the reply, the Ticket left `claimed`, nothing landed. The reply's
`Yours:` line, per [reply.md](reply.md), reads `direction`, keyed on the `direction=` line and
never on the session's own reading of the Review:

- `direction=findings`: the `yours=` line as printed, naming the open Findings of the `findings=`
  line, the Review, the worktree and the request to run again (the Ticket, or in `bug-fix` and
  `refactoring` the request that started the run).
- `direction=protected`: the `yours=` line as printed, then the two `by_hand=` lines as the Next
  step's commands, which the run types neither of.
- `direction=reason`: the session words the choice from the quoted reason, with the worktree and
  its branch: fix what it names in the worktree and request the run again, which resumes on the
  Review it has, or leave the branch unlanded. The run takes neither.

An `undo=` line, printed on a red gate after a fix call or the resume, is the undo command the
reply names.

## The fix call

**What the run commits after the review.** The review read the branch once, and nothing the run
commits after it is read by a reviewer again: the fix of a red flow, or a rebase a resumed run
finished after the review. Such a branch is handed to `do-code-review` with
`fix` with the Review's location, then the developer's branch as the landing target, and with no
**Gate** of the run's own over it first, so a second one here would pay for the suite twice, per
[ADR 0049](../../../docs/adr/0049-one-tree-is-gated-once-and-do-skips-the-gate-the-landing-call-runs.md).
A run whose own gate ran before the review hands the fix call the `command=` line that gate
printed: the fix call gates the same tree itself, from that very line, and refuses to land it red.
A run that reaches this point having run no gate of its own, the resume on `verdict=land` of
[ticket.md](ticket.md) and the resume of [bug-fix.md](bug-fix.md), has no such line to hand, since
the session that printed it was another run's: it hands the fix call no `command=` line, and the
fix call runs the Gate itself from the Testing Policy's Project facts, which is what a fix call
handed no `command=` line does. What that Gate ran
is in the fix call's return, which the Run report's gate line carries instead, per
[reply.md](reply.md).
On `route=fix` and `route=resume` the call is made from the lines the review route script printed,
as printed: `fix=` the call and its two arguments, `gate=` the `command=` line only when one was
given, and `caller=` the line that marks the call as the run's own.
Last of all the call carries one line that marks it as the run's own, after its one review:

```
Caller: do
```

Every fix call the run makes carries it: the landing after a `not landed: target moved`, the
landing of the in-run resume and of a resumed run, and the fix of a red flow, in `ticket`,
`bug-fix` and `refactoring` alike, and whatever the `Act on:` line of the return before it read.
No reviewer is forked, and on that line no Fixer and no Gate fixer either, since what the run
committed after the review is code no reviewer read: a Finding a commit on the branch already fixed
is settled by the call's own re-check, one it cannot settle comes back in its landing line, and a
list with nothing left comes down to the Gate and the landing. Its return reads like the first
one's, and a return that reads not landed stops the run the way the first one does.
