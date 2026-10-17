---
type: regex
pattern: '(?i)\bbuild repository\b'
match: contains
target: last_message
---
The approval message is the one the developer answers, so the field is in it under the name the
chain uses for it. Read by the script on the message itself, since a judge can take a service named
in a ticket's title for the field.
