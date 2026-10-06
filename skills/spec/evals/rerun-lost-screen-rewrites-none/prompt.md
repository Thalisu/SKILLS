/spec

The spec of this feature is already written, at `.scratch/20260901-orders-export/spec.md`. The plan changed since, so this is a rerun on the same feature.

Closing summary of the discuss session on the orders export:

Decisions
- Export (experience-first): the export button on the orders list is dropped. A nightly job writes each Customer's orders of the day to the Customer's storage bucket as a CSV file, and nobody opens a screen for it.
- Columns (boundary-discipline): the CSV carries the glossary's column names, not the database names, and dates in the customer's locale.

Defaults taken
- A day with no orders writes a file with the header row only.
- Seams: the tests drive the export job of the order module with an in-memory list of orders and a fake storage; no new seam.

Deferrals
- Exports on demand from the orders list: reopens when a Customer asks for them.

Files written: none.
Next step: /spec.
