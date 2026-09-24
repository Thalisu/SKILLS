---
type: llm
criteria: "The run landed and its final message, the Reply, ends on a Next step line naming the push with the developer's branch, `git push` with main named (for example `git push origin main`), and carries no line reading `Yours:` anywhere, since a landed run is not a stop. The run pushed nothing itself: no tool call in the transcript runs `git push` in any form."
---
A landed run hands the push over as its Next step, never as a stop, and pushes nothing.
