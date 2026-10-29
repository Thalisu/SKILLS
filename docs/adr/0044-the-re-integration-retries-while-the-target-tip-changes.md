# The re-integration retries while the target's tip changes, and has no fixed count

A run whose landing returns `not landed: target moved` integrates again and lands through `fix`,
and it keeps doing so for as long as each attempt meets a new tip of the target. A failure against
the tip the previous attempt already met is not concurrency, and it stops the run as blocked. Every
retry means another landing happened, and concurrent runs are finite, so the loop ends. A fixed
count blocks the first run past it, which is the failure this exists to remove. This supersedes the
rule of ADR 0034 that a second move of the target stops the run.

## Considered options

- A fixed cap of attempts: it bounds the cost of a retry (a **Gate**, and a ledger judge when a
  hunk is contested), and it stops whichever run is one past the cap, however healthy.

## Consequences

The loop's cost grows with the number of runs landing at once: each lost race repeats the run's
integration and its **Gate**. Whether an attempt met a new tip is git's verdict, never the
session's reading: the integration's own ancestor check, whose no-op after a
`not landed: target moved` is the failure against a tip already met.

Amended: per ADR 0113, the reasons `resume.md` gave beside a resumed rebase live here. The run asks
before discarding uncommitted changes in the worktree, since the discard is the one irreversible act
on that path. A rebase stopped with no conflicted file is asked about, since what is staged for the
commit it stopped at was staged with nobody's answer recorded and is not the run's to land. A branch
finished behind the tip it stopped onto could not land by fast-forward. When the developer's branch
only moved forward, as it does when another run landed while this one was cut short, the run
continues without asking, since it lands again nothing the branch no longer holds and keeps the hand
resolution the stop holds, which an abort would throw away. On `moved=ask` a continue would land
again commits the developer removed, which cannot be undone once landed, and the landing takes them
with no second review, so the question names every one of them. Under `--auto` that question is
still asked, since an abort drops work and a continue lands again what cannot be undone, so neither
is taken on a Ruling.
