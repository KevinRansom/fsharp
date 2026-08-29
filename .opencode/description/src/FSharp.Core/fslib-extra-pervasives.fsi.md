# fslib-extra-pervasives.fsi

## Overview

This is the public API signature (`.fsi`) for the extra pervasives — the additional top-level bindings automatically opened in all F# code. It declares the `ExtraTopLevelOperators` module (namespace `Microsoft.FSharp.Core`) plus the type-provider support types in `Microsoft.FSharp.Core.CompilerServices`. Unlike the implementation, the signature only exposes the public surface with XML documentation.

## Module `ExtraTopLevelOperators`

Marked `[<AutoOpen>]` and declared with `[<CompiledName>]` bindings. Exposed API:

### Printing

- `printf` / `printfn` (`PrintFormat` / `PrintFormatLine`) — print to `stdout`, the latter adding a newline. Types: `format: Printf.TextWriterFormat<'T> -> 'T`.
- `eprintf` / `eprintfn` (`PrintFormatToError` / `PrintFormatLineToError`) — print to `stderr`.
- `print` / `printn` (`PrintValue` / `PrintValueLine`) — `inline`; convert a value with `string` and write to standard output (with newline for `printn`).
- `sprintf` (`PrintFormatToString`) — `format: Printf.StringFormat<'T> -> 'T`.
- `failwithf` (`PrintFormatToStringThenFail`) — `format: Printf.StringFormat<'T,'Result> -> 'T`.
- `fprintf` / `fprintfn` (`PrintFormatToTextWriter` / `PrintFormatLineToTextWriter`) — take a `TextWriter` then a format.

### Collection builders

- `set` (`CreateSet`) — `elements: seq<'T> -> Set<'T>`.
- `dict` (`CreateDictionary`) — `seq<'Key * 'Value> -> System.Collections.Generic.IDictionary<'Key,'Value>` when `'Key : equality`.
- `readOnlyDict` (`CreateReadOnlyDictionary`) — `seq<'Key * 'Value> -> IReadOnlyDictionary<'Key,'Value>` when `'Key : equality`.
- `array2D` (`CreateArray2D`) — `rows: seq<#seq<'T>> -> 'T[,]`.

### Async builder

- `async` (`DefaultAsyncBuilder`) — an `AsyncBuilder` value enabling `async { }` expressions.

### Numeric conversions (inline, `op_Explicit`)

- `single` (`ToSingle`, → `single`), `double` (`ToDouble`, → `double`), `uint8` (`ToByte`), `int8` (`ToSByte`), each with a static-member constraint `^T : (static member op_Explicit ...)` and a default of `int`.
- Nested `module Checked` exposes checked variants `Checked.uint8` and `Checked.int8`.

### Quotation splices and pattern

- `(~%)` (`SpliceExpression`) — `expression: Expr<'T> -> 'T`.
- `(~%%)` (`SpliceUntypedExpression`) — `expression: Expr -> 'T`.
- `(|Lazy|)` (`LazyPattern`) — `input: Lazy<'T> -> 'T`.

### Query builder

- `query` — a `QueryBuilder` value enabling `query { }` expressions.

## Namespace `Microsoft.FSharp.Core.CompilerServices`

The public type-provider contracts:

- `MeasureProduct<'M1,'M2>`, `MeasureInverse<'M>`, `MeasureOne` — sealed marker types for measure expressions in static parameters.
- `TypeProviderAttribute` — `new : unit -> TypeProviderAttribute`.
- `TypeProviderAssemblyAttribute` — `new : unit -> ...` and `new : assemblyName: string -> ...`; `member AssemblyName : string`.
- `TypeProviderXmlDocAttribute` — `new : commentText: string -> ...`; `member CommentText : string`.
- `TypeProviderDefinitionLocationAttribute` — `new : unit -> ...`; mutable members `FilePath`, `Line`, `Column`.
- `TypeProviderEditorHideMethodsAttribute` — `new : unit -> ...`.
- `TypeProviderTypeAttributes` — flags enum: `SuppressRelocate = 0x80000000`, `IsErased = 0x40000000`.
- `TypeProviderConfig` — constructors from `(string -> bool)` or `(string -> bool * (unit -> string array))`; members `ResolutionFolder`, `RuntimeAssembly`, `ReferencedAssemblies`. `TemporaryFolder`, `IsInvalidationSupported`, `IsHostedExecution`, `SystemRuntimeAssemblyVersion` (get/set), and method `SystemRuntimeContainsType : string -> bool`.
- `IProvidedNamespace` — abstract `NamespaceName`, `GetNestedNamespaces`, `GetTypes`, `ResolveTypeName`.
- `ITypeProvider` — inherits `IDisposable`; `GetNamespaces`, `GetStaticParameters`, `ApplyStaticArguments`, `GetInvokerExpression`, the `[<CLIEvent>] Invalidate` event, `GetGeneratedAssemblyContents`.
- `ITypeProvider2` — `GetStaticParametersForMethod`, `ApplyStaticArgumentsForMethod`.
