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

# The Implementer shape costs less and raises fewer Act on Findings, but one of its runs returns an
# unexpected fork (1 against 0): a shape that stops runs the developer then resumes by hand must not
# ship. Its other run stopped on the budget, which is expected and stays out of the total.
run <<'EOF'
run shape=opus case=adds-a-seam folder=/tmp/run-eval-adds-a-seam.Q3x9Lm cost_usd=4.12 review=present act_on=1 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=0 implementer_not_green=0 implementer_out_of_brief=0
run shape=implementer case=adds-a-seam folder=/tmp/run-eval-adds-a-seam.Impl01 cost_usd=2.50 review=present act_on=1 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=1 unreadable=0 implementer_returns=2 implementer_not_green=0 implementer_out_of_brief=0
run shape=opus case=renames-a-field folder=/tmp/run-eval-renames-a-field.Op02Zz cost_usd=3.00 review=present act_on=1 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=0 implementer_not_green=0 implementer_out_of_brief=0
run shape=implementer case=renames-a-field folder=/tmp/run-eval-renames-a-field.Impl02 cost_usd=2.10 review=present act_on=0 builder_returns=1 built=1 budget_stopped=1 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=1 implementer_not_green=0 implementer_out_of_brief=0
EOF
last="$(tail -n 1 <<<"$out")"
if [ "$rc" = 1 ] && [ "$last" = "verdict=fail" ] && grep -qxF -- "check unexpected=fail implementer=1 opus=0" <<<"$out"; then
  ok "an Implementer shape that adds an unexpected stopped or fork return fails the verdict and names the unexpected check"
else
  fail "an Implementer shape that adds an unexpected stopped or fork return fails the verdict and names the unexpected check (exit $rc, wanted 1; last line: $last; wanted the line: check unexpected=fail implementer=1 opus=0)"
  dump_out
  [ -n "$err" ] && echo "      stderr: ${err//$'\n'/$'\n'      }"
fi

# The Implementer shape raises no more Act on Findings and adds no unexpected return, but costs the
# same in total (2.10 + 2.50 against 1.60 + 3.00, both 4.60): moving the pin buys no saving, so an
# equal cost fails the verdict. The per-run figures differ so that only the decimal totals tie.
run <<'EOF'
run shape=implementer case=adds-a-seam folder=/tmp/run-eval-adds-a-seam.Impl01 cost_usd=2.10 review=present act_on=1 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=2 implementer_not_green=0 implementer_out_of_brief=0
run shape=opus case=adds-a-seam folder=/tmp/run-eval-adds-a-seam.Q3x9Lm cost_usd=1.60 review=present act_on=1 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=0 implementer_not_green=0 implementer_out_of_brief=0
run shape=opus case=renames-a-field folder=/tmp/run-eval-renames-a-field.Op02Zz cost_usd=3.00 review=present act_on=1 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=0 implementer_not_green=0 implementer_out_of_brief=0
run shape=implementer case=renames-a-field folder=/tmp/run-eval-renames-a-field.Impl02 cost_usd=2.50 review=present act_on=0 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=1 implementer_not_green=0 implementer_out_of_brief=0
EOF
last="$(tail -n 1 <<<"$out")"
if [ "$rc" = 1 ] && [ "$last" = "verdict=fail" ] && grep -qxF -- "check cost=fail implementer=4.60 opus=4.60" <<<"$out"; then
  ok "an Implementer shape that costs the same as the Opus-only shape fails the verdict and names the cost check"
else
  fail "an Implementer shape that costs the same as the Opus-only shape fails the verdict and names the cost check (exit $rc, wanted 1; last line: $last; wanted the line: check cost=fail implementer=4.60 opus=4.60)"
  dump_out
  [ -n "$err" ] && echo "      stderr: ${err//$'\n'/$'\n'      }"
fi

# The Implementer shape raises no more Act on Findings and adds no unexpected return, but costs more
# in total (5.60 against 4.60): a shape that raises the bill must not ship.
run <<'EOF'
run shape=opus case=adds-a-seam folder=/tmp/run-eval-adds-a-seam.Q3x9Lm cost_usd=1.60 review=present act_on=1 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=0 implementer_not_green=0 implementer_out_of_brief=0
run shape=implementer case=adds-a-seam folder=/tmp/run-eval-adds-a-seam.Impl01 cost_usd=3.10 review=present act_on=1 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=2 implementer_not_green=0 implementer_out_of_brief=0
run shape=opus case=renames-a-field folder=/tmp/run-eval-renames-a-field.Op02Zz cost_usd=3.00 review=present act_on=1 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=0 implementer_not_green=0 implementer_out_of_brief=0
run shape=implementer case=renames-a-field folder=/tmp/run-eval-renames-a-field.Impl02 cost_usd=2.50 review=present act_on=1 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=1 implementer_not_green=0 implementer_out_of_brief=0
EOF
last="$(tail -n 1 <<<"$out")"
if [ "$rc" = 1 ] && [ "$last" = "verdict=fail" ] && grep -qxF -- "check cost=fail implementer=5.60 opus=4.60" <<<"$out"; then
  ok "an Implementer shape that costs more than the Opus-only shape fails the verdict and names the cost check"
else
  fail "an Implementer shape that costs more than the Opus-only shape fails the verdict and names the cost check (exit $rc, wanted 1; last line: $last; wanted the line: check cost=fail implementer=5.60 opus=4.60)"
  dump_out
  [ -n "$err" ] && echo "      stderr: ${err//$'\n'/$'\n'      }"
fi

verdict_is() { # $1 label, $2 the wanted last line, $3 the wanted exit, $4.. extended regexes a whole line of $out must match
  local label="$1" want="$2" want_rc="$3" last pattern good=1 missing=""
  shift 3
  last="$(tail -n 1 <<<"$out")"
  [ "$rc" = "$want_rc" ] && [ "$last" = "$want" ] || good=0
  for pattern in "$@"; do grep -qE -- "^$pattern\$" <<<"$out" || {
    good=0
    missing="$missing; wanted a line matching: $pattern"
  }; done
  if [ "$good" = 1 ]; then ok "$label"; else
    fail "$label (exit $rc, wanted $want_rc; last line: $last, wanted $want$missing)"
    dump_out
    [ -n "$err" ] && echo "      stderr: ${err//$'\n'/$'\n'      }"
  fi
}

# Each case below starts from the run lines of the passing case above and breaks one thing, so the
# input would otherwise pass. A run with no cost leaves both totals unknowable: the maintainer must
# not record a pass for a comparison whose bill was never read.
run <<'EOF'
run shape=implementer case=adds-a-seam folder=/tmp/run-eval-adds-a-seam.Impl01 cost_usd=2.50 review=present act_on=1 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=2 implementer_not_green=0 implementer_out_of_brief=0
run shape=opus case=adds-a-seam folder=/tmp/run-eval-adds-a-seam.Q3x9Lm cost_usd=4.12 review=present act_on=1 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=0 implementer_not_green=0 implementer_out_of_brief=0
run shape=opus case=renames-a-field folder=/tmp/run-eval-renames-a-field.Op02Zz cost_usd=3.00 review=present act_on=1 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=0 implementer_not_green=0 implementer_out_of_brief=0
run shape=implementer case=renames-a-field folder=/tmp/run-eval-renames-a-field.Impl02 cost_usd=absent review=present act_on=0 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=1 implementer_not_green=0 implementer_out_of_brief=0
EOF
verdict_is "a run with no cost reads the verdict as incomplete, with act_on and cost unknown" verdict=incomplete 3 \
  "check act_on=unknown( .*)?" "check cost=unknown( .*)?"

# A run that never reached its Review has no Act on Findings to count.
run <<'EOF'
run shape=implementer case=adds-a-seam folder=/tmp/run-eval-adds-a-seam.Impl01 cost_usd=2.50 review=present act_on=1 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=2 implementer_not_green=0 implementer_out_of_brief=0
run shape=opus case=adds-a-seam folder=/tmp/run-eval-adds-a-seam.Q3x9Lm cost_usd=4.12 review=absent act_on=absent builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=0 implementer_not_green=0 implementer_out_of_brief=0
run shape=opus case=renames-a-field folder=/tmp/run-eval-renames-a-field.Op02Zz cost_usd=3.00 review=present act_on=1 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=0 implementer_not_green=0 implementer_out_of_brief=0
run shape=implementer case=renames-a-field folder=/tmp/run-eval-renames-a-field.Impl02 cost_usd=2.10 review=present act_on=0 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=1 implementer_not_green=0 implementer_out_of_brief=0
EOF
verdict_is "a run with no Review reads the verdict as incomplete, with act_on and cost unknown" verdict=incomplete 3 \
  "check act_on=unknown( .*)?" "check cost=unknown( .*)?"

# A run that built nothing never exercised the shape it names.
run <<'EOF'
run shape=implementer case=adds-a-seam folder=/tmp/run-eval-adds-a-seam.Impl01 cost_usd=2.50 review=present act_on=1 builder_returns=1 built=0 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=2 implementer_not_green=0 implementer_out_of_brief=0
run shape=opus case=adds-a-seam folder=/tmp/run-eval-adds-a-seam.Q3x9Lm cost_usd=4.12 review=present act_on=1 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=0 implementer_not_green=0 implementer_out_of_brief=0
run shape=opus case=renames-a-field folder=/tmp/run-eval-renames-a-field.Op02Zz cost_usd=3.00 review=present act_on=1 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=0 implementer_not_green=0 implementer_out_of_brief=0
run shape=implementer case=renames-a-field folder=/tmp/run-eval-renames-a-field.Impl02 cost_usd=2.10 review=present act_on=0 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=1 implementer_not_green=0 implementer_out_of_brief=0
EOF
verdict_is "a run that built nothing reads the verdict as incomplete" verdict=incomplete 3

# The Implementer shape has no run for renames-a-field: its totals cover fewer cases than the Opus-only
# shape's, so a lower cost there proves nothing.
run <<'EOF'
run shape=implementer case=adds-a-seam folder=/tmp/run-eval-adds-a-seam.Impl01 cost_usd=2.50 review=present act_on=1 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=2 implementer_not_green=0 implementer_out_of_brief=0
run shape=opus case=adds-a-seam folder=/tmp/run-eval-adds-a-seam.Q3x9Lm cost_usd=4.12 review=present act_on=1 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=0 implementer_not_green=0 implementer_out_of_brief=0
run shape=opus case=renames-a-field folder=/tmp/run-eval-renames-a-field.Op02Zz cost_usd=3.00 review=present act_on=1 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=0 implementer_not_green=0 implementer_out_of_brief=0
EOF
verdict_is "a case run in one shape and missing from the other reads the verdict as incomplete" verdict=incomplete 3

# An Opus-only run dispatched the Implementer twice: that shape never ran as named.
run <<'EOF'
run shape=implementer case=adds-a-seam folder=/tmp/run-eval-adds-a-seam.Impl01 cost_usd=2.50 review=present act_on=1 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=2 implementer_not_green=0 implementer_out_of_brief=0
run shape=opus case=adds-a-seam folder=/tmp/run-eval-adds-a-seam.Q3x9Lm cost_usd=4.12 review=present act_on=1 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=0 implementer_not_green=0 implementer_out_of_brief=0
run shape=opus case=renames-a-field folder=/tmp/run-eval-renames-a-field.Op02Zz cost_usd=3.00 review=present act_on=1 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=2 implementer_not_green=0 implementer_out_of_brief=0
run shape=implementer case=renames-a-field folder=/tmp/run-eval-renames-a-field.Impl02 cost_usd=2.10 review=present act_on=0 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=1 implementer_not_green=0 implementer_out_of_brief=0
EOF
verdict_is "an Opus-only shape that dispatched an Implementer reads the verdict as incomplete and names the shape check" verdict=incomplete 3 \
  "check shape=fail opus_implementer_returns=2 implementer_implementer_returns=[0-9]+"

# No Implementer run dispatched an Implementer: the Implementer shape never ran as named.
run <<'EOF'
run shape=implementer case=adds-a-seam folder=/tmp/run-eval-adds-a-seam.Impl01 cost_usd=2.50 review=present act_on=1 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=0 implementer_not_green=0 implementer_out_of_brief=0
run shape=opus case=adds-a-seam folder=/tmp/run-eval-adds-a-seam.Q3x9Lm cost_usd=4.12 review=present act_on=1 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=0 implementer_not_green=0 implementer_out_of_brief=0
run shape=opus case=renames-a-field folder=/tmp/run-eval-renames-a-field.Op02Zz cost_usd=3.00 review=present act_on=1 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=0 implementer_not_green=0 implementer_out_of_brief=0
run shape=implementer case=renames-a-field folder=/tmp/run-eval-renames-a-field.Impl02 cost_usd=2.10 review=present act_on=0 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=0 implementer_not_green=0 implementer_out_of_brief=0
EOF
verdict_is "an Implementer shape that dispatched no Implementer reads the verdict as incomplete and names the shape check" verdict=incomplete 3 \
  "check shape=fail opus_implementer_returns=0 implementer_implementer_returns=0"

# The Opus-only shape dispatched an Implementer and the Implementer shape also costs more (11.60
# against 7.12): a comparison of shapes that never ran as named decides nothing, so the cost failure
# does not turn it into a fail.
run <<'EOF'
run shape=implementer case=adds-a-seam folder=/tmp/run-eval-adds-a-seam.Impl01 cost_usd=9.50 review=present act_on=1 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=2 implementer_not_green=0 implementer_out_of_brief=0
run shape=opus case=adds-a-seam folder=/tmp/run-eval-adds-a-seam.Q3x9Lm cost_usd=4.12 review=present act_on=1 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=0 implementer_not_green=0 implementer_out_of_brief=0
run shape=opus case=renames-a-field folder=/tmp/run-eval-renames-a-field.Op02Zz cost_usd=3.00 review=present act_on=1 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=2 implementer_not_green=0 implementer_out_of_brief=0
run shape=implementer case=renames-a-field folder=/tmp/run-eval-renames-a-field.Impl02 cost_usd=2.10 review=present act_on=0 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=1 implementer_not_green=0 implementer_out_of_brief=0
EOF
verdict_is "a failed shape check reads the verdict as incomplete even when another check fails" verdict=incomplete 3 \
  "check shape=fail opus_implementer_returns=2 implementer_implementer_returns=[0-9]+"

# The Implementer shape has no run for renames-a-field and its other run returns an unexpected fork:
# a failure already observed sinks the shape, whatever the missing run would have shown.
run <<'EOF'
run shape=implementer case=adds-a-seam folder=/tmp/run-eval-adds-a-seam.Impl01 cost_usd=2.50 review=present act_on=1 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=1 unreadable=0 implementer_returns=2 implementer_not_green=0 implementer_out_of_brief=0
run shape=opus case=adds-a-seam folder=/tmp/run-eval-adds-a-seam.Q3x9Lm cost_usd=4.12 review=present act_on=1 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=0 implementer_not_green=0 implementer_out_of_brief=0
run shape=opus case=renames-a-field folder=/tmp/run-eval-renames-a-field.Op02Zz cost_usd=3.00 review=present act_on=1 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=0 implementer_not_green=0 implementer_out_of_brief=0
EOF
verdict_is "a failed check reads the verdict as fail before a missing case reads it as incomplete" verdict=fail 1 \
  "check unexpected=fail implementer=1 opus=0"

# On the passing input, each shape dispatched the Implementer as named, and the shape check says so.
run <<'EOF'
run shape=implementer case=adds-a-seam folder=/tmp/run-eval-adds-a-seam.Impl01 cost_usd=2.50 review=present act_on=1 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=2 implementer_not_green=0 implementer_out_of_brief=0
run shape=opus case=adds-a-seam folder=/tmp/run-eval-adds-a-seam.Q3x9Lm cost_usd=4.12 review=present act_on=1 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=0 implementer_not_green=0 implementer_out_of_brief=0
run shape=opus case=renames-a-field folder=/tmp/run-eval-renames-a-field.Op02Zz cost_usd=3.00 review=present act_on=1 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=0 implementer_not_green=0 implementer_out_of_brief=0
run shape=implementer case=renames-a-field folder=/tmp/run-eval-renames-a-field.Impl02 cost_usd=2.10 review=present act_on=0 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=0 implementer_returns=1 implementer_not_green=0 implementer_out_of_brief=0
EOF
verdict_is "shapes that ran as named pass the shape check and the verdict" verdict=pass 0 \
  "check shape=pass opus_implementer_returns=0 implementer_implementer_returns=[0-9]+"

# The maintainer copies each shape's totals into the Ticket's Evidence and raises the Implementer
# only when they show it stopping. Every sum differs from its neighbours, and unexpected mixes
# stopped, fork and unreadable so a sum that drops one kind shows (opus 2+2=4, implementer 2+1=3).
# The Implementer's NOT GREEN and out-of-brief returns leave the passing verdict as it is.
run <<'EOF'
run shape=implementer case=adds-a-seam folder=/tmp/run-eval-adds-a-seam.Impl01 cost_usd=2.50 review=present act_on=1 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=1 unexpected_fork=0 unreadable=1 implementer_returns=6 implementer_not_green=4 implementer_out_of_brief=1
run shape=opus case=adds-a-seam folder=/tmp/run-eval-adds-a-seam.Q3x9Lm cost_usd=4.12 review=present act_on=2 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=1 unexpected_fork=1 unreadable=0 implementer_returns=0 implementer_not_green=0 implementer_out_of_brief=0
run shape=opus case=renames-a-field folder=/tmp/run-eval-renames-a-field.Op02Zz cost_usd=3.00 review=present act_on=1 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=0 unreadable=2 implementer_returns=0 implementer_not_green=0 implementer_out_of_brief=0
run shape=implementer case=renames-a-field folder=/tmp/run-eval-renames-a-field.Impl02 cost_usd=2.10 review=present act_on=0 builder_returns=1 built=1 budget_stopped=0 unexpected_stopped=0 unexpected_fork=1 unreadable=0 implementer_returns=3 implementer_not_green=1 implementer_out_of_brief=1
EOF
want_totals="total shape=opus runs=2 complete=2 cost_usd=7.12 act_on=3 unexpected=4 implementer_returns=0 implementer_not_green=0 implementer_out_of_brief=0
total shape=implementer runs=2 complete=2 cost_usd=4.60 act_on=1 unexpected=3 implementer_returns=9 implementer_not_green=5 implementer_out_of_brief=2"
totals="$(sed '/^check /,$d' <<<"$out")"
last="$(tail -n 1 <<<"$out")"
if [ "$rc" = 0 ] && [ "$last" = "verdict=pass" ] && [ "$totals" = "$want_totals" ]; then
  ok "each shape's totals print as two lines, opus first, before the check lines, and NOT GREEN returns leave the verdict passing"
else
  fail "each shape's totals print as two lines, opus first, before the check lines, and NOT GREEN returns leave the verdict passing (exit $rc, wanted 0; last line: $last, wanted verdict=pass; wanted before the check lines exactly:"$'\n'"$want_totals)"
  dump_out
  [ -n "$err" ] && echo "      stderr: ${err//$'\n'/$'\n'      }"
fi

[ "$fails" = 0 ]
