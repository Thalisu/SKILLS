# The review never edits; the fix runs in a sub-agent outside the chain, and through step 5 inside /do

`do-code-review` is one agent that reads, runs what it needs to prove a finding, and reports; it
never writes into the tree. Fixing is a separate writer, and where it lives depends on the caller.
Inside `/do`, an accepted finding becomes one more unit of the step 5 build loop, where the session
is the only writer and the `unit-test-author` takes its `git status` baseline on that assumption;
a fixer sub-agent there would be a second writer, or would have to carry the TDD loop itself.
Outside the chain, the fix is a second human call, `/do-code-review fix <review>`, that reads the
review file the first call wrote beside the ticket, forks one fixer sub-agent with its `Act on`
list, re-runs the check each of those findings named, and appends what was fixed and what was
verified to the same file; the fixer follows the project's Testing Policy when one is installed.
Two calls instead of one run because the human reads the review between them and decides what the
fixer gets: the file is the hand-off, and a finding whose location no longer matches is reported
stale, never guessed at. The nesting stays inside the harness limit of three layers: human,
orchestrator, fixer, test author.

## Considered options

- The reviewer applies its own fixes: the author's eyes are no longer fresh for the re-read, and a
  forked agent cannot ask before an irreversible edit.
- `fix` as a mode of the same run, the fixer forked right after the report: the human never sees the
  review before the fixer acts on it, and the run has no artifact to hand a later session.
- One fixer sub-agent for both paths: two writers in the `/do` worktree, and a fixer that has to
  re-implement the step 5 loop or skip it.
