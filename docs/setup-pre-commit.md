# setup-pre-commit

## What it does

`setup-pre-commit` installs a Husky pre-commit hook in a project: `lint-staged` on the staged
files, followed by whichever of the project's CI checks you choose to run before every commit. It
reads the CI pipeline, turns each check a laptop can run into a **candidate** with its source, its
scope and its measured cost, and asks which ones go into the hook.

It adds nothing the project does not already use or that you did not pick. The formatter is the
one the project already has (Biome stays Biome, a Prettier config stays Prettier), Prettier is only
offered when there is none, and a CI check you leave unticked stays in CI only.

## When to reach for it

You invoke this by typing `/setup-pre-commit`, and the agent won't reach for it on its own. It runs
inline, in your session, because it asks you questions, installs dependencies and writes files into
the project.

| Situation | What to do |
|---|---|
| A Node project with no pre-commit hook | `/setup-pre-commit` |
| A monorepo whose Node code lives in a subdirectory | `/setup-pre-commit <that directory>`, or let it ask |
| A project that already has Husky | `/setup-pre-commit`; it extends the existing hook and config instead of replacing them |
| A project without a `package.json` | not this skill: it stops and names a hook manager that fits the stack |

## Prerequisites

- **What it writes.** In the package that owns the hook: dev dependencies (`husky`, `lint-staged`,
  and a formatter only when you agreed to add one), the `prepare` script, `.husky/pre-commit`, the
  lint-staged config and, only when Prettier was added, `.prettierrc`. Nothing outside the project.
- **Tooling.** Node and the project's package manager, detected from the `packageManager` field or
  the lockfile.

## Candidates

A candidate is one CI step that survived the filter: a check that runs on a push or a pull request
and that a developer can run locally without secrets, service containers or a browser. Plumbing
(checkout, install, cache), anything that builds or ships an artifact, and a matrix repeated per
version never reach you as options.

Each candidate carries three facts, so the choice is made on evidence:

| Fact | What it tells you |
|---|---|
| Source | the pipeline file, job and step it came from |
| Scope | `staged`: it takes file arguments and runs through lint-staged; `whole-repo`: typecheck, the test suite, a codegen drift check |
| Cost | the wall time of one local run, or `failed locally` with the first error |

Only `staged` candidates and fast `whole-repo` ones are recommended. A slow hook blocks every
commit and teaches the team to reach for `--no-verify`, so the choice shows the total cost of what
you ticked.

## Where the hook goes

Git runs one set of hooks for the whole repository. When the `package.json` that owns the scripts
sits in a subdirectory, the skill keeps `.husky/` there and points Git at it, and the hook changes
into that directory before running anything. A hook manager that is already installed
(`pre-commit`, `lefthook`, `simple-git-hooks`, a hand-written `.git/hooks/pre-commit`) stops the run
before any write, because a second manager silently replaces the first; the skill asks whether to
migrate its steps instead.

## Common questions

**Why was a CI step I expected not offered?**
It was filtered out: it runs only on release or deploy, needs a secret or a service container, is an
end-to-end suite, or is the format or lint check that lint-staged already runs on the staged files.
The report lists what was dropped and why.

**Can it add a commitlint check?**
Not to the pre-commit hook: commitlint checks the message, which does not exist yet when
pre-commit runs. When CI runs it, the skill offers it separately as a `commit-msg` hook.

**Why did it run my tests during setup?**
To measure each candidate's cost before you decide. The command is the one CI runs, with a
five-minute timeout, and a command that needs credentials or writes outside the working tree is
never run.

## It's working if

- `git commit` runs lint-staged on the files you staged, then only the checks you picked.
- The formatter the hook runs is the one the project already used.
- The hook fails a commit locally for the same reasons the picked CI steps would fail it.

## Where it fits

`setup-pre-commit` is a run-once setup, re-run after the CI pipeline gains a check worth moving
earlier.

- [testing-policy](testing-policy.md), because it defines the unit suite a `whole-repo` test
  candidate would run.

The grouped list of every skill is in [the top-level README](../README.md).
