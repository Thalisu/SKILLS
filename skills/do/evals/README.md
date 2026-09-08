# Eval cases

Prepared for `claude plugin eval` (`<case>/case.yaml` + `prompt.md` + `graders/*.md`, the layout its
`--help` describes). The `case.yaml` keys and the grader types (`llm`, `regex`, `tool_used`,
`file_exists`) follow the runner's help text and may need adjusting once it runs here.

`do` is user-invoked, so every prompt types the skill; there is no trigger case. Every case here
ends at a door: the request fits no Playbook, so the run is one message, and the cases inspect
that message and the tree. Every case carries the same two graders, the first line reading
`Playbook: none` and nothing written, plus one grader for its door.

Every fixture is synthetic: a small typed notes module, a tracker file where the case needs one,
a spec in the format `spec` writes with its `Journey:` line under the title, the journey beside
it where that line names one, and, where the case needs them, two Tickets under `issues/` in the
Ticket format.

| case | checks |
|---|---|
| `empty-asks-for-task` | no argument: one message asking for the task, no ticket picked from the fixture, nothing written |
| `feature-goes-to-discuss` | a feature with no Ticket: one message naming `/discuss`, nothing built, no Playbook matched |
| `question-goes-to-how` | a "how does X work" question: one message naming `/how` (or `/teach`), the question left unanswered |
| `sketch-goes-to-prototype` | a request to try a layout: one message naming `/prototype`, no HTML or variant written |
| `spec-path-goes-to-tickets` | a Spec's path whose `Journey:` line names a journey that exists: one line saying a Spec fits no Playbook, with `/tickets` as the command, no tickets cut |
| `spec-required-goes-to-journey` | a Spec's path whose `Journey:` line reads `required` with no journey beside it: the same line with `/journey` named first, no journey written |
| `missing-path-says-so` | a path that does not exist, with two neighbouring Tickets on disk: one line saying so, no neighbour opened in its place |
| `issue-number-without-tracker-file` | `#2` with no tracker file and a `02-` Ticket file on disk as bait: one message asking for the Ticket's path, the number never matched against the files |
| `issue-unopenable-says-so` | `#7` with a tracker file naming GitHub and `gh`, in a fixture with no remote: one line saying the issue could not be opened, nothing invented |

A Ticket path that matches `ticket` has no case here: with no Playbook reference installed the
router answers `Playbook: none` and names the missing reference, and the Playbook's own cases
arrive with the Playbook.

## Running

Run from the skill directory, granting the tools the cases need and opting in to their scaffold
scripts:

```
claude plugin eval . --scaffold --allow-tools Bash Read Edit Write
```

The runner is in early access. A first-party Claude Code install enables it by itself after
`claude update` and a fresh session; a client that cannot fetch feature flags (Bedrock, Vertex, a
custom base URL, or non-essential traffic disabled) needs the enablement variable Anthropic hands
out at onboarding, and there is no settings flag for it. Until it is enabled the command prints
`` `plugin eval` is currently in early access `` and exits 1. Every scaffold here was run by hand in
a throwaway directory and commits its fixture; the cases themselves were authored against the
runner's help text.

## Adding a Playbook

Adding a Playbook is three edits and nothing else: one reference file under `references/`, with
the door checks, the steps with their done conditions, and the links to the shared references;
one router line in `SKILL.md`, the condition that matches the Playbook, placed above any broader
condition it could shadow, with the reference linked under Links; and one case here, a prompt
that matches the Playbook and graders for the tree, the commits and the reply. The skill file
grows by one line.
