# ServiceErrorResolutionHints

**Purpose:** Legacy stub/compatibility surface in the service layer that re-exposes the compiler's error-resolution hint algorithm (string-distance based "did you mean X?" suggestions) under the `FSharp.Compiler.Diagnostics` namespace. The implementation is effectively empty — it only opens the real `FSharp.Compiler.ErrorResolutionHints` module (AutoOpen), so its members resolve to those of that module at use sites.

**Namespace(s):** `FSharp.Compiler.Diagnostics`

## Declared types / modules
- `ErrorResolutionHints` (module, implementation): the `.fs` body is just `open FSharp.Compiler.ErrorResolutionHints` — an import-only stub.

## Public API surface (per the `.fsi`)
- `ErrorResolutionHints.GetSuggestedNames : (string -> unit) -> string -> seq<string>` — documented as "Given a set of names, uses and a string representing an unresolved identifier, returns a list of suggested names if there are any feasible candidates." The actual implementation comes from the opened `FSharp.Compiler.ErrorResolutionHints` module.

## Internal helpers / notable details
- Note the function shape differs from the newer `CompilerDiagnostics.GetSuggestedNames` in `ServiceCompilerDiagnostics.fsi`: this signature takes the collector function `(string -> unit)` directly rather than the `Suggestions` wrapper type.

## Significant internal logic
- None of its own — depends entirely on `FSharp.Compiler.ErrorResolutionHints` (string-distance / edit-distance matching of close names used when the compiler reports an unresolved identifier).

## Cross-references
- `src/Compiler/ErrorResolutionHints.fsi` (the real module whose members this stub re-exports)
- `src/Compiler/Service/ServiceCompilerDiagnostics.fs` (the modern, documented surface in the same namespace)
