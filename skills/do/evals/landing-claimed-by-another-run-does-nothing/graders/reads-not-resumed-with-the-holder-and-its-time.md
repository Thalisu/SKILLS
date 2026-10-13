---
type: regex
pattern: 'Final integration:\W*not resumed, its claim is held by\W*\S*02-show-the-hold-on-the-order-page\.md\W* since\W*2026-10-13T09:41:07Z'
match: contains
target: last_message
---
A run that meets a claim another run holds on its repository gives the line such a run gave before
this feature, word for word: not resumed, the claim held by the Ticket of the run that holds it,
since the time that run claimed, both copied off `final-claim.sh`.
