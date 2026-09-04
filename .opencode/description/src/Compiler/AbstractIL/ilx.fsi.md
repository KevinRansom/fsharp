# ilx.fsi

**Purpose**
Interface contract for the "ILX" extension types (see `ilx.fs` for the implementation): pre-erasure representations of F# discriminated unions (`IlxUnionCaseField`, `IlxUnionCase`, `IlxUnionHasHelpers`, `IlxUnionRef`, `IlxUnionSpec`, `IlxUnionInfo`) and pre-erasure closure types (`IlxClosureLambdas`, `IlxClosureApps`, `IlxClosureFreeVar`, `IlxClosureRef`, `IlxClosureSpec`, `IlxClosureInfo`). CodeGen uses these to carry the source-level shape of F# unions and closures into the `ILMethodDef`s before the erasure pass turns them into F# `FSharpUnion`/`FSharpFunc` IL.

**Namespace(s)**
- `FSharp.Compiler.AbstractIL` (module `internal FSharp.Compiler.AbstractIL.ILX.Types`)

**TypeDefs declared** — see `ilx.md` for the full list; in .fsi the same union/record shapes are declared with the same members (plus doc-comments such as `member Constructor: ILMethodSpec` and `member GetStaticFieldSpec: unit -> ILFieldSpec`).

**Public API surface (per .fsi)**
- `val instAppsAux: int -> ILGenericArgs -> IlxClosureApps -> IlxClosureApps`
- `val destTyFuncApp: IlxClosureApps -> ILType * IlxClosureApps`
- `val mkILFormalCloRef: ILGenericParameterDefs -> IlxClosureRef -> useStaticField: bool -> IlxClosureSpec`
- `val mkLowerName: nm: string -> string`
- `val actualTypOfIlxUnionField: IlxUnionSpec -> int -> int -> ILType`
- `val mkILFreeVar: string * bool * ILType -> IlxClosureFreeVar`

**Cross-references**
- `ilx.fs` (implementation), `il.fs` (IL types and methods used by the ILX shapes)
