# Eval cases

Prepared for `claude plugin eval` (`<case>/case.yaml` + `prompt.md` + `graders/*.md`, the layout its
`--help` describes). The command is gated server-side per organization (early access), so the cases
have been authored, not executed; the `case.yaml` keys and grader types beyond `tool_used` follow
the runner's help text and may need adjusting once it runs.

`journey` is user-invoked, so every prompt types the skill; there is no trigger case. Each run ends
when the skill asks its first question, since no user is there to answer it, which is exactly the
moment the cases inspect: the precedent note, the tree and the first drafted path are in the thread
by then, and nothing has been written.

Every fixture is synthetic: a two-page backoffice (a Customers page with a search box, a create
form, a delete dialog and an empty state, under a top navigation), a local-markdown tracker file, a
glossary, and a spec in the format `spec` writes with `Journey: required` under its title.

| case | checks |
|---|---|
| `spec-required` | no argument: one message asking for the spec, nothing else, nothing written |
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
