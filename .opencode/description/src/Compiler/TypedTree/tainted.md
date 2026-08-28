# tainted.fs

**Purpose**: The "tainting" mechanism for type provider interaction. Wraps type-provider objects and all values flowing from them in a `Tainted<'T>` so that every call into user-supplied provider code is executed under the provider's lock and failures are converted into `TypeProviderError`s with provider designation, range, and (optional) type/method context. Everything is compiled only `#if !NO_TYPEPROVIDERS`.

**Namespace(s)**: `FSharp.Compiler`.

**Declared types**:
- `TypeProviderToken` (`[<Sealed>]`, internal) — empty token implementing `LockToken` for provider locking.
- `TypeProviderLock` (`[<Sealed>]`, internal) — `inherit Lock<TypeProviderToken>()`, one per provider instance.
- `TypeProviderError : Exception` — carries `errNum`, `tpDesignation`, `range`, `RichText` error list, and optional `typeNameContext`/`methodNameContext`; members `Number`, `Range`, `RichMessage`, `MapText`, `WithContext`, `ContextualErrorRichMessage`/`ContextualErrorMessage` (prefixes "in method M of type T"), `Iter f` (uniforms plain vs composite errors).
- `TaintedContext` (record) — `{ TypeProvider: ITypeProvider; TypeProviderAssemblyRef: ILScopeRef; Lock: TypeProviderLock }`.
- `Tainted<'T>` (`[<NoEquality>][<NoComparison>]`, internal) — wraps a value with its context; asserts non-null provider in ctor.

**Public/used API surface** (internal to compiler):
- `Tainted` members: `TypeProviderDesignation`, `TypeProviderAssemblyRef`, `Protect f range` (runs `f value` under `Lock.AcquireLock`, converting `AggregateException`/other exceptions to `TypeProviderError`), `PApply`, `PApply2`, `PApply3`, `PApply4` (apply under lock, re-wrap results), `PApplyNoFailure`, `PApplyWithProvider` (passes the provider to `f`), `PApplyArray`/`PApplyFilteredArray` (array results; raises `etProviderReturnedNull` on null), `PApplyOption`, `PUntaint`/`PUntaintNoFailure` (run under lock, return raw value), `AccessObjectDirectly` (raw value, "use with extreme caution"), `static CreateAll(providerSpecs)`, `OfType<'U>()`, `Coerce<'U> range`.
- Module `Tainted` (internal): active pattern `(|Null|NonNull|)` for `Tainted<'T | null>` (reference types), helpers `Eq`, `EqTainted` (reference-equality of wrapped values), `GetHashCodeTainted`.

**Significant internal logic**: Every provider call goes through `Protect`, which takes the provider `Lock` (so reentrant calls serialize per provider) and normalizes arbitrary exceptions — including `AggregateException` inner exceptions — into `TypeProviderError`s with a stable error number from `FSComp.SR.etProviderError`. `PApply*` variants re-wrap each result in the same tainted context so provider data stays tainted throughout unification/type expansion.

**Cross-references**: `tainted.fsi` (contract), `TypeProviders.fs` (main consumer), `FSharp.Core.CompilerServices` (`ITypeProvider`), `AbstractIL` (`ILScopeRef`), `Text/RichText`, `FSComp.SR` (resource strings).
