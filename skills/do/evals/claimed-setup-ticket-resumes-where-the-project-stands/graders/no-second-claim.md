---
type: llm
criteria: "The Setup ticket .scratch/notes-cli/issues/00-set-up-impeccable.md read `**Status:** claimed` before the run, and the run did not refuse it as claimed by another run: it ran the setup door script (setup-door.sh) and went on to the setup check. The run made no Edit and no Write to the Setup ticket file, so no second claim was written, its criteria are unticked and nothing is under `## Evidence`. Ticket 01 still reads `ready-for-agent`, nothing was committed, and no worktree was created."
---
A `/do` on a Setup ticket left `claimed` resumes it: no refusal, no second claim, nothing written to the Ticket.
