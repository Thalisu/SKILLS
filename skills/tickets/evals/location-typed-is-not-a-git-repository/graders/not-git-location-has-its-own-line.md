---
type: regex
pattern: '(?i)^(?=.*notifications-service).*(not an? (git )?(repository|repo|checkout|clone|work(ing)? ?tree)|n.t an? (git )?(repository|repo|checkout|clone|work(ing)? ?tree)|no \.git|not (under|tracked by|in|initiali[sz]ed (as|with)) git|without (a )?\.?git|no git (repository|repo|metadata|directory|folder))'
match: contains
target: last_message
---
The close has a line that names the notifications service's location and says, on that same line,
that what is there is not a git repository. The wording is the run's own, so the pattern accepts
the phrasings a line can say "not a git repository" in, as the same grader of `spec` does; the
judge reads the reason itself in `not-git-location-warned-and-nothing-more`.
