# A contested hunk takes the Target side, and what it sets aside is reapplied after the integration

Every `contested` hunk is resolved by the door script to the **Target** side, and its **Incoming**
side is written whole to a **Loss ledger**, one entry per hunk id. Once the integration finishes, a
read-only agent judges each entry `reapply` or `drop` with its reason, the session applies every
`reapply` as its own commit on top, and the **Gate** runs whole after the last one. Nobody is asked
anything: the human answer ADR 0028 relied on stalled every run with no human reachable and cost a
round trip per hunk otherwise. The one judgment left to a model now produces commits a reviewer
reads, instead of an edit buried inside the replay. This supersedes the rule of ADR 0028 that a
contested hunk is the human's to answer. The class stays a script's verdict.

## Considered options

- An agent writing a merged hunk per conflict, favouring the Target: the ledger would record only
  what the agent noticed it dropped, and a line lost without the agent noticing would reach the
  branch with no trace anywhere.
- Keeping the developer's answer per hunk, with the agent only where no human is reachable: two
  resolution paths to keep in step, and the questions this change exists to remove.

## Consequences

ADR 0027 placed the rebase in the session because a contested hunk needed a human. That reason is
gone, but the placement stands, since the reapplied commits need a writer and the review never
edits code. `do-code-review`'s landing still resolves only the mechanical class and returns
`not landed: target moved` for the rest. `do` now answers that return in the same run: it runs its
integration once more and lands through `fix`, per ADR 0033, instead of stopping for a second
`/do`. A second move of the target stops the run. `contested.sh` loses its question mode, its
`no human` exit and the `both` and `stop` answers, so a `claude -p` run now finishes an integration
it used to abort.

ADR 0044 supersedes the rule above that a second move of the target stops the run: the
integration retries for as long as each attempt meets a new tip.

Amended: the `integrate` Playbook of ADR 0029 runs no **Gate** after its reapplied commits. A
**Gate** guards a landing or a review, and `integrate` has neither. No **Gate** ran green before
its operation, so a red one could not tell a break the operation caused from one the branch
already carried, and the run may not edit the developer's code to chase green. Its Reply carries
the unchecked tree as Pending debt instead, whenever any stop resolved a hunk, mechanical or
contested, since the union's text reaches the branch as unchecked as a reapply commit does. No
eval yet covers a contested hunk or a reapply in `integrate`; that gap is open debt, closed by a
case under `skills/do/evals/` whose stop carries a contested hunk.

Amended: per ADR 0113, the reasons `mechanics.md` and `not-landed.md` gave beside the Loss ledger
live here. A `not landed: target moved` is answered in the same run, so the developer never types
the request again only so that a human is present. The ledger's location goes to the review as an
argument, so the review reads what a `contested` hunk set aside.

Amended: per ADR 0113, the reasons `conflict-loop.md` gave beside its rules for the contested
class, the Loss ledger and the reapplies live here. The all-mechanical blocks never run on a stop
with a contested hunk, since their union takes every conflicted file, contested ones included. The
Target side is read off the index stages, so the session reads no marker there either. A rerun at
the same stop rewrites each ledger entry where it stands, so the ledger never holds a hunk twice,
and the ledger's path is fixed before the rebase starts, since the branch the rebase replays is on
record only while it runs. Every entry is judged before the Gate runs again, so what a contested
hunk set aside is on record as kept or let go and never merely set aside. `ledger.sh` reads a
heading outside a fence only, since a `## <id>` line a side quotes is that side's own text, and an
empty ledger forks no judge, so a rebase with no contested hunk pays nothing for the judging. One
`ledger-judge` fork reads the whole ledger, since a fork per entry would pay for reading the ledger
and the tree around it again for every hunk. The Final integration's brief names the Spec as the run's intent, since
its ledger gathers what the Spec branch's rebase set aside across every Ticket of the Spec and no
one Ticket's Digest covers it. The judge holds reading and search alone per ADR 0032, since a
ledger entry is a side of a diff a stranger's commit may have written, and a script binds each
block it returns to its entry before the session writes from it, for the same reason. `ledger.sh`
writes verdicts from an entry directory rather than loose arguments, so the judge's free-text
reason never becomes a shell word a command could hide inside; `contested.sh` writes entries and
that verb writes verdicts, so neither overwrites the other and a rerun at the same stop carries a
verdict over, and a resumed run judges only what `pending` named, so running twice leaves the same
ledger. A refused verdict is never retried, since a reading of an entry nobody set aside is not one
the run asked for and a second reading never writes over the first. With no `ledger-judge`
available the run neither stops nor asks, since the developer cannot hand one over mid-run and the
ledger is what the run needs judged, and it never forks another agent in its place, since a fork
under any other name could still hold the write tools the judge's definition denies it. Each
reapply is its own commit, in the order `pending` printed, so each piece of work a contested hunk
set aside is a diff the developer reads and reverts alone, and no test author is dispatched for it,
since the edit is work the branch already carried before the rebase, not a behaviour the run adds.
The whole-side write goes through the index and never a redirect into the path, since the tree may
hold that path as a symlink the Target side left there: a redirect would follow it and land the
run's bytes outside the worktree while the index stayed unchanged, leaving nothing to commit; the
check before it already bound the path back to the entry, so a block naming a path outside the tree
never reaches `write-blob.sh`. A reapply stages that file alone, so nothing else rides along, and
its commit body names the entry's id, so the ledger and the history point at each other. A reapply
that brings nothing back moves on to the next entry rather than stopping the run, since the reapplies before it are already
commits of their own. The Gate runs once after the last reapply and never between two, so what
came back is held to the same checks as everything else and the most expensive command of the run
is paid once whatever the entry count. A red Gate after the reapplies stops as blocked and never
goes back to the build loop, since the branch now holds the developer's code the replay brought in
beside the work that came back, and a run that loops on it edits their work; the stop names the
ledger, since the ledger holds what came back and what did not. A commit whose change the target
already holds is skipped rather than continued, since git refuses an empty commit and leaves the
rebase where it is, and nothing of the run's work is lost by it: the change is either already on
the branch it was going to land on, or it is the Incoming side of a contested hunk the ledger holds
whole. A blocked stop with the rebase open names the abort as its undo, since the rebase has not
finished. The integration step alone leaves its Ticket `claimed` on a stop, since a `bug-fix` or
`refactoring` run has no Ticket and the Final integration's Ticket has already landed, its claim
yielded. A resumed run reads only the reapplies, since the hunks its ledger came from were classed,
resolved and judged at a stop of the run that wrote it.
