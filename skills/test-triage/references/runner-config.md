# Runner configuration and load-time facts

## Contents

- Purpose and invariants
- Schema of `docs/tests/runner.json`
- Discovery precedence
- Single-target templates
- Remote-smelling commands and confirmation
- Boot and readiness
- Known infra causes
- Load-time facts (`scripts/context.sh`)
- How the facts block is injected (verified behaviour)

## Purpose and invariants

`docs/tests/runner.json` is the skill's own memory of how tests run in this repository. It is not a manifest the skill reads to guess from: every value in it came from the user — typed together with the target, or answered when the skill asked — and was executed at least once in the run that wrote it. It exists in any repository, whatever the language, and it is the only place where a single-target form with `{target}` can live.

Written by the skill with an ordinary file write; read by `context.sh` verbatim. No tool parses it — keep it small and flat.

## Schema of `docs/tests/runner.json`

```json
{
  "unit": { "suite": "<command>", "single": "<command with {target}>" },
  "e2e":  { "suite": "<command>", "single": "<command with {target}>" },
  "boot": "<command that brings the test stack up, or null>",
  "known_infra": [
    { "signature": "<substring of the error output>", "remedy": "<command or action, or null>" }
  ]
}
```

- Every key is optional; a missing kind means "discover or ask".
- `{target}` is the only placeholder. It is replaced with a file, a flow or a filter — whatever the user said the runner takes.
- `known_infra` is capped at 10 entries; the oldest is dropped. `remedy` is `null` when the action tried did not clear the cause — the signature alone still lets the next run recognise infra at once.
- Commit messages: `docs(tests): record <kind> runner`, `docs(tests): record infra cause`.

## Discovery precedence

Per kind, first hit wins:

1. `runner.json` entry.
2. `package.json` scripts by name, local before remote:
   - unit: `test:unit` → `test:local`, `test:unit:local` → `test` (only when not remote-smelling) → a remote-smelling script, only when no local candidate exists;
   - e2e: `test:e2e:local` → `test:e2e`, `e2e` → `test:e2e:remote`.
   A `local` / `remote` given by the user pins the variant; when the pinned variant has no script, fall to 3 — never substitute the other variant.
3. Ask once, before running, for the suite command and the single-target form together. Scripts listed in the facts under other names may be offered as options; the user picks, the skill never picks for them. An answer the user already typed with the target is the answer.

A script runs through the package manager the facts indicate — the `packageManager` field when present, else the lockfile in the root — as `<pm> run <script>`. Nothing is ever written to `package.json`.

## Single-target templates

Shapes the user may give for `single`. Placeholders only — the runner is whatever the repository uses:

| shape | when |
|---|---|
| `<runner> {target}` | a bare runner takes a file or a filter as its last argument (for example a jest- or pytest-family runner) |
| `<pm> run <script> -- {target}` | the suite is a package script whose body is a bare runner invocation; the skill derives this form itself |
| `<ENV_VAR>={target} <runner>` | the runner selects one flow through an environment variable |
| `cd <dir> && <runner> {target}` | the tests live in their own directory or package |
| `<runner> --filter {target}` | the runner takes a named filter flag |

## Remote-smelling commands and confirmation

A script is remote-smelling when `:remote`, `:ci`, `ssh`, `rsync` or `scp` appears in its name or body. Before a full e2e suite or any remote command runs, the exact command line is printed and an explicit yes is awaited — even when the user has just said "local" or "remote". Every command line is printed before it runs, confirmed or not. A confirmed line stays confirmed for its re-runs within the same run.

## Boot and readiness

`boot` is the command that brings the test stack up; when absent, a `package.json` script named like `dev:all`, `docker:*`, `dev` or `start` is proposed. It runs in the background. Readiness means the thing that failed now answers — the port or URL named in the error — checked by polling it, not by waiting a fixed time.

## Known infra causes

At detection time the error output is matched against every `known_infra.signature` (substring match); a hit skips diagnosis and applies the remedy. A new cause is appended whether or not its remedy worked, so the next run recognises the signature immediately. BLOCKED writes nothing else: no dossier, no memory outside the repository.

## Load-time facts (`scripts/context.sh`)

Called from the `!` block at the top of `SKILL.md`; may also be run by hand: `<skill-dir>/scripts/context.sh [project-dir]`. It always exits 0, because an injected command that exits non-zero aborts the whole skill invocation. Output, in order:

```
branch: <name> | not a git repository | detached at <sha>
protected: yes (<branch> exists) | no | n/a
other long-lived branches: <names> | none
dirty tracked files: none | (<n>): + up to 8 lines of git status --short
package.json scripts (all <n> | <k> of <n>, matching …): + "<name>: <body>  [local|remote-smelling]"
package_manager: <packageManager field> | none
lockfiles: <files named *lock* in the root> | none
docs/tests/runner.json: + up to 16 lines verbatim | absent        (or: docs/tests/: absent)
open dossiers (<n>): path | test | signature | veto | occurrences | green_runs   (up to 8)
```

When `package.json` has more than 12 scripts only those whose name matches `test|e2e|spec|dev|start|docker` are shown. Parsing uses awk only; a minified or unusual `package.json` yields `scripts: none found` — read the file yourself then. The worst case stays under 60 lines.

## How the facts block is injected (verified behaviour)

Checked against a throwaway project with six skill variants, in default and bypass permission modes:

- `${CLAUDE_SKILL_DIR}` expands inside the `!` command to the skill directory whatever the working directory is; `$PWD` is the project.
- Injected commands never prompt. In default mode the invocation aborts silently — zero turns, no error text in `--output-format json` — unless a permission rule allows the command; a typical global allow list does not cover it.
- The rule that matches is exactly `allowed-tools: Bash(${CLAUDE_SKILL_DIR}/scripts/context.sh)` with the script invoked directly, quoted or unquoted path. Prefixing the command with `bash ` and mirroring that in the rule did **not** match; `Bash(bash *)` matches but is far broader than needed.
- With `--permission-mode bypassPermissions` nothing is required.

Keep the script executable (`chmod 755`): a direct invocation of a non-executable file fails, and the failure aborts the whole skill.
