#!/usr/bin/env bash
# reader-pointers-mixed-line.sh: the pointer case of each reader test goes red when a reference line
# holds a shaped pointer `Read [X.md](X.md) when <condition>` and a bare link to the same X.md. The
# bare link lets a run open X.md with no condition, and a case that reads the line as a whole sees
# only the shaped text on it.
# Each reader runs inside a throwaway copy of what it reads; this repo's references are never written to.
# Run: bash skills/do/tests/reader-pointers-mixed-line.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../../../scripts/tests/lib.sh"
root="$(cd "$here/../../.." && pwd -P)"
fails=0
tmp="$(mktemp -d)"
trap 'cd /; rm -rf "$tmp"' EXIT

copy_of() { # $1 name: lib.sh, .agents/invocation.md and skills/do, laid as in this repo at $tmp/<name>
  mkdir -p "$tmp/$1/scripts/tests" "$tmp/$1/.agents" "$tmp/$1/skills"
  cp "$root/scripts/tests/lib.sh" "$tmp/$1/scripts/tests/"
  cp "$root/.agents/invocation.md" "$tmp/$1/.agents/"
  cp -r "$root/skills/do" "$tmp/$1/skills/"
}

with_bare_link() { # $1 copy name, $2 reference file, $3 X.md: appends ` and see [X.md](X.md)` to the first line holding `Read [X.md](X.md) when`
  local file="$tmp/$1/skills/do/references/$2"
  awk -v needle="Read [$3]($3) when" -v tail=" and see [$3]($3)" \
    '!done && index($0, needle) { $0 = $0 tail; done = 1 } { print }' "$file" >"$file.new" &&
    mv "$file.new" "$file"
  grep -qF "Read [$3]($3) when" "$file" && grep -qF " and see [$3]($3)" "$file"
}

status_of() { # $1 copy name, $2 reader script, $3 case label: ok or FAIL, what the reader printed for that case, on stdout
  (cd "$tmp/$1" && bash "skills/do/tests/$2" 2>&1) |
    awk -v label="$3" 'index($0, "ok    " label) == 1 { print "ok"; exit } index($0, "FAIL  " label) == 1 { print "FAIL"; exit }'
}

copy_of pristine
for spec in "pr-fix-readers.sh|pr.md|pr-fix.md|no pointer to pr-fix.md has another shape" \
  "resume-readers.sh|ticket.md|resume.md|no pointer to resume.md has another shape" \
  "trivial-auto-readers.sh|trivial.md|trivial-auto.md|no pointer to trivial-auto.md has another shape" \
  "trivial-escape-readers.sh|trivial.md|trivial-escape.md|no pointer to trivial-escape.md has another shape" \
  "refactoring-readers.sh|refactoring.md|refactoring-design-fork.md|every pointer to refactoring-design-fork.md reads Read [refactoring-design-fork.md](refactoring-design-fork.md) when <condition>"; do
  IFS='|' read -r reader reference target label <<<"$spec"
  echo "# $reader: a line in $reference with a shaped pointer and a bare link to $target"
  expect "$reader: the pointer case is ok over the unchanged references" \
    test "$(status_of pristine "$reader" "$label")" = ok
  copy_of "mixed-$target"
  expect "$reference in the copy holds a shaped pointer and a bare link to $target on one line" \
    with_bare_link "mixed-$target" "$reference" "$target"
  expect "$reader: the pointer case fails when a line adds a bare link to $target beside its shaped pointer" \
    test "$(status_of "mixed-$target" "$reader" "$label")" = FAIL
done

[ "$fails" = 0 ] || exit 1
