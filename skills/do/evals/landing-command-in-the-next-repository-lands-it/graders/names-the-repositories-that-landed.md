---
type: regex
pattern: '^\W*Landed:\W*ledger-service\W+billing-service\W*$'
match: contains
target: last_message
---
The Reply names the repositories that landed on a line of its own, in the order the blocking edges
give: `ledger-service`, which had landed before this session, then `billing-service`, the one this
run landed, and no other.
