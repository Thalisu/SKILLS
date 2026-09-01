# Definition kinds per language

What `scripts/discover.sh` asks ast-grep for, per language, and the fixture line that proves each
kind (`tests/fixture`, item numbers from `tests/spec.txt`). Every row was run on this fixture; add a
row or a kind only with a fixture line that exercises it and a green `scripts/selftest.sh`.

Rule shape (one document per present language, all names of the batch in one regex):

```yaml
id: def_ts
language: ts
severity: hint
rule:
  any:
    - {kind: function_declaration, has: {field: name, regex: '^(formatCpf|maskCpf)$', pattern: $NAME}}
    - {kind: variable_declarator,  has: {field: name, regex: '^(formatCpf|maskCpf)$', pattern: $NAME}, inside: {any: [{kind: lexical_declaration}, {kind: variable_declaration}], inside: {any: [{kind: program}, {kind: export_statement}]}}}
```

`$NAME` captures the matched identifier (`metaVariables.single.NAME.text`), which is how a hit is
attributed to its item. `has`/`inside` match direct children/parents only unless told otherwise.

| ast-grep language | extensions (all recognised by ast-grep 0.45.3) | kind | name filter | fixture |
|---|---|---|---|---|
| `ts` | `.ts` | `function_declaration` | `field: name` | `src/legacy/format.ts:1` (item 1) |
| | | `method_definition` | `field: name` | `src/services/UserService.ts:11` (7) |
| | | `variable_declarator` — top-level only, see below | `field: name` | `src/utils/format.ts:1` (1) |
| | | `class_declaration` | `field: name` | `src/services/UserService.ts:10` (8) |
| | | `interface_declaration` | `field: name` | `src/services/UserService.ts:1` (9) |
| | | `enum_declaration` | `field: name` | `src/services/UserService.ts:5` (10) |
| | | `type_alias_declaration` | `field: name` | `src/billing/invoice.ts:1` (11) |
| | | `export_specifier` (`export { a as b }`) | `field: alias` | `src/index.ts:1` (5) |
| `tsx` | `.tsx` | same kinds as `ts` | | `src/components/Badge.tsx:5` — `memo(function …)` declarator (4) |
| `javascript` | `.js .jsx .mjs .cjs` | `ts` kinds minus interface/enum/type alias | | `js/legacy.mjs:1` (12) |
| `python` | `.py` | `function_definition` (decorated ok) | `field: name` | `py/service.py:10` (13) |
| | | `class_definition` | `field: name` | `py/service.py:4` (14) |
| `rust` | `.rs` | `function_item` (incl. `impl` methods) | `field: name` | `rs/lib.rs:20` (15) |
| | | `function_signature_item` (trait fn) | `field: name` | `rs/lib.rs:14` (16) |
| | | `struct_item` | `field: name` | `rs/lib.rs:5` (17) |
| | | `enum_item` | `field: name` | `rs/lib.rs:9` (18) |
| | | `const_item` | `field: name` | `rs/lib.rs:1` (19) |
| | | `type_item` | `field: name` | `rs/lib.rs:3` (20) |
| `go` | `.go` | `function_declaration` | `field: name` | `go/svc.go:9` (21) |
| | | `method_declaration` (receiver) | `field: name` | `go/svc.go:13` (22) |
| | | `type_declaration` | `has: {kind: type_spec, has: {field: name, …}}` | `go/svc.go:3` (17) |
| `java` | `.java` | `method_declaration` | `field: name` | `java/Svc.java:18` (23) |
| | | `constructor_declaration` | `field: name` | `java/Svc.java:10` — collapsed into the class, see below (24) |
| | | `class_declaration` | `field: name` | `java/Svc.java:7` (24) |
| | | `interface_declaration` | `field: name` | `java/Svc.java:3` (25) |
| `kotlin` | `.kt .kts` | `function_declaration` | `has: {kind: simple_identifier, …}` — no `name` field | `kt/Svc.kt:2` (23) |
| | | `property_declaration` | `has: {kind: variable_declaration, has: {kind: simple_identifier, …}}` | `kt/Svc.kt:5` (26) |
| | | `class_declaration` | `has: {kind: type_identifier, …}` | `kt/Svc.kt:1` (24), `kt/Svc.kt:7` data class (17) |
| `swift` | `.swift` | `function_declaration` | `field: name` | `swift/Svc.swift:10` (23) |
| | | `property_declaration` | `field: name` | `swift/Svc.swift:6` (27) |
| | | `class_declaration` (also `struct`) | `field: name` | `swift/Svc.swift:5` (24), `swift/Svc.swift:1` struct (17) |
| `c` | `.c .h` | `function_definition` | `has: {kind: function_declarator, has: {field: declarator, …}}` | `c/svc.c:3` (15), `c/svc.h:6` inline (29) |
| `cpp` | `.cc .cpp .cxx .hpp .hh` | `function_definition` | same nesting, regex `(^\|::)(names)$` for `Svc::fetchUser` | `cpp/svc.cpp:10` (23), `cpp/svc.hpp:3` (30) |
| `csharp` | `.cs` | `method_declaration` | `field: name` | `cs/Svc.cs:7` (22) |
| | | `property_declaration` | `field: name` | `cs/Svc.cs:5` (28) |
| | | `class_declaration` | `field: name` | `cs/Svc.cs:3` (24) |
| `ruby` | `.rb` | `method` | `field: name` | `rb/svc.rb:6` (27) |
| | | `singleton_method` (`def self.x`) | `field: name` | `rb/svc.rb:2` (15) |
| | | `class` | `field: name` | `rb/svc.rb:1` (24) |
| `php` | `.php` | `function_definition` | `field: name` | `php/Svc.php:3` (15) |
| | | `method_declaration` | `field: name` | `php/Svc.php:10` (23) |
| | | `class_declaration` | `field: name` | `php/Svc.php:8` (24) |
| `lua` | `.lua` | `function_declaration` (`M.f`, `Svc:f`, `local function f`) | `field: name`, regex `(^\|[.:])(names)$` | `lua/svc.lua:4` and `:8` (15) |
| `bash` | `.sh .bash` | `function_definition` | `field: name` | `sh/svc.sh:3` (15) |

Extensions outside this table are code without ast coverage (`GENERIC` in the report, e.g. `sql`)
and only reach the word-search funnel; `md json yaml toml lock png …` are not code and are ignored
everywhere except the file list.

## Behaviours worth knowing

- `range.start.line` is 0-based; the script adds 1.
- One `DEF` per (file, matched name), first line wins: a Java class and its constructor, or the
  overload signatures of one TypeScript function, collapse into one line. Lua `M.f` and `Svc:f`
  stay separate (different qualified names).
- `variable_declarator` is restricted to declarations whose parent is `program` or
  `export_statement`: every local `const x = …` inside a function is a declarator too, and without
  the restriction a name used for locals in several files comes back as a DUPLICATE of locals
  (item 32 in the fixture proves the restriction).
- Not covered, by design of the table: Rust `trait_item`, C++ `class_specifier`/`struct`, Java
  `field_declaration`, Kotlin class parameters, Go interface methods, Python module-level
  assignments. Such symbols surface as `NAME` lines through the funnel when the name occurs
  anywhere, never as `DEF`.
- Signatures are the definition's first line with `export`, `pub(...)`, visibility keywords,
  `function`/`def`/`fn`/`func`/`fun` and a trailing `{`, `=>`, `:` or `=` removed; a top-level
  `name = (params) => …` arrow is printed as `name(params)`; capped at 90 characters.
- Uses per definition come from `rg -w` over code files minus the defining file, import/export/
  `use`/`require(` lines dropped. When one name has several definitions, each using file is tied
  to a definition by resolving its import specifier (relative paths, `@/`/`~/` aliases, Python
  dotted modules, Rust `use` paths) as a suffix of the definition path; files whose import cannot
  be resolved are reported as `UNATTRIBUTED`.
