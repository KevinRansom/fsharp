# SemanticClassification.fs

**Purpose**: Computes token-level "semantic classification" from the captured name-resolution results (`TcResolutions`) of a type-checked file: for each captured `Item` occurrence, classify the text range by the semantic kind (value, function, type, union case, member, disposable, ...). This powers rich editor syntax highlighting that is more precise than lexical colorization.

**Namespace(s)**: `FSharp.Compiler.EditorServices`

## Types / Modules declared

- **`SemanticClassificationType`** (union with literal discriminants 0–36) — the classification vocabulary: `ReferenceType`…`Plaintext` (e.g. `Function`, `Property`, `Module`, `Namespace`, `ComputationExpression`, `Operator`, `Method`, `ExtensionMethod`, `RecordField`, `Exception`, `Delegate`, `NamedArgument`, `LocalValue`, `TypeDef`, `Plaintext`).
- **`SemanticClassificationItem`** (struct) — `{ Range: range; Type: SemanticClassificationType }`.
- **`module TcResolutionsExtensions`** (AutoOpen)
  - `(|CNR|)` active pattern — unfolds `CapturedNameResolution` into `(Item, ItemOccurrence, DisplayEnv, NameResolutionEnv, AccessorDomain, range)`.
  - `isDisposableTy`/`isValRefDisposable` (+ similar small checks) — detect `IDisposable` in the type hierarchy (guarded by `protectAssemblyExplorationNoReraise`).
  - `isDiscard` — name starts with `_`.
  - Extension member `TcResolutions.GetSemanticClassification(g, amap, formatSpecifierLocations, range option, ?relatedSymbolKinds) : SemanticClassificationItem[]` — the main entry: walks captured resolutions, classifies each `Item`+`ItemOccurrence` (definitions vs uses, local vs global, attribute/printf/computation-expression special cases, format specifiers), optionally filtered to a range / `RelatedSymbolUseKind`.

## Public API surface

- `SemanticClassificationType` (with stable integer discriminants, so clients can map to theme colors), `SemanticClassificationItem`, and `GetSemanticClassification` (reached via `FSharpCheckFileResults.GetSemanticClassification` in `FSharpCheckerResults.fs`, and via the background path in `BackgroundCompiler.fs`).

## Internal helpers / active patterns

- `(|CNR|)` — the canonical projection of a captured resolution used throughout the classifier.
- Hierarchy probing via `TypeHierarchy` (`ExistsHeadTypeInEntireHierarchy`) for `IDisposable` detection; `AccessibilityLogic` for private-to-file distinctions; `PrettyNaming` for display-name decisions.
- Local classification helpers per `Item` kind (value/function/type/union-case/field/record-field/member/parameter/namespace/module, attribute applications, computation-expression builders/operations, `printf` format strings using `formatSpecifierLocations`).

## Significant internal logic

- Classification is *definition-aware*: the same `Item` at its definition site is classified differently (e.g. `TypeDef` vs `Type`, `Function` definition vs call) than at use sites — driven by `ItemOccurrence`/`AccessorDomain`.
- `Plaintext` is the fallback for ranges that resolve to nothing meaningful (operators in some contexts, discarded names, etc.).
- Format specifiers are classified from the pre-computed `formatSpecifierLocations` (range + arity, see `FSharpCheckFileResults.GetFormatSpecifierLocationsAndArity`) rather than re-scanning strings.
- Assembly exploration for `IDisposable` is exception-guarded so a broken reference can't crash coloring.

## Cross-references

- Contract: `SemanticClassification.fsi`.
- Consumed by: `FSharpCheckerResults.GetSemanticClassification` (foreground), `BackgroundCompiler.GetSemanticClassificationForFile` (background), which returns a `SemanticClassificationView` backed by `SemanticClassificationKey.fs` stores; exposed to clients via `FSharpChecker.GetBackgroundSemanticClassificationForFile` (see `service.fsi`) and `FSharpWorkspaceQuery.GetSemanticClassification`.
- Symbol/item vocabulary from `FSharp.Compiler.Infos`, `FSharp.Compiler.NameResolution` (`CapturedNameResolution`, `Item`, `ItemOccurrence`), `FSharpCompiler.Import` (`ImportMap`, `TcGlobals`).
