# The trivial door's escape

It is read by step 5 of [trivial.md](trivial.md), the door on the diff, when
`trivial-door.sh diff` exits other than 0, and by no other step or Playbook.

| Exit | Meaning | The run |
|---|---|---|
| 1 | `verdict=not-trivial`, `goes_to=<playbook>` | restores the touched files (`git checkout -- <files>`), commits nothing, and ends in one message quoting the script's lines and naming the Playbook: `refactoring` for a changed signature, a renamed, an extracted or an un-exported export; `discuss` for a new exported symbol or a new file; `bug-fix` for a test file the change had to touch |
| 2 | usage, or not a git repository | blocked; the reply quotes the error on the blocker's line, with `Yours: direction: fix what the error names, then type the request again` |
| 3 | `verdict=judgment` | the run reads the diff itself against the same three questions (a test file, a new exported symbol, a changed signature), stops as for exit 1 when one holds, and says in the Run report that the second check was its own judgment and not the script's |

The exit-1 stop is a refusal: it names the one way on and carries no `Yours:` line, per
[reply.md](reply.md).
