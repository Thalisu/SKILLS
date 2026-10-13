---
type: llm
criteria: "The run ended its turn on the refusal and did nothing to wait for the blocker. Pass only when all of these hold. First, no tool call in the transcript sleeps, polls or loops on Ticket 02's status (no `sleep`, no `watch`, no `until` or `while` loop, no repeated read of Ticket 02 to see whether it changed, no scheduled or background task). Second, the final message asks the developer no question and offers nothing to confirm: it does not ask whether to build the blocker, whether to wait, or whether to resume. Third, the final message does not say the run is waiting, paused, or will continue by itself once the blocker is resolved: what resumes the Ticket is the developer typing `/do` on it again."
---
The refusal is the wait: no run stays open holding a window idle while the blocker is built in
another session.
