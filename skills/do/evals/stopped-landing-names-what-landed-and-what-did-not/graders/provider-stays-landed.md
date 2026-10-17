---
type: file_contains
path: "../billing-service/src/invoice.js"
pattern: 'function hold\('
---
The main checkout of `billing-service` sits on `main`, which held Ticket 01's work before the run:
a stop in `orders-service` undoes nothing in the repository that already landed.
