# ExternalSymbol.fs

**Purpose**: Defines the data types used to represent F# symbols that originate from an external (non-F# or non-source-available) assembly, along with the result type of the "find declaration" (goto-definition) operation. This is used by tooling (Language Server, Visual F#) to report where a symbol came from when its declaration is in a referenced assembly rather than in the user's source code.

**Namespace(s)**: `FSharp.Compiler.EditorServices`

## TypeDefs / Unions / Modules declared

- **`FindDeclExternalType`** (union, public) — Represents a type in an external non-F# assembly: `Type` (full name + generic args), `Array`, `Pointer`, `TypeVar`. Has a `ToString` that renders e.g. `Name<Arg1, Arg2>`, `T[]`, `&T`, `'t`.
- **`FindDeclExternalParam`** (union, public, sealed) — A single method parameter: `Param` or `Byref` of a `FindDeclExternalType`. Members `IsByRef`, `ParameterType`, static `Create(parameterType, isByRef)`.
- **`FindDeclExternalSymbol`** (union, public, `DebuggerDisplay`-attributed) — A symbol in an external assembly: `Type`, `Constructor`, `Method` (with generic arity), `Field`, `Event`, `Property`. Rendered via `ToString` (e.g. `Type.Method`2(a, b)`).
- **`FindDeclFailureReason`** (union, public) — Reason the find-declaration operation failed: `Unknown`, `NoSourceCode`, `ProvidedType`, `ProvidedMember` (type providers without `TypeProviderDefinitionLocationAttribute`).
- **`FindDeclResult`** (union, public) — Result of `GetDeclarationLocation`: `DeclNotFound reason`, `DeclFound range`, `ExternalDecl (assembly * FindDeclExternalSymbol)`.
- **`module Option`** — one-line helper `ofOptionList`: `Some` if all options are `Some`, else `None`.
- **`module FindDeclExternalType`** — `tryOfILType`: converts an `ILType` into a `FindDeclExternalType` if possible (handles Array/Boxed/Value/Ptr/TypeVar).
- **`module FindDeclExternalParam`** — `tryOfILType`, `tryOfILTypes`: convert IL signature types into parameter lists.
- **`DebugKeyStore`** (class, in `[<AutoOpen>]` module, debug tooling) — human-readable log of what is written into an `ItemKeyStore` while debugging.
- **`_DebugKeyStoreNoop`** (class) — zero-cost no-op replacement used when not debugging.

## Public API surface

- Main public entries: `FindDeclExternalType`, `FindDeclExternalParam`, `FindDeclExternalSymbol`, `FindDeclFailureReason`, `FindDeclResult`.
- `FindDeclExternalParam.Create`, `IsByRef`, `ParameterType`, `ToString`.

## Internal helpers

- `tryOfILType` in both the `FindDeclExternalType` and `FindDeclExternalParam` modules (ILType → semantic type conversion, used when building the display name of an external declaration).
- `ToDebuggerDisplay` member (internal) on `FindDeclExternalSymbol`.

## Significant internal logic

- `tryOfILType` recursively walks IL types: arrays keep inner type, `Value`/`Boxed` emit `Type` with generic args, `Ptr` → `Pointer`, `TypeVar` looked up by ordinal in a supplied `typeVarNames` array; anything unrecognized (e.g. `Void`, byref) yields `None`.
- `FindDeclExternalParam.tryOfILType` special-cases `ILType.Byref` to produce a `Byref` param; everything else becomes a plain `Param`.

## Cross-references

- Produces `ExternalDecl` payloads of `FindDeclResult`, which is the return type of `FSharpCheckFileResults.GetDeclarationLocation` in `FSharpCheckerResults.fs`.
- Consumed by `ServiceAnalysis` / language-service "find all" paths when a reference points at a non-F# type.
- IL types come from `FSharp.Compiler.AbstractIL.IL` (see also `ItemKey.fs` which likewise encodes `ILType`s).
