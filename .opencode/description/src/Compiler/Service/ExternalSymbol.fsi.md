# ExternalSymbol.fsi

**Purpose**: Public contract for `ExternalSymbol.fs`. Declares the external-symbol representation types (`FindDeclExternalType`, `FindDeclExternalParam`, `FindDeclExternalSymbol`) and the find-declaration result types (`FindDeclFailureReason`, `FindDeclResult`) so that tooling can inspect what a "find declaration" request resolved to when the answer is a symbol in an external assembly.

**Namespace(s)**: `FSharp.Compiler.EditorServices`

## TypeDefs / Unions / Modules declared (contract)

- **`FindDeclExternalType`** (public union) — external type: `Type`/`Array`/`Pointer`/`TypeVar`; `override ToString: unit -> string`.
- **`FindDeclExternalParam`** (public union, sealed) — external parameter: `IsByRef: bool`, `ParameterType`, `static Create`, `ToString`.
- **`FindDeclExternalSymbol`** (public union) — external symbol: `Type`/`Constructor`/`Method`/`Field`/`Event`/`Property`; `ToString`; internal `ToDebuggerDisplay`.
- **`FindDeclFailureReason`** (public union) — `Unknown`/`NoSourceCode`/`ProvidedType`/`ProvidedMember`.
- **`FindDeclResult`** (public union) — `DeclNotFound`/`DeclFound`/`ExternalDecl`.
- **`module internal FindDeclExternalType`** — `tryOfILType: string array -> ILType -> FindDeclExternalType option` (hidden from public API).
- **`module internal FindDeclExternalParam`** — `tryOfILType`, `tryOfILTypes` (hidden helpers used by the find-declaration implementation).

## Public API surface

- Exactly the five union types above, plus the small set of members (`Create`, `IsByRef`, `ParameterType`, `ToString`) — this file is almost entirely public data declarations.
- Note the fsi does **not** declare the `Option` helper module or the `DebugKeyStore` debugging classes; those are implementation-only details of the `.fs`.

## Internal helpers / active patterns

- `tryOfILType` / `tryOfILTypes` are the only internal surface: they let the service convert raw IL signatures into the display-level external types without exposing `ILType` to clients.

## Significant internal logic

- The `fsi` intentionally exposes the *result* vocabulary (what an external declaration looks like) but hides the IL-conversion mechanics, keeping the compiler's internal IL type system out of the public API.
- `FindDeclFailureReason` encodes type-provider cases (`ProvidedType`, `ProvidedMember`) so clients can distinguish "no source" from "type provider without location info".

## Cross-references

- `FindDeclResult` is the return type of `FSharpCheckFileResults.GetDeclarationLocation` (see `FSharpCheckerResults.fsi`).
- IL types (`ILType`) come from `FSharp.Compiler.AbstractIL.IL`; see `ItemKey.fs` for a parallel IL-encoding scheme.
- `range` comes from `FSharp.Compiler.Text`.
