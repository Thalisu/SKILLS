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

Type `/testing-policy`, or the agent reaches for it automatically when a task fits: a mention of
the testing policy, the definition of done or the test-author agents, or a request to refresh the
testing DoD.

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

- **Done** is the full unit suite green plus the E2E coverage green, run against the change; an
  E2E stack that cannot run blocks, it never passes.
- **Unit tests are written red-first, one at a time**: a tracer bullet, then red, minimal green,
  refactor on green, next test. Never a batch of tests ahead of the code.
- **Tests describe behaviour through the public interface**, named for what they prove; mocks only
  at system boundaries, never the repo's own modules. A test that is hard to write that way is a
  design signal for a seam, not a reason to mock an internal.
- **A failing test is a product bug until shown otherwise.** Skips, weakened assertions, sleeps
  and adjusted expectations are forbidden; the one legitimate rewrite is a test that broke on a
  pure refactor, because it was testing implementation.
- **Reuse, then extend, then create**, with the second copy of any asset promoted to its shared
  home in the same changeset.

## The surface

The E2E gate is not the same for every repo, so the skill infers which surface the repo owns and
renders accordingly:

| Surface | The repo | The E2E gate |
|---|---|---|
| native | owns a user-facing surface and its E2E flows | the standard tiered gate, with an `e2e-test-author` agent |
| consumer | an API, a queue worker or a library with no surface of its own | impact-scoped over the repos that consume it; no E2E agent here, because a suite here would not represent the real flow |
| mixed | both | each half gated by its own rule |

## The Project map

The section states the gate; the two agents make it hold at authoring time. Each carries a
**Project map**: the real homes for mocks, helpers, factories, fixtures and page objects, and the
**System boundaries** the tests are allowed to mock, each with its shared mock. The map is
discovered from the repo and scoped to it; no example map ships with the skill, and a map from
another repo is never the model. With the map in hand an author is told where the assets are and
what a boundary is before writing, and reports a **Reuse audit** of what was searched and decided.

The duplication scan runs on every install and refresh, and its findings are reported, never
auto-fixed. The debt is paid by the second-use rule: the next author who needs a duplicated asset
consolidates it first.

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
`stale` at the same moment, and each is refreshed the same way.

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

## Where it fits

`testing-policy` is an install-then-refresh maintenance step: run it once per project, and again
whenever a `testing-policy-v<N>` tag moves or the verify script reports a state other than current.

- [test-triage](test-triage.md), because it enforces the same rule from the other side: the policy
  says a failing test is a product bug until shown otherwise, and the triage refuses to make a test
  pass by changing what it verifies.
- [discover](discover.md), because the test-author agents' Reuse audit is the same
  reuse-before-create check applied to test assets.

The grouped list of every skill is in [the top-level README](../README.md).
