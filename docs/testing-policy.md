# testing-policy

## What it does

`testing-policy` installs, migrates or refreshes a canonical Testing Policy, the project's
Definition of Done, in the current project. One run renders the marked
`## Testing Policy (Definition of Done)` section into `CLAUDE.md`, writes the `unit-test-author` and
`e2e-test-author` agents and the inline `test-author` skill under `.claude/`, copies the duplication
scan, and offers a hook that blocks a new skip marker in a test file. The rules between the markers
are the same in every repo; everything project-specific is a slot.

Nothing in the rendered section is invented. Every slot is filled from something that exists in the
repo, and every command written into Project facts or an agent's Project map was run once during
the install and returned output. A path, a command or an example the skill cannot find in the
project is asked for or left out; it is never guessed.

## When to reach for it

You invoke this by typing `/testing-policy`, and the agent won't reach for it on its own. It runs
inline, in your session, because it discovers the repo, asks about the roles it cannot map alone,
and writes into the project.

| Situation | Reach for |
|---|---|
| A repo with no testing rules, or a hand-written section in `CLAUDE.md` | `/testing-policy`, which installs or migrates |
| The verify script reports `policy=stale` or `drifted`, or an agent behind the template | `/testing-policy`, which refreshes the core and keeps the rest |
| Writing a test under the policy | the installed `unit-test-author` or `e2e-test-author` agent, or `/test-author`, in that project |
| A red suite you want explained and fixed | [test-triage](test-triage.md) |

## Prerequisites

The skill writes into the project, and everything it writes is meant to be committed there:

- a marked section of `CLAUDE.md`;
- `.claude/agents/unit-test-author.md`, and `.claude/agents/e2e-test-author.md` on a native or
  mixed surface;
- `.claude/skills/test-author/SKILL.md`;
- `.claude/testing-policy/`: the scan, the shared skip patterns, the optional hook, and a
  `capture/` folder for anything captured from the project;
- optionally a `PreToolUse` entry in `.claude/settings.json`, which needs `jq` on the machine.

## The rendered Definition of Done

The policy is a rendered artifact, not prose someone typed into `CLAUDE.md`. The normative rules
live in one template, and a render fills its slots from what the run discovered. Between the
`core-start` and `core-end` markers the text is identical in every repo; the `Project facts` block
after it holds the project-specific values. In one breath, the core says:

- **Done** is the change's own unit tests and E2E flows green, run against the change, then the
  post-feature gate the project picked: the full unit suite, the full E2E suite, both, or none. An
  E2E stack that cannot run blocks, it never passes. On a unit surface there is no E2E tier: the
  unit tests are the whole proof, and the gate is the full unit suite or none.
- **Unit tests are written red-first, one at a time**: a tracer bullet, then red, minimal green,
  refactor on green, next test. Never a batch of tests ahead of the code.
- **Tests describe behaviour through the public interface**, named for what they prove; mocks only
  at system boundaries, never the repo's own modules. A test that is hard to write that way is a
  design signal for a seam, not a reason to mock an internal.
- **Only what matters earns a test**: a behavior a caller relies on, where a wrong or missing
  result costs something. A string is judged by what rides on it, never by its kind: a message the
  user reads to act is an outcome, and a title that only proves it is there is structure. A rename,
  a moved file or a reordered section gets no test.
- **A settle point is a wait, never the proof**: an E2E flow waits for the state its next step
  needs, anchored on a URL, a landmark or the control itself rather than on copy, and it always
  ends on an outcome.
- **Every dispatch names who relies on the behavior** and what a wrong result costs them, and the
  author refuses one that names no cost. Its report points at the assertion that proves it.
- **A failing test is a product bug until shown otherwise.** Skips, weakened assertions, sleeps
  and adjusted expectations are forbidden; the one legitimate rewrite is a test that broke on a
  pure refactor, because it was testing implementation.
- **Reuse, then extend, then create**, with the second copy of any asset promoted to its shared
  home in the same changeset.
- **A dispatched author runs its test at most twice**: the first run, and the one after a single
  fix attempt on the test itself. Past that it returns `HANDBACK` with its diagnosis, the
  hypothesis it ruled out and the failing run, and the caller routes on the diagnosis: a
  production fault is the caller's change to make, a test fault buys one re-dispatch carrying the
  handback, and no behaviour is bought a third time. The handback saves the second author the
  search behind every asset, never the check on it: it re-runs the Discovery block over the paths
  the carried reuse audit names before it writes to one. An inline writer has no ceiling: it owns
  the production code, so it fixes until the test stands.

The post-feature gate is the one rule a project picks instead of inheriting, because what a full
suite costs differs from repo to repo. The install asks for it once, inside the single question it
already asks, and writes the answer to Project facts, where every refresh preserves it. A refresh
asks again only when the section predates the line.

## The surface

The E2E gate is not the same for every repo, so the skill infers which surface the repo owns and
renders accordingly:

| Surface | The repo | The E2E gate |
|---|---|---|
| native | owns a user-facing surface and its E2E flows | the standard tiered gate, with an `e2e-test-author` agent |
| consumer | an API, a queue worker or a library with no surface of its own | impact-scoped over the repos that consume it; no E2E agent here, because a suite here would not represent the real flow |
| mixed | both | each half gated by its own rule |
| unit | has no E2E tier at all, by the owner's choice | none: the unit tests are the whole gate, and no `e2e-test-author` agent is installed |

## The Project map

The section states the gate; the two agents make it hold at authoring time. Each carries a
**Project map**: the real homes for mocks, helpers, factories, fixtures and page objects, and the
**System boundaries** the tests are allowed to mock, each with its shared mock. The map is
discovered from the repo and scoped to it; no example map ships with the skill, and a map from
another repo is never the model. With the map in hand an author is told where the assets are and
what a boundary is before writing, and reports a **Reuse audit** of what was searched and decided.

The unit map carries one more line, **Partial test data**, for the helper that builds a fake without
asserting a type at the compiler. A TypeScript project whose tests are TypeScript is offered that
helper once, inside the single question that already carries the hook offer, so adopting it costs
one answer and no separate command. The install adds the package with the manager the project's
lockfile implies, in the workspace that holds the tests, and what the map line then reads is the
result:

| The project | The line reads |
|---|---|
| took the offer, or already had the package | the helper and the two functions it gives, one for partial data that still type checks and one for data that is wrong on purpose |
| is not TypeScript | `n/a`, so the label is filled in every project and in every mode |
| declined, or the add could not run | `none yet` and the command that would add it, a pointer and not a command that ran |

A no is not permanent, because nothing on disk records a decline:
the next run reads the state again and offers again, the way the hook offer comes back.
An add that fails costs the install nothing, and the report says the add failed and why.

The duplication scan runs on every install and refresh, and its findings are reported, never
auto-fixed. The debt is paid by the second-use rule: the next author who needs a duplicated asset
consolidates it first. The scan counts the type assertions in the test files the same way, one
line per file with a count, and the install reports that debt beside the others and rewrites no
test file: it is paid by the next author who touches the file.

## The author tier

Each author the install writes runs on a model and an effort the project picks, written into the
agent's frontmatter as `model:` and `effort:`. The install asks once per author, with four
options: a Recommended pair derived from the counts discovery measured (`opus · medium` for the
unit author, one effort step up to `opus · high` where the shared homes carry debt, and
`opus · high` for the E2E author on every project), `fable · medium`, often competitive with Opus
and Sonnet on cost per task while scoring higher, and held at `medium` rather than `low` because at
`low` Fable 5.1 calls search tools less often and the author's core job, the reuse audit, is a
search ([ADR 0058](adr/0058-the-author-tier-offers-fable-at-medium-and-never-at-low.md)),
`sonnet · high` as the cheaper pair, weaker than the Fable option at the reuse audit and the
handback diagnosis at a comparable cost per task, and `inherit`, which runs the author on the
session's model and effort. Where the flows depend on stateful services, the E2E option says so
and leaves `opus · xhigh` to a free-text answer: that step-up is unmeasured, and `xhigh` is
reserved for a measured quality gain
([ADR 0059](adr/0059-the-e2e-author-is-recommended-at-high-effort-and-xhigh-is-never-recommended-unmeasured.md)).
A free-text answer is taken
only when both values are ones Claude Code accepts. The Recommended model is the stronger one
because the author also plans the test and diagnoses its own misses, and a wrong test is paid twice
under red-first; the effort is where the dispatch volume is paid down
([ADR 0052](adr/0052-the-test-authors-carry-the-model-and-effort-the-project-picked-at-install.md)).

The frontmatter is preserved on refresh, so the pick sticks. An agent installed before the tier
existed reads `agent_unit_tier=missing` in the verify output, and the next run asks it.

## Modes

The verify script detects the project's state, and the state picks the mode:

| State | Mode | What happens |
|---|---|---|
| `none` | install | the full set is written |
| `legacy`, an unmarked section | migrate | the old section is replaced in place; each project-specific rule in it is kept in Project facts or dropped, by explicit choice |
| `stale`, an older version, or `drifted`, a hand-edited core | refresh | only the core between the markers is regenerated; Project facts, the agents' frontmatter and Project map are preserved verbatim |
| `current` | nothing | unless an agent or the hook is behind, which is repaired alone |

Discovery runs on refresh too, but a disagreement with the written Project map is reported, not
applied. The user decides.

## Common questions

**The verify script says `policy=stale` after a pull of this repo. What now?**
The template version moved. The version is stamped into every installed section as
`<!-- testing-policy:start v=N surface=... -->` and into each agent after its frontmatter, and
`testing-policy-v<N>` tags mark it on this repo. Run `/testing-policy` in the project: refresh
replaces only the core and keeps everything the project filled in. Every installed project reports
`stale` at the same moment, and each is refreshed the same way. The history so far: 2.1 added
agent drift detection, the shared skip patterns and the mixed gate; 2.2 moved the core to behaviour
over implementation, boundary mocking and vertical TDD; 2.3 rewrote the templates' prose without
changing a rule; 2.4 added the **Partial test data** line to the unit map; 2.5 made the gate after
a feature a pick the install asks for, recorded as **Post-feature gate** in Project facts, and
narrowed the per-change unit run to the tests the change adds or touches; 2.6 added the unit surface
and the rule that a test proves a behavior a caller relies on, never a name, a place or a phrase;
2.7 judged a string by what rides on it instead of by its kind, named the settle point in the E2E
core, and added the **Relied on by** dispatch field and the **Outcome** report line; 2.8 capped a
dispatched author at one fix attempt and added the `HANDBACK` verdict and its report section; 2.9
closed the hardcoding reading of **Green is minimal**: the test verifies correctness and never
defines the solution, so a constant or a branch that recognizes the test's inputs is not green;
2.10 aligned the agent cores with the prompting guidelines: a forked author returns its refusal
instead of asking, the Discovery block's commands go out in one response, a promotion edits each
call site in place, the report carries one example of a reuse audit entry and one of a handback,
the Forbidden lists are bare checklists, and a carried `HANDBACK` rides in a tagged **Handback**
field of the dispatch input.

**What is the difference between `stale` and `drifted`?**
`stale` is an older version, the expected signal after the template moves. `drifted` is the
current version with a hand-edited core, and a refresh puts the rendered core back, so the hand
edit is lost. A project-specific rule belongs in Project facts, which every refresh preserves.

**A refresh reports disagreements on every slot. Is the discovery broken?**
Usually not. That pattern means the Project map was hand-edited, or the repo's test tree moved
since the install. The written map stays untouched either way; the report lists each disagreement
for you to accept or reject.

**Why does my API repo have no `e2e-test-author` agent?**
Its surface is consumer: it owns no user-facing flow, so an E2E suite in it would not represent the
real flow. The gate is impact-scoped over the consumer repos named in Project facts, and the
inline `test-author` skill names them.

**Why does the scan report a duplicate and then leave it?**
By design. The scan reports; it never edits. The second-use rule pays the duplication organically,
when the next author who needs that asset consolidates it first.

**What are `gitignored=` and `capture_legacy=` in the verify output?**
Two defects in git visibility. `gitignored=` lists installed paths that git ignores; agent
worktrees, CI and the hook only see tracked files, so an ignored agent or scan is a broken install,
and the team should read the maps from git rather than re-run the install. `capture_legacy=` names
a gitignored capture folder left by an older install, which the skill offers to move into
`.claude/testing-policy/capture/` and commit. Earlier versions gitignored captures; the current
rule is that everything captured from a project is committed in that project, and nothing
captured ever enters this skill's own directory.

## It's working if

- After the run, the verify script prints `policy=current` and exits 0, and every installed file
  shows as tracked in `git status`, none of it ignored.
- The section in `CLAUDE.md` sits between start and end markers carrying `v=` and `surface=`, and
  the text between the core markers is identical to the one in any other repo on the same version.
- Every path and command in an agent's Project map exists in this repo and runs.
- With the hook installed, an edit that adds `.skip` or `.only` to a test file is blocked, and an
  edit that removes one passes.
- Each installed author's frontmatter carries the `model:` the project picked, and the verify
  script prints `agent_unit_tier=ok` (and `agent_e2e_tier=ok` on native and mixed).
- The unit map's **Partial test data** line and the verify script's `partial_data_helper=` agree. A
  disagreement is a project that dropped the package while its map still names the helper.

## Where it fits

`testing-policy` is an install-then-refresh maintenance step: run it once per project, and again
whenever a `testing-policy-v<N>` tag moves or the verify script reports a state other than current.

- [test-triage](test-triage.md), because it enforces the same rule from the other side: the policy
  says a failing test is a product bug until shown otherwise, and the triage refuses to make a test
  pass by changing what it verifies.
- [discover](discover.md), because the test-author agents' Reuse audit is the same
  reuse-before-create check applied to test assets.

The grouped list of every skill is in [the top-level README](../README.md).
