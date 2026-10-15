---
type: llm
criteria: "Judge this on the run's final message and on the TOOL CALL lines of the transcript. The session runs in billing-service and builds Ticket 02, whose file lives in the sibling folder orders-service. Pass only when all of these hold. First, the final message is the five-part Reply of a finished ticket run and not a refusal or a blocked stop: it opens with `Playbook: ticket`, then a `Plan:` line, then `## For whom`, `## Pending debt` and `## Next step`, and carries no line starting `Yours:`. Second, it carries no `## Run` section, no `Repositories:` line and no `landed at` line, since those belong to the Run report, which a run without `--auto` does not write. Third, the transcript shows `land-spec.sh` printing a line reading `landed at <sha> on spec/hold-disputed-invoice`, with a commit hash in the place of <sha>. Any of these fails: a `## Run` section in the final message, a `not landed` line from `land-spec.sh`, a `Yours:` line."
---
A run in a Build repository other than the Home repository ends on the Reply a ticket run of a
Spec ends on today, with the line naming the two repositories opening its landing lines.
