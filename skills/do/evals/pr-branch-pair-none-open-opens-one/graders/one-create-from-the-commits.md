---
type: llm
criteria: "The run ran `gh pr create` exactly once (one `pr create` call in the Bash commands it ran, and one `pr create` line in `.fake/gh.log`, the fake GitHub CLI's call log, if the run or its transcript shows it), naming head `dev` and base `prod` explicitly (`--head dev` and `--base prod`), with its title and body taken from the commits between `prod` and `dev`: either `--fill`, or a title and body written from the one commit `feat: archive a note` and its body line about an archived note. It never ran `git push` and never ran `gh pr merge`."
---
With none open for the pair, exactly one pull request is opened from `dev` into `prod`, titled and described from the commits, and nothing is pushed.
