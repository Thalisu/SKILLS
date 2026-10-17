---
type: regex
pattern: '(?i)^(?!.*notification-service)(?=.*billing-service).*(not exist|n.t exist|nothing (exists|is|sits|lives|was found)? ?(there|at|on|in|under)\b|missing|not found|no such|not present|absent|not there|no (directory|folder|path|file|clone|checkout))'
match: contains
target: last_message
---
The close has a line that names the billing service's location, says nothing exists there, and
does not name the notification service's location: one line for this location, never a sentence
merged with the other one's. The wording is the run's own, so the pattern accepts the phrasings a
line can say "nothing exists there" in; the judge reads the reason itself in
`each-bad-location-gets-its-reason`.
