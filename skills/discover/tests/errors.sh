#!/usr/bin/env bash
# errors.sh: one malformed spec line must not kill the batch: the healthy items are still
# answered, the broken one gets STATE ERROR, and the script exits 0.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
skill="$(cd "$here/.." && pwd -P)"
fail() { echo "FAIL: $*" >&2; exit 1; }

status=0
out="$(bash "$skill/scripts/discover.sh" --root "$skill/tests/fixture" 2>&1 <<'SPEC'
1 | formatCpf | format a CPF string | - | no
2 |  | the names field is empty | - | no
3 | createInvoice | build an invoice record | - | no
SPEC
)" || status=$?

[ "$status" -eq 0 ] || fail "exit $status (want 0); output: $(printf '%s' "$out" | head -3)"
printf '%s\n' "$out" | grep -q '^# 1 ' || fail "item 1 missing from the report"
printf '%s\n' "$out" | grep -qE '^DEF src/utils/format\.ts:1 formatCpf' || fail "item 1 not answered with its DEF"
printf '%s\n' "$out" | grep -q '^# 2' || fail "item 2 missing from the report"
printf '%s\n' "$out" | grep -q '^STATE ERROR malformed spec line' || fail "item 2 lacks STATE ERROR malformed spec line"
printf '%s\n' "$out" | grep -q '^# 3 ' || fail "item 3 missing from the report"
printf '%s\n' "$out" | grep -qE '^DEF src/billing/invoice\.ts:3 createInvoice' || fail "item 3 not answered with its DEF"

status=0
bash "$skill/scripts/discover.sh" --root "$skill/tests/fixture" >/dev/null 2>&1 <<'SPEC' || status=$?
1 |  | every line malformed | - | no
2 |  | every line malformed | - | no
SPEC
[ "$status" -eq 2 ] || fail "all-malformed spec must still exit 2 (got $status)"

echo "errors: ok"
