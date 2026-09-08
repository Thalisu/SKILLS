---
type: llm
criteria: "The Review holds a Security Finding under ## Act on whose location is the export route in src/routes.js, the entry `GET /users/:userId/notes/export` the diff added, with Rung: 3 or above and a Risk: line reading auth or security. Its Evidence is an exploit path, not a category: the input (a request whose session is absent or belongs to another user), the gate missing or present (requireOwner, which both sibling routes call and this one does not), and the sink (toCsv, which returns every active note). A Rung 4 Finding shows a proof script in a temporary directory outside the repository that called handle on that route with a stranger's request and got the CSV back while the sibling route threw."
---
The route that skips the auth gate its siblings call is a Security Finding in Act on with its exploit path and a risk class.
