# Eval cases

Prepared for `claude plugin eval` (`<case>/case.yaml` + `prompt.md` + `graders/*.md`, the layout its
`--help` describes). The command is gated server-side per organization (early access), so the cases
have been authored, not executed; the `case.yaml` keys and grader types beyond `tool_used` follow
the runner's help text and may need adjusting once it runs.

`journey` is user-invoked, so every prompt types the skill; there is no trigger case. Each run ends
when the skill asks its first question, since no user is there to answer it, which is exactly the
moment the cases inspect: the precedent note, the tree and the first drafted path are in the thread
by then, and only what closed before that question has been written. The skill saves a path it
closes from precedent to `journey.md`, and a term it resolves to `CONTEXT.md`, the moment each one
closes.

Every fixture is synthetic: a two-page backoffice (a Customers page with a search box, a create
form, a delete dialog and an empty state, under a top navigation), a glossary, and a spec in the
format `spec` writes with `Journey: required` under its title. Every fixture also carries a
local-markdown tracker file except `dated-slug-newest`, which carries no tracker file, so its bare
slug resolves in the scratch.

| case | checks |
|---|---|
| `spec-required` | no argument: one message asking for the spec, nothing else, nothing written |
| `dated-slug-newest` | a bare slug that carries two dated feature folders goes through the resolver, and the spec walked is the newest, `20260905-suppliers`, never the abandoned `20260801` draft |
| `unknown-slug-stops` | a bare slug that names no feature folder, beside a feature whose folder only ends in it, goes through the resolver, and its `spec=none` ends the run in one message asking for the spec's path; nothing is walked or written |
| `one-question` | the first path is drafted from precedent and shown before any question; the first message that asks something carries exactly one question, a recommendation and the tell, from the actor's seat |
| `precedent-first` | a fork the sibling page settles (the delete confirmation, the empty state, the form's cancel) is closed with `file:line` and never asked |
| `spec-contradiction` | a story the app refutes (a sidebar the app does not have) is named in the precedent note with `file:line`, and the question is which side wins |
| `runnable-fork` | a screen with no precedent is marked runnable and forks the `prototype` agent with a complete brief, instead of asking for a layout in words; every other fork stays a question |
| `no-writes-without-decision` | with no fork closed, nothing is created or edited in the project (no journey, the spec and its verdict untouched) and nothing is committed |

A `PROTOTYPE ask` answered by resuming the agent has no case either: the ask reaches the user only
after the brief was sent, so the run has already ended at that question.

Run from the skill directory, granting the tools the cases need and opting in to their scaffold
scripts:

```
claude plugin eval . --scaffold --allow-tools Bash Read Edit Write Agent
```

While that command stays gated, `scripts/run-eval.sh` runs the same cases headlessly from the repo
root, under a sandboxed config with this repo's skills linked in, and grades them itself: a judge
session reads each `llm` grader, and the other grader types are checked by the script. Name the
cases to run only some of them:

```
bash scripts/run-eval.sh journey dated-slug-newest
```
