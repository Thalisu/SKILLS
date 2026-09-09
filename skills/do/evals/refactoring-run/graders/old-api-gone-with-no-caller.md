---
type: llm
criteria: "In the final tree, src/notes.ts no longer exports `label`, and `grep -rn 'label' src bin e2e` finds no call to the old notes-module `label`; the CLI bin/notes.mjs reads the status through the extracted module instead. No re-export, alias or wrapper named `label` survives in src/notes.ts. The dead helper `countArchived`, which had no caller in the fixture, is gone too, and it went in the subtraction commit rather than in the reshape."
---
Every caller is migrated and the old API is deleted in the same wave, with no shim left behind.
