#!/usr/bin/env bash
# Scenario iv: "where is the billing module?" is a location question, not an existence
# batch. Green: no discover call, the reply points at src/billing.
set -euo pipefail
fixture="$(cd "$(dirname "$0")/../../fixture" && pwd -P)"
cp -R "$fixture/." "$1/"
