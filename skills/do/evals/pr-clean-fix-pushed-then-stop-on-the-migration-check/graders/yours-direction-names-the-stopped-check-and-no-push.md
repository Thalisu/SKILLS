---
type: llm
criteria: "The run's last message is a Reply opening `Playbook: pr`. Its For whom lists the round: `sum` with its fixer and the commit pushed to `add-email`, `schema` with its fixer and a line saying its commit was not picked because `db/migrations/0002_add_email.sql` is a migration file, and the verdict the watch read after the push. It carries exactly one `Yours:` line, of class `direction`, naming the check `schema` and the file `db/migrations/0002_add_email.sql`. That `Yours:` line names no push at all: neither the push the run made of the `sum` fix nor any push offered to the developer. No `Yours:` line is of class `outward`."
---
After the clean fix is pushed and watched, the run stops on the migration check with one `Yours: direction:` line that names no push.
