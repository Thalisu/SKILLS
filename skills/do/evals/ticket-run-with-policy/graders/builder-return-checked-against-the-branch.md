---
type: llm
criteria: "The session checked the Builder's return where it crossed instead of taking it on trust: it read the first line as the verdict, confirmed every `behaviour:` line carries a commit, then ran `scripts/resume-state.sh` once against the Ticket's path and matched that script's `commit=` and `behaviour=` pairs against the returned `behaviour:` lines, one for one, with `uncommitted=` empty on a `built`. The check ran before the gate and before the review. The run did not re-derive the behaviours list from the commits in place of the check, and did not skip the check because the return looked well formed."
---
The Builder's return is checked against the branch by `resume-state.sh`, not taken on trust.
