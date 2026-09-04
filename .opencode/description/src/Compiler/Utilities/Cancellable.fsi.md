# Cancellable.fsi

**Purpose**: Signature file for `Cancellable.fs` (same directory). Documents the public contract of the compiler's synchronous cancellation support, spanning two namespaces: `FSharp.Compiler` (ambient token holder) and `Internal.Utilities.Library` (the `Cancellable<'T>` computation expression).

**Namespace(s)** declared: `FSharp.Compiler` (top-level, `Cancellable` type) and `Internal.Utilities.Library` (the `Cancellable<'T>` computation expression and builder).

**Declared items** (public contract):
- In `namespace FSharp.Compiler`:
  - `[<Sealed>] type Cancellable` — `UseToken` (internal), `HasCancellationToken`, `Token`, `CheckAndThrow`, `TryCheckAndThrow`.
- In `namespace Internal.Utilities.Library`:
  - `[<RequireQualifiedAccess; Struct>] type internal ValueOrCancelled<'TResult>` — `Value of 'TResult | Cancelled of OperationCanceledException`.
  - `[<Struct>] type internal Cancellable<'T> = Cancellable of (CancellationToken -> ValueOrCancelled<'T>)`.
  - `module internal Cancellable` — `run`, `fold`, `runWithoutCancellation`, `token`, `toAsync`.
  - `type internal CancellableBuilder` — full computation-expression surface: `Bind`, `BindReturn`, `Combine`, `Delay`, `Return`, `ReturnFrom`, `TryFinally`, `TryWith`, `Using`, `Zero`.
  - `[<AutoOpen>] module internal CancellableAutoOpens` — `val cancellable : CancellableBuilder`.

**Relationship to .fs**: The .fs additionally defines the `AsyncLocal<CancellationToken voption>` storage (`tokenHolder`), the `guard` / `ensureToken` mechanism (which is disabled when the `DISABLE_CHECKANDTHROW_ASSERT` env var is set), and the `[InlineIfLambda]`/`__debugPoint` optimizations used by the builder. No other public types are declared in either file.

**Cross-references**: see sibling `Cancellable.md` for behavioral notes (cancellation-as-data, ambient `AsyncLocal`, `ToAsync` bridging).
