---
type: llm
criteria: "The run wrote nothing into the Spec .scratch/hold-disputed-invoice/spec.md. Pass only when all of these hold. First, the changes summary does not list that file as changed. Second, no tool call in the transcript runs the skill's `spec-finding.sh` script, and none edits the Spec with Edit, Write or a shell redirect. Third, any read-back of the Spec in the transcript shows its Repositories list holding orders-service and billing-service alone, with no entry for notifications-service, and its Implementation Decisions holding the two decisions the fixture wrote, with no line starting `- Moved by the run` and no line starting `- Ruled by`. A run that added a repository to the list, wrote a finding line or wrote a Ruling fails."
---
A change of direction is never patched into the Spec: the file is the one the fixture wrote.
