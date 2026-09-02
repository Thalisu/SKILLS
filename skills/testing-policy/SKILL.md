---
name: testing-policy
description: Install, migrate or refresh the canonical Testing Policy (Definition of Done) in the current project - the marked CLAUDE.md section, the test-author agents (unit-test-author, e2e-test-author), the /test-author inline skill, the duplication scan and an optional hook that blocks skip/only in test files. Detects the project's state (none / legacy / stale / current), decides whether the E2E gate is native or lives in consumer repos (APIs, libraries), and maps test conventions into the agents' Project map. Use when the user mentions "testing policy", "definition of done", "test-author agent", or asks to update or refresh the testing DoD.
---

Install, migrate or refresh the canonical Testing Policy in this project.

## Sources and what they become

| Source (next to this file) | Installed as |
|---|---|
| `POLICY.md`, rendered by `scripts/render-policy.sh <surface>` | the marked `## Testing Policy (Definition of Done)` section in `CLAUDE.md` |
| `AGENT-UNIT.md`, rendered by `scripts/render-agent.sh unit` | `.claude/agents/unit-test-author.md` |
| `AGENT-E2E.md`, rendered by `scripts/render-agent.sh e2e` | `.claude/agents/e2e-test-author.md` — native and mixed surfaces only |
| `SKILL-TEST-AUTHOR.md`, rendered by `scripts/render-agent.sh test-author` | `.claude/skills/test-author/SKILL.md` — the inline entry point for writers without the `Agent` tool |
| `scripts/scan-test-assets.sh` | `.claude/testing-policy/scan-test-assets.sh` — discovery and duplication scan |
| `scripts/skip-patterns.sh` | `.claude/testing-policy/skip-patterns.sh` — the skip markers and test-file classes shared by the scan and the hook; project additions live in `skip-patterns.local.sh` next to it |
| `scripts/forbid-test-skips.sh` | `.claude/testing-policy/forbid-test-skips.sh` + a `PreToolUse` entry in `.claude/settings.json` — optional, offered in step 6 |
| `scripts/verify-policy.sh` | not installed — run it from here in steps 0 and 8 |
| `references/example-project-map.md` | not installed — calibration for the density of a Project map / Project facts |

Generated vs preserved. Everything rendered from a template or copied from `scripts/` is **generated** — overwritten on refresh, never hand-edited. **Preserved** on refresh: Project facts, the agents' frontmatter and Project map, `skip-patterns.local.sh`, `.claude/settings.json`. One addition is allowed in a preserved part: a line the template gained since the installed version (`verify-policy.sh` names it in `agent_*_map_missing=`; 2.2 added **System boundaries** to the unit map) is filled from this run's discovery and appended at its template position — existing lines stay verbatim, and the report names the appended line. The template version lives once, in `POLICY.md`; every rendered file carries it (`v=` on the section's start marker, `<!-- testing-policy:agent v=… -->` / `<!-- testing-policy:skill v=… -->` after an agent's or the skill's frontmatter).

Two invariants. Every `{{slot}}` is filled from what exists in the project — never invent a path, a command or an example. Every command written into Project facts or a Project map was run once during this install and returned output.

## Step 0 — detect state

Run `bash <skill-dir>/scripts/verify-policy.sh <project>`. `policy=` picks the mode:

- `none` → **install**
- `legacy` (a Testing Policy section without markers; `legacy_lines=` gives its extent, `EOF` when it closes the file) → **migrate**
- `stale` (marked, older version) or `drifted` (core hand-edited) → **refresh**
- `current` → nothing to do unless another line is not `ok` / `n/a` / `none` or the user asked to re-map: a `stale` or `drifted` agent is refreshed alone (step 5), a `wired-missing` hook re-copied (step 6). Otherwise say so and stop.

Keep the rest of the output — steps 5-7 use it: `agent_unit` / `agent_e2e` (`missing` · `unmarked` = hand-written, ask · `stale` = older template, v2 marker style included · `drifted` = current version, core hand-edited · `ok`), `agent_unit_map_missing` / `agent_e2e_map_missing` (Project-map lines the template gained — appended in step 5), `skill_test_author` (`missing` · `stale` · `ok`), `scan_script`, `skip_patterns`, `hook` (`missing` · `script-only` · `wired` · `wired-missing` = wired in settings but the script is gone), `gitignored`.

## Step 1 — surface: native, consumer or mixed

Infer before asking. Native evidence: a UI tree (`app/`, `pages/`, `screens/`, `src/app/`) and an E2E tool with flows in the repo (`playwright.config.*`, `.maestro/`, `cypress/`, `e2e*/`). Consumer evidence: an HTTP/queue/library entry point, no UI tree, no E2E tool, CLAUDE.md or docs naming the repos that call it. Mixed: both.

- native → no question here.
- consumer or mixed → one `AskUserQuestion` (multiSelect) for the consumer repos: candidates from CLAUDE.md, docs, sibling directories and an existing Project facts consumer list, plus Other. When the inference itself is not conclusive, confirm the surface in the same call.

For each consumer, read its CLAUDE.md and scripts for: E2E tool · single-flow command · full-suite command · flow naming with 2-3 real file names · how its stack runs THIS repo from the local working tree · its known infra failures.

## Step 2 — discover

1. Copy `scripts/scan-test-assets.sh` and `scripts/skip-patterns.sh` to `.claude/testing-policy/` (overwrite — both are generated) and run the scan with this project's roots: `--root` for unit roots, `--flows` for E2E roots (native/mixed), `--shared` for the shared homes you already recognise. Keep the whole report: `candidate-homes` seeds the role map; `duplicate-symbols`, `local-factories`, `inline-helpers` and `skip-markers` are the debt list for step 8.
2. Read package.json scripts (or Makefile / justfile / pyproject) for: unit full-suite and single-file commands, mandatory flags and preload files, formatter, E2E single-flow and full-suite commands, remote-runner conventions.
3. Build the role map — unit: mocks · helpers · factories · fixtures; E2E (native/mixed): page objects or shared subflows · data factories · backend/DB helpers · fixtures. Exactly one candidate → record it. Two or more, or none → collect for step 3; never guess, never list both. One directory may hold two roles (a `data/` with factories and DB helpers) — that is one path per role, not an ambiguity.
4. Unit boundaries — the `--section mock-targets` report lists every module-mock target, `package` or `internal`, with its file count. A boundary is what the tests replace that lives outside the repo: the `package` targets, plus whatever the mocks home stands in for (read its files — the exported `setup*` / `mock*` / `with*` functions and the service, client or clock each replaces). Each becomes one **System boundaries** line, `what → shared mock`. An `internal` target is one of two things, and the module's own imports tell which: a module that talks to the outside — it imports a driver, SDK or client package (`ioredis`, `amqplib`, `jose`, `nodemailer`, `@supabase/supabase-js`), or calls `fetch`, the filesystem, the clock or `process.env` directly — is a thin wrapper around a boundary and is listed by what it wraps; a module that only imports this repo's other modules is an internal collaborator, **debt** for step 8, never a boundary. A boundary mocked inline per test file with no shared mock is listed as `none yet → create at <mocks home>/<name>` and counted as debt too. Only a read that stays inconclusive rides the step-3 question. No mocks at all → `none — pure modules`.
5. Record the idiom: identifier language in the test tree (it may legitimately differ from the code policy), mocking convention, locator strategy, base classes, and 2-3 real well-shaped shared assets with their signatures — calibration, never a catalog. `references/example-project-map.md` shows the expected density.
6. Preflight (native/mixed): app health endpoint, required services — include anything whose absence has produced a false product-bug red before (CLAUDE.md, docs, memory).

On **refresh**, run the same discovery and diff it against the written Project facts / Project map: disagreements are reported, the written text stays untouched — the user decides.

## Step 3 — ask, once

A single `AskUserQuestion` call holding: one question per ambiguous or orphan role (the real candidates found; for an orphan, a path following the project's own naming as the Recommended option, plus Other); one multiSelect over the `internal` mock targets from step 2 whose read stayed inconclusive (which of them wrap a boundary — the rest are debt); in **migrate** mode, one question per project-specific rule found in the legacy section that has no home in the template — keep it in Project facts, or drop it; and the hook offer from step 6. Roles that mapped cleanly are never asked. Skip the call entirely when nothing is pending.

## Step 4 — render and place the policy

1. `bash scripts/render-policy.sh <surface>` and fill the `{{slots}}` in **Project facts** only — the core has none. `SCAN_COMMAND` is the exact invocation from step 2. `WHY_IN_PLACE` states the project's real reason (the E2E stack serves the primary checkout; the unit runner's path-ignore for agent worktrees; ...).
2. Place it:
   - **install**: after the section documenting test commands when one exists, before conventions. Never inside a managed block (`<!-- GSD:*-start -->` ... `<!-- GSD:*-end -->` or similar) — between blocks, so regeneration cannot overwrite it.
   - **migrate**: replace the legacy section (`legacy_lines=` from step 0) in place, same position. Slot values come from the legacy text where it named them (commands, flow examples, infra failures); the project-specific rules the user kept go into Project facts.
   - **refresh**: replace only `core-start` .. `core-end` with `render-policy.sh <surface> --core-only`, and set `v=` on the start marker to the template version. Project facts are preserved verbatim.

## Step 5 — agents and the inline skill

- `unit-test-author` always; `e2e-test-author` on native and mixed; the `test-author` skill always (`TEST_AUTHOR_E2E_LINE` names the consumer repos on a consumer surface).
- Render with `bash scripts/render-agent.sh <unit|e2e|test-author>`; what happens next follows the state from step 0:
  - `missing` → write the whole render, Project map slots filled from the role map. The Discovery block is the step-2 scan invocation (`--section duplicate-symbols`, plus `--section local-factories` for unit / `--section inline-helpers` for E2E) and 1-2 targeted greps over the shared homes — every line run once.
  - `stale` or `drifted` → replace only the core: from the line that starts with `<!-- testing-policy:core-start` (in the v2 style that comment spans two lines — replace through its `-->`) up to `<!-- testing-policy:core-end -->`, with `render-agent.sh <unit|e2e> --core-only`; add `<!-- testing-policy:agent v=<version> -->` right after the frontmatter when absent. Frontmatter and Project map stay verbatim — except a line named in `agent_*_map_missing` (for 2.2, **System boundaries** in the unit map), which is filled from step 2 and appended at its template position; report discovery disagreements (step 2).
  - `unmarked` (hand-written, no markers) → ask before touching it; never overwrite silently.
  - `ok` → nothing.
  - The `test-author` skill has no preserved part: `missing` or `stale` → write the whole render with its one slot filled.
- Never set `model:` in the frontmatter — the agent inherits the session's model.

## Step 6 — enforcement hook

`forbid-test-skips.sh` is a `PreToolUse` hook on `Edit|Write|MultiEdit` that blocks an edit **introducing** a skip marker into a test file; edits that keep or remove existing markers pass. Markers and test-file classes come from `skip-patterns.sh` (step 2) — built-in coverage: JS/TS (jest, vitest, bun, mocha, jasmine, node:test, Playwright, Cypress: `.skip/.only/.todo/.fixme/.fail/.fails/.failing/.skipIf/.runIf`, `xit`/`fit` and friends), Python (`pytest.mark.skip|skipif|xfail`, `pytest.skip()`, `unittest.skip*`/`expectedFailure`), Maestro (`optional: true`). It needs `jq` (`command -v jq`; if absent, say so and skip the offer). It sees only Claude's edits — the user's editor is untouched.

- `hook=missing` → offer it (the question rides in step 3). On yes: copy the script to `.claude/testing-policy/`, then merge this entry into `.claude/settings.json` → `hooks.PreToolUse` (append to the existing array; never overwrite other hooks; create the file if absent):

  ```json
  {"matcher": "Edit|Write|MultiEdit", "hooks": [{"type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/testing-policy/forbid-test-skips.sh"}]}
  ```

- `script-only` → offer only the settings entry. `wired` → no offer; re-copy the script (generated) so it matches the installed `skip-patterns.sh`. `wired-missing` → re-copy the script and say so.
- When Project facts name a skip mechanism or a test-file pattern the built-ins do not cover, write it into `.claude/testing-policy/skip-patterns.local.sh` (preserved; sourced last): append to a `SKIP_PAT_*` variable, or define `skip_pattern_local <path>` setting `SKIP_PAT` / `SKIP_KIND` for the extra files. Prove it once: pipe a synthetic `Edit` payload that introduces the marker through the hook and confirm exit 2.

## Step 7 — git visibility

`verify-policy.sh` reports `gitignored=`. When any installed path is ignored, offer the fix — agent worktrees, CI and remote runners only see tracked files. Gotcha: git cannot re-include a path under an excluded parent, so a `.claude` or `.claude/` line must become `.claude/*` before `!.claude/agents/`, `!.claude/skills/`, `!.claude/testing-policy/` and `!.claude/settings.json` take effect. Show the resulting `.gitignore` lines; apply only with the user's yes.

## Step 8 — verify and report

1. Run every command written into Project facts and the Project maps once more; a command that errors or returns nothing is a wrong slot — fix it before finishing.
2. `bash scripts/verify-policy.sh <project>` must print `policy=current`, every `agent_*` `ok` (or `n/a`), no `agent_*_map_missing`, `skill_test_author=ok`, `scan_script=ok`, `skip_patterns=ok`, no `policy_missing`, no `policy_unfilled_slots`, and exit 0 (`hook=missing` is fine when the offer was declined).
3. Report: the state transition (`legacy → current v2.2`, ...); a diff-level summary per file; Project-map disagreements and appended lines (refresh); the duplication, skip-marker and internal-mock debt from the scan — reported, **not fixed**: the second-use rule pays the duplication organically (the next author that needs one of those assets consolidates first), and an internal mock is replaced by a seam the next time its test is touched; hook installed, re-copied or declined; gitignore status. Do not commit unless asked.

## Post-install checklist

Must hold after any mode. Lines marked ✓ are checked mechanically by `verify-policy.sh`; check the rest by reading.

- ✓ `testing-policy:start v=<template version> surface=<surface>` and `testing-policy:end` around the section; `core-start` / `core-end` inside; the core byte-identical to `render-policy.sh <surface> --core-only`.
- ✓ Every heading that `render-policy.sh <surface>` emits is present in the section, as a full line.
- ✓ No `{{slot}}` left in the section.
- ✓ Agents: `<!-- testing-policy:agent v=<template version> -->` after the frontmatter, bare `core-start` / `core-end` markers, core byte-identical to `render-agent.sh <unit|e2e> --core-only`; every Project-map label of the template present; `test-author` skill carries `<!-- testing-policy:skill v=<template version> -->`; `scan-test-assets.sh` and `skip-patterns.sh` present.
- Project facts name real commands that ran; consumer lines (consumer/mixed) carry the "run against this repo's local build" recipe.
- **System boundaries** in the unit map names only things outside the repo (packages, services, the clock, the filesystem) or the repo's thin wrappers around them, each with its shared mock; internal collaborators found mocked are in the report as debt, never in the map.
- Legacy project-specific rules the user kept survived into Project facts; nothing of the old section remains outside the markers.
- `skip-patterns.local.sh` exists exactly when Project facts name a mechanism outside the built-ins, and a synthetic payload proved it blocks.
