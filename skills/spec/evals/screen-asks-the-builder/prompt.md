/spec

Closing summary of the discuss session on the orders export:

Decisions
- Export (experience-first): an export button on the existing orders list downloads the visible rows as a CSV file, with the filters applied as they are on screen.
- Columns (boundary-discipline): the CSV carries the glossary's column names, not the database names, and dates in the customer's locale.

Defaults taken
- An empty list exports a file with the header row only.
- Seams: the tests drive the export handler of the order module with an in-memory list of orders; no new seam.

Deferrals
- Scheduled exports by email: reopens when a Customer asks for them.

Files written: none.
Next step: /spec.
