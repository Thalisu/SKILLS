---
type: llm
criteria: "The first line of the run's final message, the text after FINAL MESSAGE, reads `Playbook: pr`, with nothing before it, and never `Playbook: integrate` or `Playbook: none`. The run created no file, edited no file, created no worktree, made no git commit and moved no branch: `dev` and `prod` point where the scaffold left them, `prod` still lacking the `feat: archive a note` commit, and the checkout is still on `dev`. Its one `gh` attempt answered not logged in, and the run opened no pull request (no `gh pr create` succeeded)."
---
Words asking for a pull request route to `pr` on the first line and never integrate the pair.
