# Eval cases

Prepared for `claude plugin eval` (`<case>/case.yaml` + `prompt.md` + `graders/*.md`, the layout its
`--help` describes). The command is gated server-side per organization (early access), so the cases
have been authored, not executed; the `case.yaml` keys and grader types beyond `tool_used` follow
the runner's help text and may need adjusting once it runs.

`spec` is user-invoked, so every prompt types the skill; there is no trigger case. The conversation
the skill synthesises is the prompt itself: a `discuss` closing summary pasted after `/spec`, in the
shape that skill's step 6 produces. A run that has the seams in the summary ends at the closing
summary; a run that has not ends at the seams check, the one question the skill asks.

| case | checks |
|---|---|
| `no-plan` | a bare `/spec` with nothing decided in the conversation gets one message sending the user to `/discuss`; nothing is written and nothing is asked |
| `no-interview` | a summary that names the seams produces the spec with no question asked; the seams line says they were taken from the summary |
| `seams-once` | a summary that names no seams ends at exactly one question, about the seams, with a proposal; nothing is written before the answer |
| `routes-to-journey` | stories that add a route and walk more than one path get `Journey: required` and a last line naming `/journey` with the spec path |
| `routes-to-tickets` | stories that are one interaction on an existing screen get `Journey: not needed` with the condition, and a last line naming `/tickets` with the spec path |
| `no-tracker-file` | with no `docs/agents/issue-tracker.md`, the spec still lands at `.scratch/<slug>/spec.md`, the summary says the file was absent, and no setup skill is demanded |

Run from the skill directory, granting the tools the cases need and opting in to their scaffold
scripts:

```
claude plugin eval . --scaffold --allow-tools Bash Read Edit Write Agent
```
