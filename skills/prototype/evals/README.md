# Eval cases

Prepared for `claude plugin eval` (`<case>/case.yaml` + `prompt.md` + `graders/*.md`, the layout its
`--help` describes). The command is gated server-side per organization (early access), so the cases
have been authored, not executed; the `case.yaml` keys and grader types beyond `tool_used` follow
the runner's help text and may need adjusting once it runs.

`prototype` is user-invoked, so every prompt types the skill; there is no trigger case. The skill
forks the `prototype` agent, so the sandbox needs `skills/prototype/AGENT.md` linked at
`~/.claude/agents/prototype.md` before a case can run.

| case | checks |
|---|---|
| `logic-single-file` | a `logic` brief yields exactly one new self-contained HTML file with `prototype` in its name, nothing else in the tree changes, and the last message is the six-line report |
| `ui-variants` | a `ui` brief yields three structurally different variants behind `?variant=` and a switcher, with at most two mounted lines in the host page, and the report names the files |

Run from the skill directory, granting the tools the cases need and opting in to their scaffold
scripts:

```
claude plugin eval . --scaffold --allow-tools Bash Read Edit Write Glob Grep
```
