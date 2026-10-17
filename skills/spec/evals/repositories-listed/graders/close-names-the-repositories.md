---
type: llm
criteria: "Two things hold together. First, the spec the run wrote under .scratch/ visibly carries a section headed '## Repositories'. Second, the assistant's closing summary has an item that names that section and the repositories it lists: both the orders service, as the Home repository, and the billing service. A closing summary that says the spec lists the repositories while the written spec shows no '## Repositories' section fails, since the item then names a section that is not there. A mention of the two services elsewhere in the summary (in the seams item, for example) with no item naming the section fails too. The assistant asked the user nothing."
---
The close lists the section among what the run wrote, so the developer never has to open the Spec
to check that it is there: an item is worth that only when the section it names was written.
