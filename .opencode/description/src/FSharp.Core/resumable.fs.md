# resumable.fs

## Overview

This file (namespace `Microsoft.FSharp.Core.CompilerServices`) contains the **run-time machinery supporting resumable code and struct state machines** used by computation-expression compilers (notably the `task { }` and `seq`/`async` lowering). `ResumableCode<'Data, 'T>` is a delegate over a `byref<ResumableStateMachine<'Data>>` returning `bool` (the boolean indicates whether the step completed in one go, or yielded mid-way). The compiler recognizes `__stateMachine`, `__resumableEntry`, and related intrinsics to rewrite the code into an efficient dedicated struct; this file provides the fallback dynamic implementation and the reflective template.

## Attributes & state machine types

- `type NoEagerConstraintApplicationAttribute` (`[<Sealed>]`, `AttributeTargets.Method`) — suppresses eager application of member trait constraints during overload resolution.
- `type IResumableStateMachine<'Data>` (interface) — exposes `ResumptionPoint : int` and mutable `Data : 'Data`.
- `type ResumableStateMachine<'Data>` (`[<Struct; NoComparison; NoEquality>]`) — the reflective/template struct state machine with mutable fields `Data`, `ResumptionPoint`, and `ResumptionDynamicInfo`. Implements `IResumableStateMachine<'Data>` and `IAsyncStateMachine`; its `MoveNext`/`SetStateMachine` delegate to the dynamic info (these are replaced when `__stateMachine` statically generates a real state machine).
- `type ResumptionFunc<'Data>` = `delegate of byref<ResumableStateMachine<'Data>> -> bool` — the runtime continuation of a dynamically-created resumable state machine.
- `type ResumptionDynamicInfo<'Data>` (`[<AbstractClass>]`) — `ResumptionFunc` (get/set), `ResumptionData : objnull` (get/set), abstract `MoveNext` and `SetStateMachine` overloads taking `byref<ResumableStateMachine<...>>`.
- `type ResumableCode<'Data, 'T>` = `delegate of byref<ResumableStateMachine<'Data>> -> bool` — a block of resumable code.
- `type MoveNextMethodImpl<'Data>`, `SetStateMachineMethodImpl<'Data>`, `AfterCode<'Data, 'Result>` — delegate types passed to `__stateMachine`.

## `module StateMachineHelpers` (`[<AutoOpen>]`)

Compiler intrinsics (all `[<NoInlining>]`); the implementations always `failwith` because the real body is supplied at compile time:

- `__useResumableCode<'T> : bool` — statically decides whether the compiler is generating resumable code (selects the `if __useResumableCode then ... else <dynamic>` branch in each combinator).
- `__debugPoint : string -> unit` — named debug point from inlined source.
- `__resumableEntry () : int option` — yields the current resumption point.
- `__resumeAt<'T> (programLabel: int) : 'T` — jump to a resumption point.
- `__stateMachine<'Data,'Result> (moveNextMethod) (setStateMachineMethod) (afterCode) : 'Result` — drives the generation of a closure struct based on `ResumableStateMachine`; used to implement `IAsyncStateMachine` on the generated struct.

## `module ResumableCode`

Functional combinators for building resumable code. Each `inline` combinator produces a `ResumableCode` that checks `if __useResumableCode then <compiler-expanded fast path> else <Dynamic fallback>`:

- `Combine(code1: ResumableCode<_,unit>, code2: ResumableCode<_,'T>)` — chains a `unit`-producing step (which may yield) into the following step. `CombineDynamic` is the reflective fallback that re-installs the continuation into `ResumptionDynamicInfo.ResumptionFunc`.
- `Delay(f: unit -> ResumableCode<_,'T>)` — delayed step.
- `Zero ()` — no-op step that always completes (`true`).
- `While(condition, body)` / recursive `WhileDynamic` + `WhileBodyDynamicAux` — loop.
- `TryWith(body, catch)` / `TryWithDynamic` — try/with; catches exceptions in both the step evaluation and its continuation, using `ExceptionDispatchInfo` to preserve the failure site.
- `TryFinally`, `TryFinallyAsync` / recursive `TryFinallyAsyncDynamic` + `TryFinallyCompensateDynamic` — try/finally with a compensation step; `ExceptionDispatchInfo.Capture(exn).Throw()` re-raises at the end of the finally.
- `Using(resource, body)` — a `using` implemented as `TryFinally` that disposes the resource if non-null.
- `For(sequence, body)` — a `for` loop implemented as `Using` over the enumerator wrapped in a `While` advancing via `MoveNext` (with a `__debugPoint "ForLoop.InOrToKeyword"`).
- `Yield ()` / `YieldDynamic` — yields back; on the fast path it reads `__resumableEntry` and records the resumption point in `sm.ResumptionPoint`, returning `false` (yield) or `true` (post-yield resume).
- Public helper `GetResumptionFunc` reads `sm.ResumptionDynamicInfo.ResumptionFunc`.
