---
type: file_contains
path: "../billing-service/src/invoice.js"
pattern: 'function hold\('
---
The main checkout of `billing-service` sits on `main`, which held Ticket 01's work before the run
and holds it after: the resume in `orders-service` undoes nothing there.
