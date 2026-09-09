#!/usr/bin/env bash
# resolve-feature-folder.sh: the contract of .agents/scripts/resolve-feature-folder.sh, the one
# executable form of the rule that turns a bare slug into a feature folder, exercised in throwaway
# repositories. Run: bash scripts/tests/resolve-feature-folder.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
resolve="$here/../../.agents/scripts/resolve-feature-folder.sh"
today="$(date +%Y%m%d)"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

git() { command git -c user.email=t@example.com -c user.name=t -c init.defaultBranch=main "$@"; }

check() { # $1 label, $2 expected exit, $3 actual exit, $4.. lines that must appear; output in $out
  local label="$1" want="$2" rc="$3"; shift 3
  local ok=1 line
  [ "$rc" = "$want" ] || ok=0
  for line in "$@"; do grep -qxF -- "$line" <<<"$out" || ok=0; done
  if [ "$ok" = 1 ]; then echo "ok    $label"; else
    echo "FAIL  $label (exit $rc, wanted $want)"; echo "      ${out//$'\n'/$'\n'      }"; fails=$((fails + 1)); fi
}
expect() { # $1 label, $2.. a command that must succeed
  local label="$1"; shift
  if "$@"; then echo "ok    $label"; else echo "FAIL  $label"; fails=$((fails + 1)); fi
}
run() { rc=0; out="$(bash "$resolve" "$@" 2>&1)" || rc=$?; }

# A slug whose scratch holds one dated feature folder answers with that folder and the spec in it.
mkdir "$tmp/one" && cd "$tmp/one" && git init -q
mkdir -p ".scratch/$today-nightly-purge"
run nightly-purge
check "one dated folder resolves to itself" 0 "$rc" \
  "slug=nightly-purge" \
  "root=$(pwd -P)" \
  "folder=.scratch/$today-nightly-purge" \
  "spec=.scratch/$today-nightly-purge/spec.md" \
  "date=$today"

# Two dated folders for one slug: the newest wins, so a rerun reads what was written last.
mkdir "$tmp/two" && cd "$tmp/two" && git init -q
mkdir -p .scratch/20240101-nightly-purge .scratch/20260909-nightly-purge
run nightly-purge
check "the newest of two dated folders wins" 0 "$rc" \
  "folder=.scratch/20260909-nightly-purge" \
  "spec=.scratch/20260909-nightly-purge/spec.md" \
  "date=20260909"

# An undated folder from before the dated rule wins over every dated one, and is never renamed.
mkdir "$tmp/undated" && cd "$tmp/undated" && git init -q
mkdir -p .scratch/20260909-nightly-purge .scratch/nightly-purge
run nightly-purge
check "an undated folder wins over a dated one" 0 "$rc" \
  "folder=.scratch/nightly-purge" \
  "spec=.scratch/nightly-purge/spec.md" \
  "date=none"
expect "the undated folder keeps its name" test -d .scratch/nightly-purge
expect "the dated folder keeps its name" test -d .scratch/20260909-nightly-purge

if [ "$fails" = 0 ]; then echo "PASS"; else echo "$fails failing"; exit 1; fi
