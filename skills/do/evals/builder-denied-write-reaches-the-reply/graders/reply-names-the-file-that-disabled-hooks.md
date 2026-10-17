---
type: regex
pattern: "disabled_by=\\S*\\.claude/settings\\.json"
match: contains
target: last_message
---
The Reply names the settings file that turned hooks off, the `disabled_by=` value the probe printed, so the developer can see which file removed the pattern guard.
