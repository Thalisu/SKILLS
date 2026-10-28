#!/usr/bin/env bash
# evidence-lines.sh: the Context and Forks evidence lines a ticket run's close writes under the
# Ticket's `## Evidence`, in the shapes `.agents/formats/ticket-format.md` `## Evidence` fixes,
# printed from the session's two readings of context-usage.sh. Run from anywhere.
#
#   evidence-lines.sh < <key=value lines>
#
# Reads key=value lines on stdin, unknown keys ignored:
#   grounded=<tokens>                 the ground reading's current
#   ground_reason=<text>              the ground reading's stderr, in its place when it exited non-zero
#   resumed=yes|no                    yes when the run recorded the resume line of resume.md
#   peak=<tokens> band=<band> forks=<n> fork_kinds=<kinds>   the close reading, as context-usage.sh prints it
#   close_reason=<text>              the close reading's stderr, in its place when it exited non-zero
# Prints the Context line, then the Forks line. A close_reason puts both lines at not measured with
# that reason, and no resumed label; a ground_reason alone puts the Context line at not measured.
# Exit codes: 0 both lines printed.
set -euo pipefail
declare -A in=()
while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in *=*) in["${line%%=*}"]="${line#*=}" ;; esac
done
if [ -n "${in[close_reason]+set}" ]; then
  printf 'Context: not measured, %s\nForks: not measured, %s\n' "${in[close_reason]}" "${in[close_reason]}"
  exit 0
fi
if [ -n "${in[ground_reason]+set}" ]; then
  printf 'Context: not measured, %s\n' "${in[ground_reason]}"
else
  printf 'Context: grounded %s, peak %s, %s\n' "${in[grounded]}" "${in[peak]}" "${in[band]}"
fi
suffix=""
[ "${in[resumed]:-}" = yes ] && suffix=", this session only (resumed run)"
if [ "${in[forks]}" = 0 ]; then
  echo "Forks: 0$suffix"
else
  printf 'Forks: %s (%s)%s\n' "${in[forks]}" "${in[fork_kinds]}" "$suffix"
fi
