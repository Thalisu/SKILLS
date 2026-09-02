# discover v3 — TDD plan for the review findings

Scope: the nine findings of the 2026-09-01 review plus two new defects found in the
web-app trial (2026-09-02). Outer loop is an acceptance-test gate (the compliance
simulation) written and baselined FIRST; it must be all green, 3/3 reps, before this plan
is satisfied. Inner loop is strict red-green vertical slices — one failing test, one
minimal fix, never two tests ahead.

## Benchmark baseline (web-app, web-app, 167k lines src, 1258 files)

Recorded 2026-09-02, pre-fix. Re-run at the final gate; numbers must not regress.

- 6-item batch: 1.0s wall, 3,064 bytes report. Same lookups as raw `rg -n -w`: 824 lines,
  114,564 bytes (~37× larger). The batch's token advantage is real on a product repo.
- True positive worth keeping: `formatCpf`/`formatCnpj` DUPLICATE — namingFormatters.ts
  (28/3 uses) vs general.ts (2/1 uses), correct most-used-first order. Also caught an
  inline `formatCurrency` local to InvoiceImportModal.tsx:117.
- Defect N1 (analogs ignore filenames): `useDebounce` request returned NOT_FOUND with
  analogs sidebar.tsx / NewPlanModal.tsx / EditPlanModal.tsx and `HOME src/components/ui`,
  while `src/hooks/useDebouncedSubmit.ts` — the true sibling, "debounce" in its filename —
  matched only 2 content stems (score 2) and lost to score-3 noise.
- Defect N2 (callers dominated by one file): `hasPermission` (305 uses) showed 8 callers,
  7 from `scripts/verify-haspermission-coverage.cjs` — callers are sorted by path, not
  spread across files.

## Phase 0 — simulation harness (FIRST; the acceptance gate)

New: `skills/discover/tests/sim/run.sh [all|i|ii|iii|iv] [--reps N] [--section FILE]`.

Each scenario is a directory with `setup.sh` (builds a throwaway git repo under mktemp,
injects the section under test into its CLAUDE.md between the discover markers),
`prompt.txt`, and `assert.sh` (reads the headless transcript). Runner:
`claude -p "$(cat prompt.txt)" --output-format stream-json --max-turns 15` with cwd = the
temp repo; detection = a tool_use of Skill{skill:"discover"} or Agent{subagent_type:
"discover"} in the transcript. LLM output is stochastic: final gate runs `--reps 3`,
green means 3/3 per scenario; during development `--reps 1` is fine.

| # | scenario | fixture | green criteria |
|---|---|---|---|
| i | user pastes a failing function, asks for the one-line fix | copy of tests/fixture | no /discover call; no more than one direct rg; the fix lands |
| ii | "here is a spec listing createInvoice, voidInvoice, refundInvoice, listInvoices, checkout — verify against the code", prompt issued from a SUBDIRECTORY of the repo | copy of tests/fixture, cwd = src/billing | exactly one /discover batch with ≥4 items (never per-symbol calls); every reported path exists at the repo TOPLEVEL (root fix proven end-to-end); one audit line in the reply |
| iii | greenfield: add a new exported util | 5-file repo built by setup.sh | no forced /discover; a direct `rg -w` before creating is compliant; symbol gets created |
| iv | "where is the billing module?" | copy of tests/fixture | answered via direct search (Glob/rg); no batch composed |

Baseline expectation against the installed v2 text (record actual results before any fix):
(i) likely already green, (ii) RED on the toplevel-paths assert (root bug) and possibly on
batching, (iii) RED (v2 mandates the batch), (iv) flaky RED. A baseline where nothing is
red means the asserts are too weak — tighten before proceeding.

### Phase 0 baseline (recorded 2026-09-02 — installed section, model sonnet, --reps 1)

Note: the installed/template marker is `v=1`, not v2 as this plan says elsewhere; slice 7
bumps to the next version, whatever the number. Harness detail: each scenario runs in a
throwaway git repo with the section under test rendered into its CLAUDE.md, headless
`claude -p` under a sandboxed CLAUDE_CONFIG_DIR — the real ~/.claude (memory, hooks,
settings, plugins) never loads; credentials are symlinked, only the discover agent and
skill are wired in. Verified in-sandbox before baselining: /discover and the discover
agent visible, project CLAUDE.md loaded, global CLAUDE.md absent.

| # | result | detail |
|---|---|---|
| i | GREEN | fix landed; 0 discover calls; ≤1 direct search |
| ii | RED | batching itself fine (1 call, 5 items, audit line present); paths reported relative to src/billing — checkout.ts, invoice.ts, report.ts — root bug confirmed end-to-end |
| iii | RED | one discover batch forced in the 5-file repo |
| iv | RED | one discover batch composed for the where-is question |

As predicted: only the root bug is red in ii (batching held), iii/iv red under the current
mandate. Three of four red — the asserts have teeth.

Phase 0 exit: harness runs all four scenarios, baseline table committed in this file. ✔

## Inner slices (strict red → green, in this order)

Each script slice's red is the selftest: add the spec item to `tests/spec.txt`, write the
DESIRED lines into `tests/expected.txt`, watch `selftest.sh` fail, then make the minimal
change to `scripts/discover.sh`. Never edit expected.txt to match broken output.

### Slice 1 — BLOCKER: root is invisible and wrong (finding 1)
- RED: new `tests/root.sh` — run `discover.sh --root tests/fixture` from `/`; assert the
  report's first line is `ROOT <absolute-fixture-path>`. Fails: no ROOT line exists.
- GREEN: script prints `ROOT $(pwd -P)` after cd; update expected.txt (selftest drift is
  part of the red).
- RED 2: AGENT.md contract — new `tests/contract.sh` asserts AGENT.md's one tool call
  contains `--root "$(git rev-parse --show-toplevel`. Fails today.
- GREEN 2: AGENT.md call becomes
  `discover.sh --root "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"`.
  End-to-end proof stays with sim scenario ii (invoked from a subdir).

### Slice 2 — MAJOR: cross-language use counts and callers (finding 2)
- RED: spec item `34 | trim | trim helper (bash) | - | yes`. Desired expected: DEF
  discover-fixture bash def with `uses=0` and NO CALLERS line. Today: `uses=1`, caller
  `src/services/UserService.ts:12` (`id.trim()` — a TS string method).
  (Fixture already contains both sides of the collision; nothing new to build.)
- GREEN: `use_lines()` filters candidate files to the defining language's family before
  counting (families: ts/tsx/js/jsx/mjs/cjs · py · sh/bash · rs · go · java/kt/kts · one
  per remaining lang). NAME funnel and analogs stay cross-language on purpose (SQL table
  referenced from TS must keep working — spec item 31 guards it).

### Slice 3 — MINOR: one malformed line kills the batch (finding 6)
- RED: new `tests/errors.sh` — 3-line spec, middle line has empty names. Assert exit 0,
  items 1 and 3 fully answered, item 2 reported as `# 2` + `STATE ERROR malformed spec
  line`. Today: exit 2, no output for anyone.
- GREEN: parser stores the error per item instead of aborting; exit 2 only when every
  line is malformed (or spec empty). AGENT.md: map `STATE ERROR <reason>` →
  `<n> ERROR <reason>`, other items unaffected.

### Slice 4 — MINOR: stem funnel matches language keywords (finding 5)
- RED: spec item `35 | voidInvoice,cancelInvoice | void an issued invoice | - | no`.
  Desired: analogs all under src/billing, `HOME src/billing`. Today: top analog is
  useThrottle.ts (TS `void` keyword matched stem "void"), `HOME src/hooks`.
- GREEN: add language keywords to the `stems_of` stoplist (void async await static const
  class interface enum public private return yield state null undefined true false…).

### Slice 5 — trial defect N1: analogs ignore filenames
- RED: add fixture file `src/hooks/useDebounceLead.ts` (body deliberately poor in stems)
  plus keep the two existing stem-noise files; spec item
  `36 | useDebounce,debounce | delay a callback until input settles | - | no` expected to
  list useDebounceLead.ts as FIRST analog and `HOME src/hooks`. Today it ranks below
  content-stem noise.
- GREEN: analog scoring adds +2 when any stem matches the file's basename
  (case-insensitive) — mirrors web-app's buried useDebouncedSubmit.ts.

### Slice 6 — trial defect N2: callers dominated by one file
- RED: extend the slice-2 area — fixture gets one file calling createInvoice 7 times;
  spec item 6 (`— callers?`) expected to show at most 2 callers per file before moving to
  the next file, `+N more` still correct. Today: alphabetical fill lets one file take 7
  of 8 slots (web-app: verify-haspermission-coverage.cjs).
- GREEN: CALLERS selection round-robins across files (cap 2 per file until 8 filled).

### Slice 7 — section text v3 (findings 3, 4, 7, 8, 9 — ONE version bump)
All five text findings land in a single `<!-- discover version: 3 -->` bump so the
versioned-section machinery fires once, not five times (maintenance finding).
- RED: sim scenarios iii and iv failing against v2 (from the Phase 0 baseline), plus new
  `tests/section-lint.sh` asserting on CLAUDE-SECTION.md: contains "from any source"
  (exception rewrite, finding 4); contains a fallback line matching
  "if /discover errors" (finding 9); does NOT contain "planning reconnaissance" as a
  mandate trigger (finding 3); exactly one `Discovery:` audit format (finding 8);
  contains the small-repo carve-out (finding 7).
- GREEN: rewrite CLAUDE-SECTION.md v3 —
  (d) reworded: "verifying named symbols from an ADR/spec is a discover batch; open-ended
  recon is not — use direct search"; exception: "a single name you already have from any
  source"; carve-out: "repos under ~50 files: direct `rg -w` is compliant"; one audit
  line format, search-counting dropped ("repeated single lookups are a smell — batch
  them"); one fallback line for uninstalled machines.
- RED 3 → GREEN 3 (machinery roundtrip): new `tests/setup-roundtrip.sh` — temp project
  with a v2 section; `verify.sh` must say `section=stale installed_version=2`;
  `install.sh`; `verify.sh` exits 0 with `section=current`. Deterministic, no LLM.

## Final gate (satisfaction criteria — all of these, in one run)

1. `selftest.sh` green (expected.txt regenerated only through reviewed diffs).
2. `tests/root.sh`, `contract.sh`, `errors.sh`, `section-lint.sh`, `setup-roundtrip.sh`
   all green.
3. **Simulation all green: scenarios i–iv, 3/3 reps each, against the v3 section.**
4. web-app benchmark re-run: formatCpf/formatCnpj DUPLICATE still caught with
   correct order; report ≤ 4KB, ≤ 2s; `trim`-class phantom callers gone (spot-check:
   `hasPermission` callers spread across ≥ 4 distinct files); useDebounce lookup now
   surfaces useDebouncedSubmit.ts as top analog with `HOME src/hooks`.
5. Version machinery fired exactly once (v2→v3); `verify.sh` exits 0 on this machine.

Out of scope (explicitly deferred): LSP-backed reference counting (alternatives-d),
intel-file investment (alternatives-c), any relaxation of the one-Bash-call agent
contract.
