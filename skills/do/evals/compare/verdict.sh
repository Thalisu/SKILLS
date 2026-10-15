#!/usr/bin/env bash
# usage: verdict.sh < <run lines of both shapes>
# Reads the run lines compare.sh prints for the Opus-only shape (`opus`) and the Implementer shape
# (`implementer`), in any order, and decides whether the Implementer shape ships: it passes only
# when it raises no more Act on Findings, adds no unexpected stopped or fork return, and costs
# strictly less in total. Pure: it reads stdin and nothing else.
# Exit 0 pass, 1 fail.
set -uo pipefail

awk '
  {
    for (i = 2; i <= NF; i++) {
      split($i, kv, "=")
      field[kv[1]] = kv[2]
    }
    s = field["shape"]
    cost[s] += field["cost_usd"]
    act_on[s] += field["act_on"]
    unexpected[s] += field["unexpected_stopped"] + field["unexpected_fork"] + field["unreadable"]
  }
  END {
    failed = 0
    if (unexpected["implementer"] > unexpected["opus"]) failed = 1
    if (act_on["implementer"] > act_on["opus"]) failed = 1
    if (cost["implementer"] >= cost["opus"]) failed = 1
    if (failed) { print "verdict=fail"; exit 1 }
    print "verdict=pass"
  }
'
