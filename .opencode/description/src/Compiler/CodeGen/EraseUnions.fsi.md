# EraseUnions.fsi

**Purpose**: Signature file for `FSharp.Compiler.AbstractIL.ILX.EraseUnions` (implementation in `EraseUnions.fs`). Declares the one and only public entry point of the union type-definition generation pass.

**Namespace / module declared**:
```
/// Compiler use only.  Erase discriminated unions.
module internal FSharp.Compiler.AbstractIL.ILX.EraseUnions
```
(internal, compiler-use only).

**API declared**:
- `val mkClassUnionDef :
      addMethodGeneratedAttrs: (ILMethodDef -> ILMethodDef) *
      addPropertyGeneratedAttrs: (ILPropertyDef -> ILPropertyDef) *
      addPropertyNeverAttrs: (ILPropertyDef -> ILPropertyDef) *
      addFieldGeneratedAttrs: (ILFieldDef -> ILFieldDef) *
      addFieldNeverAttrs: (ILFieldDef -> ILFieldDef) *
      mkDebuggerTypeProxyAttribute: (ILType -> ILAttribute) ->
      g: TcGlobals ->
      tref: ILTypeRef ->
      td: ILTypeDef ->
      cud: IlxUnionInfo ->
      ILTypeDef`
  documented: "Make the type definition for a union type."
  The 6-callback tuple corresponds exactly to the internal `ILStamping` record and is used to stamp every generated method/property/field with the correct `[CompilerGenerated]`/`[CompilerVisibleOnly]`-equivalent or "type-forwarder" attribute, and to attach the `DebuggerTypeProxyAttribute` to the per-case debug proxy types.

**Dependencies opened**: `FSharp.Compiler.AbstractIL.IL`, `FSharp.Compiler.AbstractIL.ILX.Types` (`IlsxUnionInfo`), `FSharp.Compiler.TcGlobals`.

**Cross-references**:
- `EraseUnions.fs` — implementation (~1100 lines); defines the internal `ILStamping`, `TypeDefContext`, `NullaryConstFieldInfo`, `AlternativeDefResult` types and the `mkMethodsAndPropertiesForFields` / `emitDebugProxyType` / `emitMakerMethod` / `emitTesterMethodAndProperty` / `emitNestedAlternativeType` / `processAlternative` / `emitRoot*` / `assembleUnionTypeDef` pipeline.
- Sibling erasure modules in `src/Compiler/CodeGen/`: `EraseUnions.Types.fs` (classification), `EraseUnions.Emit.fs` (IL instruction emission), `EraseClosures.fs` (closures), `IlxGen.fs` (drives these), `IlxGenSupport.fs` (attribute helpers).