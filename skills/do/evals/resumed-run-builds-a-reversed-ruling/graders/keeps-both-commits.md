---
type: llm
criteria: "The two commits the fixture left on do/archive-a-note (`feat(notes): archive a note out of the list` and `feat(notes): count the archived notes`) are still on the branch at the end, as git output the run produced shows: the run did not reset, rebase away, revert or rebuild them. The build loop continued at the third behaviour, the second Archive on the same note: the run's new commits come after these two and none of them rebuilds the first two behaviours."
---
The resumed run keeps both commits that still match and continues at the first behaviour without one.
