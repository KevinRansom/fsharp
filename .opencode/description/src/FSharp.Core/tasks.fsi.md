# tasks.fsi

## Overview

Signature file (namespace `Microsoft.FSharp.Control`) exposing the public surface of the `task { }` / `backgroundTask { }` computation expression builders (implemented in `tasks.fs`). It declares the state-machine helper types, the builder classes, the extension overload modules, and the `Task`/`ValueTask` functional helper modules.

## State machine helper types (lines 21–56)

- `TaskStateMachineData<'T>` (`[<Struct; NoComparison; NoEquality>]` + `[<CompilerMessage(1204, IsHidden = true)>]`) — holds `Result: 'T` and `MethodBuilder: AsyncTaskMethodBuilder<'T>`; for use by compiled F# code.
- `TaskStateMachine<'TOverall>` — `ResumableStateMachine<TaskStateMachineData<'TOverall>>` (compiler template for state-machine structs).
- `TaskResumptionFunc<'TOverall>` — `ResumptionFunc<...>` (runtime continuation for dynamic tasks).
- `TaskCode<'TOverall, 'T>` — `ResumableCode<...>` (compiler-recognized delegate for blocks of task code).

## `TaskBuilderBase` (`[<Class>]`, line 62)

Computational-expression protocol built over `TaskCode`: `Combine`, `Delay`, `For`, `Return`, `TryFinally`, `TryWith`, `While`, `Zero`. Under `NETSTANDARD2_1 || NET`: `Using<'Resource, ... when 'Resource :> IAsyncDisposable>`.

## `TaskBuilder` / `BackgroundTaskBuilder` (`[<Class>]`, lines 119, 134)

Both `inherit TaskBuilderBase` and declare:
- `static RunDynamic: TaskCode<'T, 'T> -> Task<'T>` — dynamic implementation used for quotations/reflective execution.
- `inline Run: TaskCode<'T, 'T> -> Task<'T>` — hosts the code in a state machine and starts the task (`BackgroundTaskBuilder`'s runs via `Task.Run` when escaping to a background thread is needed).

## `module TaskBuilder` (`[<AutoOpen>]`, line 149)

- `val task: TaskBuilder` — the `task` computation expression builder.
- `val backgroundTask: BackgroundTaskBuilder` — builder that switches to a background thread (via `Task.Run`) when not already on one.

## Namespace `Microsoft.FSharp.Control.TaskBuilderExtensions`

Priority-ordered extension modules (F# gives higher priority to extension members opened later; auto-open sequencing via assembly attribute controls priority):

- **`LowPriority`** (line 192) — on `TaskBuilderBase`: SRTP `Bind`/`ReturnFrom`/`BindDynamic` over any `^TaskLike` with the GetAwaiter pattern (`[<NoEagerConstraintApplication>]`), and `Using` over `'Resource :> IDisposable | null`. Adds `MergeSources` (`and!`) for task-like + task-like on both `TaskBuilder` and `BackgroundTaskBuilder`.
- **`LowPlusPriority`** (line 274) — `MergeSources` overloads for async + task-like and task-like + async.
- **`MediumPriority`** (line 323) — on `TaskBuilderBase`: `Bind`/`ReturnFrom` over `Async<'TResult1>`; plus `MergeSources` over the many `Task`/task-like/`Async` combinations.
- **`HighPriority`** (line 422) — on `TaskBuilderBase`: `Bind`/`ReturnFrom`/`BindDynamic` over `Task<'T>` directly (non-SRTP); `MergeSources` for Task + Task.

## `module Task` (line 471)

`[<RequireQualifiedAccess>]` + `ModuleSuffix`; camelCase functions over `Task<'T>` (category **Async Programming**): `result` (`Result`), `map` (`Map`), `bind` (`Bind`), `ignore<'T>` (`Ignore`, `[<RequiresExplicitTypeArguments>]`), `catchWith` (`CatchWith`, cancellation exceptions propagate unchanged), `catch` (`Catch`, reifies outcome as `Result<'T, exn>`), `empty : Task<unit>` (`Empty`). Under `NETSTANDARD2_1 || NET`: `ofValueTask` (`OfValueTask`).

## `module ValueTask` (`NETSTANDARD2_1 || NET`, line 609)

Mirror module over `ValueTask<'T>`: `result`, `map`, `bind`, `ignore<'T>`, `catchWith`, `catch`, `empty`, and `ofTask` (`OfTask`) converting a `Task<'T>` into a `ValueTask<'T>`.
