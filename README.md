# SKILLS

Agent skills I maintain across projects. Each skill is a self-contained directory under `skills/`,
following the [Agent Skills](https://docs.claude.com/en/docs/claude-code/skills) convention: a
`SKILL.md` with YAML frontmatter, plus optional `scripts/`, `references/`, `assets/`, `tests/` and
`evals/`. Each skill also has a page under `docs/` that says what it does, when to reach for it and
where it sits among the others.

Captures from real projects never enter this repository, in any form. A skill that reads a project
writes what it finds inside that project and commits it there, so the team reads it from git instead
of re-running the skill on every machine. Nothing project-derived is kept in a skill's own directory,
which is shared by every project and is public, and no skill ships an example taken from a real
repo. Nothing is gitignored to that end: a stray `local/` or `capture/` directory under `skills/`
shows up in `git status`, and the versioned `.githooks/pre-commit` refuses to commit one. Enable it
once per clone:

```bash
git config core.hooksPath .githooks
```

Grouped by who can fire the skill; the contract is in [`.agents/invocation.md`](.agents/invocation.md).

## User-invoked

Reachable only by the human typing the name.

| Skill                                              | Purpose                                                                                                                                                              | Docs                                             |
| -------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------ |
| [`discover-setup`](skills/discover-setup/SKILL.md) | Wire the discover agent and skills on a machine and install or update the mandatory Discovery rule in a project's `CLAUDE.md` or in the user's `~/.claude/CLAUDE.md` | [docs/discover-setup.md](docs/discover-setup.md) |
| [`discuss`](skills/discuss/SKILL.md) | Interview the user about a plan before code, one question at a time with a recommendation, recording terms in `CONTEXT.md` and hard-to-reverse decisions in `docs/adr/` as they land | [docs/discuss.md](docs/discuss.md) |
| [`journey`](skills/journey/SKILL.md) | Walk every path of a spec from the actor's seat, drafting each from the app's precedent and asking one question per fork it leaves open, then write the journey beside the spec and point the spec's `Journey:` line at it | [docs/journey.md](docs/journey.md) |
| [`prototype`](skills/prototype/SKILL.md) | Build one throwaway, runnable prototype in a subagent to settle a design question you have to see or drive: a single HTML file that drives a state model, or three variants of a screen on its real route | [docs/prototype.md](docs/prototype.md) |
| [`spec`](skills/spec/SKILL.md) | Turn the conversation into a spec, published where the project's issue tracker points, with a verdict that names the next command: `journey` when the stories add a screen or walk more than one path or step, `tickets` otherwise | [docs/spec.md](docs/spec.md) |
| [`testing-policy`](skills/testing-policy/SKILL.md) | Install and keep in sync a canonical Testing Policy (Definition of Done) across repos                                                                                | [docs/testing-policy.md](docs/testing-policy.md) |
| [`tickets`](skills/tickets/SKILL.md) | Cut a spec, and the journey its verdict points at, into tracer-bullet tickets with blocking edges, published one file or one issue per ticket, stopping before any write when the journey is required but missing, contested or already ticketed | [docs/tickets.md](docs/tickets.md) |

## Model-invoked

Reachable by the model on its own, or by the human typing the name.

| Skill                                        | Purpose                                                                                                                        | Docs                                       |
| -------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------ |
| [`discover`](skills/discover/SKILL.md)       | Batch "does this already exist in the repo?" lookups answered by a Haiku subagent in one line per symbol                       | [docs/discover.md](docs/discover.md)       |
| [`test-triage`](skills/test-triage/SKILL.md) | Run a test target, cluster the failures, auto-fix and commit only the small ones, file a dossier in `docs/tests/` for the rest | [docs/test-triage.md](docs/test-triage.md) |

## Install

Clone the repo and link a skill into the harness skill directory. Every link points into the clone,
so a `git pull` updates the installed skills.

```bash
git clone https://github.com/Thalisu/SKILLS.git ~/SKILLS
ln -s ~/SKILLS/skills/<name> ~/.claude/skills/<name>
```

`discover` needs one more step: link `discover-setup` as above, then run `/discover-setup` from a
project. It links the discover agent and both discover skills and installs the Discovery section in
the `CLAUDE.md` you choose, the project's or your global one.

`prototype` ships an agent too: beside the skill link, link `skills/prototype/AGENT.md` to
`~/.claude/agents/prototype.md`. Typing `/prototype` forks that agent, and so do `discuss`, for a
branch that has to be seen, and `journey`, for a fork of a path that has to be seen.

```bash
ln -s ~/SKILLS/skills/prototype/AGENT.md ~/.claude/agents/prototype.md
```

Contributors enable the pre-commit hook once per clone, as shown above. Maintainers of this repo can
run `scripts/link-skills.sh` to relink every skill at once; it is a dev-only script, not a supported
installer.

## License

MIT.

## Credits

Some skills, rules and principles are based from [Matt Pocock's skills repo](https://github.com/mattpocock/skills) and from [pstack](https://github.com/cursor/plugins/tree/main/pstack).
