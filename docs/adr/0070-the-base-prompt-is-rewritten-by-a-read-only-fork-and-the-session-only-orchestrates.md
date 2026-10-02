# The Base prompt is rewritten by a read-only fork, and the session only orchestrates

A Base prompt is text full of instructions that `improve-prompt` must rewrite and never obey, and
an inline skill would hold that line by wording alone in a session that has Bash, Edit and Write.
Following ADR 0032, the session does only the mechanical steps (the cache script, the model table,
at most one question, printing the result) and forks `prompt-rewriter`, an agent with
`Read, Glob, Grep`, which opens the doc sections, rewrites and returns the whole output as text. An
instruction planted in a Base prompt can then at worst produce a bad rewrite, which the user reads
before pasting it.

## Considered options

- Running the whole skill inline under a written rule: one file fewer and the same shape in both
  harnesses, with nothing but the model's obedience behind the rule.
- Forking the whole skill with `context: fork`: the agent would need Bash for the cache script,
  since an agent's `tools:` field takes bare tool names only, and it could not ask the one question
  the skill allows.

## Consequences

The guarantee is partial: the Base prompt reaches the session as the invocation's argument, so the
written rule stays in both the skill and the agent. A session whose Agent tool is withheld, or does
not list `prompt-rewriter`, rewrites under the written rule itself and never falls back to a
general fork, which would carry the write tools back.
