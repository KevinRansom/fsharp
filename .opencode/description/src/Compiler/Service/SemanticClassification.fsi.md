# SemanticClassification.fsi

**Purpose**: Public contract for `SemanticClassification.fs`: the semantic-classification vocabulary (`SemanticClassificationType`, `SemanticClassificationItem`) and the entry point that turns captured name-resolution data into classification items for a file (optionally a subrange).

**Namespace(s)**: `FSharp.Compiler.EditorServices`

## Types declared

- **`SemanticClassificationType`** (union with stable discriminant values 0–36) — "a kind that determines what range in a source's text is semantically classified as after type-checking". Discriminants: `ReferenceType=0`, `ValueType=1`, `UnionCase=2`, `UnionCaseField=3`, `Function=4`, `Property=5`, `MutableVar=6`, `Module=7`, `Namespace=8`, `Printf=9`, `ComputationExpression=10`, `IntrinsicFunction=11`, `Enumeration=12`, `Interface=13`, `TypeArgument=14`, `Operator=15`, `DisposableType=16`, `DisposableTopLevelValue=17`, `DisposableLocalValue=18`, `Method=19`, `ExtensionMethod=20`, `ConstructorForReferenceType=21`, `ConstructorForValueType=22`, `Literal=23`, `RecordField=24`, `MutableRecordField=25`, `RecordFieldAsFunction=26`, `Exception=27`, `Field=28`, `Event=29`, `Delegate=30`, `NamedArgument=31`, `Value=32`, `LocalValue=33`, `Type=34`, `TypeDef=35`, `Plaintext=36`.
- **`SemanticClassificationItem`** (struct) — `Range: range`, `Type: SemanticClassificationType`; `new: (range * SemanticClassificationType) -> SemanticClassificationItem`.
- **`module TcResolutionsExtensions`** (AutoOpen, internal)
  - `val (|CNR|): CapturedNameResolution -> Item * ItemOccurrence * DisplayEnv * NameResolutionEnv * AccessorDomain * range` — the internal projection active pattern.
  - `TcResolutions` extension member `GetSemanticClassification: g * amap * formatSpecifierLocations * range option * ?relatedSymbolKinds -> SemanticClassificationItem[]` — the per-resolution-set classifier.

## Public API surface

- The union, the struct, and (via AutoOpen) `GetSemanticClassification` on `TcResolutions`. Clients in practice reach classification through `FSharpCheckFileResults.GetSemanticClassification` (see `FSharpCheckerResults.fsi`) or the background `SemanticClassificationView` (see `SemanticClassificationKey.fsi`).

## Internal helpers / active patterns

- The `(|CNR|)` pattern and the disposable/discard heuristic helpers live in the `.fs`; only the pattern signature is visible in the fsi.

## Significant internal logic (contract notes)

- Stable integer discriminants matter: external theme/mapping tables key off these numbers, so the order/values are part of the ABI.
- The classifier is defined over `TcResolutions` + `TcGlobals` + `ImportMap` + format-specifier locations — i.e. it runs *after* type checking, per file, and can be restricted to a `range` (for incremental classification of one region) or filtered by `RelatedSymbolUseKind`.

## Cross-references

- Implemented by `SemanticClassification.fs`; called from `FSharpCheckerResults.fs` (foreground) and `BackgroundCompiler.fs`/`TransparentCompiler.fs` (background).
- Results stored/shared via `SemanticClassificationKey.fs` (`SemanticClassificationView`), exposed through `FSharpChecker.GetBackgroundSemanticClassificationForFile` (`service.fsi`) and `FSharpWorkspaceQuery.GetSemanticClassification` (`FSharpWorkspaceQuery.fs`).
- Depends on `FSharp.Compiler.Infos` (`CapturedNameResolution`, `TcResolutions`), `FSharp.Compiler.NameResolution`, `FSharp.Compiler.Import`, `FSharp.Compiler.Text`.
