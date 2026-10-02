---
type: llm
criteria: "The session read the pasted summary as the plan of the nightly purge and treated the trailing --auto as a flag of the command, never as part of the plan: the spec file under .scratch/ does not contain the token --auto, describes no 'auto' feature or automatic mode of the purge, and its folder's slug carries no 'auto'. The session never asked the user what --auto means, never told the user the token was unknown, and did not send the user to /discuss. A closing summary that says the run was under --auto, or names the flag in its last line, passes: the flag is the mode of the run, and only its reading as part of the plan fails."
---
The `--auto` token typed after the summary is dropped, and the rest is read as it would be without
the flag.
