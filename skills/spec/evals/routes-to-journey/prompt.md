/spec

Closing summary of the discuss session on the returns page:

Decisions
- Returns page (experience-first): a new route lists every return of the signed-in Customer with a status filter; from the list the Customer opens a return; from a fulfilled Order the Customer starts one. Today a return is requested by email.
- Return states (model-the-domain): requested, approved, refused, refunded, as a state machine in the order module with one transition per action; no booleans.
- Refund amount (boundary-discipline): computed on the server from the order lines, never sent by the client.

Defaults taken
- The empty list shows one line of text and a link to the orders page.
- Seams: the tests drive the HTTP handlers of the order module, the highest existing seam; no new seam.

Deferrals
- Partial returns (a subset of lines): reopens when a Customer asks for one.

Files written: CONTEXT.md (Return, Refund), docs/adr/0001-return-state-machine.md.
Next step: /spec.
