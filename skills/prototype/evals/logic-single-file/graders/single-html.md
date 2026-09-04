---
type: llm
criteria: "Exactly one new file was created, its name contains 'prototype' and ends in .html, and it was written into a fresh directory outside the repository (under $TMPDIR or /tmp, made with mktemp), never into the tree. It is self-contained: no <script src>, no external stylesheet, no framework. The logic is in a script block that never touches the DOM, and the page has a state panel, free-play buttons and tabbed scenarios that include applying a coupon after checkout and stacking two coupons. The banner at the top states the question and that the file is throwaway. The repository tree is unchanged: src/cart.js is untouched, git status reports nothing, and no git commit was made."
---
One throwaway HTML file in a temp directory, nothing in the tree, nothing committed.
