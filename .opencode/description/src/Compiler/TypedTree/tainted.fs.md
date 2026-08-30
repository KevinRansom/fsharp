# tainted.fs

## Pipeline role

This file belongs to the TypedTree folder of the F# compiler. It implements `tainted.fsi`'s type-provider "tainting" mechanism: `Tainted<'T>` wraps a value produced by a type provider together with the provider context (`ITypeProvider`, its `ILScopeRef`, and a per-provider lock), so that *any* failure of a provider call can be attributed back to that specific provider, with a source range, through the `TypeProviderError` exception type. All provider interaction during type checking goes through these `PApply*`/`PUntaint*` combinators; in particular `PApplyArray` additionally guards against the provider returning `null`, and `Protect` translates raw exceptions (including wrapped `AggregateException`s) into `TypeProviderError`. The whole file is compiled only `#if !NO_TYPEPROVIDERS`.

## Headers, namespace, opens

- Copyright header (Microsoft, `License.txt`).
- `namespace FSharp.Compiler` under `#if !NO_TYPEPROVIDERS`.
- Opens `System`, `Internal.Utilities.Library` (for `Lock`/`LockToken`), `FSharp.Core.CompilerServices` (for `ITypeProvider`), `FSharp.Compiler.AbstractIL.IL` (for `ILScopeRef`), `FSharp.Compiler.Text`/`FSharp.Compiler.Text.Range` (for `range`, `range0`).

## Lock plumbing

- `[<Sealed>] type internal TypeProviderToken() = interface LockToken` — the token type for the per-provider lock.
- `[<Sealed>] type internal TypeProviderLock() = inherit Lock<TypeProviderToken>()`.

## `type internal TypeProviderError`

Exception type carrying `(errNum, tpDesignation, range, RichText list, typeNameContext option, methodNameContext option)`:

- Constructors: the full one; `new((errNum, msg), tpDesignation, m)` (single error); `new(errNum, tpDesignation, m, messages: seq<RichText>)`.
- `Number`; `Range`; 
- `RichMessage` — a single text, or the merged text of all errors (`RichText.concatWith` newlines) imitating old behavior.
- `override Message` — `this.RichMessage.Text`.
- `MapText(f, tpDesignation, m)` — maps every error's text through `f` (returning `(errNum, RichText)`), rebuilding a new `TypeProviderError`.
- `WithContext(typeNameContext, methodNameContext)` — wraps so messages gain the context prefix.
- `ContextualErrorRichMessage` / `ContextualErrorMessage` — with context: `Type Provider 'TP' has reported the error in method M of type T: MSG` (via `FSComp.SR.etProviderErrorWithContext`); without: `… has reported the error: MSG` (`etProviderError`).
- `Iter f` — uniformly handles plain and composite instances: single error → `f this`; multiple → `f` per-error `TypeProviderError` (same context).

## `type TaintedContext`

Record `{ TypeProvider: ITypeProvider; TypeProviderAssemblyRef: ILScopeRef; Lock: TypeProviderLock }`.

## `type internal Tainted<'T>`

`[<NoEquality>][<NoComparison>]` wrapper `(context, value)`; constructor asserts the provider is non-null.

- `TypeProviderDesignation` — `!! context.TypeProvider.GetType().FullName`.
- `TypeProviderAssemblyRef`.
- `member Protect f (range)` — the core protection: `context.Lock.AcquireLock(fun _ -> f value)`; `TypeProviderError` re-raised; `AggregateException` → wrapped `TypeProviderError(false, errNum 21, designation, range, messages)` (for each inner exception, base-exception message); other exceptions → single-message `TypeProviderError`. Messages use the innermost/base exception message (`if isNull e.InnerException then e.Message else e.Message + ": " + e.GetBaseException().Message`).
- `member TypeProvider` — a `Tainted<_>` around `context.TypeProvider`.
- `PApply(f, range)` — `Protect`, returns `Tainted(context, u)`.
- `PApply2/3/4(f, range)` — `Protect` and produce 2/3/4 tainted values.
- `PApplyNoFailure f = PApply(f, range0)`.
- `PApplyWithProvider(f, range)` — passes `(value, context.TypeProvider)` to `f`.
- `PApplyArray(f, methodName, range)` — `Protect`; `null` array → `TypeProviderError` with `FSComp.SR.etProviderReturnedNull(RichText.mkMethod methodName)`; else maps to tainted values.
- `PApplyFilteredArray(factory, filter, methodName, range)` — same but filters.
- `PApplyOption(f, range)` — `None`/`Some (Tainted …)`.
- `PUntaint(f, range)` — `Protect`, returns the raw result.
- `PUntaintNoFailure f` — `PUntaint(f, range0)` (requires `f` not to raise).
- `AccessObjectDirectly` — direct access, "use with extreme caution".
- `static member CreateAll(providerSpecs: (ITypeProvider * ILScopeRef) list)` — one `Tainted<_>` per provider, each with a fresh `TypeProviderLock`.
- `OfType<'U>()` — `Some (Tainted …)` when `value` is a `'U`, else `None`.
- `Coerce<'U> (range)` — type-test coercion under protection.

## `module internal Tainted`

Helper module (the `.fsi` marks it `[<RequireQualifiedAccess>]`; the `.fs` does not):

- `(|Null|NonNull|)` — over `Tainted<'T | null>` (with `'T: not null, not struct`): null-check via `PUntaintNoFailure isNull`.
- `Eq p v` — `p.PUntaintNoFailure (fun pv -> pv = v)`.
- `EqTainted t1 t2` — reference equality (`===`) of the raw values.
- `GetHashCodeTainted t` — `t.PUntaintNoFailure hash`.

## Relation to the signature

The `.fs` implements exactly the `.fsi` surface; notable differences: the `.fs` module `Tainted` is not `[<RequireQualifiedAccess>]`, the `.fsi` declares `Tainted`.`TypeProvider` as `TaintedTypeProvider`, and the `.fsi` adds `[<Class>]`/internal access modifiers. The `.fs` additionally documents `TaintedContext` (not in the `.fsi`'s declared list) and the `Protect` internals.