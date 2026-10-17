#!/usr/bin/env bash
# compare-readme.sh: the do evals README's `## Running` section is the one place the maintainer
# learns that the comparative eval is theirs to run (the build never runs it), how to read its exit,
# and that its figures go in the Ticket's `## Evidence`. Only that section answers: a mention
# elsewhere in the README does not.
# Run: bash skills/do/tests/compare-readme.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
readme="$here/../evals/README.md"
fails=0

flat="$(flat_section "$readme" "## Running")"
sentences="$(sed 's/\. /.\n/g' <<<"$flat")"

# A code and its meaning sit in one clause, in either order: `0 pass`, `0: pass`, `pass (0)`.
exit_means() { # $1 the exit code, $2 an ERE for its meaning: succeeds when $flat ties the two
  grep -qiE "\\b$1\\b[^0-9.;]{0,40}($2)|($2)[^0-9.;]{0,20}\\b$1\\b" <<<"$flat"
}

missing=""
grep -qF "compare/compare.sh" <<<"$flat" || missing="$missing; compare.sh"
for flag in "--runs N" "--model NAME" "--cases FOLDER"; do
  grep -qF -- "$flag" <<<"$flat" || missing="$missing; $flag"
done
exit_means 0 'pass' || missing="$missing; exit 0 pass"
exit_means 1 'fail' || missing="$missing; exit 1 fail"
exit_means 2 'usage' || missing="$missing; exit 2 usage"
grep -qiE "\\b2\\b[^0-9]{0,120}(could not be read|cannot be read|could not read|unreadable|no work folder)" <<<"$flat" ||
  missing="$missing; exit 2 a run that could not be read"
exit_means 3 'incomplete' || missing="$missing; exit 3 incomplete"
grep -qi 'maintainer' <<<"$flat" || missing="$missing; the maintainer runs it"
grep -i 'build' <<<"$sentences" | grep -qiE "\\b(never|not)\\b|n't\\b" || missing="$missing; the build never runs it"
grep -qF '## Evidence' <<<"$flat" || missing="$missing; ## Evidence"
grep -qF 'Ticket' <<<"$flat" || missing="$missing; the Ticket"
grep -qi 'figure' <<<"$flat" || missing="$missing; the figures"
grep -qiE '\bpin' <<<"$flat" || missing="$missing; a pin raise"

label="the Running section tells the maintainer to run compare.sh, what each exit means, and to record its figures in the Ticket's ## Evidence"
if [ -z "$missing" ]; then ok "$label"; else fail "$label (missing: ${missing#; })"; fi

exit "$((fails > 0))"
