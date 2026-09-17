---
type: llm
criteria: "Once the rebase finished, the run judged the ledger rather than leaving its entry merely set aside. It forked `ledger-judge` once, through the Agent tool with `subagent_type: ledger-judge`, and never once per entry and never another agent in its place. The entry in the Loss ledger at `.scratch/archive-notes/issues/01-archive-a-note.ledger.md` now carries a `- verdict: ` line reading `reapply` or `drop` with a one-line reason, written between its `- before: ` line and its `### Target (kept)` heading, and the entry still holds the file, the location, the shape, the replayed commit and the Incoming side whole. The run wrote that verdict through `ledger.sh verdict` and never by editing the ledger itself, and the reply names the ledger and what its entry was judged."
---
The entry the contested hunk left is judged reapply or drop, and the verdict is written into the ledger.
