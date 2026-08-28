# TypedTreeOps.Transforms.fs

**Purpose**: "Defines derived expression manipulation and construction functions" — a large library of typed-tree *transformations* (rewritings) and *analyses* (nullness, type-tests, patterns). Auto-opens a set of support modules and provides the high-level transformation functions used by the checker and by codegen. Modules include `XmlDocSignatures` (XmlDoc signature rendering), `NullnessAnalysis` (nullness inference), `TypeTestsAndPatterns` (type-predicates and deconstruction), `Rewriting` (the main rewriting workhorse — `Rewrite*`/`rewrite` over exprs, val, tycon, etc.), `TupleCompilation` (tuple compilation), `ConstantEvaluation` (constant folding / `TryConstantFold*`), `ResumableCodePatterns` (resumable state machine patterns), and `SeqExprPatterns` (seq-expression patterns).

**Namespace(s)**: `FSharp.Compiler.TypedTreeOps`.

**Modules declared** (internal; see .fsi for the contract):
- `XmlDocSignatures` (`[<AutoOpen>]`) — XmlDoc signature rendering: `commaEnc`, `angleEnc`, `ticksAndArgCountTextOfTyconRef`, `typarEnc`, `buildAccessPath`, `XmlDocArgsEnc`, `XmlDocSigOf{Val,UnionCase,Field,Property,Tycon,SubModul,Entity}`, plus extension members on `ActivePatternElemRef` (`LogicalName`, `DisplayNameCore`, `DisplayName`), `TryGetActivePatternInfo`, `mkChoiceCaseRef`, and extension members on `PrettyNaming.ActivePatternInfo` (`DisplayNameCoreByIdx`, `DisplayNameByIdx`, `ResultType`).
- `NullnessAnalysis` — nullness inference and analysis.
- `TypeTestsAndPatterns` — type-predicates and deconstruction (the `is*Ty`, `dest*Ty`, `strip*Ty`, `try*Ty`, `eval*` families — see `.fsi` for the full list).
- `Rewriting` — the main rewriting workhorse (see `.fsi` for the exported functions).
- `TupleCompilation` — tuple compilation helpers.
- `ConstantEvaluation` — constant folding / `TryConstantFold*`.
- `ResumableCodePatterns` — resumable state-machine pattern analysis.
- `SeqExprPatterns` — seq-expression patterns.

**Significant internal logic**: The `Rewriting` module is the workhorse of expression transformation — it walks/rewrites a typed tree applying a set of "rewrites" (e.g. inline a val, substitute typars, fold constants, etc.). `TupleCompilation` rewrites tuples (e.g. into compiled-tuple types). `ConstantEvaluation` does constant folding of expressions. The `SeqExprPatterns` / `ResumableCodePatterns` modules provide the pattern-matching used by the `seq`/`use`/`async` desugaring. `XmlDocSignatures` is the rendering used by the F# documentation generator (XmlDoc) to produce `<member>` signatures.

**Cross-references**: `TypedTreeOps.Makers` (construction), `TypedTreeOps.Remap.fsi` (for `Remap`), `TypedTreeBasics.fsi`, `TcGlobals.fs`, `PrettyNaming` (XmlDoc), `Checker.fs` (consumer), `IlxGen.fs` (consumer), the F# documentation generator (XmlDoc consumer).
