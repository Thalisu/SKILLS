---
type: regex
pattern: 'Final integration:\W*stopped again\W.*not landed: Finding 1 not fixed or not verified'
match: contains
target: last_message
---
A resumed landing that stops a second time says so from its first words, `Final integration:
stopped again`, with the reason of this stop quoted on that line.
