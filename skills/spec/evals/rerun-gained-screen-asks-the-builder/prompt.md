/spec

The spec of this feature is already written, at `.scratch/20260901-orders-export/spec.md`. One decision was added since, so this is a rerun on the same feature.

Closing summary of the discuss session on the orders export:

Decisions
- Nightly export (unchanged): a nightly job writes each Customer's orders of the day to the Customer's storage bucket as a CSV file.
- Export on demand (new in this session, experience-first): an export button on the existing orders list downloads the visible rows as a CSV file, with the filters applied as they are on screen.
- Columns (boundary-discipline): both exports carry the glossary's column names, not the database names, and dates in the customer's locale.

Defaults taken
- An empty list, or a day with no orders, exports a file with the header row only.
- Seams: the tests drive the export job and the export handler of the order module with an in-memory list of orders and a fake storage; no new seam.

Deferrals
- Scheduled exports by email: reopens when a Customer asks for them.

Files written: none.
Next step: /spec.
