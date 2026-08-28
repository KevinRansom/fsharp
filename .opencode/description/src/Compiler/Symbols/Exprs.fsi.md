# Exprs.fsi

**Purpose**
Public contract for surfacing the *definitional contents* of an assembly and of checked (TAST)
expressions through the compiler API. Given implementation files (`CheckedImplFile`s), tooling can
enumerate the top-level declarations and decompose function bodies into a language-level expression
tree (`FSharpExpr`) analyzed via the `FSharpExprPatterns` active patterns — i.e., "uncompiled"
presentation of what the compiler knows, as used by scripting/reflection and FCS.

**Namespace(s)**
`namespace rec FSharp.Compiler.Symbols` (rec to cross-reference `Symbols.fsi`)

**Modules / Types declared**
- `FSharpAssemblyContents` (class, `internal new: TcGlobals * CcuThunk * ModuleOrNamespaceType option * TcImports * CheckedImplFile list`) — definitional contents of an assembly; `ImplementationFiles: FSharpImplementationFileContents list`.
- `FSharpImplementationFileContents` (class, `internal new: SymbolEnv * CheckedImplFile`) — one implementation file: `QualifiedName`, `FileName`, `Declarations`, `IsScript`, `HasExplicitEntryPoint`.
- `FSharpImplementationFileDeclaration` (union, `[RequireQualifiedAccess]`) — `Entity of FSharpEntity * FSharpImplementationFileDeclaration list` | `MemberOrFunctionOrValue of value * curriedArgs * body: FSharpExpr` | `InitAction of action: FSharpExpr`.
- `FSharpExpr` (sealed class) — a checked/reduced expression with `Range`, `Type`, `ImmediateSubExpressions`; intended to be analyzed with the `FSharpExprPatterns` module.
- `FSharpObjectExprOverride` (sealed class) — one method of an object expression: `Signature: FSharpAbstractSignature`, `GenericParameters`, `CurriedParameterGroups`, `Body: FSharpExpr`.
- `module FSharpExprPatterns` — public module of active patterns over `FSharpExpr` (see below).

**Public API surface**
`FSharpExprPatterns` active patterns (each `(|Pattern|_|) : FSharpExpr -> ... option`):
- Value uses & calls: `Value`, `Application`, `Call` (receiver-optional + member + type args + untupled args), `CallWithWitnesses` (also witness args), `NewObject`, `WitnessArg`.
- Abstractions: `TypeLambda`, `Lambda`, `Quote`, `ThisValue`, `BaseValue`.
- Control flow: `IfThenElse`, `DecisionTree`, `DecisionTreeSuccess`, `FastIntegerForLoop`, `WhileLoop`, `TryFinally`, `TryWith`, `DebugPoint`.
- Definitions: `Let` (with `DebugPointAtBinding`), `LetRec`, `Sequential`, `DefaultValue`, `Const`.
- Data: `NewRecord`, `NewAnonRecord`, `AnonRecordGet`, `NewTuple`, `TupleGet`, `NewArray`, `Coerce`, `TypeTest`, `NewDelegate`, `AddressOf`, `AddressSet`, `ValueSet`.
- Union types: `NewUnionCase`, `UnionCaseGet`, `UnionCaseSet`, `UnionCaseTag`, `UnionCaseTest`.
- Records/classes: `FSharpFieldGet`, `FSharpFieldSet`, `ILFieldGet`, `ILFieldSet`.
- Trait/IL: `TraitCall` (unresolved trait call: support types, member name/flags, arg/return types, args), `ILAsm` (string form of IL instruction).

**Internal helpers**
None in the .fsi; constructors are `internal`. Implementation-specific active patterns such as the IL
op recognizers live in the .fs.

**Significant notes**
- `FSharpExpr` nodes are *reduced*: pattern matching is shown as `DecisionTree` nodes rather than
  `match`, and curried/tupled application is collapsed to compiled form (arguments detupled).
- The .fs doc comments state patterns should analyze via this module rather than matching the
  internal tree.
- `FSharpImplementationFileContents.Declarations` is computed on demand (see .fs: `ConvExprOnDemand`).

**Cross-references**
- `Exprs.fs` — implementation of all of the above.
- `Symbols.fsi` — `FSharpEntity`, `FSharpMemberOrFunctionOrValue`, `FSharpType`, `FSharpUnionCase`,
  `FSharpField`, `FSharpAbstractSignature` used throughout.
- `SymbolPatterns.fs` — complementary symbol-level active patterns (vs. expression-level ones here).
