---
type: llm
criteria: "The run's last message is a Reply opening `Playbook: pr`. Its For whom lists the round with `greet`, its fixer `do-pr-fixer` and its branch, the fixer's return line and the commit pushed to `add-greet`, then the verdict the watch read after the push, and a line saying `greet` is red again after that push. It carries exactly one `Yours:` line, of class `direction`, which names the check `greet`, the commit pushed for it (a short or full sha) and what the fixer ruled out, quoted off its return line (the local command that reproduced the failure, such as `bash tests/greet.sh`), and offers to revert that commit or fix the check by hand. No `Yours:` line is of class `outward`, and the `Yours:` line offers no push."
---
The stop names the check back red, the pushed commit and the fixer's reproduction command on one `Yours: direction:` line.
