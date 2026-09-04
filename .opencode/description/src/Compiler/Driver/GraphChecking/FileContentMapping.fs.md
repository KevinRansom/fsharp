# FileContentMapping.fs

**Purpose**: Walks the parsed syntax tree of a single file and extracts the "significant constructs" — `FileContentEntry` values (top-level namespaces, `open` statements, prefixed identifiers, nested modules, potential module names) — as a lossless summary used to compute file-to-file dependencies in the graph-checking architecture. Large module (~750 lines) of AST visitors covering declarations, types, members, expressions, and patterns.

**Namespace(s)**: `FSharp.Compiler.GraphChecking` (module `internal rec FileContentMapping`)

**Public API surface** (per the .fsi):
- `val mkFileContent: f: FileInProject -> FileContentEntry list` — entry point: extract the file's `FileContentEntry` list from its `ParsedInput`. Handles both `ImplFile` and `SigFile`, mapping `SynModuleDecl`/`SynModuleSigDecl` to entries; `NamedModule`/`DeclaredNamespace` become `TopLevelNamespace(path, content)` wrappers (skipping the last identifier for a named module).

**Internal helpers** (extensive visitor family):
- Path helpers: `longIdentToPath` (drops a leading `` `global` `` and optionally the last segment), `synLongIdentToPath`, `visitLongIdent` (multi-segment only → `PrefixedIdentifier`), `visitLongIdentForModuleAbbrev` (keeps full path for `module` abbreviations).
- Declaration visitors: `visitSynModuleDecl`, `visitSynModuleSigDecl`, `visitSynTypeDefn`, `visitSynTypeDefnSig`, `visitSynValSig`, `visitSynField`, `visitSynMemberDefn`, `visitSynMemberSig`, `visitSynUnionCase`, `visitSynEnumCase`, `visitSynType`, `visitSynTypeConstraint`, `visitSynInterfaceImpl`, `visitSynAttributes` (attributes, attribute lists, single attributes).
- Expression/pattern visitors: `visitSynExpr` (large; covers let-bindings, matches, lambdas, member access, `nameof`, etc.), `visitPat` (CPS via `Continuation` for multi-branch patterns), `visitSynArgPats`, `visitSynSimplePat(s)`, `visitSynMatchClause`, `visitBinding`, `visitSynBindingReturnInfo`.
- `type Continuations` — CPS list type used by the expression/pattern visitors.
- `collectFromOption` — map-or-empty helper.
- `visitIdentAsPotentialModuleName` — yields `FileContentEntry.ModuleName` for single-ident references (e.g. `nameof Foo`).

**Active patterns / internal types**:
- `let inline (|NameofIdent|_|) (ident: Ident)` — matches the special `` nameof `` identifier.
- `type NameofResult = SingleIdent of Ident | LongIdent of LongIdent` (internal) + `visitNameofResult` — handles `nameof Module` as a potential module reference.
- `let (|NameofPat|_|) (pat: SynPat)` (return struct) — special-cases the `nameof Module ->` pattern form, unwrapping parentheses and extracting the single or long identifier.

**Significant internal logic**:
- Open statements become `OpenStatement` entries; `open` of a *type* (generic argument) instead contributes the type's references — an important distinction for dependency tracking.
- Nested modules produce explicit `NestedModule(name, content)` entries so that `open` statements can be scoped to the enclosing module during state folding in `DependencyResolution.processStateEntry`.
- Multi-part identifiers contribute `PrefixedIdentifier` paths (all but the last segment); single identifiers in `nameof` positions contribute `ModuleName` entries, enabling `let x = nameof Foo` to create a dependency.
- Deep syntax (patterns, tuples, records, lists) is traversed in CPS using `Continuation.concatenate` to avoid stack overflow on pathological inputs.

**Cross-references**:
- Types: `FileContentEntry`, `LongIdentifier`, `FileInProject` from `Types.fs`.
- CPS helper: `Continuation.fs` / `Continuation.fsi`.
- Consumer: `DependencyResolution.fs` (`processStateEntry`, `mkGraph`).
- Uses `FSharp.Compiler.SyntaxTreeOps` (attribute lookup) and syntax types from `FSharp.Compiler.Syntax`.
