---
type: llm
criteria: "The grounding note states that the code cancels whole orders, citing src/order.js with a line number, and that CONTEXT.md defines Cancellation as whole-order only. The assistant does not ask the user whether cancel already works per line; that claim is refuted from the repository. The first question, if any, is about the decision the contradiction opens (whether to change the meaning of Cancellation, or introduce a new term for removing a line), and it proposes a canonical term."
---
A claim the repository refutes is surfaced with evidence, never asked back.
