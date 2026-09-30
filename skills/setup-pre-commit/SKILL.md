---
name: setup-pre-commit
description: "Set up a Husky pre-commit hook in the current project: finds where the hook belongs, keeps the formatter the project already uses instead of forcing Prettier, reads the CI pipeline for checks worth running before a commit and adds only the ones the user picks."
disable-model-invocation: true
---

Set up a Husky pre-commit hook in this project. Runs inline: it asks the user, installs
dependencies and writes files into the project.

The goal is a hook that fails a commit for the reasons CI would fail it, and fast enough that
nobody skips it with `--no-verify`. A hook that takes minutes gets bypassed and then protects
nothing, so every choice below trades coverage against the seconds it adds to each commit, and the
user makes the trade with the facts in front of them. That is why the project's own tools win over
any default, why every CI check is offered with its measured cost instead of added, and why step 5
is the first step that writes.

Arguments: `$ARGUMENTS` (optional: the path of the package the hook serves, in a monorepo)

## 1. Find where the hook goes

Git runs one set of hooks for the whole repository, so every commit anywhere in it goes through
the hook, even when the code the hook checks lives in one subdirectory. Establish, and keep for
every later step:

- **Git root**: `git rev-parse --show-toplevel`, where `core.hooksPath` is resolved from.
- **Package root**: the directory whose `package.json` owns the dev dependencies and the scripts
  the hook calls. The argument when one was given; otherwise the git root when it has a
  `package.json`; otherwise the single `package.json` below it (ignore `node_modules`). More than
  one candidate and no workspace root: ask which one with AskUserQuestion.
- **Workspace**: `pnpm-workspace.yaml`, a `workspaces` field, `turbo.json` or `nx.json` at the
  package root means the scripts may fan out over packages; note it for step 3.
- **Package manager**: the `packageManager` field first, then the lockfile (`pnpm-lock.yaml` pnpm,
  `yarn.lock` yarn, `bun.lock` or `bun.lockb` bun, `package-lock.json` npm). Default to npm. Every
  command below uses its runner (`npx`, `pnpm exec`, `yarn`, `bunx`) and its `run`.

Stop and report, writing nothing, when:

| Found | Why it stops |
|---|---|
| No `package.json` anywhere in the repo | Husky needs Node; say so and name the hook manager that fits the stack (`pre-commit` for Python, `lefthook` for a polyglot repo) instead of forcing one |
| `.pre-commit-config.yaml`, `lefthook.yml`, `simple-git-hooks` in `package.json`, or `git config core.hooksPath` pointing anywhere but a `.husky/_` | Another hook manager already owns the hooks; a second one silently replaces the first. Name it and ask whether to migrate its steps into Husky or leave it |
| A hand-written `.git/hooks/pre-commit` (not a `.sample`) | Husky would bypass it. Show it and ask whether its commands move into the new hook |

An existing `.husky/` is not a stop: the run becomes a refresh, and step 5 extends the existing
`pre-commit` instead of replacing it.

## 2. Decide the staged-file tools

`lint-staged` runs tools on the staged files only, which is the fast part of the hook. Decide what
it runs from what the project already uses, because a formatter the project does not use rewrites
files the team never agreed to format:

| The project has | lint-staged runs |
|---|---|
| A Prettier config (`.prettierrc*`, `prettier.config.*`, a `prettier` key in `package.json`) or `prettier` in its dependencies | `prettier --ignore-unknown --write` |
| `biome.json` or `biome.jsonc` | `biome check --write --no-errors-on-unmatched` on the extensions Biome handles; no Prettier |
| `dprint.json`, or `deno.json` with `fmt` | that formatter's write command; no Prettier |
| ESLint running Prettier as a rule (`eslint-plugin-prettier`) | `eslint --fix` only; a second Prettier pass would fight it |
| No formatter at all | nothing yet: ask whether to add Prettier, with its defaults below, or to run no formatter |

An existing ESLint config adds `eslint --fix` on the extensions it lints, unless CI does not run
ESLint, in which case it becomes a candidate in step 3 instead. An existing lint-staged config
(`.lintstagedrc*`, `lint-staged.config.*`, a `lint-staged` key in `package.json`) is extended,
never replaced, and its globs win over the table.

When the project has no formatter, say before asking that adopting one reformats every file the
first time it is staged, so the next diffs will be noisy until the codebase has been formatted
once.

## 3. Read the CI pipeline for candidates

Find the pipeline files at the git root: `.github/workflows/*.yml|yaml`, `.gitlab-ci.yml`,
`.circleci/config.yml`, `azure-pipelines.yml`, `bitbucket-pipelines.yml`, `Jenkinsfile`,
`.travis.yml`, `.buildkite/`, `.woodpecker/`. None found: say so and skip to step 4 with the step 2
tools only.

Read only the jobs that run on a push or a pull request; skip release, deploy, schedule and manual
triggers. For every `run` step, resolve it to the command a developer would type at the package
root: follow `npm run <x>` / `make <x>` / `just <x>` to what it runs, rewrite it for the detected
package manager, and drop the CI-only flags (`--ci`, `--reporter=junit`, coverage upload flags).

Drop a step, without offering it, when it is:

- plumbing: checkout, install, cache, setup of a language or a tool;
- producing or shipping an artifact: build for release, docker build or push, publish, deploy,
  release, coverage or report upload;
- dependent on something a laptop does not have: a `secrets.*` or CI-only variable, a service
  container, a browser or a device farm (end-to-end suites);
- already covered by step 2 (the format or lint check lint-staged runs on staged files);
- a matrix repeat: keep one entry for the whole matrix.

Every step that survives is a **candidate**. For each one, record:

- **Source**: `<file>:<job>:<step name>`.
- **Command**: the local command; confirm the script or binary exists at the package root, and
  mark it `missing locally` when it does not.
- **Scope**: `staged` when the tool takes file arguments and can run through lint-staged (a linter,
  a spell checker, a header check), `whole-repo` otherwise (typecheck, the test suite, a codegen
  drift check).
- **Cost**: run the command once at the package root with a five-minute timeout, and record the
  wall time, or `failed locally` with the first error line. A `staged` candidate is timed on the
  whole repo and the record says so, since the hook will run it on far fewer files. Time only a
  check-only command, one that reads the tree and exits with a verdict (`tsc --noEmit`,
  `eslint .`, `vitest run`), because a run here is a side effect on the user's project before they
  agreed to anything. A command that rewrites files (`--fix`, `--write`, codegen), reaches a
  database or the network, or needs credentials is recorded as `not measured`, with the reason.

A `commitlint` step is not a pre-commit candidate: it checks the message, so offer it separately as
a `commit-msg` hook.

<examples>
<example>
CI step, in `.github/workflows/ci.yml`, job `check`, on `pull_request`:
`run: pnpm run typecheck`, where the script is `tsc --noEmit`.
Candidate: source `ci.yml:check:Typecheck`, command `pnpm run typecheck`, scope `whole-repo`,
cost `12s`.
AskUserQuestion option: label `pnpm run typecheck (Recommended)`, description
`ci.yml:check:Typecheck · whole-repo · 12s`.
</example>
<example>
CI step, in `.gitlab-ci.yml`, job `lint`, on merge requests: `npx cspell "src/**"`.
Candidate: scope `staged` (cspell takes file arguments, so lint-staged runs it as `cspell` on
`*.{ts,md}`), cost `41s on the whole repo, far less on staged files`. Recommended: a `staged`
check costs only what was staged.
</example>
<example>
CI step, in `.github/workflows/ci.yml`, job `test`, with a `postgres` service container:
`run: npm test -- --ci --coverage`.
Dropped: needs a service container a laptop does not have running. Listed in the report as
`ci.yml:test:Test · dropped: service container postgres`.
</example>
<example>
CI step, job `unit` on a matrix of Node 20 and 22: `run: npm run test:unit`, where the suite
needs no service. Candidate once for the whole matrix, cost `2m 40s`. Offered without
`(Recommended)`, with the description `ci.yml:unit:Unit · whole-repo · 2m 40s, adds this to every
commit`.
</example>
</examples>

## 4. Let the user choose

Show the step 2 plan in one short list (the lint-staged globs and commands, the dependencies it
installs), then offer the candidates with AskUserQuestion, `multiSelect: true`. Each option's
label is the command; its description is the source, the scope and the cost. Recommend a
candidate, by listing it first with `(Recommended)` in the label, only when it is `staged`, or
`whole-repo` and under about 30 seconds. A candidate that is `missing locally`, `failed locally`
or `not measured` is offered unrecommended, with the reason in its description, so the user
still sees it and decides. With more than four candidates, group them into
up to four questions by kind (lint, types, tests, other). A candidate the user does not pick is not
added.

Whole-repo checks run on every commit and block it, so a hook that takes minutes teaches the team
to commit with `--no-verify`. Say so once, next to the total of the picked costs.

## 5. Install

At the package root, with the detected package manager:

1. Add as dev dependencies `husky`, `lint-staged`, and the formatter only when step 2 decided to
   add one. Skip what is already there.
2. Run `husky init` when `.husky/` does not exist. It writes a `prepare` script and a sample
   `.husky/pre-commit` that runs the tests: the next step overwrites that sample. An existing
   `prepare` script keeps its command and gains `husky` with `&&`.
3. When the package root is not the git root, follow the Husky subdirectory recipe: `.husky/`
   stays in the package root, the `prepare` script becomes
   `cd <relative path to git root> && husky <package root, relative to the git root>/.husky`, and
   the hook's first line is `cd <package root, relative to the git root>`, since Git runs hooks
   from the git root.
4. Write `.husky/pre-commit` (Husky v9 needs no shebang): lint-staged first, then the picked
   `whole-repo` commands ordered fastest first, so a cheap failure stops the commit before the slow
   ones run. On a refresh, append only the lines that are not already there.
5. Write or extend the lint-staged config: the step 2 globs, plus every picked `staged` candidate
   on the extensions it handles. A new config goes to `.lintstagedrc`.
6. Only when step 2 decided to add Prettier and no config exists, write `.prettierrc`:

   ```json
   {
     "useTabs": false,
     "tabWidth": 2,
     "printWidth": 80,
     "singleQuote": false,
     "trailingComma": "es5",
     "semi": true,
     "arrowParens": "always"
   }
   ```

## 6. Verify

- `.husky/pre-commit` exists and is executable.
- The `prepare` script runs `husky`, and `git config core.hooksPath` reads `.husky/_` (or
  `<package root>/.husky/_` in a subdirectory) after it ran.
- Run the hook's commands once, as the hook would: stage one changed file, then run `lint-staged`
  and every picked whole-repo command. Report a failure with its output and keep the line in the
  hook: a check that fails here would fail CI too, so the failure is a finding for the user, not a
  defect of the hook.

## 7. Report and commit

Report, in this order: the git root and the package root, the formatter decision and why, each
candidate with the choice the user made, each dropped CI step with the rule that dropped it, the files written or extended, the
dependencies added, and the measured cost of the whole hook. Then show the diff and ask whether to commit it with the
message `chore: add pre-commit hooks (husky + lint-staged)`. The commit is the smoke test: it runs
through the new hook. When the hook fails that commit, show its output and stop with the changes
staged; bypassing it with `--no-verify` would hide the one result this commit exists to show.
Without a yes, leave the changes in the working tree.
