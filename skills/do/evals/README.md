# Eval cases

Prepared for `claude plugin eval` (`<case>/case.yaml` + `prompt.md` + `graders/*.md`, the layout its
`--help` describes). The `case.yaml` keys and the grader types (`llm`, `regex`, `tool_used`,
`file_exists`) follow the runner's help text and may need adjusting once it runs here.

A case whose fixture installs its own stand-in of a skill this repo ships names that skill under
`context.unlinked_skills`, the way `unlisted-reader` names an agent under `context.unlinked_agents`.
The runner links every skill of this repo into the session's sandbox, so without that key the linked
skill wins and the stand-in never runs. `skills/do/tests/stand-in-skills.sh` holds every case to it.

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
| `layout-goes-to-prototype` | a request to try a layout: one message naming `/prototype`, no HTML or variant written |
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
| `ticket-run-with-policy` | a Ticket built end to end under an installed Testing Policy on a native surface (a CLI with a flow under `e2e/`): the checklist verbatim before the first edit with every skipped step reasoned, the worktree before the first edit, entered with a bare `cd` and never with the harness's worktree tool, and the main checkout's dirty `README.md` untouched, one discover batch with its audit line, one dispatch in flight, one commit per behaviour holding a test and an implementation with the behaviour line in its body, the gate after the last edit, the review called once with the Ticket's location and the landing target and never with `fix` nor `--no-fix`, `main` fast-forwarded by the review and nothing pushed, the affected flow run from the main checkout, the Ticket `resolved` in the main checkout with its criteria ticked and the evidence appended only after the flow run, absent from every commit and untouched on the worktree branch, no worktree of the run remaining, the reply carrying the PR sections, naming a principle only beside a decision and listing the Ticket and the Review as left uncommitted |
| `integration-mechanical-conflict` | the same Ticket on the same fixture, with a `post-commit` hook that lands one commit on `main` the first time a commit lands on the run's `do/` branch, adding lines at the end of `src/notes.ts` where the build adds its own: the rebase between the gate and the review stops on a conflict, the run shows the door script's lines and states the counts before it resolves anything, resolves every hunk itself with the union of the three index stages and asks the developer nothing, runs the gate's command lines a second time and calls the review after them with the commit the rebase landed on as its fixed point; the landed file carries both sides with `main`'s above the replayed commit's, and nothing is pushed |
| `integration-no-human-aborts` | the same Ticket on the same fixture, with the `post-commit` hook landing a commit on `main` that rewrites `list()` through its closing line, where the build appends its own function: the rebase stops on a hunk the door script classes contested, and in a session nobody can answer (the case assumes the runner drives it through the SDK, so `CLAUDE_CODE_ENTRYPOINT` starts with `sdk-`) the run shows the door script's lines and the counts, `contested.sh` answers `no human`, and the run aborts the integration with the prefixed `rebase --abort`, asks nothing, names `src/notes.ts`, leaves `do/archive-a-note` as it was and the Ticket `claimed`, and lands and pushes nothing |
| `absent-review` | a session without `do-code-review` (the fixture installs no stand-in): the gate completed, the review step `skip: do-code-review not listed`, nothing landed, the worktree, its branch and the review named as the next step, the Ticket `claimed` and uncommitted |
| `review-act-on-fixed-and-landed` | a Review with one `Act on` Finding, planted in the stand-in: the review's Fixer turns it into one commit on the worktree branch, the run makes no commit for it, the review is called once, and the landing follows it |
| `review-not-landed-blocks` | a return that says not landed, the Finding `not fixed`, planted in the stand-in: the run stops as blocked with the review's reason quoted, the worktree and its branch named, nothing landed, the Ticket left `claimed` |
| `red-flow-lands-through-fix` | the affected flow red after the first landing, since the stand-in's planted Fixer commit makes the CLI exit non-zero: the fix as one unit in the worktree, gated, then handed to the fix call on the same Review with `main` as the landing target, which lands it with no second review |
| `blocked-ticket-refused` | Ticket 02 blocked by Ticket 01 still `ready-for-agent`: refused before the claim in one message naming the blocker and its status, the blocker read for its status line and never for its body, nothing written |
| `resolved-ticket-stops` | a Ticket already `resolved`: one line saying so, nothing written |
| `claimed-no-worktree-starts-over` | a `claimed` Ticket whose worktree is gone: one line saying the run starts over, the claim standing, a new worktree and the build |
| `claimed-worktree-resumes` | a `claimed` Ticket whose `do/archive-a-note` worktree holds two commits, one per behaviour with its `Behaviour:` line: the first message says it resumes and lists them, no second worktree, the loop continues at the third behaviour and the first two get no new commit |
| `resumed-worktree-uncommitted-asks` | the same worktree with an uncommitted half-written test in it: the first message says it resumes, names `src/notes.test.ts` and asks before discarding, then waits; nothing discarded, no commit, no second worktree |
| `resumed-integration-keeps-a-hand-resolution` | the same worktree with all three behaviours committed, stopped mid-rebase onto a `main` that added a line at the end of `union.txt` and `hand.txt` where the third commit adds its own, neither file staged: `union.txt` already holds the union of its three index stages and `hand.txt` a resolution typed by hand, with the review stand-in of `integration-mechanical-conflict` installed. The first message says it resumes, names the branch read from the rebase state and both conflicted files, and the stop is classed `trusted hand.txt` and `mechanical union.txt` before anything is touched; the run asks nothing, finishes the rebase, `hand.txt` reaches the branch byte for byte, and the reply names it as taken on trust with no unmergeable question anywhere |
| `protected-branch-said-first` | `main` beside a `develop` branch: the first message names the branch and the rule and says landing will be refused; the run still builds to the gate and calls the review, the review lands nothing, and the reply names the worktree and its branch with the two commands that land by hand |
| `design-fork-settled` | a Ticket whose third criterion (a second Archive restores the note, a toggle) contradicts the Spec's decision and the journey's failure branch (a second Archive is a no-op), with no Extreme side: the run names the Design fork and both sides in one line, rules for the no-op on the Spec's decision, appends the choice-taker's ruling line to the Spec's Implementation Decisions, rewrites the third criterion to the no-op still unticked with every other criterion unchanged, names the Spec as changed and carries on to at least one behaviour commit on `do/archive-a-note` instead of stopping; the main checkout's dirty README.md untouched |
| `withheld-agent-tool` | the Agent tool withheld from the whole session, the nearest a case can get to withholding it from a delegate: no agent dispatched and no delegate forked, the door's reader among them, so the Digest read by the session itself and written beside the Ticket all the same, the inline test-author skill applied, the session's own commits carry the work |
| `unlisted-reader` | the Ticket of `withheld-agent-tool` with the Agent tool granted and every agent linked but `do-reader`, which the case's `context.unlinked_agents` keeps out of the runner's sandbox: no reader forked and no other agent forked in its place, the Spec and the journey read by the session itself, the Digest written beside the Ticket with the door's hashes, and one line naming `do-reader` as not listed and `scripts/link-skills.sh` as what links it |
| `global-loop-withheld-agent-tool` | the Ticket of `ticket-run-without-policy`, no Testing Policy in the project, with the Agent tool withheld and the runner's HOME assumed to link the global authors: the first message reads `Loop: fallback` and says in one line that the tool is withheld, the Project map derived once beside the Ticket, no author dispatched, every test written by the session red first, and the flows step reading `skip: no end-to-end command in the project` with `/testing-policy` named and the criterion left as pending debt |
| `portuguese-session` | the Ticket's path followed by a Portuguese request, the one way a single prompt opens the session in Portuguese: the reply in Portuguese, the status line, the evidence and the commit messages in English |
| `absent-vendored-skill` | a session that does not list `how`, which is the runner's own session (it lists the skill under test and the fixture's skills, never the vendored ones): the grounding step states the one-line fallback and completes, the build continues to the gate |
| `bug-fix-run` | a bug reported in words with no Ticket, on the CLI fixture whose `archivedCount` compares with an assignment: the run reproduces it itself on `node bin/notes.mjs`, rules the hypotheses out with runtime evidence, lands the failing reproduction as its own commit before the fix commit, re-runs the reproduction on the same surface, calls the review once with the branch alone as the spec source, and lets the review fast-forward `main`; the reply pastes the failing then passing output, no worktree remains and nothing is pushed |
| `bug-ticket-no-cause` | the same defect as a Ticket that names no cause: the first message reads `Defect: cause unknown, diagnosis first`, the reproduce and cause steps of `bug-fix` run before the behaviours list, the instrumentation is reverted, and the red run reproduces the defect before any change to `src/notes.js` |
| `ticket-run-without-policy` | the same Ticket in a project with no Testing Policy, on the plain JavaScript fixture: the first message reads `Loop: fallback`, the run reads `references/tdd-fallback.md` before its first test and never dispatches a test author, and for each behaviour the failing test is written and run red by the session before the implementation, both landing in one commit |
| `refactoring-run` | a reshape asked for in words on the native fixture, the note status scattered over two independent booleans that four functions and the CLI read, plus a `countArchived` helper with no caller: `Playbook: refactoring` with the checklist verbatim, the pin before any structure moves (the suite and the typecheck quoted, an equivalence harness outside the test tree for the archive transitions no test in the tree covers (archiving a note clears its pin and drops it from the list, and pinning an archived note is refused), and a red-first test on `src/status.ts` through the test author), the subtraction commit carrying that still-red test, the reshape migrating the CLI and deleting `label`, the harness agreeing on the new code, the cleanup commit deleting it with its gap named as debt, then the gate and the review through the stand-in, which fast-forwards `main`; the fixture's assertions untouched throughout |

The `ticket` cases scaffold the same fixture with a Testing Policy installed (the marked section
in `CLAUDE.md` with its Project facts, the `unit-test-author` agent with its Project map, the
inline `test-author` skill), a spec, its journey and two Tickets under `issues/`, and, for the
runs, an uncommitted line in `README.md` as the developer's work in progress; the resume cases add
the `do/archive-a-note` worktree with two commits on it, one per behaviour, and one of them an
uncommitted edit in that worktree. Most cases put the policy on a consumer surface with no
consumer, so the verification has no flow to run; `ticket-run-with-policy`,
`red-flow-lands-through-fix` and `integration-mechanical-conflict` put it on a native surface, with a
CLI under `bin/`, the `e2e-test-author` agent and a flow under `e2e/` that drives the CLI, so the
affected flow runs from the main checkout. `integration-mechanical-conflict` adds one thing to that
fixture, a `post-commit` hook under its `.git/`: the first commit on a `do/` branch fires it once,
and it lands one commit on `main` with git's plumbing in a temporary index, so the developer's
branch moves only after the run's worktree exists and the rebase has something to replay. Its
commit only adds lines, at the end of the file the build appends to, which is what makes every hunk
of the stop class `mechanical`. The fixture's commands are real: `node --test 'src/**/*.test.ts'` runs the unit suite,
`node --test 'e2e/**/*.test.ts'` the flows, and `tsc --noEmit` typechecks `src/`.
`ticket-run-without-policy` scaffolds the plain JavaScript fixture of the `trivial-` cases instead,
with the same spec, journey and Tickets and no policy section, no agent and no inline skill, so the
run takes the TDD fallback and node alone runs its suite.
The two bug cases scaffold a third fixture, the plain JavaScript notes module with a CLI under
`bin/` and a planted defect in `archivedCount`, so the run has a surface to reproduce on and the
defect has a one-character cause: `bug-fix-run` ships it with no Ticket at all, and
`bug-ticket-no-cause` ships it with a Ticket and a spec that describe the wrong output and never say
why.

`refactoring-run` runs outside the chain, so its fixture carries no spec, no journey and no Ticket: the
request in words is the whole input and the branch is the whole state. It scaffolds the native fixture
with the policy, the two agents and the inline skill, and reshapes `src/notes.ts`, whose status lives in
an `archived` and a `pinned` boolean that `archive`, `pin`, `label`, `list` and the CLI all read, so the
reshape has a structure to name, callers to migrate and dead weight to subtract. Its stand-in review is
the same one, with one change the branch-only spec source needs: a first argument that is not a file in
the main checkout writes the Review to `.scratch/reviews/<branch>.md` there, per
[ADR 0021](../../../docs/adr/0021-the-ticket-reaches-the-review-handed-over-and-the-review-defaults-to-the-main-checkouts-scratch.md),
and reads the intent off the branch's first commit subject.

The `do-code-review` in this repo takes a ref and writes the Review, and does not take a Ticket's
location, fix or land yet, so the review-era cases install a stand-in for the contract `do` calls
in the fixture, `.claude/skills/do-code-review/`: a skill whose one instruction runs `review.sh`
and returns its output, and a script with that contract's call and return (the Ticket's location,
the fixed point and the landing target in; the Review's location, its text and the landing line
out; `fix` and `--no-fix` refused). It writes the Review beside the Ticket, plays the Fixer the
case planted (`plant` reads `green`, `act-on`, `not-fixed` or `red-flow`; a second call is always
green), re-runs the unit suite, fast-forwards the landing target when the Review is Green under
the protected-branch rule, and logs every call and every landing under the fixture's `.git/` for
the graders. `absent-review` installs none. The stand-in goes when the real skill takes the call.
`red-flow-lands-through-fix` carries the one stand-in that takes `fix`: `do`'s landing of what it
committed after its one review, per
[ADR 0033](../../../docs/adr/0033-the-review-runs-once-per-run-and-what-comes-after-it-lands-through-the-gate-alone.md),
which re-runs the unit suite and fast-forwards with no reviewer and no Fixer, appends its
`## Fix run` to the same Review, and, like its review call, prints the outcome alone rather than
the Review's text, as the real skill does for a caller that hands the Gate.

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
