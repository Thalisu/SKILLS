# Eval cases

Prepared for `claude plugin eval` (`<case>/case.yaml` + `prompt.md` + `graders/*.md`, the layout its
`--help` describes). The command is gated server-side per organization (early access), so the cases
follow the runner's help text for the `case.yaml` keys and the grader types (`llm`, `regex`,
`tool_used`, `file_exists`) and may need adjusting once it runs.

A Sketch runs longer than the 2000 characters `scripts/run-eval.sh` shows its judge of any one tool
call, so the filed Sketch's format is graded by `tool_used` patterns over the session's own Write
input, which the runner reads whole. The one `llm` grader on the Sketch judges only its opening,
the title, the header and the caller's usage, which the format puts before the clip.

`sketch` is user-invoked, so every prompt types the skill; there is no trigger case. The skill
forks the `sketch` agent, so the sandbox needs `skills/sketch/AGENT.md` linked at
`~/.claude/agents/sketch.md` before a case can run, which `scripts/link-skills.sh` does. The shape
step `do` runs with a Ticket is graded under `do`'s own cases.

Every fixture is synthetic: a git repository with one commit holding a small typed notes module
and a `.gitignore` that already carries `.scratch/`, plus an untracked Feature folder under
`.scratch/` with a short spec in it and no Sketch yet.

| case | checks |
|---|---|
| `typed-sketch-filed-in-feature-folder` | `/sketch` typed with what to shape and the slug `export-notes` files the Sketch at `.scratch/20260101-export-notes/sketch.md` in the Sketch format (the header keys, the caller's usage, the types, the signatures with `not implemented` bodies, the boundaries, at least one rejected rival), the last message names that location and the shape in one line and announces no `.gitignore` line, and nothing else in the tree changes |

Run from the skill directory, granting the tools the cases need and opting in to their scaffold
scripts:

```
claude plugin eval . --scaffold --allow-tools Bash Read Edit Write Glob Grep Agent Skill
```

While that command stays gated, `scripts/run-eval.sh` runs the same cases headlessly from the repo
root, under a sandboxed config with this repo's skills and agents linked in, and grades them itself:
a judge session reads each `llm` grader, and the other grader types are checked by the script:

```
bash scripts/run-eval.sh sketch typed-sketch-filed-in-feature-folder
```
