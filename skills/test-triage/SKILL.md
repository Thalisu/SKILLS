---
name: test-triage
description: Runs a test target, clusters the failures, investigates them, auto-fixes and commits only the small ones, and files a dossier in docs/tests/ for the ones that need real work. Use when the user asks to triage tests, run tests and investigate what broke, find out why tests are failing or which tests broke, or mentions "test-triage", "triagem de testes", "por que os testes estão falhando" or "testes quebrados". Do NOT use for a bare request to just run a test command.
argument-hint: "[unit|e2e|all|<path>|<filter>] [local|remote]"
allowed-tools: Bash(${CLAUDE_SKILL_DIR}/scripts/context.sh)
---

# Test Triage

Every message to the user, starting with the first one, is written in **pt-BR**; so is every dossier body. File names, frontmatter keys, `runner.json` and commit messages are in **English**.

Run → cluster → investigate → fix the small, document the hard.

## Repository facts (collected before you start)

!`"${CLAUDE_SKILL_DIR}/scripts/context.sh"`

If the block above is empty or shows a policy message, collect the same facts with tools once step 1 is done: `git branch -a`, `git status --short`, `package.json` scripts, `docs/tests/runner.json`, `bash "${CLAUDE_SKILL_DIR}/scripts/dossier.sh" list-open`. The facts are a snapshot taken at invocation: anything that must be current at decision time (dirty files, HEAD) is re-read then.

## 1. Resolve the target

The argument is free-form. Resolve in this order, first match wins:

1. Keyword `unit` / `e2e` / `all` → whole suite of that kind.
2. A path that exists on disk → infer the kind from the path (a test file under
   the repo's unit test layout vs. its e2e layout).
3. Anything else → a filter passed to the runner (`jest <regex>`, `pytest -k <expr>`).
4. Empty → ask the user: unit, e2e, or all.

`all` runs unit first. **If unit is red, do not run e2e** — report and stop; the
unit failures almost always explain the e2e ones and e2e is expensive.

## 2. Resolve the command

**Only `package.json` scripts.** Do not read CLAUDE.md, Makefiles, or any other
manifest to guess a command.

- Match scripts by name (`test`, `test:unit`, `test:e2e*`, `e2e*`) against the
  resolved kind.
- **Nothing matches → ask the user how that kind of test is run** in this repo.
  Then offer to write the answer into `package.json` as a script (show the exact
  script name and body, ask before writing). Once accepted, use it — from the
  next run on, discovery finds it by itself.
- Never invent a command from what you saw in another repo.

**Confirm before running** when the resolved command is (a) a full e2e suite, or
(b) a script whose name or body smells remote/CI (`:remote`, `:ci`, `ssh`,
`rsync`). Show the exact command line and wait. A targeted run (one file, one
filter) goes straight through with no confirmation.

## 3. Run and separate infra from tests

Run the command. No preflight.

If the output looks like the environment, not the code — `ECONNREFUSED`, docker
daemon down, the app not answering on the base URL, a missing container, a DB
that won't accept connections — this is **not a test failure**:

1. Look for a boot script in `package.json` (`dev:all`, `docker:dev`, `dev`, `start`).
2. Ask the user whether to run it.
3. Retry the test command **once**.
4. Still broken → report **BLOCKED**, name the infra error, stop. No dossier, no
   fix, no commit. Blocked is never reported as green or as a test failure.

## 4. Cluster the failures

Group failing tests by signature: same error message shape, same source file,
same suite. Report the cluster count, not the raw test count — one broken mock
failing 15 tests is one problem.

- **More than 50% of the run red** → do not triage. Report a systemic hypothesis
  (environment, bad merge, global mock/setup) and stop.
- **≤ 3 clusters** → deep review of each, sequentially, in this context. Read the
  test, read the source under test, `git log`/`git diff` the involved files, run
  the test in isolation. Do not spawn subagents.
- **> 3 clusters** → shallow triage: list each cluster with a one-line hypothesis
  and ask which one to dig into. The clusters left uninvestigated stay in the
  terminal only; offer in one line to write a single triage doc, and write it
  only if asked.

## 5. Flake check

For each failing test, re-run **that test alone, once**.

- Still red → real failure, continue to classification.
- Green in isolation → **it does not become green**. It is a flake / test
  interference, classified `veto: race-condition`, and it gets a dossier. An
  unstable test is a bug.

Never re-run a test repeatedly hoping for green. Never add sleeps or timeout
padding to stabilize anything.

## 6. Classify: small vs. hard work

**Small** (→ fix and commit) requires BOTH:
- the root cause is identified with real evidence, and
- the fix fits in **one** production file.

**Hard work** (→ dossier, no fix) if ANY of these applies:
- touches schema or a migration
- touches an external API contract
- race condition, flake, or timing
- more than one production file
- root cause uncertain
- the only available fix is changing a **result assertion**

### Test code: access vs. verification

The dividing line is access code vs. verification code.

**May be auto-fixed** — but only with evidence in `git log`/`git diff` that the
UI or contract changed on purpose, and that evidence goes in the commit message:
- page-object selectors, labels, routes
- fixture data that tracked a legitimate change

**Never auto-fixed, always a dossier:**
- changing, loosening or removing a result assertion
- changing an expected value to match the observed one
- `sleep` / `wait_for_timeout` padding
- `skip`, `xfail`, or any equivalent

## 7. Fix path (small only)

1. Apply the fix.
2. Re-run the failing target. **Not green → `git checkout` every file you
   touched** and reclassify as hard work. The tree always goes back clean.
3. Green → run the **full unit suite**. Regression → `git checkout` everything
   you touched and reclassify as hard work.
4. Green → format only the files you touched, with whatever the repo uses
   (Prettier for JS/TS, ruff for Python).
5. `git add` the exact paths you touched. **Never `git add -A` or `git add .`.**
6. One commit per cluster, conventional message (`fix(<scope>): ...`).
7. **Never push.**

### Refusals on the fix path

- The file you would edit already had uncommitted changes → **do not fix it**.
  The fix would ride along with the user's WIP and the rollback would destroy
  their work. Downgrade to a dossier and say so.
- On `main` or `production` → diagnose only, never commit.

For e2e: the verification gate is the affected flow plus the full unit suite. Do
not run the full e2e suite to validate a fix — leave that to the user.

## 8. Dossier path (hard work only)

A dossier is written **only** for a failure that needs real work. A failure that
was fixed needs no dossier — the commit is the record.

Location: `docs/tests/`, created if missing. Number = highest existing `NNNN`
prefix + 1, zero-padded to 4. Slug in kebab-case English.

`docs/tests/0007-pix-reemission-timeout.md`:

```markdown
---
status: open
kind: e2e
repro: cd e2e-tests && pytest client_tests/test_pix.py
failed_at: <sha of HEAD when it failed>
veto: race-condition
occurrences: 1
first_seen: 2026-08-28
last_seen: 2026-08-28
green_runs: 0
---

## Erro

<verbatim excerpt, trimmed to the meaningful frames>

## Hipótese

<root cause with evidence: file:line, git log/blame references>

## Descartado

- <what was ruled out, and how it was ruled out>

## Próximo passo

<one concrete next action>
```

`Descartado` is not optional — it is what stops the next session from repeating
the same investigation. If nothing was ruled out, say what was not checked.

Commit the dossier on its own: `docs(tests): register <slug>`. Never in the same
commit as a fix.

## 9. Reconcile open dossiers

At the **start** of every run, read only the frontmatter of `docs/tests/*.md`
with `status: open`. At the end, reconcile in both directions:

- A new failure matching an open dossier (same `repro` **and** same error
  signature) → update that dossier: `occurrences` +1, new `last_seen`, new
  `failed_at`. Do not create a duplicate.
- An open dossier whose test **ran green in this run** → `status: fixed`,
  `fixed_by: <sha>`. Only for dossiers actually covered by this run — a unit run
  can never close an e2e dossier.
- Exception: a dossier with a flake veto (`race-condition`) does not close on one
  green run. Increment `green_runs`; close only at 2.

## 10. Report

Terminal summary in pt-BR:

- verdict (verde / vermelho / BLOCKED / sistêmico) and the command that ran
- cluster count and, per cluster, what was done (corrigido+commit / dossiê / não investigado)
- dossiers created, updated, closed
- commit SHAs created
- what was left for the user, and why

A green run writes nothing — it reconciles open dossiers and reports.

## Hard rules

- A red test is a product bug until proven otherwise. Making a test pass by
  changing what it verifies is never an auto-fix.
- "Tests didn't run" is never "tests passed". Infra failure is BLOCKED.
- Never push, never open a PR, never commit on `main`/`production`.
- Never stage files you did not touch.
- Never spawn subagents.
