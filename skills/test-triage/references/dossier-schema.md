# Dossier schema 2 and reconcile rules

## Contents

- What a dossier is
- Frontmatter fields
- Veto vocabulary
- Body sections
- Identity and matching
- Reconcile rules
- Visible to git, committed by the user
- `scripts/dossier.sh` reference
- Dossiers written before schema 2

## What a dossier is

One file per failure that needs real work: `docs/tests/NNNN-<slug>.md`, numbered by the highest existing prefix + 1, English kebab-case slug, English body by default. A failure that was fixed has no dossier: the commit is the record. A green run creates none.

## Frontmatter fields

| field | value | set by |
|---|---|---|
| `schema` | `2` | `new` |
| `status` | `open` or `fixed` | `new`, `green` |
| `kind` | `unit` or `e2e` | `new` |
| `test` | stable identity: `<file>::<name>` for a unit test, the flow path for an e2e flow | `new` |
| `signature` | first meaningful error line, normalised: no timestamps, ids or absolute paths | `new` |
| `repro` | the single-target command exactly as it was run | `new` |
| `failed_at` | short sha of HEAD when it last failed | `new`, `bump` |
| `fixed_by` | short sha of the run that closed it; present only with `status: fixed` | `green` |
| `veto` | one word from the vocabulary below | `new` |
| `occurrences` | runs in which it failed | `new` (1), `bump` |
| `first_seen`, `last_seen` | `YYYY-MM-DD` | `new`, `bump` |
| `green_runs` | runs in which its test passed while the dossier was open | `green` |

Text values (`test`, `signature`, `repro`) are double-quoted; everything else is a plain scalar.

## Veto vocabulary

Exactly one per dossier, the reason it is hard work:

| veto | meaning | closes on |
|---|---|---|
| `schema` | the fix touches a schema or a migration | first green run |
| `contract` | the fix touches an external API contract | first green run |
| `race-condition` | flake, timing, interference: green alone, red in the suite | **second** green run |
| `multi-file` | the fix needs more than one file, or a new file | first green run |
| `uncertain` | it is not established why the test is red | first green run |
| `assertion` | the assertion or expected value disputes what the code deliberately does; the only path to green is changing what the test verifies, skipping it, or padding it with a sleep | first green run |

When more than one reason applies, the topmost applicable row wins; a test whose only path to green is changing what it verifies is always `assertion`.

## Body sections

English by default (another language only when the user explicitly asks), in this order, all mandatory:

- `## Error`: verbatim excerpt trimmed to the meaningful frames.
- `## Hypothesis`: root cause with evidence: `file:line`, `git log` / `git blame` references.
- `## Ruled out`: what was ruled out and how. This is what stops the next session from repeating the investigation; when nothing was ruled out, say what was not checked.
- `## Next step`: one concrete next action.

A later run that investigates the same failure appends its findings to `Hypothesis` / `Ruled out`; the frontmatter is touched only by the script.

## Identity and matching

An observed failure matches an open dossier by `test` first, then by `signature`. Both come from `dossier.sh list-open`, frontmatter only; bodies are never read for matching. `new` refuses to create a second open dossier for the same `test` (exit 3, prints the existing path).

## Reconcile rules

At the end of every run, for each open dossier whose `test` was actually executed in this run (a unit run never touches an e2e dossier, a targeted run only its own target):

- failed again → `bump`: `occurrences` + 1, `last_seen` = today, `failed_at` = HEAD. No duplicate dossier.
- ran green → `green`: `green_runs` + 1, then `status: fixed` and `fixed_by`, immediately, except `veto: race-condition`, which closes only when `green_runs` reaches 2.

A dossier is never closed by a run that did not execute its test.

## Visible to git, committed by the user

`docs/tests/` belongs in the repository: a dossier is what the next person reads instead of re-running the triage on their own machine, and `runner.json` is the team's record of how this repo's tests are run. So the skill never gitignores the folder: `new` runs `check-visible` before writing and reports `gitignored: <rule>` when a rule hides it, naming the rule, without touching `.gitignore` (that edit is the user's call). It does not commit the folder either: dossiers, `bump` / `green` edits and `runner.json` are left in the working tree, unstaged, and the report names them. The only commits a run makes are its fixes, one per cluster.

## `scripts/dossier.sh` reference

`bash <skill-dir>/scripts/dossier.sh [--dir DIR] <command> …`; `DIR` defaults to `docs/tests`, relative to the working directory.

| command | effect | prints |
|---|---|---|
| `next-id` | next `NNNN` | the id |
| `new <slug> --kind K --test T --signature S --repro R --veto V` | runs `check-visible`, then creates the file from `assets/dossier-template.md`; `failed_at` = HEAD (`unknown` outside git), dates = today | the path as the last line, or `exists: <path>` with exit 3 for a duplicate |
| `check-visible` | reports whether `DIR` is hidden from git; never edits `.gitignore`; no-op outside git | `visible: yes`, `gitignored: <source>:<line>:<pattern>` or `not a git repository` |
| `list-open` | open dossiers, oldest first | `path \| test \| signature \| veto \| occurrences \| green_runs` |
| `bump <path> --failed-at SHA` | `occurrences`, `last_seen`, `failed_at` | `bumped: …`, or `unchanged: …` for the same sha on the same day |
| `green <path> --sha SHA` | `green_runs`, then `status` / `fixed_by` per the veto | `fixed: …`, `green_runs=n (still open): …`, or `already fixed: …` |

Exit 2 on misuse, with the reason on stderr. Edits rewrite single frontmatter keys in place; the body is byte-identical afterwards. Only bash, awk, sed, grep and git are used.

## Dossiers written before schema 2

A dossier without `schema` and `test` still appears in `list-open` (empty `test`) and accepts `bump` / `green`; a missing key is added on the first edit. Match it by `signature`; when it is investigated again, add `test` and `schema: 2` by hand.
