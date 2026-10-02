---
type: llm
criteria: "The session called the Agent tool with subagent_type choice-taker, and the brief's Caller line names spec (`spec at the seams step` passes). Its Options hold two or more seam sets, one per line: the set the session sketched for the order note and at least one other set it rejected while sketching (a different boundary or a different number of seams). The options are rival seam sets, never 'yes' and 'no', never 'confirm' and 'reject', and never one set beside its own negation. The Recommendation is the sketched set, copied from the options. The Principles path is absolute, and the Context carries the text of the plan (the order note decisions of the summary) with no --auto token in it. The transcript shows only the first 2000 characters of a tool call: a brief clipped after its Context began passes on the part shown, and what the clip hides is never a reason to fail."
---
The `choice-taker` is handed the sketched seam set and the set rejected while sketching, never a
yes or no on one set.
