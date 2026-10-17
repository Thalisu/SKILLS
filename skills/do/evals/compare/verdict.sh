#!/usr/bin/env bash
# usage: verdict.sh < <run lines of both shapes>
# Reads the run lines compare.sh prints for the Opus-only shape (`opus`) and the Implementer shape
# (`implementer`), in any order, and decides whether the Implementer shape ships: it passes only
# when it raises no more Act on Findings, adds no unexpected stopped or fork return, and costs
# strictly less in total. The verdict is incomplete, never a pass, when a shape did not run as
# named, a run lacks its cost, its Review or a build, or a case ran in one shape only.
# Pure: it reads stdin and nothing else.
# Exit 0 pass, 1 fail, 3 incomplete.
set -uo pipefail

awk '
  {
    delete field
    for (i = 2; i <= NF; i++) {
      split($i, kv, "=")
      field[kv[1]] = kv[2]
    }
    s = field["shape"]
    runs_of[s, field["case"]]++
    cases[field["case"]] = 1
    runs[s]++
    if (field["cost_usd"] == "absent" || field["review"] != "present" || field["act_on"] == "absent" || field["built"] < 1) incomplete_runs++
    else complete[s]++
    cost[s] += field["cost_usd"]
    act_on[s] += field["act_on"]
    unexpected[s] += field["unexpected_stopped"] + field["unexpected_fork"] + field["unreadable"]
    implementer_returns[s] += field["implementer_returns"]
    not_green[s] += field["implementer_not_green"]
    out_of_brief[s] += field["implementer_out_of_brief"]
  }
  END {
    for (n = 1; n <= 2; n++) {
      s = n == 1 ? "opus" : "implementer"
      printf "total shape=%s runs=%d complete=%d cost_usd=%.2f act_on=%d unexpected=%d implementer_returns=%d implementer_not_green=%d implementer_out_of_brief=%d\n", s, runs[s], complete[s], cost[s], act_on[s], unexpected[s], implementer_returns[s], not_green[s], out_of_brief[s]
    }

    check_shape = implementer_returns["opus"] == 0 && implementer_returns["implementer"] > 0 ? "pass" : "fail"
    printf "check shape=%s opus_implementer_returns=%d implementer_implementer_returns=%d\n", check_shape, implementer_returns["opus"], implementer_returns["implementer"]

    check_unexpected = unexpected["implementer"] <= unexpected["opus"] ? "pass" : "fail"
    printf "check unexpected=%s implementer=%d opus=%d\n", check_unexpected, unexpected["implementer"], unexpected["opus"]

    if (incomplete_runs) check_act_on = "unknown"
    else check_act_on = act_on["implementer"] <= act_on["opus"] ? "pass" : "fail"
    printf "check act_on=%s implementer=%d opus=%d\n", check_act_on, act_on["implementer"], act_on["opus"]

    # Compared in whole cents, as printed, so float noise in the sums cannot pass an equal cost.
    if (incomplete_runs) check_cost = "unknown"
    else check_cost = sprintf("%.0f", cost["implementer"] * 100) + 0 < sprintf("%.0f", cost["opus"] * 100) + 0 ? "pass" : "fail"
    printf "check cost=%s implementer=%.2f opus=%.2f\n", check_cost, cost["implementer"], cost["opus"]

    unmatched = 0
    for (c in cases) if (runs_of["opus", c] != runs_of["implementer", c]) unmatched = 1

    if (check_shape == "fail") { print "verdict=incomplete"; exit 3 }
    if (check_unexpected == "fail" || check_act_on == "fail" || check_cost == "fail") { print "verdict=fail"; exit 1 }
    if (check_act_on == "unknown" || check_cost == "unknown" || unmatched) { print "verdict=incomplete"; exit 3 }
    print "verdict=pass"
  }
'
