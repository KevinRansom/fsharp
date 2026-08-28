# tainted.fsi

**Purpose**: Compilation interface for the type-provider tainting mechanism. Declares `TypeProviderToken`, `TypeProviderLock`, the `TypeProviderError` exception type, the `Tainted<'T>` wrapper type, and the `Tainted` helper module — all so callers can attribute any failure to the specific type provider (with a source range) that caused it. Compiled only `#if !NO_TYPEPROVIDERS`.

**Namespace(s)**: `FSharp.Compiler`.

**Declared types (signatures)**:
- `TypeProviderToken` (`[<Sealed>]`, internal) — `interface LockToken`.
- `TypeProviderLock` (`[<Sealed; Class>]`, internal) — `inherit Lock<TypeProviderToken>`.
- `TypeProviderError : System.Exception` (internal) — constructors `new: (int * RichText) * string * range` (single error) and `new: int * string * range * seq<RichText>` (aggregated errors); members `Number: int`, `Range: range`, `RichMessage: RichText`, `ContextualErrorRichMessage: RichText`, `ContextualErrorMessage: string`, `WithContext: string * string -> TypeProviderError`, `MapText: (RichText -> int * RichText) * string * range -> TypeProviderError`, `Iter: (TypeProviderError -> unit) -> unit`.
- `Tainted<'T>` (`[<NoEquality; NoComparison; Class>]`, internal) — "wraps a value produced by a type provider to properly attribute any failures"; members `TaintedTypeProvider: Tainted<ITypeProvider>` (in .fs: `TypeProvider`), `TypeProviderDesignation: string`, `TypeProviderAssemblyRef: ILScopeRef`, `PApply`, `PApply2`, `PApply3`, `PApply4`, `PApplyNoFailure`, `PApplyWithProvider`, `PApplyArray`, `PApplyFilteredArray`, `PApplyOption`, `PUntaint`, `PUntaintNoFailure`, `OfType<'U>: unit -> Tainted<'U> option`, `Coerce<'U>: range -> Tainted<'U>`, `static member CreateAll: (ITypeProvider * ILScopeRef) list -> Tainted<ITypeProvider> list`.
- `module Tainted` (`[<RequireQualifiedAccess>]` internal in the .fsi) — `(|Null|NonNull|)` active pattern (`'T: not null and 'T: not struct`), `Eq`, `EqTainted`, `GetHashCodeTainted`.

**Contract notes**: The .fsi marks the `Tainted` module `[<RequireQualifiedAccess>]` (the .fs does not), and types constructors as `[<Class>]`; `PApply*` guarantees "any exception will be attributed to the type provider with an error located at the given range"; `PUntaintNoFailure` requires 'f' cannot raise.

**Cross-references**: `tainted.fs` (implementation), `TypeProviders.fs` (main consumer), `FSharp.Core.CompilerServices.ITypeProvider`, `Internal.Utilities.Library` (`Lock`, `LockToken`).
