# A debt item reaches `Act on` only at Rung 3, proven by a read-only evaluator

Pending debt and a Review's `Consider` Findings are an earlier agent's claims, and some are that
agent seeing something where nothing is. Each item is judged by a read-only evaluator forked for it
alone, all of them at once, which may run a proof in a temporary directory and never edits the
project. The Rung it reaches decides the Bucket, never the item's wording: `Act on` when the failure
was walked or run (Rung 3 or above), `Consider` when it stays plausible and unproven, `Cleared` when
the evaluator refuted it with evidence, `Noted` when it is real but no code change settles it. The
developer reverses any of them by moving the Finding by hand before the fix runs.

## Considered options

- **The session judges every item itself**: the reading of every item lands in one window, and the
  judge is the same kind of agent that raised the item.
- **The `choice-taker` rules do or skip**: it picks between options by a norm and never
  investigates whether a defect exists.
