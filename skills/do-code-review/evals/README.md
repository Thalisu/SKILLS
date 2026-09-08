# Eval cases

Prepared for `claude plugin eval` (`<case>/case.yaml` + `prompt.md` + `graders/*.md`, the layout its
`--help` describes). The command is gated server-side per organization (early access), so the
cases have been authored, not executed; the `case.yaml` keys and the grader types (`llm`,
`tool_used`, `file_exists`) follow the runner's help text and may need adjusting once it runs
here. Until then `tests/evals.sh` runs every scaffold in a throwaway directory and asserts the
fixture each case relies on: the planted defects are in place, the fixture's suite is green, the
caller outside the diff breaks, and the door script reads the facts the case expects.

`do-code-review` is model-invoked, so one case is a bare trigger in Portuguese; the others type the
skill. Every fixture is synthetic: a small notes module in plain JavaScript with `node --test` as
its suite, so it runs offline with node alone. The planted diff keeps its Ticket and its spec in
`.scratch/` tracked by git, so that run also exercises the durability line.

| case | checks |
|---|---|
| `planted-diff` | five defects and a clean hunk on a branch whose Ticket the prompt hands over as `do` does: each defect in its expected Bucket at or above its minimum Rung, the clean hunk with no `Act on`, no Rung 1 or 2 in `Act on`, each location once, six Axis lines, no principle without a location, the reviewer with no write or edit tool, the Review beside the Ticket, named after it, with `Ticket:` naming it |
| `ref-does-not-resolve` | `/do-code-review nope` ends in one line, `nope does not resolve; nothing reviewed`, and writes nothing |
| `empty-diff` | a clean tree on the base branch ends in one line, `no diff between main (<sha>) and the working tree; nothing reviewed`, and writes nothing |
| `no-spec` | a branch with no spec and no tracker file: five Axes reported, the Spec line reading `no spec`, nothing asked, the Review named after the branch |
| `triggers-pt-br` | a bare "revisa esse diff antes de eu dar push" fires the skill |

Run from the skill directory, granting the tools the run needs and opting in to the scaffold
scripts:

```
claude plugin eval . --scaffold --allow-tools Bash Read Write Glob Grep Agent Skill
```
