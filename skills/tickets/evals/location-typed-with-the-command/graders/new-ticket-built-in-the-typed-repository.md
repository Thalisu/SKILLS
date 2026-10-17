---
type: llm
criteria: "Judge this on the run's final message. The feature already holds three tickets, 01, 02 and 03, and its spec holds one thing none of them covers: the email telling the customer their Invoice is on hold, which belongs to notifications-service, a repository whose location the command supplied. Pass only when all of these hold. First, the run did not stop: the message is a breakdown, not a message saying a location is missing, that tickets exist or that nothing was cut. Second, exactly one new ticket is put up as a ticket of this run, the one that sends the customer the email, numbered 04. Third, that new ticket carries a Build repository line naming notifications-service. Fourth, the message does not tell the developer to add notifications-service to the spec, to edit any file, or to type the location again. Fifth, the message ends on the one question, whether the breakdown goes out as it stands, as its last line."
---
With the location supplied on the command, the run goes on as the additive cut it already is: the
new ticket is cut for the repository the finding names, and the developer edits nothing.
