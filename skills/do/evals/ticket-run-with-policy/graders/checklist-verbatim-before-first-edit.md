---
type: llm
criteria: "Before any file was created or edited, the run's first message showed the ticket Playbook's twelve-step checklist verbatim (the numbered steps 0 to 11 as written in the reference, from 'Input resolved and confirmed' to 'Reply'), and that message held, in this order, `Playbook: ticket`, the title '01: Archive a note' confirmed back, done stated as a predicate (the criteria plus the gate), and a `Loop: policy` line, with no claim line: the claim is written only at step 2, after the Plan is verified, so it is not part of the run's first message. Every step the run skipped carries `skip: <reason>` where it is reported; the review step was not skipped, since the fixture lists do-code-review."
---
The checklist appears verbatim before the first edit and every skipped step carries a reason.
