# CRUD grid

Read only when the stories create, edit or delete. It seeds the failure branches of a path: for
each operation the path performs, walk the conditions below from the actor's seat. A cell the
precedent settles is a default, named after the sibling page that settles it. A cell with no
precedent is a fork. A cell that does not apply to the path is skipped without comment. Every cell
ends in a state the actor can read: a line in the glossary's words, and where they are afterwards.

| Condition | list | view | create | edit | delete |
|---|---|---|---|---|---|
| empty | the empty state: one sentence in the glossary's words and the one action that fills it, never a blank table | does not apply | the blank form: which fields are required, visible before submit | does not apply | deleting the last item lands the actor on the list's empty state |
| loading | what holds the space (the previous list, a skeleton, a spinner) and the word that appears when it takes long | the same, with the way back | the submit control while saving: disabled, with a word, so a second press is impossible | the same as create | the row while deleting, so a second press is impossible |
| success | the list with the filter, sort and page the actor set | the item, with the way back | where the actor lands (the new item, or the list with it visible) and the line that confirms | the item with the change visible, and the line | the list without the item, and a line that says so |
| validation error | a filter with no match: "no X match", cleared in one action, never the empty state | does not apply | each field's error beside it, in the glossary's words, before submit when the field can be checked, the first one focused | the same as create | a delete the rules refuse (an item still in use): the reason, and what to do first |
| server error | a line saying the list could not load, and a retry, never a blank | the same, with the way back | the form kept with what the actor typed, the error in one line, retry on the same control | the same as create | the item still in the list, and one line saying the delete did not happen |
| forbidden | what the actor cannot see and who to ask, or the entry absent from the navigation | the same | the control absent, never present and failing | the fields read-only, with a word why | the control absent |
| concurrent edit | an item changed since load: the list refreshes on the next action, and a line names what changed when it matters | the item changed under the actor: a line and a reload, never a silent overwrite | a duplicate created meanwhile: the rule the spec sets, allowed or "already exists" with a link to it | the save meets a newer version: the actor sees both and picks, or is told to reload; never the last write winning in silence | the item already deleted: the list without it and a line, never an error |
| undo or retry | retry after a failed load, on the same control | the same | submit twice: one item, the second press a no-op; a retry after an error resends what the actor typed | save twice: one version | undo, when the spec allows it, in the line that confirmed the delete, for as long as the spec says; a second delete on the same item is a no-op |

The columns are the operations the stories name, the rows the conditions the actor can meet. A
path that lists and deletes walks two columns; a path that only views walks one.
