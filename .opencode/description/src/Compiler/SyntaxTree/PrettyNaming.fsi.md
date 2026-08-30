# PrettyNaming.fsi

**Purpose**: Public F# contract for `FSharp.Compiler.Syntax.PrettyNaming` — the canonical module for F# name mangling, demangling, and classification. Declares the full surface of the identifier/operator/active-pattern/classification helpers, the mangled-name constants used by the IL layer, the generic-name and provided-type mangle/demangle API, the `ActivePatternInfo` type, and the `CustomOperations` submodule. This .fsi is the contract consumed by FSharp.Core, the compiler, the F# service, FSI, and tooling.

**Namespace(s)**: `FSharp.Compiler.Syntax` (module `public FSharp.Compiler.Syntax.PrettyNaming`)

**Modules / Types declared** (public contract):
- `parenGet`, `parenSet`, `qmark`, `qmarkSet`, `opNamePrefix` — name literals
- `ActivePatternInfo` — `APInfo of bool * (string * range) list * range` with `ActiveTags`, `ActiveTagsWithRanges`, `LogicalName`, `IsTotal`, `Range` members
- `NameArityPair` — `NameArityPair of string * int`
- `CustomOperations` module (qualified access) — `Into : string = "into"`
- `InvalidMangledStaticArg` exception
- Literals: `FSharpModuleSuffix` (`"Module"`), `MangledGlobalName` (`` "`global`" ``), `unionCaseTesterPropertyPrefix` (`"get_Is"`), `unionCaseTesterPropertyPrefixLength` (`6`), `suffixForVariablesThatMayNotBeEliminated` (`"$cont"`), `suffixForTupleElementAssignmentTarget` (`"$tupleElem"`), `stackVarPrefix` (`"__stack_"`), `FsiDynamicModulePrefix`, `FSharpOptimizationDataResourceName*`, `FSharpSignatureDataResourceName*` (with `*B`, `*Compressed*`, `*2` variants), `IllegalCharactersInTypeAndNamespaceNames`, `unassignedTyparName`, `keywordsWithDescription`

**Public API surface** (the .fsi lists them all; notable ones):
- **Identification / classification**: `IsIdentifierName`, `IsActivePatternName`, `IsOperatorDisplayName`, `IsLogicalOpName`, `IsLogicalPrefixOperator`, `IsLogicalInfixOpName`, `IsLogicalTernaryOperator`, `IsPunctuation`, `IsIdentifierFirstCharacter`, `IsIdentifierPartCharacter`, `IsLongIdentifierPartCharacter`
- **Operator mangle / demangle**: `CompileOpName`, `ConvertValLogicalNameToDisplayNameCore`, `ConvertLogicalNameToDisplayName`, `ConvertValLogicalNameToDisplayName`, `ConvertLogicalNameToDisplayLayout`, `ConvertValLogicalNameToDisplayLayout`
- **Backticks**: `DoesIdentifierNeedBackticks`, `NormalizeIdentifierBackticks`
- **Compiler-generated names**: `IsCompilerGeneratedName`, `CompilerGeneratedName`, `GetBasicNameOfPossibleCompilerGeneratedName`, `CompilerGeneratedNameSuffix`
- **Generic names**: `TryDemangleGenericNameAndPos`, `DemangleGenericTypeNameWithPos`, `DecodeGenericTypeNameWithPos`, `DemangleGenericTypeName`, `DecodeGenericTypeName`
- **Property / path handling**: `TryChopPropertyName`, `ChopPropertyName`, `SplitNamesForILPath`, `IsUnionCaseTesterPropertyName`
- **Provided types**: `DemangleProvidedTypeName`, `MangleProvidedTypeName`, `ComputeMangledNameWithoutDefaultArgValues`
- **Other**: `outArgCompilerGeneratedName`, `ExtraWitnessMethodName`, `mkUnionCaseFieldName`, `mkExceptionFieldName`, `ActivePatternInfoOfValName`, `GetLongNameFromString`, `FormatAndOtherOverloadsString`, `FsiDynamicModulePrefix`, `FSharpOptimizationDataResourceName2`, `FSharpSignatureDataResourceName2`

**Internal helpers / active patterns** (internal to the .fs, not in the .fsi):
- `opNameTable`, `opCharTranslateTable`, `standardOpsDecompile`, `standardOpNames`
- `compileCustomOpName` (memoized), `decompileCustomOpName`
- `isCoreActivePatternName`, `EscapeActivePatternCases`, `AddBackticksToIdentifierIfNeeded`
- `opNameCons`, `opNameNil`, `opNameEquals`, `opNameEqualsNullable`, `opNameNullableEquals`, `opNameNullableEqualsNullable`
- `compilerGeneratedMarker` / `compilerGeneratedMarkerChar` / `mangledGenericTypeNameSym` / `chopStringTo`
- `isTildeOnlyString`, `IsValidPrefixOperatorUse`, `IsValidPrefixOperatorDefinitionName`
- The `(|Control|Equality|Relational|Indexer|FixedTypes|Other|)` active pattern

**Significant internal logic** (contract-level):
- The module is the single place where F#'s operator *display* names and *mangled* (logical) names are reconciled — the IL layer and FSharp.Core depend on the exact strings emitted by `CompileOpName`, so the .fsi exposes those strings as a stable contract.
- `NormalizeIdentifierBackticks` documents the round-trip: add double backticks to non-identifier non-active-pattern names, remove them if unnecessary.
- `CompileOpName` is documented as applicable only to actual operator names; for other names, use `ConvertValLogicalNameToDisplayName*` instead.
- `ActivePatternInfo` exposes the `|A|_|`-style total/non-total active pattern structure with ranges, so the F# service can pretty-print active pattern case names.
- `MangleProvidedTypeName` / `DemangleProvidedTypeName` document the static-parameter encoding for F# type providers.
- `unionCaseTesterPropertyPrefix` documents the synthetic `get_Is<Case>` property shape used by the CLR to expose union case testers; `IsUnionCaseTesterPropertyName` is the predicate.

**Cross-references**: `PrettyNaming.fs` (implementation), `SyntaxTree.fs` (the AST nodes whose `name` fields flow through these functions), `SyntaxTreeOps.fs` (tree walks), `AbstractIL` (consumer of `CompileOpName` and the `opName*` constants), `FSharp.Core` (operator names are fixed by this module's table), service/fsi (consumer of the display-name conversions for signatures and error text).
