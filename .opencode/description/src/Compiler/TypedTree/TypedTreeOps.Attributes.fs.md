# TypedTreeOps.Attributes.fs

> Pipeline role: Implements typed tree checkstyle metadata — attribute classification, well-known attribute flag computation, and debug printing of expressions and types. Provides the classification tables consumed all over the compiler (imports, type checking, codegen) to recognize standard .NET/F# attributes (`DllImportAttribute`, `ConditionalAttribute`, `VolatileFieldAttribute`, `ThreadStaticAttribute`, `MethodImplAttribute`, etc.) and F#-specific attributes (`AutoOpen`, `CompiledName`, `StructLayout`, ...). Exposes `ILAttribute`-based helpers for the AbsIL view of attributes read from metadata, plus a large debug-printing implementation (`DebugPrint`) used for dumps and diagnostics.
> Namespace: `FSharp.Compiler.TypedTreeOps`

---

## Module: `type` `FSharp.Compiler.TypedTreeOps.ILExtensions` (`[<AutoOpen>]`, internal, declared at line 37)

AbsIL view of attributes — helpers reading `ILAttribute`s directly off .NET binaries rather than F# `Attrib` nodes.

**Opening section (lines 40–42)**: "Detect attributes", so the first batch of functions test an `ILAttribute` by its enclosing path + name:

- `isILAttribByName (tencl: string list, tname: string) (attr: ILAttribute) : bool` — matches an IL attribute against a (namespace-parts, name) pair.
- `isILAttribKind` / `isILAttribNames` — predicate helpers over a set of candidate names.
- `tryILAttribs` — scans an `ILAttributes` collection for the first attribute matching a given name, returns its constructor arguments.
- `tryILAttribsAtIdx` variant.
- `attribs_Unsupported` (a `string list`, current occurrence at line 110) — the classified global set of names treated as "unsupported .NET attributes" which the F# compiler deliberately ignores/does not surface to user code via reflection metadata (the "unsupported" list `[attribName SequenceAttribute; ...]` built in `TcGlobals`-adjacent modules but referenced here).

**ILAttribute classification**:

- `classifyILAttrib (attr: ILAttribute) : WellKnownILAttributes` (line 139) — maps a single IL attribute to the `WellKnownILAttributes` flag type (imports, netmodule, platform-specific, DllImport, ...).
- `computeILWellKnownFlags (_g: TcGlobals) (attrs: ILAttributes) : WellKnownILAttributes` (line 193) — folds `classifyILAttrib` over a metadata attribute set, merging the flags.

**Type provider assembly attribute decoding**:

- `TryDecodeTypeProviderAssemblyAttr (cattr: ILAttribute) : (string | null) option` (line 1186) — decodes the assembly-level `TypeProviderAssembly` attribute value (used to discover `.DesignTime` provider assemblies).
- `mkSignatureDataVersionAttr (g : TcGlobals) (version: ILVersionInfo)` (line 1209) — builds the `SignatureDataVersion` IL attribute used to stamp FSharp.Core signature data.
- `IsSignatureDataVersionAttr cattr` (line 1221) — test helper recognizing that stamp.

---

## Module: `type` `FSharp.Compiler.TypedTreeOps.AttributeHelpers` (internal, declared at line 244)

Classifies F# `Attrib` nodes and computes the well-known-flag sets used across the compiler.

**Classification of individual attributes** (each returns the relevant `WellKnownXxxAttributes`):

- `classifyEntityAttrib (g: TcGlobals) (attrib: Attrib) : WellKnownEntityAttributes` (line 270) — flags `Measure`, `RequireQualifiedAccess`, `CompiledName`, `Struct`, `StructuralEquality`, `StructuralComparison`, `NoEquality`, `NoComparison`, `ReferenceEquality`, `DefaultAugmentation`, `AllowNullLiteral`, `CustomEquality`, `CustomComparison`, `AutoOpen`, `Obsolete`, ... based on attribute name + evidence about the referenced type.
- `classifyAssemblyAttrib (g) (attrib) : WellKnownAssemblyAttributes` (line 400) — assembly-level attributes: `AutoOpen`, `InternalsVisibleTo`, `TypeProviderAssembly`, ... plus the `ExtensionAttribute`-positioning logic.
- `classifyValAttrib (g) (attrib) : WellKnownValAttributes` (line 564) — flags `CompilationRepresentation`, `CompiledName`, `SpecialName`, `Optional`, `DefaultParameterValue`, `ParamArray`, `EntryPoint`, `ThreadStatic`, `ContextStatic`, `Literal`, `Volatile`, `UnmanagedFunctionPointer`, `DllImport`, `MethodImpl`, `Conditional`, `ReflectedDefinition`, `Measure`, `AbstractClass`?, `CLIEvent`, `StandardName`? , `CompilerMessage` (deprecation?), `CppInlineAssembly` ... which feed into `Val` flags and codegen.

**Computed flag sets** (combined for an entity/val):

- `computeEntityWellKnownFlags (g: TcGlobals) (attribs: Attribs) : WellKnownEntityAttributes` (line 502) — folds `classifyEntityAttrib` over an entity's attributes.
- `computeValWellKnownFlags (g: TcGlobals) (attribs: Attribs) : WellKnownValAttributes` (line 662) — folds `classifyValAttrib` over a val's attributes; drives `Val.CompiledRepresentationForUseInSignature`, avoiding duplication of `Attribs` list.
- `hasFlag` (bit-test) helpers used with the flag sets.

**Other helpers in this module**: `tryAttribute`; `tryGetBindings`; `getAttribSeqPoint` (line ~750) reading proof-of-anchor/`DebuggerStepThrough`-ish sequence point hints; `getAttribString`; attribute plumbing to attach to `Entity`/`Val` (`Attrib` list construction); some helpers for `Attribute.Equals`?

---

## Module: `type` `FSharp.Compiler.TypedTreeOps.ByrefAndSpanHelpers` (internal, declared at line 1399)

Small internal helpers dealing with byref/span-derived types as used by code generation & feature gating:

- Recognizes `Span<'T>`, `ReadOnlySpan<'T>`, `IsByRefLike` tycons; used to compute whether a type is readonly, whether `IsByRefLike` rendering is needed, and language-version gating for byref-like types.

---

## Module: `type` `FSharp.Compiler.TypedTreeOps.DebugPrint` (internal, declared at line 1472)

Debug/display printing of typed tree terms, used in dumps, `--testDumpDebugInfo`, and internal error messages:

- `exprToDebugString` / `tyconToDebugString` / logic printing `Expr` and `TType` with full `Val`/`Typar` stamps.
- `debugPrintExpr`, `debugPrintTycon`, `debugPrintType`, `debugPrintMExpr`, `debugPrintImplFile`, plus the layout-based readers using `Layout` / `TaggedText` infrastructure.
- Marker functions `assumeDllImportAttributes` used by the DLL-import attribute decoding in `TcImports`.

---

## Related

- Consumed by: `TypedTreeBasics` (flag types live under `WellKnownAttribs`), `TcImports` (metadata import, type provider discovery), `CheckExpressions` (attribute admissibility), `Optimizer`/`IlxGen` (codegen attribute emission), `CheckDeclarations`.
- Attribute flag types: `WellKnownAttribute`s in `FSharp.Compiler.IlxGen`-adjacent modules (see `WellKnownAttribs.fs.md`).