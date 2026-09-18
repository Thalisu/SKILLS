# A contested hunk takes the Target side, and what it sets aside is reapplied after the integration

Every `contested` hunk is resolved by the door script to the **Target** side, and its **Incoming**
side is written whole to a **Loss ledger**, one entry per hunk id. Once the integration finishes, a
read-only agent judges each entry `reapply` or `drop` with its reason, the session applies every
`reapply` as its own commit on top, and the **Gate** runs whole after the last one. Nobody is asked
anything: the human answer ADR 0028 relied on stalled every run with no human reachable and cost a
round trip per hunk otherwise. The one judgment left to a model now produces commits a reviewer
reads, instead of an edit buried inside the replay. This supersedes the rule of ADR 0028 that a
contested hunk is the human's to answer. The class stays a script's verdict.

## Considered options

- An agent writing a merged hunk per conflict, favouring the Target: the ledger would record only
  what the agent noticed it dropped, and a line lost without the agent noticing would reach the
  branch with no trace anywhere.
- Keeping the developer's answer per hunk, with the agent only where no human is reachable: two
  resolution paths to keep in step, and the questions this change exists to remove.

## Consequences

ADR 0027 placed the rebase in the session because a contested hunk needed a human. That reason is
gone, but the placement stands, since the reapplied commits need a writer and the review never
edits code. `do-code-review`'s landing still resolves only the mechanical class and returns
`not landed: target moved` for the rest. `do` now answers that return in the same run: it runs its
integration once more and lands through `fix`, per ADR 0033, instead of stopping for a second
`/do`. A second move of the target stops the run. `contested.sh` loses its question mode, its
`no human` exit and the `both` and `stop` answers, so a `claude -p` run now finishes an integration
it used to abort.

ADR 0044 supersedes the rule above that a second move of the target stops the run: the
integration retries for as long as each attempt meets a new tip.
