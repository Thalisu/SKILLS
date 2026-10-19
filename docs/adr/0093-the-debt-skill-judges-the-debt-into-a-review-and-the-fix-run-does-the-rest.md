# The debt skill judges the debt into a Review, and the fix run does the rest

Acting on a feature's Pending debt takes two jobs: deciding which items are really needed, and
fixing them in parallel groups that do not touch each other. The second is what `do-code-review`'s
fix run already does (Waves cut by `fix-waves.sh`, one Fixer per Finding in its own worktree, the
Gate, the landing by `land.sh`), so the new skill owns the first alone: it writes a Debt review in
the format of `review-format.md` beside the Spec, with only the items that hold up under `Act on`,
and calls `/do-code-review fix` on it. Its Fixed point is the tip of the branch the developer is on
when the skill runs, the Fixers work on a `debt/<slug>` branch cut there, and a Green Debt review
fast-forwards that same branch, never a branch name the skill assumes. The Debt review's author is
the judgment, not a reviewer reading a diff, which ADR 0033 allows: what comes after the one review
lands through the Gate alone.

## Considered options

- **The skill forks `do-code-review-fixer` and runs `fix-waves.sh` itself**: the Fixer's contract
  names one caller, and the Gate and the landing would be written a second time.
- **A pipeline of its own**: two ways to cut parallel groups and two landings, bound to drift the
  way the slug rule did before ADR 0031.
