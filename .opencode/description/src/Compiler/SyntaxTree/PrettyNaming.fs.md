# PrettyNaming.fs

**Purpose**: Public module (`FSharp.Compiler.Syntax.PrettyNaming`) of F# naming utilities shared across the compiler, the F# service/SDK, FSI, and tooling. It is the single source of truth for: (1) converting between F# operator *display names* (like `+`, `|>`, `..`, `!%`) and the *mangled logical names* the CLR uses (`op_Addition`, `op_PipeRight`, `op_Range`, `op_DereferencePercent`); (2) deciding when a name needs double-backticks and when it does not; (3) classifying names (identifiers, active patterns, operators, compiler-generated names, property accessors, mangled generic names); (4) mangle/demangle of generic type names (`Foo`1`, `Foo``2`) and of provided-type static arguments. Almost every error message and signature in the compiler flows through this module.

**Namespace(s)**: `FSharp.Compiler.Syntax` (module `public FSharp.Compiler.Syntax.PrettyNaming`)

**Modules / Types declared**:
- `opNamePrefix` (`"op_"`), `parenGet` (`".()"`), `parenSet` (`".()<-"`), `qmark` (`"?"`), `qmarkSet` (`"?<-"`) — name literals
- `opNameTable` — display-name → logical-name table for all standard F# operators
- `opCharTranslateTable` — single-char → English word mapping for *custom* operator mangling (`>` → `Greater`, `<` → `Less`, `~` → `Twiddle`, …)
- `standardOpsDecompile` — reverse table (logical → display) for the standard set
- `NameArityPair` type — `NameArityPair of string * int` (demangled name + arity)
- `ActivePatternInfo` — `APInfo of isTotal * (string * range) list * range`; members `ActiveTags`, `ActiveTagsWithRanges`, `LogicalName`, `IsTotal`, `Range`
- `CustomOperations` module (qualified access) — `Into = "into"`
- `InvalidMangledStaticArg` exception
- Active pattern `Control | Equality | Relational | Indexer | FixedTypes | Other` — classifies an operator name
- Literals: `FSharpModuleSuffix` (`"Module"`), `MangledGlobalName` (`"`global`"`), `unionCaseTesterPropertyPrefix` (`"get_Is"`), `suffixForVariablesThatMayNotBeEliminated` (`"$cont"`), `suffixForTupleElementAssignmentTarget` (`"$tupleElem"`), `stackVarPrefix` (`"__stack_"`)
- `keywordsWithDescription` — keyword table (used by completion/quick info)

**Public API surface** (a non-exhaustive selection of the most-used members; the .fsi lists them all):
- **Identity / classification**:
  - `IsIdentifierName : string -> bool`
  - `IsActivePatternName : string -> bool`
  - `IsOperatorDisplayName : string -> bool`
  - `IsLogicalOpName : string -> bool`
  - `IsLogicalPrefixOperator`, `IsLogicalInfixOpName`, `IsLogicalTernaryOperator`
  - `IsPunctuation : string -> bool`
  - `IsIdentifierFirstCharacter`, `IsIdentifierPartCharacter`, `IsLongIdentifierPartCharacter`
- **Mangle / unmangle operators**:
  - `CompileOpName : string -> string` (display → logical, e.g. `+` → `op_Addition`)
  - `ConvertValLogicalNameToDisplayNameCore : string -> string` (logical → display, stripping `op_*`)
  - `ConvertLogicalNameToDisplayName`, `ConvertValLogicalNameToDisplayName` — display with double-backticks / parens as appropriate
  - `ConvertLogicalNameToDisplayLayout`, `ConvertValLogicalNameToDisplayLayout` — produce a `Layout` (for pretty printers)
- **Backticks**:
  - `DoesIdentifierNeedBackticks : string -> bool`
  - `NormalizeIdentifierBackticks : string -> string`
- **Compiler-generated names**:
  - `IsCompilerGeneratedName : string -> bool` (looks for `@`)
  - `CompilerGeneratedName`, `GetBasicNameOfPossibleCompilerGeneratedName`, `CompilerGeneratedNameSuffix`
- **Generic name demangling**:
  - `DemangleGenericNameAndPos`, `DemangleGenericTypeNameWithPos`, `DecodeGenericTypeNameWithPos`, `DemangleGenericTypeName`, `DecodeGenericTypeName`
- **Property name chomping / splitting**:
  - `TryChopPropertyName`, `ChopPropertyName` (strip `get_`/`set_`)
  - `SplitNamesForILPath`
- **Static-parameter mangling (provided types)**:
  - `DemangleProvidedTypeName`, `MangleProvidedTypeName`, `ComputeMangledNameWithoutDefaultArgValues`
- **Other public surface**:
  - `FsiDynamicModulePrefix`, `outArgCompilerGeneratedName`, `ExtraWitnessMethodName`
  - `mkUnionCaseFieldName`, `mkExceptionFieldName` (reused field-name generation for union cases / exceptions)
  - `IsUnionCaseTesterPropertyName` (matches `get_Is*` — used for union case testers)
  - `ActivePatternInfoOfValName`
  - `GetLongNameFromString`, `FormatAndOtherOverloadsString`
  - `FSharpOptimizationDataResourceName` / `FSharpSignatureDataResourceName` (+ `*B` / `*Compressed*` / `*2` variants)
  - `IllegalCharactersInTypeAndNamespaceNames`
- **Internal** (not part of the FSharp.Core surface): the operator tables, the mangle/unmangle closures, the active pattern `(|Control|Equality|Relational|Indexer|FixedTypes|Other|)`, `isTildeOnlyString`, `IsValidPrefixOperatorUse`, `IsValidPrefixOperatorDefinitionName`, `compilerGeneratedMarker` / `compilerGeneratedMarkerChar`, `mangledGenericTypeNameSym`, `chopStringTo`, `CompileCustomOpName`-style helpers, `opNameCons`/`opNameNil`/`opNameEquals`/`opNameEqualsNullable`/`opNameNullableEquals`/`opNameNullableEqualsNullable`, `unassignedTyparName`, `FSharpOptimizationDataResourceName2`, `FSharpSignatureDataResourceName2`.

**Internal helpers / notable closures**:
- `opNameTable`, `opCharTranslateTable`, `standardOpsDecompile` — the three core tables
- `compileCustomOpName` — memoized (`ConcurrentDictionary`) mangle of *custom* operators (e.g. `|>%` → `op_BarPercent`), using `opCharTranslateTable` and a `StringBuilder` sized with `maxOperatorNameLength` to avoid reallocation
- `decompileCustomOpName` — the inverse walk over `standardOpsDecompile` + the `opCharTranslateTable` inverse
- `standardOpNames` — the `opNameTable` wrapped in a `Dictionary` for O(1) lookup
- `isCoreActivePatternName` — recursive recognizer for `|A|B|_|`-style names (with a `seenNonOpChar` flag to reject empty operator parts)
- `EscapeActivePatternCases` — escape-case-name pass that re-quotes active pattern tags as needed (`A` → `A`, `op_Addition` case → backticked, etc.)
- `(|Control|Equality|Relational|Indexer|FixedTypes|Other|)` — operator-class partition for the pretty printer and diagnostics
- `TryDemangleGenericNameAndPos` / `DecodeGenericTypeNameWithPos` — find the `` ` `` separator in mangled names like `Foo``3` and split name/arity

**Significant internal logic**:
- **Operator mangling rules** (per F# spec): built-in operators go through `opNameTable` (e.g. `+` → `op_Addition`, `|>` → `op_PipeRight`, `..` → `op_Range`, `.()` → `op_ArrayLookup`); custom operators are mangled char-by-char through `compileCustomOpName` (e.g. `|>%` → `op_BarPercent`, `~#` → `op_TwiddleHash`); the demangler reverses either path via `ConvertValLogicalNameToDisplayNameCore`.
- **Backtick rules**: `DoesIdentifierNeedBackticks` is true for any name that is not a valid F# identifier and is not an active-pattern name; `NormalizeIdentifierBackticks` adds or removes double backticks accordingly, and is the one function used by the quickfix "add `_` to make valid identifier".
- **Compiler-generated names** carry the `@` marker (`compilerGeneratedMarker`); `CompilerGeneratedName` prepends it, `IsCompilerGeneratedName` tests it, `CompilerGeneratedNameSuffix(basicName, suffix)` produces `basicName@suffix` (used for `@`-suffixed synthetic members).
- **Generic arity**: `DemangleGenericTypeNameWithPos`/`DecodeGenericTypeName*` handle `` ` `` separators to recover `Name` and arity `int`; `TryDemangleGenericNameAndPos` returns a `voption` of the position.
- **Provided-type statics**: `MangleProvidedTypeName(typeLogicalName, nonDefaultArgs)` / `DemangleProvidedTypeName` round-trip the static-parameter encoding used by F# type providers.
- **Union case testers**: `IsUnionCaseTesterPropertyName` recognizes the `get_Is<Case>` shape (with `unionCaseTesterPropertyPrefix = "get_Is"` and `unionCaseTesterPropertyPrefixLength = 6`) — used so the F# signature does not re-expose these synthetic properties.
- **Keyword table** (`keywordsWithDescription`) drives IntelliSense keyword completion and the F# signature data.
- The `opName*` constants (`opNameCons`, `opNameNil`, `opNameEquals`, …) are the *mangled* names for the most common operators and are shared with the IL layer so the F# compiler can emit/recognize them without recomputing.

**Cross-references**: `PrettyNaming.fsi` (public contract), `SyntaxTree.fs` (identifier/operator nodes in `SynVal`, `SynType`, etc. whose `name` fields pass through these functions), `SyntaxTreeOps.fs` (tree walks that need the demangled names), `AbstractIL` (consumes `CompileOpName` / `opName*` constants), `service.fs` / FSI (consumes the display-name conversions for signature and error text), `FSharp.Core` (operator names are fixed by this table — changing it breaks IL compatibility).
