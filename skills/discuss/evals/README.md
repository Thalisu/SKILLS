# Eval cases

Prepared for `claude plugin eval` (`<case>/case.yaml` + `prompt.md` + `graders/*.md`, the layout its
`--help` describes). The command is gated server-side per organization (early access), so the cases
have been authored, not executed; the `case.yaml` keys and grader types beyond `tool_used` follow
the runner's help text and may need adjusting once it runs.

`discuss` is user-invoked, so every prompt types the skill; there is no trigger case. Each run
ends when the skill asks its first question, since no user is there to answer it, which is exactly
the moment the cases inspect.

| case | checks |
|---|---|
| `one-question` | the first message that asks something carries exactly one question, a recommendation and the tell |
| `explores-first` | a branch the fixture's code settles is closed with `file:line`, never asked; the grounding note names the contradiction |
| `no-writes-without-decision` | with no decision taken, nothing is created or edited in the project and nothing is committed |

Run from the skill directory, granting the tools the cases need and opting in to their scaffold
scripts:

```
claude plugin eval . --scaffold --allow-tools Bash Read Edit Write
```
