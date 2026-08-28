# QuotationTranslator.fsi

**Purpose**
Public contract for converting quoted TAST data structures into the pickled forms ready for quotation
serialization. Exposes the quotation generation scope (which accumulates referenced type definitions and
type/expression splices), the public conversion entry points, the serialization-format capability flags,
and the active patterns used to recognize specific compiler-generated expression shapes during translation.

**Namespace(s)**
`module internal FSharp.Compiler.QuotationTranslator`

**Modules / Types declared**
- `InvalidQuotedTerm of exn` — exception.
- `IgnoringPartOfQuotedTermWarning of string * range` — warning-level exception.
- `IsReflectedDefinition` (`[RequireQualifiedAccess]`) — `Yes | No`.
- `QuotationSerializationFormat` — record `{ SupportsWitnesses: bool; SupportsDeserializeEx: bool }` (witness parameters recorded; type references emitted as integer indexes into a supplied table).
- `QuotationGenerationScope` (`[Sealed]`) — `static member Create: TcGlobals -> ImportMap -> CcuThunk -> ConstraintSolver.TcValF -> IsReflectedDefinition -> QuotationGenerationScope`; `member Close: unit -> ILTypeRef list * (TType * range) list * (Expr * range) list` (referenced type defs, type splices, expression splices); `static member ComputeQuotationFormat: TcGlobals -> QuotationSerializationFormat`.

**Public API surface**
- `ConvExprPublic: QuotationGenerationScope -> bool (suppressWitnesses) -> Expr -> QuotationPickler.ExprData` — convert a TAST expression to pickled form.
- `ConvReflectedDefinition: QuotationGenerationScope -> string -> Val -> Expr -> QuotationPickler.MethodBaseData * QuotationPickler.ExprData` — convert a `[<ReflectedDefinition>]` value+body.
- Active patterns (`[<return: Struct>]`):
  - `(|ModuleValueOrMemberUse|_|): TcGlobals -> Expr -> (ValRef * ValUseFlag * Expr * TType * TypeInst * Expr list) voption` — recognize a value/module-member use.
  - `(|SimpleArrayLoopUpperBound|_|): Expr -> unit voption`.
  - `(|SimpleArrayLoopBody|_|): TcGlobals -> Expr -> (Expr * TType * Expr) voption`.
  - `(|ObjectInitializationCheck|_|): TcGlobals -> Expr -> unit voption`.

**Significant notes**
- The scope accumulates state (type-def references, type splices, expression splices) during conversion
  and `Close` flushes it; callers (e.g. `TcExprQuote`/`TcExprReflectedDefinition` paths in
  `CheckExpressions.fs`) build a scope, convert, then close to obtain the splice tables that travel with
  the pickled quotation.
- `ComputeQuotationFormat` is how the checker detects runtime capabilities (witnesses, DeserializeEx) so
  the emitted form stays compatible with the runtime FSharp.Core.

**Cross-references**
- `QuotationTranslator.fs` — implementation (translation env, splices, witness handling, `ConvMethodBase`).
- `QuotationPickler.fs` (Optimize dir) — `ExprData`, `MethodBaseData` target types.
- `ConstraintSolver.fsi` (sibling) — `TcValF` type in the scope signature.
- `PostInferenceChecks.fsi` — shares the same `TcValF`/`CcuThunk` parameter thread.
