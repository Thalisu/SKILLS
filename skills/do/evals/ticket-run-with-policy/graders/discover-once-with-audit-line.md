---
type: llm
criteria: "One discover batch ran, once, before the first new symbol was created, covering every symbol the plan named in a single batch: either the discover skill was called once with a numbered batch, or, when the session did not list it, one `rg -n -w` or grep per candidate stood in and the audit line said so. The audit line in the form `Discovery: n FOUND · n DUPLICATE · n NOT_FOUND` appears in the Reply's Run section. Never one discover call per symbol, and never a symbol created before the batch."
---
The discover batch ran once and its audit line is in the thread.
