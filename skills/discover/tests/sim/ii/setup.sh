#!/usr/bin/env bash
# Scenario ii — a spec names five billing symbols; the session starts in src/billing (the
# cwd file). Green: exactly one discover batch with >=4 items, every reported path valid
# from the repo toplevel, one Discovery: audit line in the reply.
set -euo pipefail
fixture="$(cd "$(dirname "$0")/../../fixture" && pwd -P)"
cp -R "$fixture/." "$1/"
