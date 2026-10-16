---
type: regex
pattern: "Yours: direction: build \\(ubuntu-latest, 3\\.11\\), deploy; re-run or unblock the runner, then /do the pull request again"
match: contains
target: last_message
---
Checks pending with nothing changing for about 60 minutes stop the run on the exact `Yours: direction:` line, naming the two pending checks in the order the watch printed them.
