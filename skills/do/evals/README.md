# Eval cases

Prepared for `claude plugin eval` (`<case>/case.yaml` + `prompt.md` + `graders/*.md`, the layout its
`--help` describes). The `case.yaml` keys and the grader types (`llm`, `regex`, `tool_used`,
`file_exists`) follow the runner's help text and may need adjusting once it runs here.

`do` is user-invoked, so every prompt types the skill; there is no trigger case. The door cases
end at a door: the request fits no Playbook, so the run is one message, and the cases inspect
that message and the tree. Every door case carries the same two graders, the first line reading
`Playbook: none` and nothing written, plus one grader for its door; the two are repeated in
each case's folder because the runner reads a case's graders from there. The `trivial-` cases run
the `trivial` Playbook and grade the tree, the commits and the reply; each opens with the first
line reading `Playbook: trivial`, whether the run landed or refused.

Every fixture is synthetic: a small typed notes module, a tracker file where the case needs one,
a spec in the format `spec` writes with its `Journey:` line under the title, the journey beside
it where that line names one, and, where the case needs them, two Tickets under `issues/` in the
Ticket format. The `trivial-` fixtures use a plain JavaScript notes module with `node --check` as
typecheck and `node --test` as the suite, so both run offline with node alone.

| case | checks |
|---|---|
| `empty-asks-for-task` | no argument: one message asking for the task, no ticket picked from the fixture, nothing written |
| `feature-goes-to-discuss` | a feature with no Ticket: one message naming `/discuss`, nothing built, no Playbook matched |
| `question-goes-to-how` | a "how does X work" question: one message naming `/how` (or `/teach`), the question left unanswered |
| `sketch-goes-to-prototype` | a request to try a layout: one message naming `/prototype`, no HTML or variant written |
| `spec-path-goes-to-tickets` | a Spec's path whose `Journey:` line names a journey that exists: one line saying a Spec fits no Playbook, with `/tickets` as the command, no tickets cut |
| `summary-goes-to-spec` | a pasted `discuss` closing summary: the same line, with `/spec` as the command since the discussion already happened, no spec written |
| `spec-required-goes-to-journey` | a Spec's path whose `Journey:` line reads `required` with no journey beside it: the same line with `/journey` named first, no journey written |
| `missing-path-says-so` | a path that does not exist, with two neighbouring Tickets on disk: one line saying so, no neighbour opened in its place |
| `issue-number-without-tracker-file` | `#2` with no tracker file and a `02-` Ticket file on disk as bait: one message asking for the Ticket's path, the number never matched against the files |
| `issue-unopenable-says-so` | `#7` with a tracker file naming GitHub and `gh`, in a fixture with no remote: one line saying the issue could not be opened, nothing invented |
| `trivial-run` | a typo in the name of a non-exported helper: the checklist verbatim with the discover step skipped, the edit in place on `main`, typecheck, the covering suite and the door script after the edit, one commit staging only the file; no worktree, no test author, no review |
| `trivial-refuses-bug` | a "typo" inside a string the code compares at runtime: refused before any edit as a bug, `bug-fix` named, the tree unchanged |
| `trivial-refuses-new-export` | a one-line exported helper asked for by the Playbook's name: refused before any edit as a new exported symbol, `discuss` named, the tree unchanged |
| `trivial-refuses-protected-branch` | a doc typo on `main` beside a `develop` branch: refused before any edit, the branch and the rule named, the tree unchanged |
| `trivial-refuses-dirty-target` | a doc typo in a file already modified in the checkout: refused before any edit, the file named, the developer's uncommitted line intact |
| `trivial-stops-on-signature-change` | a "typo" in a parameter name of an exported function, a rename inside one file from the request's seat: the edit made, the door script stopping the run on the diff, no commit, `src/notes.js` back at HEAD, `refactoring` named with the script's lines quoted |
| `ticket-run-with-policy` | a Ticket built to the gate under an installed Testing Policy: the checklist verbatim before the first edit with every skipped step reasoned, the worktree before the first edit and the main checkout's dirty `README.md` untouched, one discover batch with its audit line, one dispatch in flight, one commit per behaviour holding a test and an implementation with the behaviour line in its body, the gate after the last edit, the Ticket `claimed` in the main checkout and absent from every commit, the review step `skip: do-code-review not listed`, the reply naming a principle only beside a decision |
| `blocked-ticket-refused` | Ticket 02 blocked by Ticket 01 still `ready-for-agent`: refused before the claim in one message naming the blocker and its status, nothing written |
| `resolved-ticket-stops` | a Ticket already `resolved`: one line saying so, nothing written |
| `claimed-no-worktree-starts-over` | a `claimed` Ticket whose worktree is gone: one line saying the run starts over, the claim standing, a new worktree and the build |
| `claimed-worktree-resumes` | a `claimed` Ticket whose `do/archive-a-note` worktree holds two commits, one per behaviour with its `Behaviour:` line: the first message says it resumes and lists them, no second worktree, the loop continues at the third behaviour and the first two get no new commit |
| `resumed-worktree-uncommitted-asks` | the same worktree with an uncommitted half-written test in it: the first message says it resumes, names `src/notes.test.ts` and asks before discarding, then waits; nothing discarded, no commit, no second worktree |
| `protected-branch-said-first` | `main` beside a `develop` branch: the first message names the branch and the rule and says landing will be refused; the run still builds to the gate, nothing lands, the worktree and its branch named |
| `design-fork-stops` | a Ticket whose third criterion contradicts the Spec's decision and the journey's failure branch: the run stops at its step naming `/discuss`, the Ticket left `claimed`, no commit |
| `withheld-agent-tool` | the Agent tool withheld from the whole session, the nearest a case can get to withholding it from a delegate: no agent dispatched and no delegate forked, the inline test-author skill applied, the session's own commits carry the work |
| `portuguese-session` | the Ticket's path followed by a Portuguese request, the one way a single prompt opens the session in Portuguese: the reply in Portuguese, the status line, the evidence and the commit messages in English |
| `absent-vendored-skill` | a session that does not list `how`, which is the runner's own session (it lists the skill under test and the fixture's skills, never the vendored ones): the grounding step states the one-line fallback and completes, the build continues to the gate |
| `ticket-run-without-policy` | the same Ticket in a project with no Testing Policy, on the plain JavaScript fixture: the first message reads `Loop: fallback`, the run reads `references/tdd-fallback.md` before its first test and never dispatches a test author, and for each behaviour the failing test is written and run red by the session before the implementation, both landing in one commit |

The `ticket` cases scaffold the same fixture with a Testing Policy installed on a consumer surface
(the marked section in `CLAUDE.md` with its Project facts, the `unit-test-author` agent with its
Project map, the inline `test-author` skill), a spec, its journey and two Tickets under `issues/`,
and, for the runs, an uncommitted line in `README.md` as the developer's work in progress; the
resume cases add the `do/archive-a-note` worktree with two commits on it, one per behaviour, and
one of them an uncommitted edit in that worktree. The
fixture's commands are real: `node --test` runs the suite and `tsc --noEmit` typechecks `src/`.
`ticket-run-without-policy` scaffolds the plain JavaScript fixture of the `trivial-` cases instead,
with the same spec, journey and Tickets and no policy section, no agent and no inline skill, so the
run takes the TDD fallback and node alone runs its suite. The review, the landing, the
verification and the close have no case yet: the review step reads `skip: do-code-review not
listed` in every run, and their cases arrive with the review.

## Running

Run from the skill directory, granting the tools the cases need and opting in to their scaffold
scripts:

```
claude plugin eval . --scaffold --allow-tools Bash Read Edit Write Glob Grep Agent Skill
```

The runner is in early access. A first-party Claude Code install enables it by itself after
`claude update` and a fresh session; a client that cannot fetch feature flags (Bedrock, Vertex, a
custom base URL, or non-essential traffic disabled) needs the enablement variable Anthropic hands
out at onboarding, and there is no settings flag for it. Until it is enabled the command prints
`` `plugin eval` is currently in early access `` and exits 1. Every scaffold here was run by hand in
a throwaway directory and commits its fixture; the cases themselves were authored against the
runner's help text.

## Adding a Playbook

Adding a Playbook is three edits and nothing else: one reference file under `references/`, with
the door checks, the steps with their done conditions, and the links to the shared references;
one router line in `SKILL.md`, the condition that matches the Playbook, placed above any broader
condition it could shadow, with the reference linked under Links; and one case here, a prompt
that matches the Playbook and graders for the tree, the commits and the reply. The skill file
grows by one line.
