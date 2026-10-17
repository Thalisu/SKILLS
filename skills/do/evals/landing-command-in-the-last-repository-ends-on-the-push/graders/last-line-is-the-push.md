---
type: llm
criteria: "Judge this on the run's final message only, the text after FINAL MESSAGE. The session landed the Spec branch of billing-service on the developer's branch, `main`, and no repository of the feature is left to land. Pass only when both of these hold. First, the last line of the message that is not blank is the command `git push main` and nothing else: at most formatting such as backticks or a code fence around it, no label before it and no words after it. When the message ends on a fenced code block, the last line is the last line inside that block. Second, the push is named on that last line alone: no earlier line of the message starts with `Push:`. Any of these fails: the last line is a `/do` command, the last line is a sentence, the last line reads `Push: git push main` with the label on it, the last line names another branch than main, text follows the `git push main` line, an earlier line reads `Push: git push main`, the message carries no `git push` at all."
---
Nothing but the push is left to the developer, so it is where the Reply ends: `git push main` on
the last line, with no `Push:` line of its own before it, which is only there when another
repository's command takes the last line.
