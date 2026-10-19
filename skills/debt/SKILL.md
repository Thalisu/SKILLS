---
name: debt
description: "Gather a feature's Pending debt (its Debt files and the Review Findings still open) and judge it into a Debt review beside the Spec"
argument-hint: "<slug>"
---

# Debt

Settle a feature's Pending debt: gather the Debt files and the Review Findings still open, then
judge them. This file holds the first step, the door.

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
| exit 0 | Print the `line=` value (`Judging <n> debt items of <folder>`) as the status line, then hand every `item=` record to the judgment step. The judgment step is not built yet, so until it lands the run ends at the status line. |

<arguments>
$ARGUMENTS
</arguments>
