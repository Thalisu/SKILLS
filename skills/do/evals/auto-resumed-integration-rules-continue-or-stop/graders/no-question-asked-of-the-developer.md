---
type: llm
criteria: "The run asked the developer nothing anywhere and waited for no answer: the session ran from the one prompt to its reply in one go, and no message of the run ends in a question to the developer or waits on one. In particular, the last message does not ask whether to continue the rebase or stop, and carries no `(continue / stop)` question for the developer to answer. The session did not decide between continuing and stopping on its own before the Agent call with subagent_type choice-taker returned: no `git rebase --continue` and no `git rebase --abort` runs before that call."
---
Under `--auto` nobody is asked whether the open rebase continues: the `choice-taker` rules it.
