# The review orchestrator runs on opus at high effort, and no Router agent is created

The `do-code-review` orchestrator briefs its two reviewers and they read the diff, so it holds no
code and its window is the smallest of the skill's actors, which makes its model the cheapest
competence in the skill to raise: it runs on `model: opus` at `effort: high`, and the read-only
Router agent designed to split the Waves is not created, the split being the orchestrator's own over
the floor `fix-waves.sh` computes, a ceiling it may cut finer and never widen. The upgrade also
reaches what no script will ever take from it, the Bucket, the Rung gate, the spec reading and the
Review's prose. The price is recurring rather than per fork, since every review call pays it and
`do` calls one per run; the reversal, if that cost bites, is the orchestrator back to sonnet with the
Router created as its own agent.

## Considered options

- Sonnet at medium effort with the Router forked read-only for the Waves: a whole agent, its
  definition, its invocation row and its docs page bought so a weak actor could delegate one
  grouping judgment, when `effort` is expressable only in an agent definition and not in an Agent
  tool call. That an agent's model and effort are a deliberate pick rather than an inheritance is
  already this repository's stance, per
  [ADR 0052](0052-the-test-authors-carry-the-model-and-effort-the-project-picked-at-install.md).
- The upgrade instead of the two scripts: a stronger model raises the average and removes no tail,
  and the tail here is a `cherry-pick` left unaborted on top of another Fixer's work. Determinism in
  that loop is about not depending on attention, not about intelligence.
