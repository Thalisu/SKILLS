#!/usr/bin/env bash
# held-ruling-on-no-doc.sh: docs/do.md tells a developer who answered no at the close of a run on a
# tracker-issue Ticket where the held, unposted Ruling is, so they can carry it to the issues by
# hand. The contract (mechanics.md's close, forks.md, reply.md's Rulings) puts it in the Reply's
# Pending debt on every run and in the Run report only under `--auto`, since without `--auto` no
# Run report is written: a page sending them to the Run report alone points at a file that may not
# exist, and the Ruling is lost.
# Run: bash skills/do/tests/held-ruling-on-no-doc.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
do_doc="$here/../../../docs/do.md"
fails=0

echo "# docs/do.md: on a no, the held Ruling is in Pending debt, and in the Run report only under --auto"
bullet="$(bullets_opening_on "$do_doc" "When the Spec and the Ticket are issues on your tracker")"
on_no=""
for opener in "On a no" "on a no" "If you answer no" "you answer no" "answered no"; do
  case "$bullet" in *"$opener"*)
    on_no="$opener${bullet#*"$opener"}"
    break
    ;;
  esac
done
expect "the tracker-issue bullet says what a no at the close does" test -n "$on_no"
# shellcheck disable=SC2034 # lib.sh's carries reads $flat
flat="$on_no"
carries "on a no the page points the developer at the Reply's Pending debt" "Pending debt"
run_report_sentences="$(sed 's/\. /.\n/g' <<<"$on_no" | grep -F 'Run report')"
expect "on a no the page names the Run report only as an --auto place, never unqualified" \
  test -z "$(grep -vF -- '--auto' <<<"$run_report_sentences")"

[ "$fails" -eq 0 ] && exit 0
exit 1
