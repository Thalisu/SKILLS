# SKILLS

Agent skills I maintain across projects. Each skill is a self-contained directory under `skills/`,
following the [Agent Skills](https://docs.claude.com/en/docs/claude-code/skills) convention: a
`SKILL.md` with YAML frontmatter, plus optional `scripts/`, `references/`, `assets/`, `tests/` and
`evals/`. Each skill also has a page under `docs/` that says what it does, when to reach for it and
where it sits among the others. A skill that reads a project writes what it learns inside that
project and commits it there; nothing project-derived is ever kept in this repository.

Grouped by who can fire the skill; the contract is in [`.agents/invocation.md`](.agents/invocation.md).

## User-invoked

Reachable only by the human typing the name.

| Skill                                              | Purpose                                                                                                                                                              | Docs                                             |
| -------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------ |
| [`discover-setup`](skills/discover-setup/SKILL.md) | Wire the discover agent and skills on a machine and install or update the mandatory Discovery rule in a project's `CLAUDE.md` or in the user's `~/.claude/CLAUDE.md` | [docs/discover-setup.md](docs/discover-setup.md) |
| [`discuss`](skills/discuss/SKILL.md) | Interview the user about a plan before code, one question at a time with a recommendation, recording terms in `CONTEXT.md` as they land and writing the hard-to-reverse decisions as ADRs at the close | [docs/discuss.md](docs/discuss.md) |
| [`do`](skills/do/SKILL.md) | Match a request to one Playbook and run its steps: a Ticket's path or issue reference builds that Ticket as the last step of the chain, a request in words runs outside it, and a request that fits no Playbook is sent to the door that owns it in one message | [docs/do.md](docs/do.md) |
| [`journey`](skills/journey/SKILL.md) | Walk every path of a spec from the actor's seat, drafting each from the app's precedent and asking one question per fork it leaves open, then write the journey beside the spec and point the spec's `Journey:` line at it | [docs/journey.md](docs/journey.md) |
| [`prototype`](skills/prototype/SKILL.md) | Build one throwaway, runnable prototype in a subagent to settle a design question you have to see or drive: a single HTML file that drives a state model, or three variants of a screen on its real route | [docs/prototype.md](docs/prototype.md) |
| [`sketch`](skills/sketch/SKILL.md) | Settle the shape a piece of work has to hold before any logic in a subagent and file it: the caller's usage, the types, the signatures and the module boundaries with unimplemented bodies, plus each rival shape it rejected in one line | [docs/sketch.md](docs/sketch.md) |
| [`spec`](skills/spec/SKILL.md) | Turn the conversation into a spec, published where the project's issue tracker points, with a verdict that names the next command: `journey` when the stories add a screen or walk more than one path or step, `tickets` otherwise | [docs/spec.md](docs/spec.md) |
| [`testing-policy`](skills/testing-policy/SKILL.md) | Install and keep in sync a canonical Testing Policy (Definition of Done) across repos                                                                                | [docs/testing-policy.md](docs/testing-policy.md) |
| [`tickets`](skills/tickets/SKILL.md) | Cut a spec, and the journey its verdict points at, into tracer-bullet tickets with blocking edges, each sized by a token estimate, with edges, folds and splits decided by the skill and only the approval asked, published one file or one issue per ticket, stopping before any write when the journey is required but missing, contested or already ticketed | [docs/tickets.md](docs/tickets.md) |

## Model-invoked

Reachable by the model on its own, or by the human typing the name.

| Skill                                        | Purpose                                                                                                                        | Docs                                       |
| -------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------ |
| [`discover`](skills/discover/SKILL.md)       | Batch "does this already exist in the repo?" lookups answered by a Haiku subagent in one line per symbol                       | [docs/discover.md](docs/discover.md)       |
| [`do-code-review`](skills/do-code-review/SKILL.md) | Review the branch since a fixed point on six Axes, every Finding proven to a Rung and written by Bucket into one Review file beside the branch, then fixes its `Act on` Findings and lands by fast-forward; the spec Axis reads the spec the chain wrote | [docs/do-code-review.md](docs/do-code-review.md) |
| [`test-triage`](skills/test-triage/SKILL.md) | Run a test target, cluster the failures, auto-fix and commit only the small ones, file a dossier in `docs/tests/` for the rest | [docs/test-triage.md](docs/test-triage.md) |

## Vendored

Skills this repo's skills call and does not own, copied from
[pstack](https://github.com/cursor/plugins/tree/main/pstack) at a pinned commit with the local
changes listed in [`vendor/README.md`](vendor/README.md). They install like any skill here and have
no page under `docs/`.

| Skill | Purpose |
| --- | --- |
| [`architect`](vendor/architect/SKILL.md) | Design the shape before code: the caller's usage, then types, signatures and module boundaries, rival candidates compared |
| [`how`](vendor/how/SKILL.md) | Senior-engineer walkthrough of how a subsystem works, with a critique mode |
| [`why`](vendor/why/SKILL.md) | Cited, confidence-calibrated read on why code was built a certain way |
| [`teach`](vendor/teach/SKILL.md) | Explain a change or subsystem until it clicks, on top of `how` and `why` |
| [`unslop`](vendor/unslop/SKILL.md) | Strip AI tells from prose and put human voice back |
| [`technical-writing`](vendor/technical-writing/SKILL.md) | Writing standard for docs, RFCs, readmes, PR descriptions and commit messages |
| [`typescript-best-practices`](vendor/typescript-best-practices/SKILL.md) | TypeScript typing and API-shape rules |
| [`no-comments`](vendor/no-comments/SKILL.md) | User-invoked: spawn the `comment-sicko` agent over a diff and act on the accepted findings |

## Install

Clone the repo and link a skill into the harness skill directory. Every link points into the clone,
so a `git pull` updates the installed skills.

```bash
git clone https://github.com/Thalisu/SKILLS.git ~/SKILLS
ln -s ~/SKILLS/skills/<name> ~/.claude/skills/<name>
ln -s ~/SKILLS/vendor/<name> ~/.claude/skills/<name>
```

The second line is for a vendored skill; `no-comments` also needs its agent linked, as `prototype`
does below: `skills/prototype/AGENT.md` to `~/.claude/agents/prototype.md`, and
`vendor/no-comments/AGENT.md` to `~/.claude/agents/comment-sicko.md`.

`discover` needs one more step: link `discover-setup` as above, then run `/discover-setup` from a
project. It links the discover agent and both discover skills and installs the Discovery section in
the `CLAUDE.md` you choose, the project's or your global one.

`prototype` ships an agent too: beside the skill link, link `skills/prototype/AGENT.md` to
`~/.claude/agents/prototype.md`. Typing `/prototype` forks that agent, and so do `discuss`, for a
branch that has to be seen, and `journey`, for a fork of a path that has to be seen.

```bash
ln -s ~/SKILLS/skills/prototype/AGENT.md ~/.claude/agents/prototype.md
```

`sketch` ships an agent too, and the same holds: link `skills/sketch/AGENT.md` to
`~/.claude/agents/sketch.md`. Typing `/sketch` forks that agent, and so does `do` at its shape step,
when a Ticket's work crosses a boundary and nothing in hand carries a shape.

```bash
ln -s ~/SKILLS/skills/sketch/AGENT.md ~/.claude/agents/sketch.md
```

`do-code-review` ships three agents: the orchestrator beside its skill file, and the technical
reviewer and the security reviewer in its `agents/` folder. Link all three by name, or the run has
nothing to fork.

```bash
ln -s ~/SKILLS/skills/do-code-review/AGENT.md ~/.claude/agents/do-code-review.md
ln -s ~/SKILLS/skills/do-code-review/agents/do-code-review-technical-reviewer.md ~/.claude/agents/do-code-review-technical-reviewer.md
ln -s ~/SKILLS/skills/do-code-review/agents/do-code-review-security-reviewer.md ~/.claude/agents/do-code-review-security-reviewer.md
```

Maintainers of this repo can run `scripts/link-skills.sh` to relink every skill at once; it is a
dev-only script, not a supported installer.

## Contributing

The rules for changing this repo are in [`CLAUDE.md`](CLAUDE.md); they apply to humans and agents
alike. The one with a mechanism behind it: captures from real projects never enter this repository,
in any form. A stray `local/` or `capture/` directory under `skills/` or `vendor/` shows up in
`git status`, and the versioned `.githooks/pre-commit` refuses to commit one. Enable the hook once
per clone:

```bash
git config core.hooksPath .githooks
```

## License

MIT.

## Credits

Some skills, rules and principles are based from [Matt Pocock's skills repo](https://github.com/mattpocock/skills) and from [pstack](https://github.com/cursor/plugins/tree/main/pstack).
