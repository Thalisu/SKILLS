# SKILLS

Agent skills I maintain across projects. Each skill is a self-contained directory under `skills/`,
following the [Agent Skills](https://docs.claude.com/en/docs/claude-code/skills) convention: a
`SKILL.md` with YAML frontmatter, plus optional `scripts/`, `references/`, `assets/`, `tests/` and
`evals/`. Each skill also has a page under `docs/` that says what it does, when to reach for it and
where it sits among the others. A skill that reads a project writes what it learns inside that
project and commits it there; nothing project-derived is ever kept in this repository.

## Usage

The main path for a task, from idea to built code:

| Step | Command           | What it does                                                                                                                                   |
| ---- | ----------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| 1    | `/discuss`        | Interview you about the plan, one question at a time; terms land in `CONTEXT.md`, hard calls in ADRs                                           |
| 2    | `/spec`           | Turn the conversation into a spec, published where the project's issue tracker points                                                          |
| 3    | `/clear`          | Drop the conversation; everything the next steps need is in the spec now                                                                       |
| 4    | `/journey <spec>` | Only when the spec's verdict says `Journey: required`: walk every path of the spec from the actor's seat, at the end clear again with `/clear` |
| 5    | `/tickets <spec>` | Cut the spec, and its journey when there is one, into tracer-bullet tickets with blocking edges                                                |
| 6    | `/do <ticket>`    | Build one ticket; run it once per ticket, in the order the blocking edges allow                                                                |

`spec` prints the next command when it closes, so step 4 is either `/journey` or skipped straight to `/tickets`.

Grouped by who can fire the skill; the contract is in [`.agents/invocation.md`](.agents/invocation.md).

## User-invoked

Reachable only by the human typing the name.

| Skill                                              | Purpose                                                                                                                                                                                                                                                                                                                                                         | Docs                                             |
| -------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------ |
| [`discover-setup`](skills/discover-setup/SKILL.md) | Wire the discover agent and skills on a machine and install or update the mandatory Discovery rule in a project's `CLAUDE.md` or in the user's `~/.claude/CLAUDE.md`                                                                                                                                                                                            | [docs/discover-setup.md](docs/discover-setup.md) |
| [`discuss`](skills/discuss/SKILL.md)               | Interview the user about a plan before code, one question at a time with a recommendation, recording terms in `CONTEXT.md` as they land and writing the hard-to-reverse decisions as ADRs at the close                                                                                                                                                          | [docs/discuss.md](docs/discuss.md)               |
| [`do`](skills/do/SKILL.md)                         | Match a request to one Playbook and run its steps: a Ticket's path or issue reference builds that Ticket as the last step of the chain, a request in words runs outside it, and a request that fits no Playbook is sent to the door that owns it in one message                                                                                                 | [docs/do.md](docs/do.md)                         |
| [`journey`](skills/journey/SKILL.md)               | Walk every path of a spec from the actor's seat, drafting each from the app's precedent and asking one question per fork it leaves open, then write the journey beside the spec and point the spec's `Journey:` line at it                                                                                                                                      | [docs/journey.md](docs/journey.md)               |
| [`prototype`](skills/prototype/SKILL.md)           | Build one throwaway, runnable prototype in a subagent to settle a design question you have to see or drive: a single HTML file that drives a state model, or three variants of a screen on its real route                                                                                                                                                       | [docs/prototype.md](docs/prototype.md)           |
| [`sketch`](skills/sketch/SKILL.md)                 | Settle the shape a piece of work has to hold before any logic, explored by a subagent that writes nothing and filed by your session: the caller's usage, the types, the signatures and the module boundaries with unimplemented bodies, plus each rival shape it rejected in one line                                                                                                                       | [docs/sketch.md](docs/sketch.md)                 |
| [`spec`](skills/spec/SKILL.md)                     | Turn the conversation into a spec, published where the project's issue tracker points, with a verdict that names the next command: `journey` when the stories add a screen or walk more than one path or step, `tickets` otherwise                                                                                                                              | [docs/spec.md](docs/spec.md)                     |
| [`testing-policy`](skills/testing-policy/SKILL.md) | Install and keep in sync a canonical Testing Policy (Definition of Done) across repos                                                                                                                                                                                                                                                                           | [docs/testing-policy.md](docs/testing-policy.md) |
| [`tickets`](skills/tickets/SKILL.md)               | Cut a spec, and the journey its verdict points at, into tracer-bullet tickets with blocking edges, each sized by a token estimate, with edges, folds and splits decided by the skill and only the approval asked, published one file or one issue per ticket, stopping before any write when the journey is required but missing, contested or already ticketed | [docs/tickets.md](docs/tickets.md)               |

## Model-invoked

Reachable by the model on its own, or by the human typing the name.

| Skill                                              | Purpose                                                                                                                                                                                                                                                  | Docs                                             |
| -------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------ |
| [`discover`](skills/discover/SKILL.md)             | Batch "does this already exist in the repo?" lookups answered by a subagent in one line per symbol                                                                                                                                                       | [docs/discover.md](docs/discover.md)             |
| [`do-code-review`](skills/do-code-review/SKILL.md) | Review the branch since a fixed point on six Axes, every Finding proven to a Rung and written by Bucket into one Review file beside the branch, then fixes its `Act on` Findings and lands by fast-forward; the spec Axis reads the spec the chain wrote | [docs/do-code-review.md](docs/do-code-review.md) |
| [`test-triage`](skills/test-triage/SKILL.md)       | Run a test target, cluster the failures, auto-fix and commit only the small ones, file a dossier in `docs/tests/` for the rest                                                                                                                           | [docs/test-triage.md](docs/test-triage.md)       |

## Vendored

Skills this repo's skills call and does not own, copied from
[pstack](https://github.com/cursor/plugins/tree/main/pstack) at a pinned commit with the local
changes listed in [`vendor/README.md`](vendor/README.md). They install like any skill here and have
no page under `docs/`.

| Skill                                                                    | Purpose                                                                                                                   |
| ------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------- |
| [`architect`](vendor/architect/SKILL.md)                                 | Design the shape before code: the caller's usage, then types, signatures and module boundaries, rival candidates compared |
| [`how`](vendor/how/SKILL.md)                                             | Senior-engineer walkthrough of how a subsystem works, with a critique mode                                                |
| [`why`](vendor/why/SKILL.md)                                             | Cited, confidence-calibrated read on why code was built a certain way                                                     |
| [`teach`](vendor/teach/SKILL.md)                                         | Explain a change or subsystem until it clicks, on top of `how` and `why`                                                  |
| [`unslop`](vendor/unslop/SKILL.md)                                       | Strip AI tells from prose and put human voice back                                                                        |
| [`technical-writing`](vendor/technical-writing/SKILL.md)                 | Writing standard for docs, RFCs, readmes, PR descriptions and commit messages                                             |
| [`typescript-best-practices`](vendor/typescript-best-practices/SKILL.md) | TypeScript typing and API-shape rules                                                                                     |
| [`no-comments`](vendor/no-comments/SKILL.md)                             | User-invoked: spawn the `comment-sicko` agent over a diff and act on the accepted findings                                |

## Install

Clone the repo and run the install script:

```bash
git clone https://github.com/Thalisu/SKILLS.git ~/SKILLS
bash ~/SKILLS/scripts/link-skills.sh
```

The script asks you to choose `claude` or `codex`. To select the destination without a prompt:

```bash
bash ~/SKILLS/scripts/link-skills.sh codex
bash ~/SKILLS/scripts/link-skills.sh claude
```

Both choices install every skill in the tables above, vendored ones included.

| Choice | Installation |
| --- | --- |
| `codex` | Links skills into `~/.agents/skills`, the [Codex user skills directory](https://learn.chatgpt.com/docs/build-skills). Leaves Claude configuration untouched. |
| `claude` | Links skills into `~/.agents/skills` and exposes them through `~/.claude/skills`. Also links agent definitions into `~/.claude/agents`. |

The shared skill directory means skills installed for Claude are also visible to Codex.
The Codex option installs skills and their bundled resources; it does not register the Claude
agent definitions as Codex custom agents. Run the script for each destination to maintain both.
An invalid choice or missing input exits without installing anything.

The Claude installation includes these agents:

| Skill            | Agents                                                                                    |
| ---------------- | ----------------------------------------------------------------------------------------- |
| `discover`       | `discover`                                                                                |
| `prototype`      | `prototype`, forked by `/prototype`, `discuss` and `journey`                              |
| `sketch`         | `sketch`, holding `Read, Glob, Grep`, forked by the `/sketch` session, by `do` at its shape step and by `do-planner` while it grounds a Ticket, which file the Sketch it returns |
| `do`             | `do-reader`, `do-planner`, `do-builder`, `choice-taker`, `ledger-judge`, `global-unit-test-author`, `global-e2e-test-author` |
| `do-code-review` | `do-code-review`, `do-code-review-technical-reviewer`, `do-code-review-security-reviewer` |
| `no-comments`    | `comment-sicko`                                                                           |

Every entry is a symlink into the clone, so a `git pull` updates what is installed. Re-run the script
after a pull that adds, renames or removes a skill: it links the new ones and prunes the links whose
skill is gone. Running it twice changes nothing. A real file already sitting where a link goes is
left alone, reported as `skipped`, and the run exits 1; move the file aside and re-run.

One step is per project rather than per machine: the Discovery rule. Run `/discover-setup` from a
project to install the Discovery section in that project's `CLAUDE.md`, or in your global one if you
ask for it.

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
