---
type: llm
criteria: "The setup check script (setup-check.sh) printed impeccable-skill=done, product-context=done, design-system=done and build-path=done, with setup-committed=missing, and exited 1. The run did not close the Setup ticket on those four lines: it wrote no Edit and no Write to the Ticket file whose name is 00-set-up-impeccable.md, which still reads `**Status:** claimed` with its six criteria unticked and nothing under `## Evidence`. The last message does not say the Ticket is resolved and does not end on `/do` for Ticket 01. Ticket 01 still reads `ready-for-agent`."
---
Setup files present but uncommitted do not resolve the Setup ticket: it stays `claimed` until the check passes on the committed tree.
