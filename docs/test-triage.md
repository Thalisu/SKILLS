# test-triage

## What it does

`test-triage` runs one test target (a whole unit or E2E suite, a file, or a filter), clusters the
failures by root cause, and splits the clusters in two: the small ones it fixes, verifies and
commits one per cluster, and the rest it registers as numbered dossiers in `docs/tests/` so the
next person inherits the investigation instead of restarting it. An unreachable service is a third
thing: booted, retried once per cause, and reported as `BLOCKED`, never as a red test.

It never changes what a test verifies. A fix that would touch a result assertion, skip a test or
pad it with a sleep is not a small fix at any size; it becomes a dossier with the `assertion` veto,
because a red test is a product bug until shown otherwise.

## When to reach for it

Type `/test-triage` with a target, or the agent reaches for it automatically when a task fits: a
request to triage the tests, to find out why they fail or which ones broke.

| Ask | Use |
|---|---|
| "why are the tests failing", "what broke", "triage the tests" | `/test-triage unit`, `e2e`, `all`, a path or a filter |
| just run the test command | the runner directly; this skill investigates, it is not a runner |
| install the rules the triage enforces | [testing-policy](testing-policy.md) |

The target is asked for when it is left out. `all` runs unit first and stops there when unit is
red.

## Prerequisites

The skill writes into `docs/tests/` in the project: numbered dossiers named `NNNN-<slug>.md` and
`runner.json`, its own record of the commands that ran. That folder belongs in git, and the skill
neither commits it nor gitignores it: the writes are left in the working tree for you to commit
with your work, and a rule that hides the folder is reported, never edited. The first run in a
repository without a recognisable test script asks once for the suite and single-target commands
and records them there.

## Cluster, small fix, dossier

A run groups failing tests by signature into **clusters**: same error shape, same source file,
same suite. One broken mock failing fifteen tests is one cluster. Each cluster then lands on one
side of a hard line.

| Side | Condition | What happens |
|---|---|---|
| Small fix | the root cause is proven with evidence, and the fix edits exactly one existing file: production code, or test access code (selectors, labels, routes, fixture data) with git evidence that the UI or contract changed on purpose | applied, verified against the target and the full unit suite, formatted, committed one per cluster; anything that does not turn green is rolled back and the tree comes back clean |
| Hard work | anything else | a numbered dossier with a veto, left uncommitted for you |

The dossier's `veto` is a closed vocabulary, the topmost applicable row winning, except that a
test whose only path to green is changing what it verifies is always `assertion`:

| veto | When |
|---|---|
| `schema` | the fix touches a schema or a migration |
| `contract` | the fix touches an external API contract |
| `race-condition` | a flake, timing, or test interference |
| `multi-file` | more than one file, or a new file |
| `uncertain` | it is not established why the test is red |
| `assertion` | the assertion disputes what the code deliberately does |

Output that describes the environment rather than the code (connection refused, a container down,
the app not answering) is an infra cause: the skill boots what is missing, retries once per cause,
at most two causes per run, and reports the same cause repeating as `BLOCKED`. No dossier, no fix,
no commit.

## Memory lives in the repo

Nothing the triage learns is kept outside the repository. Commands come from `runner.json` or from
the project's own scripts, never from another manifest or another repo, and a command is recorded
only after it ran in this session. Infra causes and their remedies go to `known_infra` in the same
file. At the end of every run the open dossiers whose tests actually ran are reconciled: bumped
when the failure repeated, closed when the test ran green, with a flake needing two green runs.
A green run creates nothing; it reconciles and reports.

## Common questions

**Should I commit `docs/tests/`?**
Yes. Earlier versions kept the folder local; the current rule is that it belongs in git, because a
dossier is what a teammate reads instead of re-running the triage. The skill itself commits only
its fixes and leaves every write under `docs/tests/` for you.

**The fix was one line. Why did it become a dossier?**
One of the conditions failed: the file was already dirty in `git status`, so a rollback would have
destroyed your work; the branch is protected; the change would alter what the test verifies; or
the fix needed a second file. The dossier says which. A run that files a dossier for every cluster
usually means the target was too wide; narrow it to a file or a filter and run again.

**The run says `BLOCKED`. Is the suite red?**
No. `BLOCKED` means an infra cause repeated after its remedy, so the tests did not run. "Tests
didn't run" is never "tests passed", and never a red test either.

**The run says systemic and stopped. Why?**
A suite run executed at least ten tests with more than half red, which points at the environment, a
bad merge or a global mock rather than at individual tests. The report states the hypothesis; a
targeted run is never classified as systemic.

**The report is in Portuguese but the dossier is in English. Is that a bug?**
No. Every message to the user is in pt-BR; everything written into the repository (file names,
frontmatter, `runner.json`, commit messages and dossier bodies) is in English, and a dossier body
in another language is written only on explicit request.

**Where did v1 go?**
`test-triage-v1` is the single-file skill as first authored. `test-triage-v2` is the versioned
layout: the scripts, the references, the evals and the `runner.json` record. The tags are on this
repo.

## It's working if

- The tree is clean after every run, green or not, apart from the files under `docs/tests/` left for
  you and the fix commits, each touching one file for one cluster.
- The exact command line was printed before it ran, and a full E2E suite or a remote command waited
  for your yes.
- An unreachable service ends as `BLOCKED` with the cause named, not as a red test and not as a
  dossier.
- The next run bumps or closes the open dossiers instead of investigating the same failure again.

## Where it fits

`test-triage` is a reach-for-it-anytime standalone: nothing fires it but a red suite and a person
who wants to know why.

- [testing-policy](testing-policy.md), because the policy states the gate and this skill enforces
  it at triage time: neither lets a test pass by changing what it verifies.

The grouped list of every skill is in [the top-level README](../README.md).
