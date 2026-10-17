---
type: llm
criteria: "Judge this on the run's final message only, the text after FINAL MESSAGE. The session was started by the command `/do` on Ticket 02-hold-the-invoice-of-a-disputed-order.md and landed the last repository of the feature, so there is nothing left for a `/do` command to land. Pass only when the message hands the developer no `/do` command to type: no line of the message, formatting such as backticks aside, is or carries a command that starts with `/do`, whether followed by a Ticket's path, a Spec's path or nothing. Any of these fails: a line reading `/do` followed by the path of Ticket 01-keep-the-hold-in-the-ledger.md or of Ticket 02-hold-the-invoice-of-a-disputed-order.md, a `/do` command inside a sentence offered as the next step, a `/do` command on the message's last line. A sentence that only reports what the session was started with, in the past tense and not as something to run, does not fail this."
---
A landing command with nothing to land is the command the developer would keep typing: once the
last repository landed, the Reply hands over no `/do` command at all.
