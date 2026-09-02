# SKILLS

Agent skills I maintain across projects. Each skill is a self-contained directory under `skills/`, following the [Agent Skills](https://docs.claude.com/en/docs/claude-code/skills) convention: a `SKILL.md` with YAML frontmatter, plus optional `scripts/`, `references/` and `assets/`.

| Skill | Purpose |
|---|---|
| [`testing-policy`](skills/testing-policy) | Install and keep in sync a canonical Testing Policy (Definition of Done) across repos |
| [`discover`](skills/discover) | Batch "does this already exist in the repo?" lookups answered by a Haiku subagent in one line per symbol |
| [`discover-setup`](skills/discover-setup) | Wire the discover agent and skills on a machine and install or update the mandatory Discovery rule in a project's `CLAUDE.md` or in the user's `~/.claude/CLAUDE.md` |
| [`test-triage`](skills/test-triage) | Run a test target, cluster the failures, auto-fix and commit only the small ones, file a dossier in `docs/tests/` for the rest |

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
| `scripts/forbid-test-skips.sh` | optional `PreToolUse` hook blocking new `.skip` / `.only` / `xit` / `pytest.mark.skip` / Maestro `optional: true` in test files |

Two invariants hold across every mode:

- **Nothing is invented.** Every slot is filled from something that exists in the project — never a guessed path, command or example.
- **Nothing is written unverified.** Every command that lands in `Project facts` or an agent's `Project map` was run once during the install and returned output.

### What the core says

The rules between the markers are the same in every repo. In one breath:

- **Done** is the full unit suite green plus the E2E coverage green, run against the change; an E2E stack that cannot run blocks, it never passes.
- **Unit tests are written red-first, one at a time**: a tracer bullet, then red → minimal green → refactor on green → next test. Never a batch of tests ahead of the code.
- **Tests describe behavior through the public interface**, named for what they prove; mocks only at system boundaries (the unit agent's map names them), never the repo's own modules. A test that is hard to write that way is a design signal for a seam, not a reason to mock an internal.
- **A failing test is a product bug until shown otherwise.** Skips, weakened assertions, sleeps and adjusted expectations are forbidden; the one legitimate rewrite is a test that broke on a pure refactor, which was testing implementation.
- **Reuse > extend > create**, with the second copy of any asset promoted to its shared home in the same changeset.

### Why the agents matter

The `CLAUDE.md` section states the gate; the two agents are what make it hold at authoring time. Each carries a **Project map** — the real homes for mocks, helpers, factories, fixtures, page objects, and the system boundaries the tests are allowed to mock — discovered from the repo rather than assumed. That is what turns "reuse shared assets" and "mock at boundaries only" from advice into something actionable: the author is told where the assets are and what a boundary is before writing, and reports a **Reuse audit** of what was searched and what was decided.

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

## discover

### The problem

In a long implementation session, every "does this already exist?" check is a glob → grep → read →
grep sequence that leaves 8–15k tokens of low-density tool output in the main context, permanently.
Six to eight of those per session is the difference between finishing a feature and compacting in the
middle of it. Done inline, the lookup also misses when the name differs: `formatCpf` exists as
`maskDocument`, the model reimplements it, and the repo now has two.

### What it does

`discover` moves the lookup into a **Haiku subagent with a strict, terse output contract**, driven by
**one deterministic script call per batch**. The orchestrator asks once per feature, with every
candidate in one batch, and gets one line per item back — roughly 40 tokens each:

```
1 DUPLICATE  src/utils/format.ts:1  formatCpf(value: string): string · 2 uses ‖ src/legacy/format.ts:1  formatCpf(value: string): string · 0 uses · HIGH
2 PARTIAL    src/hooks/useThrottle.ts:3  useThrottle<T …>(callback: T, delay: number): T — throttles instead of debouncing · LOW
3 NOT_FOUND  tried: withRetry,retryRequest,fetchWithRetry · analog: src/lib/http/client.ts:1 (generic HTTP request wrapper) · home: src/lib/http · HIGH
4 FOUND      src/billing/invoice.ts:3  createInvoice(customerId: string, total: number): Invoice · 2 uses · callers: src/billing/checkout.ts:4, src/billing/report.ts:4 · HIGH
```

| Piece | Role |
|---|---|
| `skills/discover/AGENT.md` | the Haiku agent: `tools: Bash` only, `maxTurns: 5`, no memory, no LSP; the contract and the single heredoc call it may make |
| `skills/discover/SKILL.md` | `/discover <batch>` — a `context: fork` wrapper on the agent with `background: false`, so the orchestrator waits for the result even with fork mode on |
| `skills/discover/scripts/discover.sh` | one call per batch; spec on stdin; deterministic report (`ROOT` / `DEF` / `NAME` / `ANALOG` / `HOME` / `CALLERS` / `STATE`) read by the agent only |
| `skills/discover/scripts/selftest.sh` | runs the script on `tests/fixture` (37 files, 16 languages) and diffs `tests/expected.txt` |
| `skills/discover/tests/*.sh` | invariant tests: `root.sh` (absolute-root header), `contract.sh` (AGENT.md pins `--root` to the repo toplevel), `errors.sh` (a malformed spec line never kills the batch), `section-lint.sh` (section text findings), `setup-roundtrip.sh` (stale→current machinery under a temp `HOME`) |
| `skills/discover/tests/sim/run.sh` | compliance simulation — throwaway repos, the section rendered into their `CLAUDE.md`, headless `claude -p` sessions asserted on transcript + repo state; the acceptance gate runs every scenario at 3/3 reps |
| `skills/discover/references/languages.md` | the ast-grep kind table per language, each kind tied to the fixture line that proves it |

The script finds definitions with **kind-based ast-grep rules and a name filter** — never pattern
syntax, which misses every definition with a type annotation — over a file list shared by every stage
(`rg --files`, `.gitignore` respected, tests, snapshots, `node_modules` and `*.d.ts` excluded). Uses
are counted per definition by resolving each importing file's specifier, so duplicates come out most
used first; when nothing is defined, a stem search over names and behaviour text yields the closest
analog and a suggested home. On a 1,000-file Next.js + Python repo a five-item batch runs in under a second.

### Contract

Input, one item per line: `<n>. <behaviour in one line> — names: <name1>, <name2>[, …] [— callers?]`.
At least two names per item; the behaviour text feeds the stem search.

| State | Meaning | Rule for the orchestrator |
|---|---|---|
| `FOUND` | exactly one definition matches a candidate name | import and reuse |
| `DUPLICATE` | two or more, most used first | import the first; name the duplicate in the audit line |
| `PARTIAL` | a sibling exists (throttle for a debounce request) | extend it, or say in one line why not |
| `NOT_FOUND` | no definition; always with `tried:`, `analog:`, `home:` | create it in the suggested home |
| `ERROR` | the script failed, the call was not permitted, or that item's spec line was malformed (the other items still answer) | fix the cause; nothing was searched for that item |

Confidence closes every line: `HIGH` only for ast-parsed definitions; `MED` for word hits, items with
fewer than two names and most `NOT_FOUND`; `LOW` means the orchestrator must search itself.

### Install

```bash
git clone https://github.com/Thalisu/SKILLS.git ~/SKILLS
ln -s ~/SKILLS/skills/discover-setup ~/.claude/skills/discover-setup
```

Then, from a project:

```
/discover-setup            # asks: project, user, or both
/discover-setup project    # <project>/CLAUDE.md — shared with teammates through the repo
/discover-setup user       # ~/.claude/CLAUDE.md — every project on this machine, yours only
```

That links `~/.claude/agents/discover.md` and both skills (idempotent), reads the version already
installed in the chosen `CLAUDE.md`, then appends the marked `## Discovery (mandatory)` section
(`<!-- discover:start v=N -->` … `<!-- discover:end -->`) or updates an older one in place. A project
change is left uncommitted. In a default-permission session the agent's Bash call prompts once;
the setup offers the `permissions.allow` entry and never writes it without a yes.

### Verify

```bash
bash ~/SKILLS/skills/discover-setup/scripts/verify.sh <project>   # scope=, section=, agent_link=, skill_links=, deps=
bash ~/SKILLS/skills/discover-setup/scripts/verify.sh --user      # same, for ~/.claude/CLAUDE.md
bash ~/SKILLS/skills/discover/scripts/selftest.sh                 # selftest: ok
```

### Versioning

`discover-v<N>` tags track the section template version — the `<!-- discover version: N -->` line in
`skills/discover-setup/CLAUDE-SECTION.md`, stamped into every installed section as
`<!-- discover:start v=N -->`. A project behind the tag reports `section=stale`; a hand-edited body
reports `drifted`, and `install.sh` replaces it only with `--force`.

## test-triage

### The problem

A red suite invites three bad reflexes: making the test pass by changing what it verifies, re-running until it
goes green, and calling an unreachable database "a failing test". And the work of finding out *why* something
is red evaporates when the session ends — the next one starts the same investigation from zero.

### What it does

`test-triage` runs one target (unit, e2e, all, a file or a filter), clusters the failures by root cause and
splits them into two buckets with a hard line between them:

- **Small fix** — root cause proven, the change fits in exactly one existing file: production code, or test
  *access* code (selectors, labels, routes, fixture data) with git evidence that the UI or contract changed on
  purpose. Applied, verified against the target and the full unit suite, committed one per cluster. Anything that
  does not turn green is rolled back with `git checkout`; the tree always comes back clean.
- **Hard work** — schema, contract, race condition, more than one file, uncertain cause, or a fix that would
  change a result assertion. Never auto-fixed: registered as a numbered dossier in `docs/tests/` with a closed
  `veto` vocabulary and an English body (`Error`, `Hypothesis`, `Ruled out`, `Next step`) — never committed:
  the skill keeps `docs/tests/` in `.gitignore`.

Infra failures — connection refused, container down, app not answering — are a third thing: boot → one retry
per cause → **BLOCKED**. Never green, never a test failure, never a dossier.

| Piece | Role |
|---|---|
| `skills/test-triage/SKILL.md` | the workflow: target → command → run → cluster → flake check → classify → fix or dossier → reconcile → report |
| `scripts/context.sh` | injected at load time through the `!` block: branch and protection, dirty files, `package.json` scripts tagged local / remote-smelling, `runner.json`, open dossiers; never exits non-zero |
| `scripts/dossier.sh` | `next-id`, `new`, `ensure-ignored`, `list-open`, `bump`, `green` — every dossier write goes through it, and `new` keeps `docs/tests/` gitignored |
| `assets/dossier-template.md` | the schema-2 frontmatter and the four body sections |
| `references/runner-config.md` | `docs/tests/runner.json` schema, discovery precedence, single-target forms, the verified `${CLAUDE_SKILL_DIR}` / `allowed-tools` behaviour |
| `references/dossier-schema.md` | frontmatter fields, veto vocabulary, reconcile rules, script reference |
| `evals/` | five prepared cases for `claude plugin eval` |

Two invariants:

- **Nothing is invented.** Commands come from `docs/tests/runner.json` — the skill's own record, written only
  from a command the user gave and that ran — or from `package.json` scripts by name, local before remote. Never
  from another manifest, never from another repository.
- **Memory lives in the repo, out of its history.** Open dossiers are reconciled at the end of every run —
  bumped when the failure repeats, closed when their test runs green (a flake needs two green runs) — but
  `docs/tests/` stays in `.gitignore`: nothing inside it is ever committed, and nothing is pushed.

### Install

```bash
git clone https://github.com/Thalisu/SKILLS.git ~/SKILLS
ln -s ~/SKILLS/skills/test-triage ~/.claude/skills/test-triage
```

Then, from a project:

```
/test-triage unit
```

The first run in a repository without a recognisable test script asks once for the suite and single-target
commands and records them in `docs/tests/runner.json`. Default permission mode needs nothing else: the skill's
`allowed-tools` covers the injected script.

### Versioning

`test-triage-v<N>` tags mark the skill versions: `v1` is the single-file skill as first authored, `v2` the
versioned layout with scripts, references, evals and the `runner.json` record.

## License

MIT — see [LICENSE](LICENSE).
