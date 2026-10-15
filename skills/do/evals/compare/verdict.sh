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
    check_unexpected = unexpected["implementer"] <= unexpected["opus"] ? "pass" : "fail"
    printf "check unexpected=%s implementer=%d opus=%d\n", check_unexpected, unexpected["implementer"], unexpected["opus"]
    if (check_unexpected == "fail") failed = 1
    check_act_on = act_on["implementer"] <= act_on["opus"] ? "pass" : "fail"
    printf "check act_on=%s implementer=%d opus=%d\n", check_act_on, act_on["implementer"], act_on["opus"]
    if (check_act_on == "fail") failed = 1
    # Compared in whole cents, as printed, so float noise in the sums cannot pass an equal cost.
    check_cost = sprintf("%.0f", cost["implementer"] * 100) + 0 < sprintf("%.0f", cost["opus"] * 100) + 0 ? "pass" : "fail"
    printf "check cost=%s implementer=%.2f opus=%.2f\n", check_cost, cost["implementer"], cost["opus"]
    if (check_cost == "fail") failed = 1
    if (failed) { print "verdict=fail"; exit 1 }
    print "verdict=pass"
  }
'
