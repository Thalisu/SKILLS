# The test authors carry the model and effort the project picked at install

The testing-policy install asks the project, once per author it installs, which model and effort
the `unit-test-author` and the `e2e-test-author` run on, and writes the answer into the agent's
frontmatter as `model:` and `effort:`. The question proposes one Recommended pair derived from what
step 2 measured, a cheaper pair with what it gives up, and `inherit`, which writes `model: inherit`
and no `effort:` line; the free-text answer is refused unless both values are ones the harness
accepts. The frontmatter is a preserved part of an installed agent, so a refresh keeps the pick,
and an agent whose frontmatter carries no `model:` line is one the question never reached, which
`verify-policy.sh` reports so the next run asks it.

The author does more than type a test: it runs the reuse audit, decides what earns an assertion
and where the boundary sits, and on a miss writes the diagnosis a **Handback** routes on. A wrong
test is paid twice under red-first, since the production code is then written against it, so the
Recommended model is the stronger one and the volume of dispatches is paid down through the
effort level instead.

## Considered options

- **Inherit the session's model, the rule the skill shipped with**: kept as an answer, not as the
  rule. It lets the model a developer happened to open the session with decide the quality of
  every test the chain writes.
- **The skill infers the pair with no question**: rejected because the trade-off is cost against
  quality, which is the project's to make, and a heuristic nobody saw is one nobody can correct.
- **Always ask, with no recommendation**: rejected because the user answers without the counts
  step 2 already measured.
- **Pinned model IDs**: rejected because the file is committed in the project and nobody revisits
  it when a model is retired; the aliases follow the releases.

## Consequences

The `global-*-test-author` agents the do skill ships run on projects with no Testing Policy, so no
install reaches them; they keep inheriting the session's model and effort. A dispatcher that passes
`model` to the Agent tool overrides the frontmatter, so the chain's dispatches pass none.
