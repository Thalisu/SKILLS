---
type: regex
target: last_message
match: contains
pattern: '/do --auto \S*/01-[^/\s]*\.md'
---
With no Setup ticket at the head of the frontier the flag stays on the next command: the final message carries `/do --auto` on the ticket file numbered 01, read by the script on the message.
