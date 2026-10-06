#!/usr/bin/env bash
# setup-check.sh: the state of the impeccable setup in the project it is run in, one line per step.
# It is the one executable form of that reading, so every caller that needs to know whether the
# setup is there calls it instead of working the answer out. Run from anywhere inside the project,
# with no argument. It writes nothing.
#
# Exit codes: 2 the project could not be read: one line on stderr naming what could not be read,
# and nothing on stdout.
set -uo pipefail

die() { echo "$1" >&2; exit 2; }

git rev-parse --show-toplevel >/dev/null 2>&1 || die "not a git repository: $(pwd -P)"
