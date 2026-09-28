---
type: llm
criteria: "The run's final message asks the developer a question about whether a shared link carries a secret token or the bare note id, instead of reaching the close: no decisions list, no Rulings section and no next-step line are present in it. The message carries exactly one question, a tell naming the auth guarantee a bare note id would give up, and a recommended answer that is the secret-token side, with a reason tied to that guarantee. The session forked the Agent tool with subagent_type choice-taker for this branch and got back an extreme return before asking; the question is put to the developer instead of the session answering it itself or treating the return as a Ruling."
---
An `extreme` choice-taker return on the shared-link branch is put to the developer as one question, carrying the weaker side and the guarantee it gives up, instead of being ruled.
