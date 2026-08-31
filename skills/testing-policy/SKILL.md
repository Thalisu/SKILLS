---
name: testing-policy
description: Install, migrate or refresh the canonical Testing Policy (Definition of Done) in the current project - the marked CLAUDE.md section, the test-author agents (unit-test-author, e2e-test-author), the /test-author inline skill, the duplication scan and an optional hook that blocks skip/only in test files. Detects the project's state (none / legacy / stale / current), decides whether the E2E gate is native or lives in consumer repos (APIs, libraries), and maps test conventions into the agents' Project map. Use when the user mentions "testing policy", "definition of done", "test-author agent", or asks to update or refresh the testing DoD.
---

Install, migrate or refresh the canonical Testing Policy in this project.

## Sources and what they become

| Source (next to this file) | Installed as |
|---|---|
| `POLICY.md`, rendered by `scripts/render-policy.sh <surface>` | the marked `## Testing Policy (Definition of Done)` section in `CLAUDE.md` |
| `AGENT-UNIT.md` | `.claude/agents/unit-test-author.md` |
| `AGENT-E2E.md` | `.claude/agents/e2e-test-author.md` — native and mixed surfaces only |
| `SKILL-TEST-AUTHOR.md` | `.claude/skills/test-author/SKILL.md` — the inline entry point for writers without the `Agent` tool |
| `scripts/scan-test-assets.sh` | `.claude/testing-policy/scan-test-assets.sh` — discovery and duplication scan |
| `scripts/hooks/forbid-test-skips.sh` | `.claude/testing-policy/forbid-test-skips.sh` + a `PreToolUse` entry in `.claude/settings.json` — optional, offered in step 6 |
| `scripts/verify-policy.sh` | not installed — run it from here in steps 0 and 8 |
| `references/example-project-map.md` | not installed — calibration for the density of a Project map / Project facts |

Two invariants. Every `{{slot}}` is filled from what exists in the project — never invent a path, a command or an example. Every command written into Project facts or a Project map was run once during this install and returned output.

## Step 0 — detect state

Run `bash <skill-dir>/scripts/verify-policy.sh <project>`. `policy=` picks the mode:

- `none` → **install**
- `legacy` (a Testing Policy section without markers) → **migrate**
- `stale` (marked, older version) or `drifted` (core hand-edited) → **refresh**
- `current` → nothing to do unless a piece is reported missing or the user asked to re-map; say so and stop.

Keep the rest of the output (`agent_*`, `skill_test_author`, `scan_script`, `hook`, `gitignored`) — steps 5-7 use it.

## Step 1 — surface: native, consumer or mixed

Infer before asking. Native evidence: a UI tree (`app/`, `pages/`, `screens/`, `src/app/`) and an E2E tool with flows in the repo (`playwright.config.*`, `.maestro/`, `cypress/`, `e2e*/`). Consumer evidence: an HTTP/queue/library entry point, no UI tree, no E2E tool, CLAUDE.md or docs naming the repos that call it. Mixed: both.

- native → no question here.
- consumer or mixed → one `AskUserQuestion` (multiSelect) for the consumer repos: candidates from CLAUDE.md, docs, sibling directories and an existing Project facts consumer list, plus Other. When the inference itself is not conclusive, confirm the surface in the same call.

For each consumer, read its CLAUDE.md and scripts for: E2E tool · single-flow command · full-suite command · flow naming with 2-3 real file names · how its stack runs THIS repo from the local working tree · its known infra failures.

## Step 2 — discover

1. Copy `scripts/scan-test-assets.sh` to `.claude/testing-policy/` (overwrite — it is generated) and run it with this project's roots: `--root` for unit roots, `--flows` for E2E roots (native/mixed), `--shared` for the shared homes you already recognise. Keep the whole report: `candidate-homes` seeds the role map; `duplicate-symbols`, `local-factories`, `inline-helpers` and `skip-markers` are the debt list for step 8.
2. Read package.json scripts (or Makefile / justfile / pyproject) for: unit full-suite and single-file commands, mandatory flags and preload files, formatter, E2E single-flow and full-suite commands, remote-runner conventions.
3. Build the role map — unit: mocks · helpers · factories · fixtures; E2E (native/mixed): page objects or shared subflows · data factories · backend/DB helpers · fixtures. Exactly one candidate → record it. Two or more, or none → collect for step 3; never guess, never list both. One directory may hold two roles (a `data/` with factories and DB helpers) — that is one path per role, not an ambiguity.
4. Record the idiom: identifier language in the test tree (it may legitimately differ from the code policy), mocking convention, locator strategy, base classes, and 2-3 real well-shaped shared assets with their signatures — calibration, never a catalog. `references/example-project-map.md` shows the expected density.
5. Preflight (native/mixed): app health endpoint, required services — include anything whose absence has produced a false product-bug red before (CLAUDE.md, docs, memory).

On **refresh**, run the same discovery and diff it against the written Project facts / Project map: disagreements are reported, the written text stays untouched — the user decides.

## Step 3 — ask, once

A single `AskUserQuestion` call holding: one question per ambiguous or orphan role (the real candidates found; for an orphan, a path following the project's own naming as the Recommended option, plus Other); in **migrate** mode, one question per project-specific rule found in the legacy section that has no home in the template — keep it in Project facts, or drop it; and the hook offer from step 6. Roles that mapped cleanly are never asked. Skip the call entirely when nothing is pending.

## Step 4 — render and place the policy

1. `bash scripts/render-policy.sh <surface>` and fill the `{{slots}}` in **Project facts** only — the core has none. `SCAN_COMMAND` is the exact invocation from step 2. `WHY_IN_PLACE` states the project's real reason (the E2E stack serves the primary checkout; the unit runner's path-ignore for agent worktrees; ...).
2. Place it:
   - **install**: after the section documenting test commands when one exists, before conventions. Never inside a managed block (`<!-- GSD:*-start -->` ... `<!-- GSD:*-end -->` or similar) — between blocks, so regeneration cannot overwrite it.
   - **migrate**: replace the legacy section in place, same position. Slot values come from the legacy text where it named them (commands, flow examples, infra failures); the project-specific rules the user kept go into Project facts.
   - **refresh**: replace only `core-start` .. `core-end` with `render-policy.sh <surface> --core-only`. Project facts are preserved verbatim.

## Step 5 — agents and the inline skill

- `unit-test-author` always; `e2e-test-author` on native and mixed; the `test-author` skill always (`TEST_AUTHOR_E2E_LINE` names the consumer repos on a consumer surface).
- New file: fill the Project map slots from the role map, drop the TEMPLATE comment, write. The Discovery block is the step-2 scan invocation (`--section duplicate-symbols`, plus `--section local-factories` for unit / `--section inline-helpers` for E2E) and 1-2 targeted greps over the shared homes — every line run once.
- Existing file with `testing-policy:core-start/end` markers: replace only the text between the markers with the template's core; preserve frontmatter and Project map; report discovery disagreements (step 2).
- Existing file without markers (hand-written): ask before touching it; never overwrite silently.
- Never set `model:` in the frontmatter — the agent inherits the session's model.

## Step 6 — enforcement hook (offer)

Offer to install `forbid-test-skips.sh`: a `PreToolUse` hook on `Edit|Write|MultiEdit` that blocks an edit **introducing** `.skip(` / `.only(` / `xit(` (JS/TS), `pytest.mark.skip|xfail` (Python) or `optional: true` (Maestro) into a test file; edits that keep or remove existing markers pass. It needs `jq` (`command -v jq`; if absent, say so and skip the offer). It sees only Claude's edits — the user's editor is untouched. On yes: copy the script to `.claude/testing-policy/`, then merge this entry into `.claude/settings.json` → `hooks.PreToolUse` (append to the existing array; never overwrite other hooks; create the file if absent):

```json
{"matcher": "Edit|Write|MultiEdit", "hooks": [{"type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/testing-policy/forbid-test-skips.sh"}]}
```

## Step 7 — git visibility

`verify-policy.sh` reports `gitignored=`. When any installed path is ignored, offer the fix — agent worktrees, CI and remote runners only see tracked files. Gotcha: git cannot re-include a path under an excluded parent, so a `.claude` or `.claude/` line must become `.claude/*` before `!.claude/agents/`, `!.claude/skills/`, `!.claude/testing-policy/` and `!.claude/settings.json` take effect. Show the resulting `.gitignore` lines; apply only with the user's yes.

## Step 8 — verify and report

1. Run every command written into Project facts and the Project maps once more; a command that errors or returns nothing is a wrong slot — fix it before finishing.
2. `bash scripts/verify-policy.sh <project>` must print `policy=current`, no `policy_missing` and no `policy_unfilled_slots`, and exit 0 (`hook=missing` is fine when the offer was declined).
3. Report: the state transition (`legacy → current v2`, ...); a diff-level summary per file; Project-map disagreements (refresh); the duplication and skip-marker debt from the scan — reported, **not fixed**: the second-use rule pays it organically, the next author that needs one of those assets consolidates first; hook installed or declined; gitignore status. Do not commit unless asked.

## Post-install checklist

Must hold after any mode. Lines marked ✓ are checked mechanically by `verify-policy.sh`; check the rest by reading.

- ✓ `testing-policy:start v=<template version> surface=<surface>` and `testing-policy:end` around the section; `core-start` / `core-end` inside; the core byte-identical to `render-policy.sh <surface> --core-only`.
- ✓ Headings for the surface present — native: Success gate (tiered) · E2E mapping; consumer: E2E gate (consumer-side) · Coverage mapping (consumer-side); mixed: all four; always: TDD · Test authoring — delegation and reuse · Tests represent the real flow · Project facts.
- ✓ No `{{slot}}` left; `/test-author` and the agent file(s) for the surface named in the delegation section.
- ✓ Agents present with markers; `test-author` skill present; scan script present.
- Project facts name real commands that ran; consumer lines (consumer/mixed) carry the "run against this repo's local build" recipe.
- Legacy project-specific rules the user kept survived into Project facts; nothing of the old section remains outside the markers.
