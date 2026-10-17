---
type: regex
pattern: 'Final integration:\W*stopped:.*not landed: Finding 1 not fixed or not verified'
match: contains
target: last_message
---
The Reply of a landing that stopped reads `Final integration: stopped:` with the reason, here the
landing line the red Review returned, quoted on that line.
