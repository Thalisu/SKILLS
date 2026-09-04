/spec

Closing summary of the discuss session on order notes:

Decisions
- Order note (model-the-domain): a Customer can attach one free-text note to a placed Order, edited until the order is fulfilled; the note is a field on Order, not a separate entity.
- Length (boundary-discipline): the note is limited to five hundred characters, checked where the request enters.

Defaults taken
- An empty note is stored as no note, not as an empty string.

Deferrals
- Notes on fulfilled orders: reopens if support asks for them.

Files written: CONTEXT.md (Order note).
Next step: /spec.
