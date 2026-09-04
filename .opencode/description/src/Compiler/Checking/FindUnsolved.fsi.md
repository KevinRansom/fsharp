# FindUnsolved.fsi

**Purpose**: Public contract for the end-of-file unsolved-inference-variable scan. A single entry point, used after type inference for an entire file, to collect any `Typar`s that remain unsolved.

**Namespace(s)**: `module internal FSharp.Compiler.FindUnsolved`

**Public API surface** (val contracts):
- `UnsolvedTyparsOfModuleDef : g: TcGlobals -> amap: ImportMap -> denv: DisplayEnv -> mdef: ModuleOrNamespaceContents -> extraAttribs: Attrib list -> Typar list`
  — find all unsolved inference variables after type inference for an entire file; walks the `ModuleOrNamespaceContents` plus any extra attributes and returns the collected typars.

**Implementation-only (in the .fs)**: the local `env`/`cenv` ADTs and the recursive traversals `accExpr` and `accModuleOrNamespaceDefs` are not part of the contract.

**Cross-references**: `FindUnsolved.fs` (implementation), `TypedTree` (`ModuleOrNamespaceContents`, `Typar`), `TcGlobals`, `import.fsi` (`ImportMap`), `CheckDeclarations.fs` (driver context).
