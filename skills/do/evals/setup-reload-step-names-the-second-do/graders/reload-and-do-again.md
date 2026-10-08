---
type: llm
criteria: "The run ran the setup check script (setup-check.sh), which printed impeccable-skill=done, and the session's own skill listing names no impeccable skill. The run's last message lists the six setup steps in order with install impeccable marked done and reload the coding tool marked missing. After the list it shows one step, reload the coding tool: it tells the developer to reload (quit and start again) the coding tool, and then to type `/do` on the Setup ticket again, quoting the command with the Ticket's path, 00-set-up-impeccable.md, and no --auto flag. The message closes on that `/do` line to type after the reload: it does not end on 'Say when it is done.' It shows no command for the init, design system, build path or commit steps, and the run did not invoke any impeccable skill."
---
At the reload step the developer is told to reload the coding tool and type the plain `/do` on the Setup ticket again.
