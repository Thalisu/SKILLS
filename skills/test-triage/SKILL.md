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

Target: `$ARGUMENTS`. Resolve in this order, first match wins:

1. Empty → **ask before any tool call**: unit, e2e or all.
2. Keyword `unit` / `e2e` / `all` → the whole suite of that kind.
3. A path that exists on disk → one target; its kind comes from where it lives (unit test layout vs e2e layout).
4. Anything else → one target, passed to the runner as a filter.

`local` / `remote` in the argument or in the user's reply pins that choice for the run. Anything else the user typed with the target — a command, a flow name — is an answer already given: use it, never ask for it again.

`all` runs unit first. **Unit red → do not run e2e**: report and stop.

## 2. Resolve the command

Discovery reads **only two files**: `docs/tests/runner.json` — the skill's own record of commands that ran, schema in [references/runner-config.md](references/runner-config.md) — and `package.json` scripts. Never CLAUDE.md, Makefiles or other manifests; never a command remembered from another repository.

Precedence per kind:

1. `runner.json` entry for the kind: `suite` and `single`.
2. `package.json` scripts by name, local before remote. Unit: `test:unit` → `test:local` / `test:unit:local` → `test` (only when not remote-smelling) → a remote-smelling script, only when no local candidate exists. E2e: `test:e2e:local` → `test:e2e` / `e2e` → `test:e2e:remote`. A script runs through the package manager the facts indicate (`package_manager`, `lockfiles`): `<pm> run <script>`.
3. Nothing, or the user pinned a variant no script provides → **ask once, before running**: the suite command *and* the single-target form, in one question (scripts from the facts may be offered as options; the user picks). No question when the user already typed the command.

A command the user gave — typed or answered — is run and then recorded in `runner.json`, committed as `docs(tests): record <kind> runner`. Never a second question to record it, never after the run. Nothing is ever written to `package.json`.

*Remote-smelling*: `:remote`, `:ci`, `ssh`, `rsync` or `scp` in the script name or body.

**Single-target form**: `runner.json.single`; else, when the suite script body is a bare runner invocation, `<suite> -- {target}`; else ask and record. `{target}` is a file, a flow or a filter — whatever the runner takes; never assume which.

**Always print the exact command line before running it.** A full e2e suite or any remote command additionally waits for an explicit yes — even after the user said "local" or "remote". A confirmed line stays confirmed for its re-runs in this run. Targeted runs go straight.

## 3. Run, separate infra from tests

Run with the tool's maximum timeout, or in the background with output to a file that you poll. A tool timeout is neither BLOCKED nor green: report "did not finish" with the command line and stop.

Output that describes the environment, not the code — connection refused, daemon or container down, the app not answering on its base URL, a database refusing connections — is an **infra cause**, never a test failure:

1. Match it against `runner.json.known_infra` (signature → remedy) before diagnosing from scratch.
2. Boot: `runner.json.boot`, else a `package.json` script named like `dev:all`, `docker:*`, `dev` or `start`. Ask; then run it in the background and wait until the thing that failed answers (the port or URL named in the error) before retrying.
3. Retry: **one retry per distinct cause, at most two causes per run.** After a remedy, re-run only the failing targets through `single` when they are ≤ 10 and a `single` form exists; otherwise the suite.
4. The same cause after its remedy → **BLOCKED**: name the cause, stop. No dossier, no fix, no commit. A second, different cause gets its own retry; when it is cleared the run is reported as green or red **with the infra chain** (cause → remedy → outcome) — never as "BLOCKED then green".
5. Every new cause goes to `known_infra` (cap 10, oldest dropped): `remedy` holds the action only when it worked, `null` otherwise. Committed as `docs(tests): record infra cause`. BLOCKED writes nothing else — no memory outside the repository.

## 4. Cluster the failures

Group failing tests by signature: same error shape, same source file, same suite. Report clusters, not raw counts — one broken mock failing 15 tests is one problem.

- **Systemic** — only a suite run (`unit` / `e2e` / `all`) that executed ≥ 10 tests with more than half red: do not triage; report the hypothesis (environment, bad merge, global mock or setup) and stop. A targeted run is never systemic.
- **≤ 3 clusters** → deep path, each cluster in turn, in this context: read the test and the source under test, `git log` / `git diff` the involved files, read the open dossier that matches the cluster (its `Descartado` is not repeated). Never spawn subagents.
- **> 3 clusters** → shallow path: one line per cluster with a hypothesis, ask which one to dig into. The rest stays in the terminal; offer in one line to write a single triage note, and write it only if asked.

## 5. Flake check (deep path only)

Skipped when an infra cause was found in this run. Otherwise re-run **one representative per cluster, alone, once**, through `single`:

- Still red → real failure; classify it.
- Green alone → it does **not** become green. It is a flake or interference, `veto: race-condition`, and gets a dossier.

Never re-run hoping for green. Never add sleeps or timeout padding.

## 6. Classify: small fix vs hard work

**Small fix** requires ALL of:

- the root cause is proven with evidence — file:line, git history, the failing assertion explained;
- the fix edits **exactly one existing file**: a production file, or a test *access-code* file (page-object selectors, labels, routes, fixture data) backed by `git log` / `git diff` evidence that the UI or contract changed on purpose. Never both, never a new file.

**Hard work** → dossier, with the matching `veto`:

| veto | when |
|---|---|
| `schema` | touches a schema or a migration |
| `contract` | touches an external API contract |
| `race-condition` | flake, timing, test interference |
| `multi-file` | more than one file, or a new file |
| `uncertain` | root cause not proven |
| `assertion` | the only fix changes a result assertion or an expected value, adds `skip` / `xfail` or the like, or pads with `sleep` |

Changing what a test verifies is never an auto-fix.

## 7. Fix path (small fix only)

Refuse before touching anything: on a **protected branch** (Hard rules) → diagnose only, never commit; the file to edit shows in `git status --short` **read now** → do not touch it — the fix would ride with the user's work and the rollback would destroy it — downgrade to a dossier and say why.

1. Apply the fix.
2. Re-run the failing target. Not green → `git checkout -- <file>` and reclassify as hard work. A small fix creates no file, so this rollback is complete: the tree is clean again.
3. Green → run the **full unit suite**. Regression → same rollback, reclassify.
4. Format the touched file only, with the repository's own `package.json` script (`format` / `fmt` / `lint:fix`, given the path); none → skip. Then `git status --short` must show only the touched file: revert any other file that was clean before, and report — never revert — a file that was already dirty.
5. `git add <file>` — the exact path, never `-A` or `.`. One commit per cluster: `fix(<scope>): ...`; for access-code fixes the git evidence goes in the message.

For e2e the verification gate is the affected flow plus the full unit suite — never the full e2e suite; leave that to the user.

## 8. Dossier (hard work only)

One dossier per failure that needs real work. A fixed failure needs none — the commit is the record. A failure already covered by an open dossier (same `test`, or same `signature` when `test` is empty) is not registered again: it is bumped in step 9 and its body receives the new findings.

Frontmatter schema 2 — `status`, `kind`, `test`, `signature`, `repro`, `failed_at`, `veto`, `occurrences`, `first_seen`, `last_seen`, `green_runs`, `fixed_by` — with field rules, veto vocabulary and reconcile rules in [references/dossier-schema.md](references/dossier-schema.md). Create it with the script, never by hand:

```
bash "${CLAUDE_SKILL_DIR}/scripts/dossier.sh" new <slug> --kind <unit|e2e> --test "<file::name or flow path>" \
  --signature "<first meaningful error line>" --repro "<single-target command as run>" --veto <veto>
```

It prints the path (`docs/tests/NNNN-<slug>.md`, English kebab-case slug) or refuses when an open dossier already has that `test`. Then fill the body in pt-BR: `## Erro` (verbatim excerpt trimmed to the meaningful frames), `## Hipótese` (root cause with evidence), `## Descartado` (what was ruled out and how — mandatory; when nothing was, say what was not checked), `## Próximo passo` (one concrete action).

Commit it alone: `docs(tests): register <slug>` — never in the same commit as a fix. On a protected branch: write it, leave it uncommitted, report it as "not committed: protected branch".

## 9. Reconcile open dossiers

The facts block lists the open dossiers (`dossier.sh list-open`, frontmatter only — bodies are never read for this). At the end of the run, for every open dossier whose `test` this run actually executed (a unit run never touches an e2e dossier; a targeted run only its own target):

- failed again → `bash "${CLAUDE_SKILL_DIR}/scripts/dossier.sh" bump <path> --failed-at <sha>`;
- ran green → `bash "${CLAUDE_SKILL_DIR}/scripts/dossier.sh" green <path> --sha <sha>` — closes it (`status: fixed`, `fixed_by`), except `veto: race-condition`, which closes only on the second green run.

Match by `test` first, then by `signature`. Commit every reconcile edit together, `docs(tests): reconcile <n> dossier(s)` — separate from fixes and from new dossiers.

## 10. Report

Terminal summary in pt-BR:

- verdict — verde / vermelho / BLOCKED / sistêmico / não terminou — and the command line that ran;
- infra chain, when there was one: cause → remedy → outcome;
- clusters and, per cluster: corrigido + commit / dossiê / não investigado;
- dossiers created, bumped, closed; `runner.json` changes made this run;
- commit SHAs; anything left uncommitted and why;
- what is left for the user, and why.

A green run creates nothing — it reconciles open dossiers and reports.

## Hard rules

- A red test is a product bug until proven otherwise. Making a test pass by
  changing what it verifies is never an auto-fix.
- "Tests didn't run" is never "tests passed". Infra failure is BLOCKED.
- Never push, never open a PR, never commit on a protected branch (step 7).
- Never stage files you did not touch.
- Never spawn subagents.
