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

Amended: per ADR 0113, the reasons `mechanics.md` and `final-stopped.md` gave beside the claim live
here. The claim is made by creating its file, per ADR 0020, so two runs that both read the Spec
complete never both integrate it, and a first claim reads `takeover=no` since no claim file was
there. A stop leaves the tree, the Spec branch and the claim file in place, since they are what a
later run resumes from, and the yield leaves the claim file as it was written, so the claim still
keeps a first run out while a resume can take it over. A resume claims before it reads anything from
the tree, so two resumes never both walk it, and a claim nobody yielded stops it, since its holder
is either still integrating or died without yielding and the script cannot tell which.
