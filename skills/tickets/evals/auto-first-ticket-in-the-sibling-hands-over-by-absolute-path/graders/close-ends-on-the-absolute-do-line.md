---
type: llm
criteria: "Judge this on the run's final message only, the text after FINAL MESSAGE. The session runs in the Home repository of the feature, whose folder is the fixture's root; the ticket numbered 01 that the run wrote under .scratch/show-refund-on-order/issues/ of that root is built in another repository, 'billing-service', a sibling folder. Pass only when the last non-blank line of the final message is the command `/do --auto` followed by the absolute path of that ticket file numbered 01, on its own or with only formatting around it (a code span, a bullet, or the closing fence of a code block whose only content is that line). The path is absolute only when it starts with `/` and reaches the file through the Home repository's folder, ending in /.scratch/show-refund-on-order/issues/01-<something>.md. Any of these fails: a path that starts with .scratch/ or ./ or ../ or ~, a path that runs through a folder named billing-service, a last line that names /do without --auto, names ticket 02, names another command, carries a cd or any other text in front of the command, or a last non-blank line that is anything else (a sentence, a note, a second command)."
---
The first Ticket of the frontier is built in a repository the session is not in, so the line the
developer pastes is run from that other repository's session, where the Home repository's relative
paths resolve to nothing: the close ends on `/do --auto` with the Ticket's absolute location in the
Home repository, and on nothing after it.
