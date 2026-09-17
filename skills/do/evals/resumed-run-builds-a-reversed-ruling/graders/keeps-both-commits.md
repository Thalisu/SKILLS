---
type: llm
criteria: "The two commits the fixture left on do/archive-a-note (`feat(notes): archive a note out of the list` and `feat(notes): count the archived notes`) are still on the branch at the end, as git output the run produced shows: the run did not reset, rebase away, revert or rebuild them. The run's resume line or Run section lists both with their `Behaviour:` lines, ticked against the first two lines of the re-derived behaviours list, and the build loop continued at the third behaviour, the second Archive on the same note."
---
The resumed run keeps both commits that still match and continues at the first behaviour without one.
