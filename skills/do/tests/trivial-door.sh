#!/usr/bin/env bash
# trivial-door.sh: the contract of scripts/trivial-door.sh, the second door check of the trivial
# Playbook, exercised in a throwaway git repository. Run: bash skills/do/tests/trivial-door.sh
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
door="$here/../scripts/trivial-door.sh"
context="$here/../../test-triage/scripts/context.sh"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

commit() { git -c user.email=t@example.com -c user.name=t add -A >/dev/null; git -c user.email=t@example.com -c user.name=t commit -q -m "$1"; }
check() { # $1 label, $2 expected exit, $3 actual exit, $4.. lines that must appear (fixed strings); output in $out
  local label="$1" want="$2" rc="$3"; shift 3
  local ok=1 line
  [ "$rc" = "$want" ] || ok=0
  for line in "$@"; do grep -qF -- "$line" <<<"$out" || ok=0; done
  if [ "$ok" = 1 ]; then echo "ok    $label"; else
    echo "FAIL  $label (exit $rc, wanted $want)"; echo "      ${out//$'\n'/$'\n'      }"; fails=$((fails + 1)); fi
}
absent() { # $1 label, $2 line that must not appear
  if grep -qF -- "$2" <<<"$out"; then echo "FAIL  $1 (found: $2)"; fails=$((fails + 1)); else echo "ok    $1"; fi
}
run() { rc=0; out="$(bash "$door" "$@" 2>&1)" || rc=$?; }
restore() { git checkout -q -- . ; git clean -qfd; }

cd "$tmp" || exit 1
git init -q -b main && mkdir -p src docs
cat > README.md <<'MD'
# Notes

Notes are listd here.
MD
cat > src/notes.js <<'JS'
const notes = [];

function nextId() {
  return notes.length + 1;
}

export function create(title) {
  const note = { id: nextId(), title, status: "active" };
  notes.push(note);
  return note;
}

export function list() {
  return notes.filter((n) => n.status === "active");
}

export function craete(title) {
  return create(title);
}

export const LIMIT = 100;
JS
cat > src/notes.test.js <<'JS'
import { test } from "node:test";
import assert from "node:assert/strict";
import { create, list } from "./notes.js";

test("list shows active notes", () => {
  create("a");
  assert.equal(list().length, 1);
});
JS
cat > src/shape.ts <<'TS'
export interface Note {
  id: number;
  title: string;
}

export function rename(
  note: Note,
  title: string
): Note {
  return { ...note, title };
}

export const handler = async (input: string): Promise<string> => {
  return input.trim();
};

export type Status = "active" | "archived";
TS
cat > src/legacy.cjs <<'JS'
function add(a, b) {
  return a + b;
}

module.exports = { add };
JS
cat > src/lib.py <<'PY'
LIMIT = 10


def helper(x):
    return x + 1


def create(
    title,
    status="active",
):
    return {"title": title, "status": status}


class Store:
    def add(self, note):
        return note
PY
cat > src/main.go <<'GO'
package main

func Hello() string { return "hello" }
GO
commit fixture

echo "# branch"
if diff -q <(awk '/^is_protected\(\) \{/,/^}/' "$door") <(awk '/^is_protected\(\) \{/,/^}/' "$context") >/dev/null; then
  echo "ok    is_protected is the verbatim copy of test-triage's context.sh"
else
  echo "FAIL  is_protected drifted from test-triage's context.sh"; fails=$((fails + 1))
fi
run branch; check "branch: a lone main is the working branch" 0 "$rc" "branch=main" "protected=no"
git branch develop
run branch; check "branch: main beside develop is protected" 1 "$rc" "protected=yes" "reason=develop exists"
git checkout -q -b feature/x
run branch; check "branch: a feature branch is never protected" 0 "$rc" "protected=no"
git checkout -q main; git branch -D develop feature/x >/dev/null

echo "# diff: usage"
run diff; check "diff: no file is a usage error" 2 "$rc" "usage"
run covering; check "covering: no file is a usage error" 2 "$rc" "usage"
run nope; check "an unknown subcommand is a usage error" 2 "$rc" "usage"

echo "# diff: prose and non-exported code"
sed -i 's/listd/listed/' README.md
run diff README.md; check "a doc typo passes" 0 "$rc" "no_exports=README.md" "verdict=trivial"
restore
sed -i 's/nextId/nextIdentifier/g' src/notes.js
run diff src/notes.js; check "a rename of a non-exported helper passes" 0 "$rc" "ok=src/notes.js" "verdict=trivial"
restore
sed -i 's/return input.trim();/return input.trimEnd();/' src/shape.ts
run diff src/shape.ts; check "a body change under an unchanged head passes" 0 "$rc" "ok=src/shape.ts"
restore

echo "# diff: exports"
printf '\nexport function archive(id) {\n  return id;\n}\n' >> src/notes.js
run diff src/notes.js; check "a new exported function goes to discuss" 1 "$rc" "new_export=src/notes.js: export function archive(id){" "verdict=not-trivial" "goes_to=discuss"
restore
sed -i 's/craete/create2/' src/notes.js
run diff src/notes.js; check "a renamed export goes to refactoring" 1 "$rc" "removed_export=src/notes.js: craete" "new_export=src/notes.js: export function create2(title){" "goes_to=refactoring"
restore
sed -i 's/^  title: string$/  title: string, force = false/' src/shape.ts
run diff src/shape.ts; check "a parameter added across a multi-line head is a changed signature" 1 "$rc" "changed_signature=src/shape.ts: export function rename(note:Note,title:string,force=false):Note{" "goes_to=refactoring"
restore
python3 - <<'PYEOF'
import re
p = "src/shape.ts"
s = open(p).read()
s = s.replace("export function rename(\n  note: Note,\n  title: string\n): Note {", "export function rename(note: Note, title: string): Note {")
open(p, "w").write(s)
PYEOF
run diff src/shape.ts; check "a reflow of the same head passes" 0 "$rc" "ok=src/shape.ts" "verdict=trivial"
restore
sed -i 's/  title: string;/  title: string;\n  body: string;/' src/shape.ts
run diff src/shape.ts; check "a new interface member is a changed signature" 1 "$rc" "changed_signature=src/shape.ts: export interface Note{" "goes_to=refactoring"
restore
sed -i 's/"active" | "archived"/"active" | "archived" | "trashed"/' src/shape.ts
run diff src/shape.ts; check "a widened exported type is a changed signature" 1 "$rc" "changed_signature=src/shape.ts: export type Status=" "goes_to=refactoring"
restore
sed -i 's/(input: string): Promise<string>/(input: string, trim = true): Promise<string>/' src/shape.ts
run diff src/shape.ts; check "an arrow export with a new parameter is a changed signature" 1 "$rc" "changed_signature=src/shape.ts: export const handler=async(input:string,trim=true):Promise<string>=>{"
restore
sed -i 's/LIMIT = 100/LIMIT = 200/' src/notes.js
run diff src/notes.js; check "an exported value change is the covering suite's to judge and passes" 0 "$rc" "ok=src/notes.js"
restore
sed -i 's/export const LIMIT = 100;/export const LIMIT = 100;\nexport const greeting = (name) => "hi " + name;/' src/notes.js
commit "an arrow export"
sed -i 's/"hi " + name/"hello " + name/' src/notes.js
run diff src/notes.js; check "an arrow export with a changed body passes" 0 "$rc" "ok=src/notes.js"
restore
sed -i 's/greeting = (name) =>/greeting = (name, formal) =>/' src/notes.js
run diff src/notes.js; check "an arrow export with a new parameter is a changed signature" 1 "$rc" "changed_signature=src/notes.js: export const greeting=(name,formal)=>"
restore
python3 - <<'PYEOF'
p = "src/notes.js"
s = open(p).read()
s = s.replace('export function craete(title) {\n  return create(title);\n}\n\n', "")
open(p, "w").write(s)
PYEOF
run diff src/notes.js; check "a removed export is dead code and passes" 0 "$rc" "removed_export=src/notes.js: craete" "verdict=trivial"
absent "a removed export is not a new export" "new_export="
restore
sed -i 's/module.exports = { add };/module.exports = { add, sub };/' src/legacy.cjs
run diff src/legacy.cjs; check "a widened module.exports is a changed signature" 1 "$rc" "changed_signature=src/legacy.cjs: module.exports={add,sub}" "goes_to=refactoring"
restore

echo "# diff: python"
sed -i 's/    status="active",/    status="active",\n    tags=None,/' src/lib.py
run diff src/lib.py; check "python: a parameter added across a multi-line def is a changed signature" 1 "$rc" 'changed_signature=src/lib.py: def create(title,status="active",tags=None):' "goes_to=refactoring"
restore
sed -i 's/return x + 1/return x + 2/' src/lib.py
run diff src/lib.py; check "python: a body change passes" 0 "$rc" "ok=src/lib.py"
restore
printf '\n\ndef archive(note):\n    return note\n' >> src/lib.py
run diff src/lib.py; check "python: a new public def goes to discuss" 1 "$rc" "new_export=src/lib.py: def archive(note):" "goes_to=discuss"
restore
printf '\n\ndef _private(note):\n    return note\n' >> src/lib.py
run diff src/lib.py; check "python: a new private def passes" 0 "$rc" "ok=src/lib.py"
restore
sed -i 's/LIMIT = 10/LIMIT = 20/' src/lib.py
run diff src/lib.py; check "python: a public constant change passes" 0 "$rc" "ok=src/lib.py"
restore
printf '\n__all__ = ["create", "Store"]\n' >> src/lib.py
commit "an __all__ list"
sed -i 's/__all__ = \["create", "Store"\]/__all__ = ["create", "Store", "helper"]/' src/lib.py
run diff src/lib.py; check "python: a widened __all__ is a changed signature" 1 "$rc" 'changed_signature=src/lib.py: __all__=["create","Store","helper"]'
restore

echo "# diff: test files, new files, other languages"
sed -i 's/shows active/lists active/' src/notes.test.js
run diff src/notes.test.js; check "a test file goes to bug-fix" 1 "$rc" "test_file=src/notes.test.js" "goes_to=bug-fix"
restore
echo "export const x = 1;" > src/new.js
run diff src/new.js; check "a new file goes to discuss" 1 "$rc" "new_file=src/new.js" "goes_to=discuss"
restore
sed -i 's/"hello"/"hi"/' src/main.go
run diff src/main.go; check "a language with no pattern is left to judgment" 3 "$rc" "judgment=src/main.go" "verdict=judgment"
restore
sed -i 's/"hello"/"hi"/' src/main.go; sed -i 's/craete/create2/' src/notes.js
run diff src/main.go src/notes.js; check "a stop outranks a judgment" 1 "$rc" "judgment=src/main.go" "goes_to=refactoring"
restore
sed -i 's/craete/create2/' src/notes.js; sed -i 's/shows active/lists active/' src/notes.test.js
run diff src/notes.js src/notes.test.js; check "refactoring outranks bug-fix when both apply" 1 "$rc" "test_file=src/notes.test.js" "goes_to=refactoring"
restore
sed -i 's/listd/listed/' README.md; sed -i 's/return x + 1/return x + 2/' src/lib.py
run diff README.md src/lib.py; check "several clean files pass together" 0 "$rc" "no_exports=README.md" "ok=src/lib.py" "verdict=trivial"
restore

echo "# covering"
run covering src/notes.js; check "covering: the test that imports the file is named" 0 "$rc" "covering=src/notes.js: src/notes.test.js"
run covering README.md; check "covering: a file no test names is uncovered" 0 "$rc" "uncovered=README.md"
run covering src/notes.js README.md; check "covering: several files at once" 0 "$rc" "covering=src/notes.js: src/notes.test.js" "uncovered=README.md"
run covering src/notes.test.js; check "covering: a test file does not cover itself" 0 "$rc" "uncovered=src/notes.test.js"

echo "# diff: the policy's test-file classes"
mkdir -p .claude/testing-policy
cat > .claude/testing-policy/skip-patterns.sh <<'SH'
skip_pattern_for() {
  SKIP_PAT="" SKIP_KIND=""
  case "$1" in *.check.js) SKIP_PAT='x' SKIP_KIND='check' ;; esac
}
SH
echo "export const y = 1;" > src/notes.check.js
commit "policy and a check file"
sed -i 's/= 1/= 2/' src/notes.check.js
run diff src/notes.check.js; check "an installed policy names the test-file classes" 1 "$rc" "test_file=src/notes.check.js" "classes=policy"
rm -rf .claude
run diff src/notes.check.js; check "without the policy the built-in list decides" 0 "$rc" "classes=built-in" "ok=src/notes.check.js"
absent "the built-in list does not know the policy's class" "test_file="
restore

echo "# outside a repository"
cd /; run branch; check "outside a git repository is an error" 2 "$rc" "not a git repository"

echo
if [ "$fails" = 0 ]; then echo "trivial-door: all checks passed"; else echo "trivial-door: $fails failed"; exit 1; fi
