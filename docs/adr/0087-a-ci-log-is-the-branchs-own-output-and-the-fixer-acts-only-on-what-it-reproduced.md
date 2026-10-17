# A CI log is the branch's own output, and the fixer acts only on what it reproduced

ADR 0032 keeps a stranger's text away from any fork that holds a write tool. The `pr` Playbook's
fixer takes the excerpt of a red check's log straight into its brief, with no read-only reader in
between: the log is the output of the head branch's code and the repository's workflow, which only
someone with push access can shape, not text anyone who comments on an issue can write. Two
structural guards stand in for the reader: a script cuts the excerpt and the brief carries it as
quoted data, and the fixer edits nothing until it has reproduced the failure locally, the local
output being the evidence and the log only the pointer. A check that does not reproduce locally gets
no fix: it earns the one rerun ADR 0089 allows, and stops the run when it is red again.

## Considered options

- A read-only reader that turns the log into a structured failure for the fixer: one more fork per
  round for a text the threat ADR 0032 answers does not reach.
