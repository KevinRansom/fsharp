# RelatedSymbolUse.fs

**Purpose**
Declares the `RelatedSymbolUseKind` flags type used by the name-resolution results plumbing (see
`NameResolution.fs` / `ITypecheckResultsSink.NotifyRelatedSymbolUse`) to classify symbols that are
*related* to a name resolution but are not the direct resolution result — e.g. the union case behind a
tester property (`.IsCaseA` → `CaseA`) or the record type behind a copy-and-update expression
(`{ r with ... }` → `RecordType`). These are reported via a separate sink so they don't corrupt colorization
or symbol info.

**Namespace(s)**
`namespace FSharp.Compiler.CodeAnalysis`

**Modules / Types declared**
- `RelatedSymbolUseKind` (`[System.Flags]`) — `None = 0` (no related symbols), `UnionCaseTester = 1` (union case via tester property), `CopyAndUpdateRecord = 2` (record type via copy-and-update expression), `All = 0x7FFFFFFF` (all related symbol kinds).

**Public API surface**
- The single flag enum `RelatedSymbolUseKind`; used as the `kind` argument of `NotifyRelatedSymbolUse : range * Item * RelatedSymbolUseKind -> unit` and as the filter parameter of `TcSymbolUses.GetUsesOfSymbol : Item * ?relatedSymbolUseKind -> TcSymbolUseData[]` (see `NameResolution.fsi`).

**Significant notes**
- This is a flags enum, so a single related-symbol-use report may carry multiple kinds (e.g. a copy-and-update
  that also goes through a union tester in an edge case could in principle combine `UnionCaseTester ||
  CopyAndUpdateRecord`), and `All` serves as the "match any" filter.
- The distinction from regular `NotifyNameResolution` is deliberate: related symbol uses should not affect
  colorization or primary symbol info in the language service — they are auxiliary hints only.

**Cross-references**
- `NameResolution.fs` / `NameResolution.fsi` — `CallRelatedSymbolSink`, `NotifyRelatedSymbolUse`,
  `TcResolutions.CapturedRelatedSymbolUses`, `TcSymbolUses.GetUsesOfSymbol` all consume this type.
- `CheckExpressions(fs).fs` (Expressions dir) and `CheckPatterns.fs` (sibling) — call sites that report
  union-case-tester and copy-and-update related uses.
