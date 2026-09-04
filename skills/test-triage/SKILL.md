---
name: test-triage
description: Runs a test target, clusters the failures, investigates them, auto-fixes and commits only the small ones, and files a dossier in docs/tests/ for the ones that need real work. Use when the user asks to triage tests, run tests and investigate what broke, find out why tests are failing or which tests broke, or mentions "test-triage",  "why tests are failing" or "the tests not work". Do NOT use for a bare request to just run a test command.
argument-hint: "[unit|e2e|all|<path>|<filter>] [local|remote]"
allowed-tools: Bash(${CLAUDE_SKILL_DIR}/scripts/context.sh)
---

# Test Triage

Every message to the user, starting with the first one, is written in the language the user opened the session in. Everything written to the repository (file names, frontmatter keys, `runner.json`, commit messages and dossier bodies) is in **English**; write a dossier body in another language only when the user explicitly asks.

Run → cluster → investigate → fix the small, document the hard.

## Repository facts (collected before you start)

!`"${CLAUDE_SKILL_DIR}/scripts/context.sh"`

If the block above is empty or shows a policy message, collect the same facts with tools once step 1 is done: `git branch -a`, `git status --short`, `package.json` scripts, `docs/tests/runner.json`, `bash "${CLAUDE_SKILL_DIR}/scripts/dossier.sh" list-open`. The facts are a snapshot taken at invocation: anything that must be current at decision time (dirty files, HEAD) is re-read then.

## Checklist

Track your progress against this checklist; show it to the user only in the session's opening language:

```
Triage:
- [ ] 1. Target resolved (asked first when empty)
- [ ] 2. Command resolved; command line printed; confirmed when full e2e or remote
- [ ] 3. Run; infra separated from tests (boot → retry → BLOCKED)
- [ ] 4. Failures clustered; systemic check (suite runs only)
- [ ] 5. Flake check (deep path, one representative per cluster)
- [ ] 6. Every cluster classified: small fix or hard work; instrumentation reverted
- [ ] 7. Small fixes applied, verified, formatted, committed one per cluster
- [ ] 8. Dossiers registered for hard work; docs/tests/ visible to git, left uncommitted for the user
- [ ] 9. Open dossiers reconciled
- [ ] 10. Report in the session's opening language
```

Vocabulary, used consistently: _target_ (what runs), _kind_ (`unit` or `e2e`), _runner_ (the command that runs a kind), _cluster_ (one root cause), _small fix_ / _hard work_, _dossier_, _BLOCKED_, _protected branch_.

## 1. Resolve the target

Target: `$ARGUMENTS`. Resolve in this order, first match wins:

1. Empty → **ask before any tool call**: unit, e2e or all.
2. Keyword `unit` / `e2e` / `all` → the whole suite of that kind.
3. A path that exists on disk → one target; its kind comes from where it lives (unit test layout vs e2e layout).
4. Anything else → one target, passed to the runner as a filter.

`local` / `remote` in the argument or in the user's reply pins that choice for the run. Anything else the user typed with the target, a command or a flow name, is an answer already given: use it, never ask for it again.

`all` runs unit first. **Unit red → do not run e2e**: report and stop.

## 2. Resolve the command

Discovery reads **only two files**: `docs/tests/runner.json` (the skill's own record of commands that ran, schema in [references/runner-config.md](references/runner-config.md)) and `package.json` scripts. Never CLAUDE.md, Makefiles or other manifests; never a command remembered from another repository.

Precedence per kind:

1. `runner.json` entry for the kind: `suite` and `single`.
2. `package.json` scripts by name, local before remote. Unit: `test:unit` → `test:local` / `test:unit:local` → `test` (only when not remote-smelling) → a remote-smelling script, only when no local candidate exists. E2e: `test:e2e:local` → `test:e2e` / `e2e` → `test:e2e:remote`. A script runs through the package manager the facts indicate (`package_manager`, `lockfiles`): `<pm> run <script>`.
3. Nothing, or the user pinned a variant no script provides → **ask once, before running**: the suite command _and_ the single-target form, in one question (scripts from the facts may be offered as options; the user picks). No question when the user already typed the command.

A command the user gave, typed or answered, is run and then recorded in `runner.json`. Before the first write into `docs/tests/` in a run, run `bash "${CLAUDE_SKILL_DIR}/scripts/dossier.sh" check-visible`: the folder belongs in git, because it is what the next person on the team reads instead of re-running this triage on their own machine. A `gitignored: <rule>` answer goes to the report with the rule that causes it; never edit `.gitignore` to fix it, that is the user's call (step 8). Never a second question to record it, never after the run. Nothing is ever written to `package.json`.

_Remote-smelling_: `:remote`, `:ci`, `ssh`, `rsync` or `scp` in the script name or body.

**Single-target form**: `runner.json.single`; else, when the suite script body is a bare runner invocation, `<suite> -- {target}`; else ask and record. `{target}` is a file, a flow or a filter, whatever the runner takes; never assume which.

**Always print the exact command line before running it.** A full e2e suite or any remote command additionally waits for an explicit yes, even after the user said "local" or "remote". A confirmed line stays confirmed for its re-runs in this run. Targeted runs go straight.

## 3. Run, separate infra from tests

Run with the tool's maximum timeout, or in the background with output to a file that you poll. A tool timeout is neither BLOCKED nor green: report "did not finish" with the command line and stop.

Output that describes the environment, not the code (connection refused, daemon or container down, the app not answering on its base URL, a database refusing connections), is an **infra cause**, never a test failure:

1. Match it against `runner.json.known_infra` (signature → remedy) before diagnosing from scratch.
2. Boot: `runner.json.boot`, else a `package.json` script named like `dev:all`, `docker:*`, `dev` or `start`. Ask; then run it in the background and wait until the thing that failed answers (the port or URL named in the error) before retrying.
3. Retry: **one retry per distinct cause, at most two causes per run.** After a remedy, re-run only the failing targets through `single` when they are ≤ 10 and a `single` form exists; otherwise the suite.
4. The same cause after its remedy → **BLOCKED**: name the cause, stop. No dossier, no fix, no commit. A second, different cause gets its own retry; when it is cleared the run is reported as green or red **with the infra chain** (cause → remedy → outcome), never as "BLOCKED then green".
5. Every new cause goes to `known_infra` (cap 10, oldest dropped): `remedy` holds the action only when it worked, `null` otherwise. BLOCKED writes nothing else: no memory outside the repository.

## 4. Cluster the failures

Group failing tests by signature: same error shape, same source file, same suite. Report clusters, not raw counts: one broken mock failing 15 tests is one problem.

- **Systemic** applies only to a suite run (`unit` / `e2e` / `all`) that executed ≥ 10 tests with more than half red: do not triage; report the hypothesis (environment, bad merge, global mock or setup) and stop. A targeted run is never systemic.
- **≤ 3 clusters** → deep path, each cluster in turn, in this context: read the test and the source under test, `git log` / `git diff` the involved files, read the open dossier that matches the cluster (its `Ruled out` is not repeated). Never spawn subagents.
- **> 3 clusters** → shallow path: one line per cluster with a hypothesis, ask which one to dig into. The rest stays in the terminal; offer in one line to write a single triage note, and write it only if asked.

**How a cluster is investigated (deep path).** By elimination, never by the first plausible story: name the candidate causes up front, then rule them out one at a time against evidence you can point at, a line of output, a diff, a `git log` entry, a log you added, taking the split that cuts the most remaining ground first. Stop when exactly one candidate survives and you can state the mechanism, not just the correlation. When evidence refutes a candidate, revert whatever it motivated before the next pass. What each pass eliminated, and how, is what `## Ruled out` records in step 8: write it as you go, never reconstructed at the end.

**Instrumentation.** When reading the code and the history does not settle what the program does at runtime, add a temporary log or assertion and re-run the single target to read the real state. Do not guess, and do not classify a cluster `uncertain` over a question one log line would have answered. Instrumentation is scaffolding, not a fix: never add it to a file `git status --short` already shows as dirty (that is the user's work, and the revert would take their lines with it), revert it with `git checkout -- <file>` before the cluster is classified in step 6, so that step 7's dirty-file check reads the user's work and not your own scaffolding, and never let a target count as green while it is still in place.

## 5. Flake check (deep path only)

Skipped when an infra cause was found in this run. Otherwise re-run **one representative per cluster, alone, once**, through `single`:

- Still red → real failure; classify it.
- Green alone → it does **not** become green. It is a flake or interference, `veto: race-condition`, and gets a dossier.

Never re-run hoping for green. Never add sleeps or timeout padding.

## 6. Classify: small fix vs hard work

**Small fix** requires ALL of:

- the root cause is proven with evidence: file:line, git history, the failing assertion explained;
- the fix edits **exactly one existing file**: a production file, or a test _access-code_ file (page-object selectors, labels, routes, fixture data) backed by `git log` / `git diff` evidence that the UI or contract changed on purpose. Never both, never a new file.

**Hard work** → dossier, with the matching `veto`:

| veto             | when                                                                                                                                                                         |
| ---------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `schema`         | touches a schema or a migration                                                                                                                                              |
| `contract`       | touches an external API contract                                                                                                                                             |
| `race-condition` | flake, timing, test interference                                                                                                                                             |
| `multi-file`     | more than one file, or a new file                                                                                                                                            |
| `uncertain`      | it is not established why the test is red                                                                                                                                    |
| `assertion`      | the assertion or expected value disputes what the code deliberately does: the only path to green is changing what the test verifies, skipping it, or padding it with `sleep` |

More than one reason → the topmost applicable row wins, except that a test whose only path to green is changing what it verifies is always `assertion`, even when other questions stay unresolved.

Changing what a test verifies is never an auto-fix.

## 7. Fix path (small fix only)

Refuse before touching anything: on a **protected branch** (Hard rules) → diagnose only, never commit; the file to edit shows in `git status --short` **read now** → do not touch it (the fix would ride with the user's work and the rollback would destroy it); downgrade to a dossier and say why.

1. Apply the fix: the smallest edit the evidence justifies, and nothing more. Every line of it answers to the proven root cause. A defensive guard for a case no failure showed, a widened catch, a broadened type, anything added because it might also help: that is a second hypothesis riding along untested, and it does not ship. If the target only goes green with changes the evidence does not cover, the root cause is not proven: roll back and file it as hard work, `veto: uncertain`.
2. Re-run the failing target, the same one that was red, through `single`. That run is the only proof this failure is fixed, and it has to be the surface the failure happened on: a green unit test does not prove an e2e failure gone, and a suite that stopped mentioning the test is not a pass. Not green, or inconclusive → `git checkout -- <file>` and reclassify as hard work. A small fix creates no file, so this rollback is complete: the tree is clean again.
3. Green → run the **full unit suite**. That gate answers a different question, not "is this failure fixed" (step 2 answered that) but "did the fix break something else". Regression → same rollback, reclassify.
4. Format the touched file only, with the repository's own `package.json` script (`format` / `fmt` / `lint:fix`, given the path); none → skip. Then `git status --short` must show only the touched file: revert any other file that was clean before, and report, never revert, a file that was already dirty.
5. `git add <file>` with the exact path, never `-A` or `.`. One commit per cluster: `fix(<scope>): ...`, carrying in the body the failing signature verbatim and the single-target command that now passes; for access-code fixes the git evidence goes in the message too.

For e2e the verification gate is the affected flow plus the full unit suite, never the full e2e suite; leave that to the user.

## 8. Dossier (hard work only)

One dossier per failure that needs real work. A fixed failure needs none: the commit is the record. A failure already covered by an open dossier (same `test`, or same `signature` when `test` is empty) is not registered again: it is bumped in step 9 and its body receives the new findings.

Frontmatter schema 2 (`status`, `kind`, `test`, `signature`, `repro`, `failed_at`, `veto`, `occurrences`, `first_seen`, `last_seen`, `green_runs`, `fixed_by`), with field rules, veto vocabulary and reconcile rules in [references/dossier-schema.md](references/dossier-schema.md). Create it with the script, never by hand:

```
bash "${CLAUDE_SKILL_DIR}/scripts/dossier.sh" new <slug> --kind <unit|e2e> --test "<file::name or flow path>" \
  --signature "<first meaningful error line>" --repro "<single-target command as run>" --veto <veto>
```

Before writing, `new` runs `check-visible` on `docs/tests/` (`visible: yes`, or `gitignored: <rule>` naming the rule that hides it, reported and never fixed by the script). Then it prints the path (`docs/tests/NNNN-<slug>.md`, English kebab-case slug) as its last line, or refuses when an open dossier already has that `test`. Fill the body in English (default): `## Error` (verbatim excerpt trimmed to the meaningful frames), `## Hypothesis` (root cause with evidence), `## Ruled out` (what was ruled out and how, mandatory; when nothing was, say what was not checked), `## Next step` (one concrete action).

The dossier belongs in git, since it is what a teammate reads instead of re-running the triage, but **this skill does not commit it**: only fixes are committed (step 7), and everything under `docs/tests/` is left in the working tree, unstaged, for the user to commit with the rest of their work. Say so in the report and name the files. A `gitignored:` answer from `check-visible` goes to the report verbatim, with the rule that causes it; never edit `.gitignore`; the user decides.

## 9. Reconcile open dossiers

The facts block lists the open dossiers (`dossier.sh list-open`, frontmatter only; bodies are never read for this). At the end of the run, for every open dossier whose `test` this run actually executed (a unit run never touches an e2e dossier; a targeted run only its own target):

- failed again → `bash "${CLAUDE_SKILL_DIR}/scripts/dossier.sh" bump <path> --failed-at <sha>`;
- ran green → `bash "${CLAUDE_SKILL_DIR}/scripts/dossier.sh" green <path> --sha <sha>`, which closes it (`status: fixed`, `fixed_by`), except `veto: race-condition`, which closes only on the second green run.

Match by `test` first, then by `signature`. Reconcile edits stay uncommitted, like every other write under `docs/tests/`: tracked by git, committed by the user.

## 10. Report

Terminal summary, in the session's opening language:

- verdict (green / red / BLOCKED / systemic / did not finish) and the command line that ran;
- infra chain, when there was one: cause → remedy → outcome;
- clusters and, per cluster: fixed + commit / dossier / not investigated. For a fixed cluster, one verbatim line of the failure as it read before and one line of the green re-run that replaced it, never a pasted output block;
- dossiers created, bumped, closed; `runner.json` changes made this run; everything under `docs/tests/` left uncommitted for the user, and the `gitignored:` warning from `check-visible` when the folder is hidden from git;
- commit SHAs; anything left uncommitted and why;
- what is left for the user, and why.

A green run creates nothing: it reconciles open dossiers and reports.

## Hard rules

- A red test is a product bug until proven otherwise. Making a test pass by changing what it verifies is never an auto-fix.
- "Tests didn't run" is never "tests passed". Infra failure is BLOCKED; a tool timeout is "did not finish".
- **Protected branch**: `main` / `master` when `develop`, `development`, `staging` or `release*` exists locally or on a remote; `production` / `prod` when any of those or `main` / `master` exists. A default branch that is the only branch is the working branch. On a protected branch nothing is committed.
- Never push, never open a PR.
- `docs/tests/` belongs in git: this skill never gitignores it, and never commits it either; the writes are left for the user. A rule that hides the folder (`dossier.sh check-visible`) is reported, never fixed here.
- The smallest change the evidence justifies, and nothing more. A line added because it might also help is an untested hypothesis, not a fix.
- A fix is proven only on the surface the failure happened on. The full unit suite is a regression gate, never proof that the original failure is gone.
- Instrumentation is never committed and never left behind: it is reverted before the cluster is classified.
- Never stage a file you did not touch. Never spawn subagents.
- Never invent a command; never record one that did not run in this session.
- Every message to the user in the session's opening language; every write into the repository in English.
