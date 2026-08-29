# tasks.fs

## Overview

This file (namespace `Microsoft.FSharp.Control`) implements the **`task { }` and `backgroundTask { }` computation expressions** — task builders that compile to allocation-free paths for synchronous code. It is built on top of the resumable code / `ResumableStateMachine` machinery from `resumable.fs` (`Microsoft.FSharp.Core.CompilerServices.StateMachineHelpers`). The builder was originally written by Robert Peele (2016), reworked for F# 4.0 operator-based overload resolution by Gustavo Leon (2018), and revised for FSharp.Core by Microsoft (2019).

## Task state machine types (lines 27–39)

- `TaskStateMachineData<'T>` (`[<Struct; NoComparison; NoEquality>]`) — `Result: 'T` and `MethodBuilder: AsyncTaskMethodBuilder<'T>`.
- Type abbreviations tying the resumable machinery to tasks: `TaskStateMachine<'TOverall> = ResumableStateMachine<TaskStateMachineData<'TOverall>>`, plus `TaskResumptionFunc`, `TaskResumptionDynamicInfo`, and `TaskCode<'TOverall,'T> = ResumableCode<_,_>`.

## `type TaskBuilderBase()` (line 41)

The common builder base used by both `TaskBuilder` and `BackgroundTaskBuilder`. Members conform to the F# computation-expression protocol and delegate to `ResumableCode`:

- `Delay(generator)`, `Zero()` (`ResumableCode.Zero`), `Return(value)` (stores into `sm.Data.Result`), `Combine(task1, task2)` (requires the first step to have unit result), `While(condition, body)`, `TryWith(body, catch)`, `TryFinally(body, compensation)`, `For(sequence, body)`.
- Under `NETSTANDARD2_1 || NET`: internal `TryFinallyAsync` (supports `compensation : unit -> ValueTask`, using `ResumableCode.TryFinallyAsync` with `AwaitUnsafeOnCompleted` on the awaiter) and `Using<'Resource,'TOverall,'T when 'Resource :> IAsyncDisposable | null>` (disposes asynchronously via `DisposeAsync()`).

## `type TaskBuilder()` (line 143)

Inherits `TaskBuilderBase`; provides `Task<'T>` results.

- `static RunDynamic(code: TaskCode<'T,'T>) : Task<'T>` — the dynamic (reflective) implementation, used when the compiler isn't generating statically-compiled tasks. It sets up a `TaskStateMachine<'T>`, registers a `TaskResumptionDynamicInfo<'T>` whose `MoveNext` invokes the current resumption function, sets a result via `MethodBuilder.SetResult`, or registers a pending awaiter via `MethodBuilder.AwaitUnsafeOnCompleted`; exceptions are captured and reported with `MethodBuilder.SetException` (run outside the stack unwind per Roslyn advice). Initializes `MethodBuilder <- AsyncTaskMethodBuilder<'T>.Create()` then `Start(&sm)` and returns `.Task`.
- `inline Run(code) : Task<'T>` — the fast path: `if __useResumableCode then __stateMachine<...>` (producing a dedicated struct state machine with `MoveNextMethodImpl`, `SetStateMachineMethodImpl`, `AfterCode`) else falls back to `RunDynamic`.

## `type BackgroundTaskBuilder()` (line 220)

Inherits `TaskBuilderBase`; like `TaskBuilder` but `backgroundTask { }` **escapes to a background thread where necessary** (matching `ConfigureAwait(false)` semantics): if already on a thread with no `SynchronizationContext` and the default `TaskScheduler`, it runs directly; otherwise it wraps the run in `Task.Run<'T>(...)`. Both `RunDynamic` and `inline Run` implement this check.

## `module TaskBuilder` (line 274)

- `let task = TaskBuilder()`
- `let backgroundTask = BackgroundTaskBuilder()`

## Namespace `Microsoft.FSharp.Control.TaskBuilderExtensions`

Layered (priority-ordered) extension modules that teach the builders to `bind`/`returnFrom` over various awaitables and to support `and!` (via `MergeSources`). Overload resolution walks these in order:

- **`LowPriority`** — SRTP-based `Bind`/`BindDynamic`/`ReturnFrom` over any `^TaskLike` with `GetAwaiter`/`IsCompleted`/`GetResult` (+ `ICriticalNotifyCompletion`), marked `[<NoEagerConstraintApplication>]`; `Using` over `IDisposable | null`. Adds `TaskBuilder.MergeSources`/`BackgroundTaskBuilder.MergeSources` (task-like + task-like).
- **`HighPriority`** — `Bind`/`BindDynamic`/`ReturnFrom` over `System.Threading.Tasks.Task<'T>` directly (non-SRTP fast path); `MergeSources` for `Task + Task`.
- **`MediumPriority`** — `Bind`/`ReturnFrom` over `Async<'T>` (via `Async.StartImmediateAsTask`); `MergeSources` overloads for the many `Task`/`Async`/`^TaskLike` combinations.
- **`LowPlusPriority`** — additional `MergeSources` overloads for `Async + ^TaskLike` combinations.

## `module Task` (`[<RequireQualifiedAccess>]` + `ModuleSuffix`), line 729

Public helpers over `Task<'T>`:

- `result value` (`Result`) — `Task.FromResult`, `inline`.
- `empty : Task<unit>` (`Empty`).
- `bind binder task` (`Bind`) — if completed synchronously runs the binder with exception capture (`Task.FromException`), else falls back to `TaskBuilder.task { let! v = task; return! binder v }`.
- `map mapping task` (`Map`) — similar with `return mapping v`.
- `ignore<'T> task` (`Ignore`, `[<RequiresExplicitTypeArguments>]`).
- `catchWith handler task` (`CatchWith`) — wraps in a task that catches non-cancellation exceptions (`OperationCanceledException` is rethrown).
- `catch task` (`Catch`) — `Task<Result<'T, exn>>` (`map Ok |> catchWith Error`).
- `ofValueTask` (`OfValueTask`, `NETSTANDARD2_1 || NET`) — `valueTask.AsTask()`.

## `module ValueTask` (`NETSTANDARD2_1 || NET`), line 797

Public helpers over `ValueTask<'T>`: `result`, `empty`, `ofTask`, `bind`, `map`, `ignore`, `catchWith`, `catch`. The non-synchronously-completed cases route through the `TaskBuilder.task` path and wrap the result back in a `ValueTask<'T>`.
