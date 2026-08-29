# resumable.fsi

## Overview

Signature file (namespace `Microsoft.FSharp.Core.CompilerServices`) declaring the public API for **resumable code and struct state machines**, the run-time support underlying compiler-generated state machines (e.g. `task { }`). It documents the reflective `ResumableStateMachine<'Data>` template, the `ResumableCode` composition module, the `StateMachineHelpers` intrinsics, and the `NoEagerConstraintApplicationAttribute`.

## State machine types

- `type ResumableStateMachine<'Data>` (`[<Struct; NoComparison; NoEquality>]`) — mutable fields `Data`, `ResumptionPoint` (continuation goto-label when statically compiled), and `ResumptionDynamicInfo` (removed/unsupported in `__stateMachine`-generated machines). Implements `IResumableStateMachine<'Data>` and `IAsyncStateMachine`.
- `type IResumableStateMachine<'Data>` (interface) — `ResumptionPoint : int`; mutable `Data : 'Data`.
- `type ResumptionDynamicInfo<'Data>` (`[<AbstractClass>]`) — ctor `initial: ResumptionFunc<'Data>`; `ResumptionFunc` (get/set), `ResumptionData : objnull` (get/set), abstract `MoveNext` and `SetStateMachine` (both taking `byref<ResumableStateMachine<'Data>>`).
- `type ResumptionFunc<'Data>` = `delegate of byref<ResumableStateMachine<'Data>> -> bool`.
- `type ResumableCode<'Data, 'T>` = `delegate of byref<ResumableStateMachine<'Data>> -> bool` — a compiler-recognised delegate type for blocks of resumable code.
- `type MoveNextMethodImpl<'Data>`, `SetStateMachineMethodImpl<'Data> (* IAsyncStateMachine *)`, `AfterCode<'Data, 'Result>` — delegate types consumed by `__stateMachine`.

## `module ResumableCode` (`[<RequireQualifiedAccess>]`)

Combinators for composing resumable code blocks (all `inline`):

`Combine`, `Delay`, `For`, `Yield`, `TryFinally`, `TryFinallyAsync`, `TryWith`, `Using` (requires `'Resource :> IDisposable|null`), `While` (condition marked `[<InlineIfLambda>]`), `Zero`, plus the "should not be used directly" dynamic fallbacks `CombineDynamic`, `WhileDynamic`, `TryFinallyAsyncDynamic`, `TryWithDynamic`, `YieldDynamic` (all taking `sm: byref<ResumableStateMachine<'Data>>` and returning `bool`).

## `module StateMachineHelpers` (`[<AutoOpen>]`)

Compiler intrinsics (all `[<NoInlining>]`, with detailed XML docs):

- `__debugPoint: string -> unit` — names a debug point from inlined code (e.g. `ForLoop.InOrToKeyword`); unknown names trigger warning 3514.
- `__useResumableCode<'T> : bool` — statically decides whether a branch is valid resumable code.
- `__resumableEntry: unit -> int option` — indicates a resumption point.
- `__resumeAt: programLabel: int -> 'T` — jump to a resumption point (may be the first statement of a `MoveNextMethodImpl`).
- `__stateMachine<'Data,'Result>` — statically generates a closure struct based on `ResumableStateMachine` (`moveNextMethod`, `setStateMachineMethod`, `afterCode`), implementing `IAsyncStateMachine`.

## `type NoEagerConstraintApplicationAttribute`

`[<AttributeUsage(AttributeTargets.Method, AllowMultiple=false)>]`, `[<Sealed>]`, inherits `Attribute` with a parameterless `new`. Suppresses eager application of member trait (SRTP) constraints on caller arguments during overload resolution, letting normal overload-resolution rules apply instead. Documented with a `OverloadsWithSrtp` code example comparing behavior with/without the attribute. (Category: **Attributes**.)
