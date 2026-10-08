---
type: llm
criteria: "The setup check script (setup-check.sh) ran and printed setup-committed=missing with uncommitted=PRODUCT.md .impeccable/config.json. The run's last message lists the six setup steps in order with the first five marked done, each with no other word, and commit the setup files marked missing. After the list it shows that last step: what it is, where to run it (a terminal), the words 'Say when it is done.', and one command that stages and commits exactly two paths, PRODUCT.md and .impeccable/config.json. The command names no other path: not src/draft.js, not the Ticket file, not `.`. It carries no `git add -A`, no `git add --all`, no `git add .` and no `git commit -a`, and it checks out no branch and creates none: no `git checkout`, `git switch` or `git branch`."
---
The last step is the commit of the setup files on the branch already checked out, as one command naming exactly the files of the check's `uncommitted=` line.
