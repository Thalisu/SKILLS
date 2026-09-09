# A script, then an Agent fork, and `claude -p` is never a fork's substitute

A step of a `do` Playbook picks its mechanism in one order and never argues it twice: a fact a
command can observe is a script, per `build-the-lever` and the non-negotiable that sends an
observable fact to a probe, and work that needs a sub-agent is an Agent fork. A fork earns its cost
when finding the answer costs far more than the answer itself. `claude -p` stays available for work
whose shape is a separate run, and is never an alternative a step may opt into in a fork's place,
because the one thing it buys is freedom from `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` and ADR 0009
fixes that no Playbook depends on nesting depth. One legal answer per step is also what the
`withheld-agent-tool` eval needs, since a second would give it two passing shapes and let it grade
neither.

## Considered options

- Refusing `claude -p` anywhere in the repo: it removes a mechanism that fits work outside a
  Playbook, for a rule that only had to hold inside one.
- Offering `claude -p` as a middle tier a step opts into when a fork is awkward: every new step is
  then argued into a tier, and "the Agent tool is withheld" acquires a second meaning the evals
  cannot grade.
