---
name: debt
description: "Gather a feature's Pending debt (its Debt files and the Review Findings still open) and judge it into a Debt review beside the Spec"
disable-model-invocation: true
argument-hint: "<slug>"
---

# Debt

Settle a feature's Pending debt: gather the Debt files and the Review Findings still open, then
judge them. This file holds two steps: the door, then the judgment.

The developer's argument sits at the end of this file, between the `<arguments>` tags: the feature
slug. `<skill-dir>` below is the directory this file sits in. The steps run in order, and each stop
they name ends the command there.

## 1. The door

Run the gather script on the slug exactly as the developer typed it, before anything else:

```sh
bash <skill-dir>/scripts/gather.sh <slug>
```

The session never parses a Debt file or a Review itself: gather.sh reads both. It relays the
`line=` value the script printed and decides on the script's exit code:

| What came back | What this session does |
|---|---|
| exit 3 | The slug names no feature folder. Print the `line=` value as the run's only line and stop: the run ends on that one line, forks no agent and writes nothing. |
| exit 1 | The feature owes no debt. Print the `line=` value as the run's only line and stop: the run ends on that one line, forks no agent and writes nothing. |
| exit 2 | Stop, printing the script's stderr line as the one line. |
| exit 0 | Print the `line=` value (`Judging <n> debt items of <folder>`) as the status line, then hand every `item=` record to step 2. |

## 2. The judgment

The judgment runs on the `item=` records the door handed over. The session forks the evaluators and
waits on their return files, and the script does the rest.

Make the run's directory first, and call it `<dir>` below:

```sh
mktemp -d "${TMPDIR:-/tmp}/debt.XXXX"
```

Make one Agent tool call per `item=` record, all in one message, each with
`subagent_type: debt-evaluator`, never a general-purpose agent. Each brief is exactly six keys, one
per line, `<k>` being the item's number among the records:

```
Item: <k>
Source: <the record's source=, byte for byte>
Text: <the record's text=>
Folder: <folder=>
Spec: <spec=>
Return file: <dir>/item-<k>.md
```

The Agent tool may hand back before the evaluators are done, since the harness runs subagents in the
background. The session never ends the turn on that handback. It runs the wait on every return file,
with the Bash tool's `timeout` set to `600000` ms:

```sh
bash <skill-dir>/../../.agents/scripts/returns.sh 240 <dir>/item-1.md ... <dir>/item-<n>.md
```

When it comes back with `missing=` lines, call it again over the `missing=` files only. Run three
windows and no more, then go on.

When the Agent tool is withheld, or does not list `debt-evaluator`, the session forks nothing and goes
straight to the compose call: every item then reads as not returned.

Compose the Debt review:

```sh
bash <skill-dir>/scripts/debt-review.sh <slug> <dir>
```

On exit 0 it prints `review=<path>` and `line=Written to <path>`. The session never reads a return
file itself and never places an item in a Bucket: the script does both.

Show the Debt review file's text, then the `line=` value (`Written to <location>`). Those are the
run's last lines.

<arguments>
$ARGUMENTS
</arguments>
