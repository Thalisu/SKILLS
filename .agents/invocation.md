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
third state. In this repo, `discover-setup` and `testing-policy` are user-invoked: one edits a `CLAUDE.md` and
creates links under `~/.claude`, the other writes agents, a skill and a marked section into a
project, and both are the human's call. `discover` and `test-triage` are model-invoked.

Each harness excludes a user-invoked skill from the model's reach in its own way, so nothing but the
human can fire it: no other skill can. A user-invoked skill may invoke model-invoked skills, but it
can never reach another user-invoked skill.

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
  `CLAUDE.md`; `testing-policy` and `test-triage` run inline because they edit, commit and ask.

Work that must talk to the user or write into the project runs inline. A lookup with a terse output
contract forks.

## Dependencies between them

Dependencies are expressed as an explicit instruction to **call the Skill tool** with the named skill
(`Call the Skill tool with "discover"`), not deep `../other-skill/FILE.md` cross-references, and not
a bare `/skill`-style mention left for the model to interpret. Naming the tool is what gets it fired:
most harnesses expose skill invocation as a tool the model calls, and spelling that out gets a higher
hit rate than dropping a `/name` into prose and hoping it is read as a command. Dropping the leading
`/` also keeps this harness-neutral: a skill name on its own carries no assumption about which
harness's trigger syntax it belongs to. Shared reference docs live inside the skill that owns them;
other skills reach that material by calling the Skill tool with it, not by linking across folders.

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
`/discover-setup`", never a Skill tool call.
