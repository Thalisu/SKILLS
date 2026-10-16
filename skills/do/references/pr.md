# Playbook: pr

The developer types `/do` with a pull request: its URL, in whatever words sit around it, or words
naming a pull request with its number, a request to fix its CI included. The run
follows that one pull request, and the developer reads it afterwards, through the Reply.

## The message

The run is one message, written by [reply.md](reply.md). It opens with `Playbook: pr` as plain text
on its first line, so a request the router misread shows at once, before anything else is read.
