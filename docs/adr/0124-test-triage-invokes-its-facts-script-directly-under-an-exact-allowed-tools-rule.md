# test-triage invokes its facts script directly under an exact allowed-tools rule

The skill injects its facts block with a `!` command, and an injected command never prompts. Checked
against a throwaway project with six skill variants, in default and bypass permission modes: in
default mode the invocation aborts silently (zero turns, no error text in `--output-format json`)
unless a permission rule allows the command, and a typical global allow list does not cover it.
`${CLAUDE_SKILL_DIR}` expands inside the command to the skill directory whatever the working
directory is, and `$PWD` is the project. The rule that matches is exactly
`allowed-tools: Bash(${CLAUDE_SKILL_DIR}/scripts/context.sh)` with the script invoked directly,
quoted or unquoted. Prefixing the command with `bash ` and mirroring that in the rule did not match,
and `Bash(bash *)` matches but is far broader than needed. With
`--permission-mode bypassPermissions` nothing is required.
