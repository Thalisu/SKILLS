# A resume takes over a yielded claim only, and a dead holder's claim is yielded by hand

ADR 0061 has a stopped Final integration resumed by a new `do`, and has its claim file guarantee
that two runs never both integrate; a resume that took over any claim it found would keep the first
and give up the second. A run that stops marks its claim yielded, and a claim takes over a yielded
claim only, atomically between two resumes; a claim nobody yielded reads `taken` and stops the
resume in one line, writing nothing. A holder that died without yielding is the developer's to
declare dead: the stop's Reply names the holder, when it claimed and the yield command to run before
the same `/do`.

## Considered options

- A resume takes over any claim it finds, the way a `claimed` Ticket whose worktree exists is
  resumed today: a second `/do` typed while the first run is mid-rebase puts two runs in one tree,
  and both land on the developer's branch. A repeated Ticket run only repeats one Ticket's work in
  its own worktree, which is why the looser rule holds there and not here.
- The resume asks `(take over / stop)` whenever it reads `taken`: the question appears exactly when
  another run may be integrating, and the prompt cannot say whether the holder is dead.
- The claim expires after an age: a review of a whole Spec has no duration a timeout could sit
  above.

## Consequences

Every stop the run controls (a rebase question unanswered, a review that did not land, `not landed:
target moved`) yields before the Reply. The run that reaches the Final integration from its own
Completion check is unchanged: `taken` ends it with the Spec being integrated by another run.
