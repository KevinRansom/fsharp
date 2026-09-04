# fslib-extra-pervasives.fs

## Overview

This file provides the **extra pervasives** — additional top-level bindings and operators that are automatically opened in all F# code. It lives in the `Microsoft.FSharp.Core` and `Microsoft.FSharp.Core.CompilerServices` namespaces. The main module, `ExtraTopLevelOperators`, is marked `[<AutoOpen>]` via an assembly-level attribute, which places numerous convenience functions (printing, conversions, collection builders, the `async` and `query` builders, quotation splices) directly in scope.

## Module `ExtraTopLevelOperators`

The primary module in this file. All helpers are top-level, `inline`, and marked with `[<CompiledName>]` for their canonical .NET names.

### Argument/null-checking helpers (internal)

- `checkNonNullNullArg argName arg` — raises `ArgumentNullException` if the argument is null (`box arg` is null).
- `checkNonNullInvalidArg argName message arg` — raises `ArgumentException` with the given message if the argument is null.
- `dummyArray` and `dont_tail_call f` — a small trick that forces a non-tail-call by reading a field after the call, used to prevent tailcalls in certain dictionary lookups.

### Collection builders

- `set elements` (`CreateSet`) — builds a `Set<'T>` from a sequence via `Set.ofSeq`.
- `dict keyValuePairs` (`CreateDictionary`) — builds a read-only `IDictionary<'Key,'T>`. Specializes on whether the key type is a value type:
  - `dictValueType` uses `HashIdentity.Structural` and passes keys straight through.
  - `dictRefType` wraps keys in a `StructBox` (`RuntimeHelpers.StructBox`) so that reference keys that use `null` as a representation still hash/compare correctly.
  - The actual wrapper type is `DictImpl<'SafeKey,'Key,'T>` (see below).
- `readOnlyDict keyValuePairs` (`CreateReadOnlyDictionary`) — same as `dict` but exposes `IReadOnlyDictionary<'Key,'T>`.
- `array2D rows` (`CreateArray2D`) — builds a two-dimensional rectangular array from a sequence of row sequences; validates that rows are non-null and of equal length, and rejects ragged input with `ArgumentException`.

### Printing functions

These delegate to the corresponding `Printf` module functions:

- `sprintf` (`PrintFormatToString`), `failwithf` (`PrintFormatToStringThenFail`), `fprintf`/`fprintfn` (`PrintFormatToTextWriter`/`PrintFormatLineToTextWriter`), `printf` (`PrintFormat`), `eprintf` (`PrintFormatToError`), `printfn` (`PrintFormatLine`), `eprintfn` (`PrintFormatLineToError`).
- `print value` (`PrintValue`) and `printn value` (`PrintValueLine`) — write a value to `Console.Out` (optionally with a newline). For `string`/`char`/`bool`, a `when` static-constraint branch avoids the general `string` conversion path (culture-independent direct writes).

### Asynchronous workflow builder

- `async` (`DefaultAsyncBuilder`) — an instance of `AsyncBuilder`, enabling `async { ... }` computation-expressions.

### Numeric conversions (inline, `op_Explicit`)

- `single` (`ToSingle`, → `float32`), `double` (`ToDouble`, → `float`), `uint8` (`ToByte`), `int8` (`ToSByte`).
- A nested `module Checked` provides `Checked.uint8` and `Checked.int8` (checked variants of byte/sbyte conversion).

### Quotation splice operators

- `(~%)` (`SpliceExpression`) — typed splice operator `%` used inside quotations; at runtime it always raises `InvalidOperationException` (first-class use of splice not allowed outside the quotation evaluator).
- `(~%%)` (`SpliceUntypedExpression`) — untyped splice operator `%%`.
- `(|Lazy|)` (`LazyPattern`) — active pattern that forces a `Lazy<'T>` to return its value.

### Query builder

- `query` — an instance of `QueryBuilder`, enabling `query { ... }` computation-expression syntax.

### Assembly auto-open attributes

A `do ()` block carries `[<assembly: AutoOpen(...)>]` attributes that auto-open `Microsoft.FSharp`, `LanguagePrimitives.IntrinsicOperators`, `Core`, `Collections`, `Control`, several `TaskBuilderExtensions` namespaces, and `Linq.QueryRunExtensions`. This is how the extra pervasives become globally available.

## Type-provider support (namespace `Microsoft.FSharp.Core.CompilerServices`)

The second half of the file contains the types used to support F# **type providers**:

- `MeasureProduct<'Measure1,'Measure2>`, `MeasureInverse<'Measure>`, `MeasureOne` — __sealed marker types__ that represent measure expressions when returned as generic arguments of a provided type.
- `TypeProviderAttribute` — attribute placed on a class implementing `ITypeProvider` to extend the compiler.
- `TypeProviderAssemblyAttribute` — marks a runtime assembly that has a corresponding design-time (type-provider) assembly; carries the `AssemblyName`.
- `TypeProviderXmlDocAttribute` — attaches documentation text (`CommentText`) to provided types/members.
- `TypeProviderDefinitionLocationAttribute` — records `FilePath`, `Line`, `Column` for a provided type/member.
- `TypeProviderEditorHideMethodsAttribute` — tells editors to hide `System.Object` methods from intellisense for provided types.
- `TypeProviderTypeAttributes` — flags enum with `SuppressRelocate` and `IsErased` bits.
- `TypeProviderConfig` — passed to a type-provider constructor; exposes `ResolutionFolder`, `RuntimeAssembly`, `ReferencedAssemblies`, `TemporaryFolder`, `IsInvalidationSupported`, `IsHostedExecution`, `SystemRuntimeAssemblyVersion`, and `SystemRuntimeContainsType`.
- `IProvidedNamespace` — an injected namespace with `NamespaceName`, `GetNestedNamespaces`, `GetTypes`, `ResolveTypeName`.
- `ITypeProvider` — the core provider interface (inherits `IDisposable`): `GetNamespaces`, `GetStaticParameters`, `ApplyStaticArguments`, `GetInvokerExpression`, the `Invalidate` CLI event, and `GetGeneratedAssemblyContents`.
- `ITypeProvider2` — optional extended interface adding `GetStaticParametersForMethod` and `ApplyStaticArgumentsForMethod` for provided methods.

## Supporting type: `DictImpl<'SafeKey,'Key,'T>`

The read-only dictionary used by `dict`/`readOnlyDict`. Wraps an internal `Dictionary<'SafeKey,'T>` and a pair of functions (`makeSafeKey` and `getKey`) that translate between the public key type and the internal "safe" key type:

- Implements `IDictionary<'Key,'T>` with a read-only surface (all mutation members raise `NotSupportedException`).
- Implements `IReadOnlyDictionary<'Key,'T>`, `ICollection<KeyValuePair<...>>`, `IReadOnlyCollection<...>`, `IEnumerable<KeyValuePair<...>>`, and non-generic `IEnumerable`.
- The `Keys` enumeration is emitted with an array-comprehension-based enumerator to avoid incorrect `IEnumerator.Reset()`/`Current` semantics.
- `DictDebugView<'SafeKey,'Key,'T>` is a debugger type proxy (marked with `[<DebuggerDisplay>]`, `[<DebuggerTypeProxy>]`) that surfaces the items with `RootHidden` browsing.
