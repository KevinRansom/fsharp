# FileContentMapping.fsi

**Purpose**: Minimal contract for the file-content extraction step of the graph-checking pipeline: from one `FileInProject` (its `ParsedInput` syntax tree) produce the flat list of `FileContentEntry` constructs that the dependency resolver will fold over.

**Namespace(s)**: `FSharp.Compiler.GraphChecking` (module `internal rec FileContentMapping`)

**Public API surface**:
- `val mkFileContent: f: FileInProject -> FileContentEntry list` — extract the `FileContentEntry` values (top-level namespaces, open statements, prefixed identifiers, nested modules, module names) from the file's parsed syntax.

**Notes**:
- The .fs is a large visitor-based implementation (~750 lines) over `SynModuleDecl` / `SynModuleSigDecl`, types, members, expressions and patterns; all of those visitors plus the `NameofIdent`/`NameofPat` active patterns and the `NameofResult` type are internal to the module and not part of this signature.
- Declared as a recursive module (`rec`) to match how its sibling modules in this folder interact.

**Cross-references**:
- `Types.fs` / `Types.fsi` — `FileContentEntry`, `FileInProject`, `LongIdentifier`.
- `DependencyResolution.fs` — consumes `mkFileContent` inside `mkGraph`.
- `Continuation.fs` — used internally for CPS traversal of deeply nested patterns/expressions.
