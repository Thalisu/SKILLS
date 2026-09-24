# Eval cases

Prepared for `claude plugin eval` (`<case>/case.yaml` + `prompt.md` + `graders/*.md`, the layout its
`--help` describes). The command is gated server-side per organization (early access), so the
cases have been authored, not executed; the `case.yaml` keys and the grader types (`llm`,
`tool_used`, `file_exists`) follow the runner's help text and may need adjusting once it runs
here. Until then `tests/evals.sh` runs every scaffold in a throwaway directory and asserts the
fixture each case relies on: the planted defects are in place, the fixture's suite is green, the
caller outside the diff breaks, and the door script reads the facts the case expects.

`do-code-review` is model-invoked, so one case is a bare trigger in Portuguese; the others type the
skill. The fix cases share one fixture, a paging bug on an `export-notes` branch, so a change to
the Fixer brief is graded against the same diff every way; `fix-gate-red` adds a preview module
that leans on the bug, so the right fix breaks a test outside the Finding. Every fixture is synthetic: a small notes module in plain JavaScript with `node --test` as
its suite, so it runs offline with node alone. The planted diff keeps its Ticket and its spec in
`.scratch/` tracked by git, so that run also exercises the durability line.

| case | checks |
|---|---|
| `planted-diff` | five defects and a clean hunk on a branch whose Ticket the prompt hands over as `do` does: each defect in its expected Bucket at or above its minimum Rung, the clean hunk with no `Act on`, no Rung 1 or 2 in `Act on`, each location once, six Axis lines, no principle without a location, the reviewer with no write or edit tool, the Review beside the Ticket, named after it, with `Ticket:` naming it |
| `ref-does-not-resolve` | `/do-code-review nope` ends in one line, `nope does not resolve; nothing reviewed`, and writes nothing |
| `empty-diff` | a clean tree on the base branch ends in one line, `no diff between main (<sha>) and the working tree; nothing reviewed`, and writes nothing |
| `no-spec` | a branch with no spec and no tracker file: five Axes reported, the Spec line reading `no spec`, nothing asked, the Review named after the branch |
| `triggers-pt-br` | a bare "revisa esse diff antes de eu dar push" fires the skill |
| `reviewer-retry` | a project-level stand-in shadows the security reviewer and never returns: it is forked twice, the Review is written from the technical reviewer's return, the Security line reads `not run` with its reason, the safety fact names that Axis, and the run still ends with the Review's text and its location |
| `fix-run` | a Review the case wrote, one `Act on` Finding against a planted paging bug and one `Consider`: one commit for the Finding and none for the `Consider`, the branch fast-forwarded onto it, the fix worktree and branch gone, nothing pushed and the reply ending with the push command, the `## Fix run` section naming the commit, what was verified and `landed at`, the fix reference read, the Fixer forked as `do-code-review-fixer` with no `model` key, and the orchestrator writing only the Review |
| `fix-dirty-tree` | a `fix` call with one change left uncommitted: one line, `working tree has uncommitted changes; commit or stash before fix`, no worktree, no fork and no file touched |
| `fix-stale` | a `fix` call after the case moved the code the one `Act on` Finding named: the section reports it `stale`, no commit is made and the tree is untouched |
| `fix-gate-red` | a `fix` call whose one `Act on` fix is right and turns a preview test outside the Finding red: the Gate fixer forked as `do-code-review-gate-fixer` with no `model` key, once or twice and never a third time, its prompt naming neither the Review nor its `## Act on` section, the preview repaired in code with its test's assertion untouched, and the `## Fix run` section naming the Gate fixer's commit and ending `landed at` |
| `fix-unlinked-fixers` | the `fix-gate-red` fixture on a machine that links neither fixer: no fork of either by name, a general-purpose Fixer and a general-purpose Gate fixer each on `model: sonnet` with its definition ahead of the brief, the Finding `fixed <sha>, verified`, the preview repaired in code, and the run ending `landed at` |
| `fix-already-fixed` | a `fix` call on a Review whose one `Act on` Finding an earlier call left `not fixed`, after a commit that fixed it and added the test its `Fix:` names: a second `## Fix run` section reads `1: fixed <that commit>, verified (<the check>)`, the first section kept word for word, no Fixer forked, no `fix/` worktree or branch, no new commit, and the run Green with nothing to land |
| `fix-touched-still-red` | a `fix` call after a commit that touched the one `Act on` Finding's files and added its test without fixing it: the check still fails, so a Fixer is forked as before, and that commit is never recorded as the fix |
| `fix-no-check` | a `fix` call after a commit that fixed the one `Act on` Finding, whose `Fix:` names a source file and no check: a Fixer is forked as before, and the commit is never recorded `verified` without a check the run ran |
| `fix-touched-check-no-behaviour` | a `fix` call after a commit that touched the one `Act on` Finding's files and added the test file its `Fix:` names, but the added test only checks the result's shape, never the count the Finding claims, so the suite runs green for a reason unrelated to the Finding: a Fixer is forked as before, and that commit is never recorded `verified` off the green run alone |
| `fix-check-never-red` | a `fix` call on a Security Finding after a commit that touches its header file with an unrelated rename and adds the test its `Fix:` names, whose assertion holds nine items over both the buggy code and any fix, so the check passes at HEAD without ever having failed against the Review's `Commit:`: a Fixer is forked as before, and that commit is never recorded `verified` |
| `no-fix` | `/do-code-review --no-fix`: the Review written and the run stopped, no Fixer, no worktree, nothing landed, and the fix reference never opened |

Run from the skill directory, granting the tools the run needs and opting in to the scaffold
scripts:

```
claude plugin eval . --scaffold --allow-tools Bash Read Write Glob Grep Agent Skill
```
