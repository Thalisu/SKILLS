---
type: file_contains
path: "../orders-service/src/page.js"
pattern: '^\s*return `Order \$\{order\.id\}: \$\{order\.status\}`;$'
---
The main checkout of `orders-service` still holds the page as its `main` has it. The line is
rewritten by the commit on its Spec branch, so it is gone from that working tree once anything
landed that branch there.
