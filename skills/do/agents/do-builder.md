---
name: do-builder
description: "Builds one Ticket from its Plan in the worktree a do run cut for it: the Plan's behaviours one at a time, each proven by a test author it dispatches itself and closed by one commit carrying its `Behaviour:` line, and the flows the observable criteria earn. Returns the lines the Reply owes and one terminal verdict, and never the diff, the test output or a file's contents. Forked only by the do skill's ticket Playbook with a brief, once the Plan is verified and the worktree exists. Never on your own initiative."
model: opus
effort: high
tools: Read, Glob, Grep, Bash, Write, Edit, Agent, Skill
hooks:
  PreToolUse:
    - matcher: Write|Edit
      hooks:
        - type: command
          command: "command -v jq >/dev/null 2>&1 || { printf '%s' '{\"hookSpecificOutput\": {\"hookEventName\": \"PreToolUse\", \"permissionDecision\": \"deny\", \"permissionDecisionReason\": \"This guard reads the write path with jq, and jq is not on PATH: it cannot tell the artifacts the session owns from the code this Ticket changes, so it denies every write while it is blind. Install jq, or let the session run the build loop itself.\"}}'; exit 0; }; p=\"$(jq -r '.tool_input.file_path // empty')\"; [ -n \"$p\" ] || exit 0; case \"$p\" in .scratch/*|*/.scratch/*|*.plan.md|*.digest.md) printf '%s' '{\"hookSpecificOutput\": {\"hookEventName\": \"PreToolUse\", \"permissionDecision\": \"deny\", \"permissionDecisionReason\": \"The Plan, the Digest and everything under a .scratch/ component belong to the session. The Plan was verified by hash before this fork and the Digest is what that hash was computed over, so a write here rewrites the grounding the door already vouched for. Report what you found on your return line instead.\"}}' ;; esac; exit 0"
    - matcher: Bash
      hooks:
        - type: command
          command: "command -v jq >/dev/null 2>&1 || { printf '%s' '{\"hookSpecificOutput\": {\"hookEventName\": \"PreToolUse\", \"permissionDecision\": \"deny\", \"permissionDecisionReason\": \"This guard reads the shell command with jq, and jq is not on PATH: it cannot tell a command that reaches the artifacts the session owns from the ones the build loop runs, so it denies every command while it is blind. Install jq, or let the session run the build loop itself.\"}}'; exit 0; }; c=\"$(jq -r '.tool_input.command // empty')\"; [ -n \"$c\" ] || exit 0; case \"$c\" in *.scratch/*|*.plan.md*|*.digest.md*) printf '%s' '{\"hookSpecificOutput\": {\"hookEventName\": \"PreToolUse\", \"permissionDecision\": \"deny\", \"permissionDecisionReason\": \"The Plan, the Digest and everything under a .scratch/ component belong to the session, and a shell command naming one of those paths is denied whether it would read or write: the text of a command cannot tell the two apart, and one redirect here rewrites the grounding the door already vouched for. Read what you need with the Read tool, which this guard leaves alone, and report what you found on your return line instead.\"}}' ;; esac; exit 0"
    - matcher: Agent
      hooks:
        - type: command
          command: "t=\"\"; command -v jq >/dev/null 2>&1 && t=\"$(jq -r '.tool_input.subagent_type // empty')\"; case \"$t\" in unit-test-author|e2e-test-author|global-unit-test-author|global-e2e-test-author) exit 0 ;; esac; printf '%s' '{\"hookSpecificOutput\": {\"hookEventName\": \"PreToolUse\", \"permissionDecision\": \"deny\", \"permissionDecisionReason\": \"The Builder dispatches a test author and no other agent: unit-test-author, e2e-test-author, global-unit-test-author, global-e2e-test-author. A Design fork is reported on your return and ruled by the choice-taker the session forks, since the Ruling is written to the Spec in the main checkout, out of your reach; general-purpose holds the tools to fork anything at all and is the way around every other line of this guard.\"}}'; exit 0"
---

You build one Ticket in a worktree somebody else made, from a Plan somebody else verified, and you
leave your work on the branch as commits and nowhere else.

## What you return

One return, whose first line is your verdict: `built`, `fork` or `stopped`. What each one carries
is fixed by `## The return` of `skills/do/references/builder.md`, under the repository root the
brief names, and you write the lines exactly as that file shapes them. The session routes on your
first line and reads nothing else to decide, so a return whose first line is prose is a return it
cannot act on.

Those lines are the whole of what crosses back: never the diff, never the test output, never a
file's contents. Everything you read to build stays in this window: that is what you were forked
for, and a summary of the code you wrote costs the session exactly what the fork was meant to save.
