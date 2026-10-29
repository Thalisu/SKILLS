# The global and fallback test authors

Read by the build loop, by whoever runs it (the Builder of
[builder.md](builder.md), the session in its place, the step about to build in `bug-fix` and
`refactoring`), and by the flows step, only when the loop line reads
`Loop: global` or `Loop: fallback`: the project has no Testing Policy of its own, or no unit test
author that can be dispatched. A run whose loop line reads `Loop: policy` never opens it.

## The global authors

Under `Loop: global` the project has no Testing Policy, and the authors are the two `do` ships in
its `agents/` folder, each carrying the markers and the sections of the policy's agent core in
order, with the why cut: call the Agent tool with `subagent_type: global-unit-test-author` for a
unit test and `subagent_type: global-e2e-test-author` for a flow, `run_in_background: false` on each, with the
dispatch input the build loop's `## The test authors` fixes (Read [build-loop.md](build-loop.md)
when a global author is dispatched) and one more line,
`Project map: <the map's path>`, the file `project-map.sh` wrote once for the whole run, at the
step its Playbook names. Each author reads its commands and its layout from that file, and the
verdicts are the ones that section names. The global authors have no inline entry point: with the
Agent tool withheld the loop line already reads `Loop: fallback`, the run writes every unit test
itself (Read [tdd-fallback.md](tdd-fallback.md) when the loop line reads `Loop: fallback`) and
authors the flow itself, and no author is dispatched.

A global unit test author that comes back `BLOCKED` naming a run command the project map lacks, a
slot reading `none yet → /testing-policy`, takes this route in place of the build loop's step 2
`BLOCKED` routes, with no second dispatch. The run writes this behaviour and every remaining one
itself (Read [tdd-fallback.md](tdd-fallback.md) when the author comes back `BLOCKED` on a map
slot), naming the missing slot and `/testing-policy` as the command that would fill it, and
dispatches the unit test author no more this run.

## The fallback

When the loop line reads `Loop: fallback` (no unit test author in the project and no global one
that can be dispatched), the build loop runs by the TDD fallback: Read
[tdd-fallback.md](tdd-fallback.md) when the loop line reads `Loop: fallback`, and only then: the
run writes the failing test itself where a cheap path exists, and otherwise the closest executable
check with the reason stated, and no test author is dispatched. Nothing else changes: red first,
the smallest green, one commit.

## Who authors a flow

The flows step takes its author from the brief's `Loop:` key:

- `Loop: global`: the project has no Testing Policy and so no section marker naming a surface, and
  the Project map the brief names stands in for it.
  - When the map's single-flow command is filled, each criterion the Digest marks observable gets
    its flow from `global-e2e-test-author` with the same complete input and the map's path, and the
    same verdicts.
  - When that command reads `none yet → /testing-policy` and the map's full-suite end-to-end
    command is filled too, no author is dispatched: the `fallback:` line names the single-flow slot
    the map left unfilled and quotes the full-suite command the map does carry, and the criterion
    it would have proven is left for the session to leave unticked at the close.
  - When both commands read `none yet → /testing-policy`, no author is dispatched either: the
    `fallback:` line reads `no end-to-end command in the project` and names `/testing-policy` as
    the command that would fill the slot.
- `Loop: fallback`: the same map decides, and where its command is filled the fork authors the flow
  itself and says so on a `fallback:` line.
