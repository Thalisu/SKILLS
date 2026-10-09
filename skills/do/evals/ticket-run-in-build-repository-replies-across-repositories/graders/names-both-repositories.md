---
type: regex
pattern: '^\W*Repositories: built in billing-service \(/\S+\), artifacts in /\S*/orders-service\W*$'
match: contains
target: last_message
---
The Reply carries one line naming the Build repository the run built in, by its name and the
location of its main checkout, and the Home repository its artifacts are in, read by the script
since both locations are machine-dependent.
