---
type: llm
criteria: "The session forked the Agent tool with subagent_type choice-taker for the seams and got back a refusal whose first line reads neither settled nor extreme. The run's final message ends waiting on the user's answer to exactly one question, about the seams the tests will drive the order note through: it proposes the seams (an existing seam in the order module, as few as possible) with a reason and asks whether they match the user's expectations. Before the question, one line names why the check is asked instead of ruled: the choice-taker returned no ruling, refused, or returned neither settled nor extreme, or equivalent wording. No seam reads as ruled anywhere in the message, the session did not settle the seams on its own, and the message is not a closing summary: no spec path, no verdict and no next command appear in it. Naming the seam set the sketch rejected beside the proposed one, or adding a line that nothing is written until the answer, passes: the one question is still whether the proposed seams match."
---
A return that is neither `settled` nor `extreme` is no ruling: the seams check comes back to the
developer with the reason named.
