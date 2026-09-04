# Model-invoked vs user-invoked

Every `SKILL.md` under `skills/` is a skill. The one axis that splits them is **invocation**, who can
reach it:

- **User-invoked**: reachable **only by the human typing its name**. Set
  `disable-model-invocation: true` in the `SKILL.md` frontmatter (Claude Code) and
  `policy.allow_implicit_invocation: false` in `agents/openai.yaml` (Codex). The `description` is
  **human-facing**: a one-line summary read by a person browsing slash commands. Strip trigger lists
  ("Use when the user says...").
- **Model-invoked**: reachable by **model or user**. The default: omit `disable-model-invocation` and
  the `policy` block from `agents/openai.yaml`. The `description` is **model-facing** and keeps rich
  trigger phrasing ("Use when the user wants..., mentions..., asks for...") so auto-invocation fires.
  The test for whether a skill should stay model-invoked: _could the model usefully reach for this
  autonomously?_ (Reuse is the reason to extract a skill, not the test.)

The choice is made when the skill is created, recorded in both harnesses at once, and there is no
third state. In this repo, `discover-setup`, `testing-policy`, `discuss`, `prototype`, `spec`,
`tickets` and `journey` are user-invoked: the first edits a `CLAUDE.md` and creates links under
`~/.claude`, the second writes agents, a skill and a marked section into a project, the third
interviews the human, the fourth writes throwaway files into a project, the fifth publishes a spec
into a project, the sixth publishes tickets to a project's tracker, the seventh interviews the human
about a spec and writes the journey into a project, and each is the human's call. `discover` and
`test-triage` are model-invoked.

Each harness excludes a user-invoked skill from the model's reach in its own way, so nothing but the
human can fire it: no other skill can. A user-invoked skill may invoke model-invoked skills, but it
can never reach another user-invoked skill. The agent a skill ships is a separate door, covered
below.

Every skill also carries an `agents/openai.yaml` beside its `SKILL.md`. It holds Codex UI metadata:
`interface.display_name` and `interface.short_description` for the skill picker, and, for
user-invoked skills, the `policy.allow_implicit_invocation: false` that pairs with
`disable-model-invocation`. Keep the two in sync: a skill is user-invoked in both harnesses or in
neither.

The top-level `README.md` and `skills/README.md` group their entries into **User-invoked** and
**Model-invoked**, so changing a skill's invocation touches four files in one change: the
frontmatter, `agents/openai.yaml` and both READMEs.

## Where a skill runs

Invocation says who can fire a skill. `context` says where it runs once fired, and the two are
chosen together:

- `context: fork` with an `agent:` runs the skill in a subagent, so its tool output never lands in
  the caller's context. `discover` runs this way on the `discover` agent, with `background: false`
  so the caller waits for the batch. That agent has Bash only: it can neither ask the user a question
  nor edit a file, which is why the install that the lookup depends on is a separate skill.
- No `context` runs the skill inline, in the caller's session, with the caller's tools.
  `discover-setup` runs inline because it must ask which scope to install and then edit a
  `CLAUDE.md`; `testing-policy` and `test-triage` run inline because they edit, commit and ask;
  `discuss` and `journey` run inline because an interview needs the human, who is only in the
  caller's session.

Work that must talk to the user or write into the project runs inline. A lookup with a terse output
contract forks. `prototype` forks the same way, onto the `prototype` agent with `background: false`
so the report is back before the human's turn ends; its agent has file tools and Bash and no way to
reach the human, so the brief it receives has to be complete. Its one exit is the report itself: an
agent that has to ask ends its turn with a `PROTOTYPE ask` report before writing any file, and the
caller, whichever door it came through, answer the question by itself or if extremely necessary relays the question to the human and resumes the same agent
with the SendMessage tool. A forked agent keeps its context after it returns, which is what makes
resuming cheaper than forking again: the second run starts where the first stopped, with everything
it read.

## Agents a skill ships

A skill that runs on its own agent ships the definition as `AGENT.md` beside its `SKILL.md`, linked
into `~/.claude/agents/<name>.md` (by `scripts/link-skills.sh` here, by the skill's own installer or
the README's `ln -s` elsewhere). That agent is a second door into the same contract: any session can
fork it with the Agent tool (`subagent_type: <name>`), and no frontmatter closes that door. What
gates it is the agent's `description`, which names the callers it accepts, so on this door the
invariant is kept by the callers, not by the harness.

| Agent       | Skill         | Doors                                                                                                                                                            |
| ----------- | ------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `discover`  | model-invoked | `/discover`; `Agent(subagent_type: discover)` in headless `-p` sessions only                                                                                     |
| `prototype` | user-invoked  | `/prototype`; a `discuss` or `journey` interview, for a branch or a fork that cannot be settled by talking. Nothing else forks it, and whoever forked it answers its ask by resuming it |

So a step in another skill may reach the agent a user-invoked skill ships, never the skill itself,
and only when that agent's description names the calling skill. The step spells it out as an Agent
tool call (`call the Agent tool with subagent_type: prototype`), with the same explicitness the
Skill tool convention below asks for, and the calling skill is added to the agent's description in
the same change.

## Dependencies between them

Dependencies are expressed as an explicit instruction to **call the Skill tool** with the named skill
(`Call the Skill tool with "discover"`), not deep `../other-skill/FILE.md` cross-references, and not
a bare `/skill`-style mention left for the model to interpret. Naming the tool is what gets it fired:
most harnesses expose skill invocation as a tool the model calls, and spelling that out gets a higher
hit rate than dropping a `/name` into prose and hoping it is read as a command. Dropping the leading
`/` also keeps this harness-neutral: a skill name on its own carries no assumption about which
harness's trigger syntax it belongs to. Shared reference docs live inside the skill that owns them;
other skills reach that material by calling the Skill tool with it, not by linking across folders.
The formats of the artifacts the chain shares (`CONTEXT.md`, an ADR, a spec, a journey) are the
exception: they live under `.agents/formats/`, outside every skill, and each skill that writes or
reads one links it by relative path (`docs/adr/0004`).

This is about **operative** instructions: a skill's own steps telling the agent to go run another
skill right now. Router prose that just names skills for a human to pick from (the READMEs, the docs
pages under `docs/`) is not invoking anything, so it keeps `/skill`-style names as plain labels.

Text a skill renders into a project's `CLAUDE.md` (the Discovery section from `discover-setup`, the
Testing Policy section from `testing-policy`) is a third thing. It addresses whatever agent reads
that file, in whichever harness, and its wording is validated by that skill's own tests, so it keeps
that wording. The convention here covers a skill's own steps in this repo.

The Skill tool takes one skill per call. A step that needs two skills is two calls, not one call with
two names: say so (`Call the Skill tool twice, for "discover" and "test-triage"`), not "call it with
X and Y", which reads as a single call taking both.

This whole convention only holds when the named skill is **model-invoked**. A user-invoked skill can
never be reached this way, full stop: per the invariant above, no other skill can call it, including
by naming it to the Skill tool. When a step's precondition is a user-invoked skill, phrase it as an
instruction for the human to act on: when `discover` reports an unknown agent, "tell the user to run
`/discover-setup`", never a Skill tool call. The one exception is the agent door above: a step may
fork the agent a user-invoked skill ships when that agent's description names the calling skill.
