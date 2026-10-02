# CLAUDE.md

Rules for working in this repository. They apply to every change made here, by a human or by an
agent. The long-form contracts are not loaded into the session: each "Read `<path>` before <task>"
line below names the file to open when the task is that one.

## Invocation: every skill is one or the other

Every `SKILL.md` under `skills/` and `vendor/` is either **user-invoked** or **model-invoked**.
There is no third state, and the choice is made explicitly when the skill is created.

- **User-invoked**: reachable only by the human typing its name. Set
  `disable-model-invocation: true` in the `SKILL.md` frontmatter (Claude Code) and
  `policy.allow_implicit_invocation: false` in `agents/openai.yaml` (Codex). Both, always: a skill
  is user-invoked in both harnesses or in neither. Its `description` is human-facing, a one-line
  summary for a person browsing slash commands, with no trigger lists.
- **Model-invoked**: reachable by the model or by the user. Omit `disable-model-invocation`, and
  omit the `policy` block from `agents/openai.yaml`. Its `description` is model-facing and keeps
  trigger phrasing ("Use when the user wants..., mentions..., asks for...") so auto-invocation
  fires.
- A step may tell the agent to call the Skill tool with a model-invoked skill, and never with a
  user-invoked one, which only the human can fire.
- A skill that ships an `AGENT.md` opens a second door, the Agent tool, gated by that agent's
  description naming the callers it accepts.

Read `.agents/invocation.md` before adding a skill, changing how one is reached, or making one
skill or agent call another.

## READMEs and docs

- Adding, renaming or removing a skill updates the top-level `README.md` and its folder's
  `README.md` (`skills/README.md` or `vendor/README.md`) in the same change.
- Read `.agents/readmes.md` before editing any of those three READMEs.
- Read `.agents/writing-docs.md` before writing a human-facing page under `docs/` or re-syncing
  one after a skill changes.

## Reference folders under `.agents/`

- `.agents/principles/` holds design principles as plain reference documents, one per file,
  indexed in its `README.md`. They are not skills: no frontmatter, no invocation, and no harness
  lists them. A skill or a contract that leans on one links the file by path.
  A vendored skill names it by file name instead (`vendor/README.md`, item 7), since it is
  installed into projects where no path into this repo resolves.
- `.agents/formats/` holds the formats of the artifacts the skill chain shares, one per file,
  indexed in its `README.md`, per `docs/adr/0004`. A skill that writes or reads one links the file
  by relative path: never a copy, and never a link into another skill's folder. A format read by
  one skill only stays in that skill's `references/`.
- `.agents/reading/` holds the read map, one hand-written file per task, indexed in its
  `README.md`: the sections of the verbatim copies below worth reading for that task, anchored
  on heading text. `scripts/check-reading-map.sh` fails on an anchor a refresh renamed.
- Adding, renaming or removing a principle, a format or a read case updates that folder's index in
  the same change.
- `.scratch/` is where a project keeps the chain's local artifacts, and it is always unversioned:
  one developer's own workspace, which a teammate never reads. A skill that reads or writes there
  links `.agents/scratch.md` by path, never a copy.
- Read `.agents/scratch.md` before making a skill read or write `.scratch/`, or run inside a git
  worktree.

## Verbatim guideline copies

`.agents/prompting/`, `.agents/skill-authoring/`, `.agents/test-and-evaluate/` and
`.agents/claude-code/` hold verbatim copies of upstream pages, one file per page, each folder
indexed in its `README.md` with the upstream URL and the date it was fetched.

- Refresh a copy by re-fetching it, never by hand, then run `bash scripts/check-reading-map.sh`.
- Adding, refreshing or removing a copy updates that folder's index in the same change.
- Where the skill-authoring page and a contract in this repo differ, the contract wins: the
  upstream page is general advice, and `.agents/invocation.md` is the rule here.

Never read a copy whole. `.agents/reading/` maps each task to the sections worth opening: read
the task's case file there before the task, then only the sections it lists.

- A `SKILL.md` body: `skill-body.md`
- A skill's frontmatter or description: `skill-frontmatter.md`
- A skill's folder (`references/`, split files): `skill-folder.md`
- A script a skill ships: `skill-script.md`
- An agent definition, or a brief handed to a subagent: `agent-or-brief.md`
- A prompt inside a script or a headless call: `script-prompt.md`
- An eval (a skill's `evals/`, a grader, a test that runs a model): `eval.md`. A unit test of
  this repo's scripts follows the Testing Policy below instead.
- Speed or cost (model choice, effort, prompt and output length): `speed-and-cost.md`
- What belongs in a `CLAUDE.md`, or in a rule, a skill or a hook instead: `claude-md-scope.md`
- Wording or trimming a `CLAUDE.md`, this one or one a setup skill writes: `claude-md-wording.md`
- Instruction file location, imports, `.claude/rules/`, `AGENTS.md`: `claude-md-location.md`
- A long-running or multi-step workflow, or how a skill verifies its work: `workflow.md`
- Output format, tone or verbosity: `output-format.md`

## Vendored dependencies

- `vendor/` holds the skills this repo's skills call and does not own. Edit one only to adapt it
  to the harnesses or to refresh it from upstream; any other change goes upstream first.
- Read `vendor/README.md` before editing, adding or refreshing a vendored skill, or calling one
  from a step in `skills/`.

## Installing skills locally

- `scripts/link-skills.sh` (argument `claude` or `codex`) is the supported installer: a skill
  or an agent definition it does not pick up is not installed at all.
- Re-run it after adding, removing or renaming a skill.
- `bash scripts/tests/link-skills.sh` runs it against this repo and fails on anything on disk it
  leaves unlinked.

<!-- testing-policy:start v=3.0 surface=unit -->
## Testing Policy (Definition of Done)

<!-- testing-policy:core-start -->
A feature or fix is DONE only when its own unit tests pass and then the post-feature gate passes.
"Tests didn't run" is never "tests passed".

The rules below are fixed and hold in every session. They are the short form: the read triggers
after them name the section that carries each rule in full. The project's commands, paths, tool
names and the post-feature gate it picked live in **Project facts** at the end of this section.

- **Gate**: per change, the change's own tests are green: the unit tests it added and the ones
  covering the code it touches. Per feature, the post-feature gate in Project facts runs on the
  integrated result. This repo has no end-to-end suite by choice, so a behavior no unit test
  reaches is not covered.
- **Red-first, one test at a time**: write the failing unit test before the implementation; for a
  bugfix, the test reproduces the bug before the fix turns it green. One test per cycle (red →
  green → next), never a batch of tests ahead of the code, and green is only the code the current
  test needs.
- **Behavior, not implementation**: a test exercises the target through its public interface,
  asserts only what a caller can observe, and mocks at system boundaries only. A change with no
  observable effect ships with no new test.
- **Every new test goes through the test author**: a new test file or a new test case is written
  under the test-author checklist, whose single source is the agent file:
  `.claude/agents/unit-test-author.md`.
  With the `Agent` tool, dispatch the agent, one dispatch per cycle. Without it, invoke
  `/test-author`. Editing an existing case stays with the caller, unless it needs a new shared
  asset.
- **A failing test is presumed to expose a product bug, not a test bug**: never skip, narrow or
  mark optional a failing test or assertion, and never adjust a unit expectation to match buggy
  behavior. Changing a test to make it pass requires demonstrating that the flow itself changed,
  or that a pure refactor exposed it asserting implementation, stated in the commit or report.
- **The agent runs in place**, never in a worktree (reason in Project facts).

- Read `.claude/testing-policy/policy.md` before declaring a change or a feature done, section
  **Success gate (tiered)**.
- Read `.claude/testing-policy/policy.md` before choosing the tests of a change, writing one,
  mocking a dependency, or refactoring on green, sections **TDD** and **Tests describe behavior,
  not implementation**.
- Read `.claude/testing-policy/policy.md` before dispatching a test author, or acting on what it
  returned (the dispatch input, a test still red after implementation, a `HANDBACK` verdict, a
  promoted shared asset, authors that ran in parallel), section **Test authoring: delegation and
  reuse**.
- Read `.claude/testing-policy/policy.md` before deciding whether a change needs a test, section
  **Coverage mapping**.
- Read `.claude/testing-policy/policy.md` before changing, weakening or removing an existing test,
  section **Tests represent the real flow**.
<!-- testing-policy:core-end -->

### Project facts

<!-- Filled at install from the project's real setup; PRESERVED on refresh (the skill only reports
     when a fresh discovery disagrees). Every command here has been run once and returned output. -->

- **Unit**: full suite `fails=0; for t in $(git ls-files --cached --others --exclude-standard | grep -E '^(scripts|skills/[^/]+)/tests/[^/]+\.sh$' | grep -vx 'scripts/tests/lib.sh'); do bash "$t" >/dev/null 2>&1 || { echo "RED $t"; fails=$((fails+1)); }; done; echo "red: $fails"; [ "$fails" = 0 ]` · single file `bash skills/<skill>/tests/<name>.sh` or `bash scripts/tests/<name>.sh` · mandatory flags / known phantom failures: no runner or framework: each script prints `ok` / `FAIL` per case and exits non-zero on a red; `skills/do/tests/context-usage.sh` prints a `skip  live session` line outside a live Claude session, which is not a red · skip mechanisms: no framework skip; the repo's idiom is an `echo "skip ..."` line that leaves a case out (`skills/do/tests/context-usage.sh:164`), and an early `exit 0` or a commented-out `check` does the same; the hook blocks a new `echo "skip` line through `.claude/testing-policy/skip-patterns.local.sh`
- **Post-feature gate**: none: the per-change tier is the whole gate, the change's own test scripts (full suite, when run by hand: the unit loop above)
- **Duplication scan**: `bash .claude/testing-policy/scan-test-assets.sh --root scripts/tests --root skills` · shared homes per role: the agent's Project map
- **Why the agent runs in place**: the harness's worktree tool isolates the session, and an isolated session refuses `bash <script>` (`.agents/worktrees.md`), which is how every test script here runs
<!-- testing-policy:end -->

## Prose style: no em-dashes

No em-dashes anywhere in this repo's prose: `SKILL.md` files, docs, `README.md`, ADRs and code
comments.

- Where a sentence reaches for one, rewrite the sentence. Use a comma, a colon, a period,
  parentheses or a conjunction, whichever the sentence actually wants.
- This list wins over `vendor/unslop/SKILL.md` items 13 and 14, which allow periods and commas
  only and ban a colon as a connector, including when `technical-writing` applies `unslop` to a
  doc here: parentheses and a connecting colon are how this repo's prose is already written.
- Never do a blind character substitution: replacing every em-dash with a hyphen or a comma leaves
  prose that reads as if a machine ran over it.
- The verbatim guideline copies keep their upstream punctuation, since they are never edited by
  hand.
- The character stays as a delimiter in two machine contracts: the discover batch line
  (`<n>. <behaviour> — names: ...`, `[— callers?]`) and the discover PARTIAL output line
  (`<signature> — <how it differs>`). Those, and the test data that exercises them, are syntax,
  not prose.

## Setup skills stay project-scoped

A skill that sets a project up writes its output into that project, scoped to it, never globally.

- The install target is the project's own files (its `CLAUDE.md`, its `.claude/`), committed in
  that repo, so the team reads it from git instead of re-running the skill on every machine. The
  global scope (`~/.claude/CLAUDE.md`) is used only when the user asks for it explicitly.
- Nothing a skill learns about a project comes back here. No skill in this repo names a repository
  it has run against, private or public, by name, path, URL or worked example. This repo is shared
  by every project and it is public, so anything project-derived kept in it would be global by
  construction.
- Every mapping stays in the repo it was derived from: a Project map, a runner config, a dossier,
  a captured convention.
- Nothing is gitignored to that end: a stray `local/` or `capture/` directory under `skills/` or
  `vendor/` shows up in `git status`. The versioned `.githooks/pre-commit` refuses to commit one,
  in a clone that enabled it once with `git config core.hooksPath .githooks`. That hook is the
  backstop, not a sanctioned home for captures.
