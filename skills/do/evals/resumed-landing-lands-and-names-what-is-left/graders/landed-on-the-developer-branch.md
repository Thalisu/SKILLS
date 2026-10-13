---
type: file_contains
path: "src/page.js"
pattern: 'invoice\.status === "held"'
---
The main checkout of `orders-service` sits on `main`, which held no `src/page.js` before the run:
the page, with the developer's fix, is in its working tree only once the resumed Final integration
landed the Spec branch on `main`.
