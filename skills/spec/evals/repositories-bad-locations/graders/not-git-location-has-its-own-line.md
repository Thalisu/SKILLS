---
type: regex
pattern: '(?i)^(?!.*billing-service)(?=.*notification-service).*(not an? (git )?(repository|repo|checkout|clone|work(ing)? ?tree)|n.t an? (git )?(repository|repo|checkout|clone|work(ing)? ?tree)|no \.git|not (under|tracked by|in|initiali[sz]ed (as|with)) git|without (a )?\.?git|no git (repository|repo|metadata|directory|folder))'
match: contains
target: last_message
---
The close has a line that names the notification service's location, says what is there is not a
git repository, and does not name the billing service's location. The wording is the run's own, so
the pattern accepts the phrasings a line can say "not a git repository" in; the judge reads the
reason itself in `each-bad-location-gets-its-reason`.
