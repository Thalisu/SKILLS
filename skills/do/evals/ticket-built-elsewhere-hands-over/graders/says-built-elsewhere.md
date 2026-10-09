---
type: llm
criteria: "Judge this on the run's final message only, the text after FINAL MESSAGE. The session runs in orders-service, and Ticket 02 is built in billing-service, a sibling folder whose absolute location starts with `/` and ends in /billing-service. Pass only when one line of the final message, before its last non-blank line, does all of these together (one sentence wrapped over two lines counts as one line): it says Ticket 02 is built in billing-service; it gives billing-service's absolute location; it says the Ticket is not built here, in this session or in this repository (or equivalent wording); and it says nothing was written (or nothing was claimed, or the Ticket was left untouched). It fails when the location is missing or relative, when the line names orders-service as where the Ticket is built, or when the run says it claimed, started or built the Ticket."
---
The stop says where the Ticket is built and that this session left it untouched.
