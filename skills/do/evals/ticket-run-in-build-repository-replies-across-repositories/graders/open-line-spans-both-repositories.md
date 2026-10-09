---
type: regex
pattern: '^\W*Open:\W*03-show-the-dispute-on-the-order-page\W*\(ready-for-agent\),\W*04-show-the-hold-on-the-order-page\W*\(ready-for-agent\),\W*05-record-when-the-invoice-was-held\W*\(ready-for-agent\)\W*$'
match: contains
target: last_message
---
The Reply's `Open:` line names every Ticket of the feature still open with its status, the two
built in `orders-service` and the one built in `billing-service`, the repository the session runs
in: a line cut to one repository would hide the others.
