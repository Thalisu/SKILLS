#!/usr/bin/env bash
# compare-verdict.sh: the contract of skills/do/evals/compare/verdict.sh, which reads the run lines of
# the Opus-only shape and of the Implementer shape and decides whether the Implementer shape ships.
# Run: bash skills/do/tests/compare-verdict.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
script="$here/../evals/compare/verdict.sh"
fails=0

run() { # stdin the run lines: the script's stdout in $out, its stderr in $err, its exit in $rc
  rc=0
  local errfile
  errfile="$(mktemp)"
  out="$(bash "$script" 2>"$errfile")" || rc=$?
  err="$(cat "$errfile")"
  rm -f "$errfile"
}

# The Implementer shape raises fewer Act on Findings (1 against 2), adds no unexpected stopped, fork
# or unreadable return (0 against 0) and costs strictly less (4.60 against 7.12), so the maintainer
# may move the pin: the verdict passes. The lines come interleaved, since the script reads them in
# any order.
run <<'EOF'
run shape=implementer case=adds-a-seam folder=/tmp/run-eval-adds-a-seam.Impl01 cost_usd=2.50 review=present act_on=1 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=2 implementer_not_green=0 implementer_out_of_brief=0
run shape=opus case=adds-a-seam folder=/tmp/run-eval-adds-a-seam.Q3x9Lm cost_usd=4.12 review=present act_on=1 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=0 implementer_not_green=0 implementer_out_of_brief=0
run shape=opus case=renames-a-field folder=/tmp/run-eval-renames-a-field.Op02Zz cost_usd=3.00 review=present act_on=1 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=0 implementer_not_green=0 implementer_out_of_brief=0
run shape=implementer case=renames-a-field folder=/tmp/run-eval-renames-a-field.Impl02 cost_usd=2.10 review=present act_on=0 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=1 implementer_not_green=0 implementer_out_of_brief=0
EOF
last="$(tail -n 1 <<<"$out")"
if [ "$rc" = 0 ] && [ "$last" = "verdict=pass" ]; then
  ok "an Implementer shape with fewer Act on Findings, no more unexpected returns and a lower cost passes the verdict"
else
  fail "an Implementer shape with fewer Act on Findings, no more unexpected returns and a lower cost passes the verdict (exit $rc, wanted 0; last line: $last)"
  dump_out
  [ -n "$err" ] && echo "      stderr: ${err//$'\n'/$'\n'      }"
fi

# The Implementer shape costs less and adds no unexpected return, but raises more Act on Findings
# (3 against 1): a cheaper shape that writes worse code must not ship, and the maintainer reads which
# check sank it.
run <<'EOF'
run shape=opus case=adds-a-seam folder=/tmp/run-eval-adds-a-seam.Q3x9Lm cost_usd=4.12 review=present act_on=1 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=0 implementer_not_green=0 implementer_out_of_brief=0
run shape=implementer case=adds-a-seam folder=/tmp/run-eval-adds-a-seam.Impl01 cost_usd=2.50 review=present act_on=2 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=2 implementer_not_green=0 implementer_out_of_brief=0
run shape=opus case=renames-a-field folder=/tmp/run-eval-renames-a-field.Op02Zz cost_usd=3.00 review=present act_on=0 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=0 implementer_not_green=0 implementer_out_of_brief=0
run shape=implementer case=renames-a-field folder=/tmp/run-eval-renames-a-field.Impl02 cost_usd=2.10 review=present act_on=1 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=1 implementer_not_green=0 implementer_out_of_brief=0
EOF
last="$(tail -n 1 <<<"$out")"
if [ "$rc" = 1 ] && [ "$last" = "verdict=fail" ] && grep -qxF -- "check act_on=fail implementer=3 opus=1" <<<"$out"; then
  ok "an Implementer shape with more Act on Findings fails the verdict and names the act_on check"
else
  fail "an Implementer shape with more Act on Findings fails the verdict and names the act_on check (exit $rc, wanted 1; last line: $last; wanted the line: check act_on=fail implementer=3 opus=1)"
  dump_out
  [ -n "$err" ] && echo "      stderr: ${err//$'\n'/$'\n'      }"
fi

[ "$fails" = 0 ]
