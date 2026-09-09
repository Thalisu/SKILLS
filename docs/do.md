# do

## What it does

`do` matches a request to one **Playbook** and runs its steps: a **Ticket**'s path or issue
reference builds that Ticket as the last step of the chain, a request in words runs outside it, and
a request that fits no Playbook is sent to the door that owns it in one message. Four Playbooks
exist and one run reads one of them: `ticket`, `trivial`, `bug-fix`, `refactoring`. Every reply
opens with the Playbook it matched, so a wrong match costs you one retyped request and nothing
else.

The run never lands its own work and never fixes what a review found. It builds in a git worktree
of its own, one behaviour per green commit, runs the gate, and hands the branch to
[do-code-review](do-code-review.md), which fixes the Findings it marked `Act on` and fast-forwards
your branch when the **Review** is Green. Your branch takes reviewed commits or none. Nothing is
pushed: the run ends on the `git push` for you to type.

## When to reach for it

You invoke this by typing `/do <request>`, and the agent won't reach for it on its own.

| Ask | Use |
|---|---|
| build one ticket the chain cut | `/do <the Ticket's path>`, or `/do <issue number or URL>` where the project has a tracker file |
| fix a bug nobody wrote a ticket for | `/do <the bug in words>`: what happened, where, and the error or the wrong output |
| a typo, a doc line, a log wording, a rename inside one file | `/do <the change in words>` |
| reshape code whose behaviour stays where it is | `/do <the reshape in words>`: refactor, rename, extract, inline, dedupe, move a module |
| build a whole spec | not this skill: [tickets](tickets.md) cuts the spec first, and `do` takes one ticket of the cut |
| decide the plan, or a feature with no ticket | [discuss](discuss.md), or [spec](spec.md) when the conversation already holds the discussion |
| understand code rather than change it | `/how` for the mechanism, `/why` for the rationale, `/teach` to follow it end to end |

One request, one Playbook. `do` takes a single ticket and never a spec, and it never batches two
tickets into one run. Answers arrive in the language you opened the session in; everything written
into the project is in English.

## Prerequisites

Nothing has to be installed for `do` to run, but four things in the project change what a run can
do, and the first message says which of them it found.

| In the project | What `do` does with it, and without it |
|---|---|
| the **Ticket** itself, a file under `.scratch/` or an issue on the tracker `docs/agents/issue-tracker.md` describes | the `ticket` Playbook's whole input. No file and no tracker entry, and there is nothing to match: a bare issue number is refused and the ticket's path is asked for |
| a Testing Policy with its unit test author at `.claude/agents/unit-test-author.md` | the first message reads `Loop: policy` and every new test is written by that author. Without it the line reads `Loop: fallback` and the run writes each failing test itself, red before the fix either way |
| [do-code-review](do-code-review.md) linked in the session | the review fixes its `Act on` Findings and lands the branch. Without it the step reads `skip: do-code-review not listed`, nothing lands, and the reply hands you the worktree, its branch and the review to run yourself |
| the vendored `architect`, `how` and `unslop` | the shape is sketched before a boundary is crossed, the grounding stays out of the run's context window, and the reply is cleaned up. Each is optional and each step says in one line what it does instead |

The run writes into two places outside your branch: the worktree at `.claude/worktrees/do-<slug>`,
excluded through this clone's `.git/info/exclude` and never through the project's `.gitignore`, and
the Ticket file in the **Main checkout**, which the run edits and never commits. Installing every
skill named here is the same procedure, and [the top-level README](../README.md) carries it once.
