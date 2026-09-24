---
type: llm
criteria: "After the silent Fixer, the run still went through the rest of the fix: the `## Fix run` section carries Finding 3's line reading `fixed <sha>, verified`, one `- wave <k>:` line for each of the two Waves, a `diff tests:` line, a `gate fixer:` line and a `gate:` line, and it ends in a line reading `not landed:` whose reason is a Finding not fixed, never `a Fixer did not return`. The export-notes branch still points at the commit it held before the run: nothing landed on it."
---
The run goes on through the checks and the append after a silent Fixer, and lands nothing while its Finding is not fixed.
