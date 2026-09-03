# skills

One directory per skill, each with a `SKILL.md` and, where the skill needs them, `scripts/`,
`references/`, `assets/`, `tests/` or `evals/`. Grouped by who can fire the skill; the contract is in
[`.agents/invocation.md`](../.agents/invocation.md).

## User-invoked

Reachable only by the human typing the name.

| Skill | Purpose |
|---|---|
| [`discover-setup`](discover-setup/SKILL.md) | Link the discover agent and skills on this machine, then install or refresh the mandatory Discovery section in a project's `CLAUDE.md` or in `~/.claude/CLAUDE.md` |
| [`testing-policy`](testing-policy/SKILL.md) | Install, migrate or refresh the canonical Testing Policy (Definition of Done) in a project |

## Model-invoked

Reachable by the model on its own, or by the human typing the name.

| Skill | Purpose |
|---|---|
| [`discover`](discover/SKILL.md) | Batch "does this already exist in the repo?" lookups, answered by a Haiku subagent in one line per symbol |
| [`test-triage`](test-triage/SKILL.md) | Run a test target, cluster the failures, auto-fix and commit only the small ones, file a dossier in `docs/tests/` for the rest |
