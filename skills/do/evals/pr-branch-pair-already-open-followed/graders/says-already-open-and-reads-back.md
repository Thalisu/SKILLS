---
type: llm
criteria: "The run's last message is the Reply: `Playbook: pr` on its first line, a `Plan:` line reading back #7, `dev` into `prod` (head `dev`, base `prod`, never `prod` into `dev`), and it says pull request #7 was already open for the pair rather than opened by this run. It then reads as a green pull request does: every check green (two checks), mergeable, no `Yours:` line, and a last line naming `gh pr merge 7`."
---
A pull request already open for the pair is read back head into base, said to be already open, and followed to green.
