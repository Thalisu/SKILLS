# skills

One directory per skill, each with a `SKILL.md` and, where the skill needs them, `scripts/`,
`references/`, `assets/`, `tests/` or `evals/`. Grouped by who can fire the skill; the contract is in
[`.agents/invocation.md`](../.agents/invocation.md).

## User-invoked

Reachable only by the human typing the name.

| Skill | Purpose |
|---|---|
| [`discover-setup`](discover-setup/SKILL.md) | Link the discover agent and skills on this machine, then install or refresh the mandatory Discovery section in a project's `CLAUDE.md` or in `~/.claude/CLAUDE.md` |
| [`discuss`](discuss/SKILL.md) | Interview the user about a plan before code, one question at a time with a recommendation, recording terms in `CONTEXT.md` and hard-to-reverse decisions in `docs/adr/` as they land |
| [`journey`](journey/SKILL.md) | Walk every path of a spec from the actor's seat, drafting each from the app's precedent and asking one question per fork it leaves open, then write the journey beside the spec and point the spec at it |
| [`prototype`](prototype/SKILL.md) | Build one throwaway, runnable prototype in a subagent to settle a design question you have to see or drive: a single HTML file that drives a state model, or three variants of a screen on its real route |
| [`spec`](spec/SKILL.md) | Turn the conversation into a spec, published where the project's issue tracker points, with a verdict that names the next command: `journey` when the stories add a screen or walk more than one path or step, `tickets` otherwise |
| [`testing-policy`](testing-policy/SKILL.md) | Install, migrate or refresh the canonical Testing Policy (Definition of Done) in a project |
| [`tickets`](tickets/SKILL.md) | Cut a spec, and the journey its verdict points at, into tracer-bullet tickets with blocking edges, published one file or one issue per ticket |

## Model-invoked

Reachable by the model on its own, or by the human typing the name.

| Skill | Purpose |
|---|---|
| [`discover`](discover/SKILL.md) | Batch "does this already exist in the repo?" lookups, answered by a Haiku subagent in one line per symbol |
| [`test-triage`](test-triage/SKILL.md) | Run a test target, cluster the failures, auto-fix and commit only the small ones, file a dossier in `docs/tests/` for the rest |
