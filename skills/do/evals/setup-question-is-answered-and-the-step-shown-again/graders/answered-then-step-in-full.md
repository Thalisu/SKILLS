---
type: llm
criteria: "The developer asked what the build path step changes and whether it overwrites settings impeccable already wrote. The run's last message opens with `Playbook: setup` and answers that question in its own words: the step sets buildPath to code in .impeccable/config.json and keeps the keys already in that file. The run did not read the question as word that the step is done and did not skip the check: it ran the setup check script (setup-check.sh) in the same turn. After the answer, the same message lists the six setup steps marked done or missing and shows the current step, set the code-led build path, again in full: what it is, its exact command on a line of its own, where to run it (a terminal), and the words 'Say when it is done.' The run did not set the build path itself: .impeccable/config.json does not exist in the fixture."
---
A question gets its answer, the check runs anyway, and the current step is shown again in full in the same turn.
