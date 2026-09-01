# Eval cases

Prepared for `claude plugin eval` (`<case>/case.yaml` + `prompt.md` + `graders/*.md`, the layout its `--help` describes). The command is gated on this machine, so the cases have been authored, not executed; the `case.yaml` keys and grader types beyond `tool_used` follow the runner's help text and may need adjusting once it runs.

| case | checks |
|---|---|
| `triggers-pt-br`, `triggers-en` | the skill fires on "why are these tests failing" wording |
| `no-trigger-bare-run` | it does not fire on a bare "run the tests" |
| `blocked-on-infra` | an unreachable test stack ends in BLOCKED and writes nothing |
| `rollback-to-dossier` | a failure whose only fix is an assertion is rolled back and registered as a dossier |

Run from the skill directory, granting the tools the workflow cases need and opting in to their scaffold scripts:

```
claude plugin eval . --scaffold --allow-tools Bash Read Edit Write
```
