# SKILLS

Agent skills I maintain across projects. Each skill is a self-contained directory under `skills/`, following the [Agent Skills](https://docs.claude.com/en/docs/claude-code/skills) convention: a `SKILL.md` with YAML frontmatter, plus optional `scripts/`, `references/` and `assets/`.

| Skill | Purpose |
|---|---|
| [`testing-policy`](skills/testing-policy) | Install and keep in sync a canonical Testing Policy (Definition of Done) across repos |

---

## testing-policy

### The problem

A testing Definition of Done written once into a `CLAUDE.md` decays in three ways:

- **It drifts.** Every repo hand-edits its copy. After a few months no two repos enforce the same gate, and there is no way to tell which one is current.
- **It gets invented.** A policy that names commands and paths is only useful if those commands and paths are real. Written from memory, it names a test script that doesn't exist and an E2E command nobody can run.
- **It isn't enforced where tests are written.** A section in `CLAUDE.md` is read at session start and forgotten by the time someone actually authors a test file.

### What it does

`testing-policy` treats the Definition of Done as a **rendered artifact, not prose**. The normative rules live in one template (`POLICY.md`); everything project-specific is a `{{slot}}` filled from discovery run against the actual repo. Running the skill installs, migrates or refreshes the whole set:

| Source | Installed as |
|---|---|
| `POLICY.md`, via `scripts/render-policy.sh <surface>` | the marked `## Testing Policy (Definition of Done)` section in `CLAUDE.md` |
| `AGENT-UNIT.md` | `.claude/agents/unit-test-author.md` |
| `AGENT-E2E.md` | `.claude/agents/e2e-test-author.md` — native and mixed surfaces only |
| `SKILL-TEST-AUTHOR.md` | `.claude/skills/test-author/SKILL.md`, the inline path for writers without the `Agent` tool |
| `scripts/scan-test-assets.sh` | `.claude/testing-policy/scan-test-assets.sh` — duplication and skip-marker scan |
| `scripts/hooks/forbid-test-skips.sh` | optional `PreToolUse` hook blocking new `.skip` / `.only` / `xit` / `pytest.mark.skip` / Maestro `optional: true` in test files |

Two invariants hold across every mode:

- **Nothing is invented.** Every slot is filled from something that exists in the project — never a guessed path, command or example.
- **Nothing is written unverified.** Every command that lands in `Project facts` or an agent's `Project map` was run once during the install and returned output.

### Why the agents matter

The `CLAUDE.md` section states the gate; the two agents are what make it hold at authoring time. Each carries a **Project map** — the real homes for mocks, helpers, factories, fixtures, page objects — discovered from the repo rather than assumed. That is what turns "reuse shared assets" from advice into something actionable: the author is told where the assets are before writing, and reports a **Reuse audit** of what was searched and what was decided.

The duplication scan is reported, never auto-fixed. Debt is paid organically by the second-use rule: the next author who needs a duplicated asset consolidates it first.

### Surfaces

The E2E gate is not the same for every repo, so the skill infers the surface and renders accordingly:

- **native** — the repo owns a user-facing surface and its E2E flows. Standard tiered gate.
- **consumer** — an API, queue worker or library with no surface of its own. Real E2E coverage lives in the repos that consume it; an E2E suite here would not represent the real flow. The gate becomes impact-scoped over the consumer list.
- **mixed** — both, with each half gated by its own rule.

### Modes

`scripts/verify-policy.sh <project>` detects the state and picks the mode:

| State | Mode | Behavior |
|---|---|---|
| `none` | install | full install |
| `legacy` (unmarked section) | migrate | replaces in place; project-specific rules from the old section are kept or dropped by explicit choice |
| `stale` / `drifted` | refresh | regenerates only the core between `core-start` / `core-end`; `Project facts` preserved verbatim |
| `current` | — | nothing to do |

Discovery runs on refresh too, but disagreements with the written `Project map` are **reported, not applied** — the user decides.

### Install

```bash
git clone https://github.com/Thalisu/SKILLS.git ~/SKILLS
ln -s ~/SKILLS/skills/testing-policy ~/.claude/skills/testing-policy
```

Then, from the project that should receive the policy:

```
/testing-policy
```

To check a project's state without changing anything:

```bash
bash ~/SKILLS/skills/testing-policy/scripts/verify-policy.sh <project>
```

### Versioning

Repo tags track the policy template version — the `<!-- testing-policy version: N -->` line in `POLICY.md`, which is stamped into every installed section as `<!-- testing-policy:start v=N surface=... -->`. A repo whose marker is behind the tag reports `policy=stale` and needs a refresh run, which is the whole point of the marker: drift becomes visible instead of silent.

## License

MIT — see [LICENSE](LICENSE).
