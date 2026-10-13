---
type: regex
pattern: '^\W*Push:\W*git push\b.*\bmain\W*$'
match: contains
target: last_message
---
The Reply's last line is another repository's command, so the push of what landed here, `main` of
`billing-service`, is named on a line of its own.
