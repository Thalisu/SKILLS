# Playbook: pr

The developer types `/do` with a pull request: its URL, in whatever words sit around it, or words
naming a pull request with its number, a request to fix its CI included. The run
follows that one pull request, and the developer reads it afterwards, through the Reply.

## The message

The run is one message, written by [reply.md](reply.md). It opens with `Playbook: pr` as plain text
on its first line, so a request the router misread shows at once, before anything else is read.

## Steps

```
pr:
1. pull request: its URL or its number, taken from the request as written
2. read-back: #<n>, its head into its base, off the GitHub CLI's answer
3. reply: by the reply reference
```

### 1. Pull request

The run takes the pull request from the request as the developer wrote it: the URL, or the number
the words name. It passes that to the GitHub CLI as it read it and never a pull request it guessed,
since a guessed number that exists answers like the right one.

Done when the run holds the URL or the number.

### 2. Read-back

The read-back line, off the GitHub CLI's answer for that pull request and never the session's
wording: `gh pr view <the URL or the number> --json number,headRefName,baseRefName`, read as
`#<n>`, `<head>` into `<base>`, from its `number`, `headRefName` and `baseRefName`. It is the
Reply's `Plan:` line, so a request the session misread shows on the Reply's first lines, as the
wrong pull request or the wrong branches, before the developer reads anything else.

Done when the line is recorded for the `Plan:` line.

### 3. Reply

The Reply, by [reply.md](reply.md), its `Plan:` line the read-back of step 2.
