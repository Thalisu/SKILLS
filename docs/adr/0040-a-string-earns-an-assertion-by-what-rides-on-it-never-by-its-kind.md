# A string earns an assertion by what rides on it, never by its kind

Testing Policy 2.6 listed kinds of text that never earn a test (a heading, a listing, a phrase in
prose) and ordered a test pinning one deleted. The list was calibrated on this repository, whose
artifacts are prose and whose pruned suites pinned markdown, and read literally in a product
repository it deletes contracts: a message is the toast a user reads to act, a guard's message text
can be what routes a denial to a 403, and the same page title is structure in one test and the proof
of an access check in another. Version 2.7 replaces the list with the criterion 2.6 already applied
to every other result: a string earns an assertion when a caller relies on it and a wrong or missing
one costs something (a message read to act, a text that tells two states apart, an accessible name,
a line a program parses); a string present only as structure earns none, whatever its kind.

## Considered options

- Keep the kind list and add exceptions for messages and state labels: every exception is one more
  kind, and the same title still lands on both sides of it.

## Consequences

The criterion needs a reader's judgement where the list needed none, which is why ADR 0042 puts it
at the dispatch, where the caller must name the cost.
