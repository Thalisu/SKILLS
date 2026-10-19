---
type: llm
criteria: "The run forked `do-pr-fixer` for the red check `greet` once, and exactly one fix commit reached the bare remote `.fake/remote.git`, by fast-forward from the commit in `.fake/red.sha`, changing `src/greet.sh` (and possibly adding a test). After that push the run called the watch again with the pull request alone, which read `greet` red again, and the run then stopped: it forked no second `do-pr-fixer` for `greet`, started no next round, and pushed nothing more, so `add-greet` at the remote holds that one fix commit and nothing above it. No command the run made pushed with `--force`, `-f` or a `+` refspec, merged into `add-greet`, or pushed to any other branch. The developer's checkout is as the run found it: on `add-greet`, its HEAD still the commit in `.fake/red.sha`, `NOTES.md` still untracked with its one line."
---
A check whose pushed fix comes back red stops the run after one push, with no second fixer and no next round.
