# XmlDocFileWriter.fs

**Purpose** Writes the XML documentation file for a compiled assembly. Given the checked CCU (`CcuThunk`), it first assigns each documented element its canonical "XmlDocSig" id (so the doc file's `<member name="…">` keys are stable and match the C#/F# doc conventions), then walks the CCU again to emit a `<doc><assembly>…<members>…</members></doc>` XML file. This is the last pipeline stage in fsc when `--doc:<path>` (i.e. `tcConfig.xmlDocOutputFile`) is set.

**Pipeline role** fsc `main6` — after the IL module is saved and the PDB emitted. Pure: takes the checked CCU and writes a text file; no type checking happens here.

**Namespace(s)** `FSharp.Compiler` — module `FSharp.Compiler.XmlDocFileWriter`, `internal`; single submodule `XmlDocWriter`.

**Functions (in `XmlDocWriter`)**

- `hasDoc (doc: XmlDoc) = not doc.IsEmpty` — predicate used to skip documentation-less elements.

- **`ComputeXmlDocSigs (tcGlobals, generatedCcu: CcuThunk) -> unit`** — the id-assignment pass. Internal helpers:
  - `doValSig ptext (v: Val)` — if `v.XmlDoc` is non-empty, `v.XmlDocSig <- XmlDocSigOfVal g false ptext v` (the `M:`/`P:` id from the qualified path + val name).
  - `doTyconSig ptext (tc: Tycon)` — sets `tc.XmlDocSig <- XmlDocSigOfTycon [ ptext; tc.CompiledName ]` if doced; then:
    - for each member (`tc.MembersOfFSharpTyconSorted`) → `doValSig ptext vref.Deref`;
    - for each union case `uc` → `uc.XmlDocSig <- XmlDocSigOfUnionCase [ ptext; tc.CompiledName; uc.Id.idText ]` (if doced), and for each field `field in uc.RecdFieldsArray` → `field.XmlDocSig <- XmlDocSigOfProperty [ ptext; tc.CompiledName; uc.Id.idText; field.Id.idText ]` (comment: "union case fields are exposed as properties").
    - for each `rf in tc.AllFieldsArray` → record fields (non-static, on a record tycon) get `XmlDocSigOfProperty [ ptext; tc.CompiledName; rf.Id.idText ]` ("represents a record field, which is exposed as a property"); otherwise `XmlDocSigOfField [ ptext; tc.CompiledName; rf.Id.idText ]`.
  - `doModuleMemberSig path (m)` — `m.XmlDocSig <- XmlDocSigOfSubModul [ path ]` for module members.
  - `rec doModuleSig path (mspec)` — builds the dotted path (`None | Some "" -> Some mspec.LogicalName | Some p -> Some (p + "." + mspec.LogicalName)`), then recurses into `mtype.ModuleAndNamespaceDefinitions`, `mtype.ExceptionDefinitions`, `vals` (filtered to `not x.IsCompilerGenerated && (x.MemberInfo.IsNone || x.IsExtensionMember)`), and `mtype.TypeDefinitions`.
  - Kicked off by `doModuleSig None generatedCcu.Contents`.

- **`WriteXmlDocFile (g, assemblyName, generatedCcu, xmlFile) -> unit`** — the emitter. Internal helpers:
  - Requires the `.xml` suffix: `if not (FileSystemUtils.checkSuffix xmlFile "xml") then error (Error(FSComp.SR.docfileNoXmlSuffix (), Range.rangeStartup))`.
  - Creates a fresh `let includeEnv = XmlDocIncludeExpander.mkExpansionEnv ()`.
  - `addMember id xmlDoc` — if doced, `let doc = xmlDoc.GetExpandedXmlText(true, includeEnv); members <- (id, doc) :: members` (i.e. `<include>` is evaluated here).
  - `doVal v -> addMember v.XmlDocSig v.XmlDoc`; `doField rf -> addMember rf.XmlDocSig rf.XmlDoc`; `doUnionCase uc -> addMember uc.XmlDocSig uc.XmlDoc` plus each field's member; `doTycon tc ->` the tycon + each member (skipping `v` for which `ComputeUseMethodImpl g v` is true — i.e. a method-impl pair whose doc belongs on the extension side) + its union cases + fields.
  - `modulMember m -> addMember m.XmlDocSig m.XmlDoc`.
  - `rec doModule mspec` — same shape as `doModuleSig` but calls the `addMember` family.
  - Kicked off by `doModule generatedCcu.Contents`.
  - Finally writes the file: opens `FileSystem.OpenFileForWriteShim(xmlFile, FileMode.Create).GetWriter()`, and `fprintfn`s the following lines in this exact order:
    ```
    <?xml version="1.0" encoding="utf-8"?>
    <doc>
    <assembly><name>%s</name></assembly>   (with assemblyName)
    <members>
    <member name="%s">                      (once per documented item)
    %s                                       (the expanded doc text, verbatim)
    </member>
    </members>
    </doc>
    ```

**Public API surface** `ComputeXmlDocSigs` and `WriteXmlDocFile` — see `XmlDocFileWriter.fsi.md`. Called from `FSharp.Compiler.Driver` (fsc.fs `main6`) only when `tcConfig.xmlDocOutputFile` is `Some`.

**Internal helpers / active patterns**
- The `do*` closures in each function; `addMember` is the single "record one doc entry" helper.
- `XmlDocIncludeExpander.mkExpansionEnv` + `XmlDoc.GetExpandedXmlText (true, includeEnv)` — the `<include>` expansion machinery (from `FSharp.Compiler.Xml`).
- `ComputeUseMethodImpl g v` (from `FSharp.Compiler.TypedTreeOps` / method-impl logic) — decides whether a val pair should be skipped in the top-level member list.
- `IsCompilerGenerated` and extension-member filtering — keep the output limited to user-visible members (matching the C# XML doc-file convention).

**Significant internal logic**
- **Two passes, two purposes.** `ComputeXmlDocSigs` is the *mutation* pass (it sets the `XmlDocSig` field on the tree so subsequent consumers — FCS, tooling, doc generation — can reuse the same ids); `WriteXmlDocFile` is a pure read-and-emit pass. They share the same walking shape but are independent functions so either can be called selectively.
- **Property-vs-field ids** is the F# ↔ C# interop decision: union-case fields and record fields are given `P:` ids (as properties) rather than `F:` because consumers see them as property accessors; the file's comments call this out explicitly ("union case fields are exposed as properties"; "represents a record field, which is exposed as a property").
- **`<include>` vs `<inheritdoc>`.** `<include href="…"/>` is resolved at write time (self-contained XML file); `<inheritdoc/>` is *not* resolved here — the .fsi states it "is written to the XML file as-is; resolution happens at tooling time" (DocFX/Sandcastle). This is the documented split of responsibility.
- **Compiler-generated and method-impl filtering.** The `vals` list is filtered to `not x.IsCompilerGenerated && (x.MemberInfo.IsNone || x.IsExtensionMember)`, and `doTycon` additionally skips a val for which `ComputeUseMethodImpl g v` holds — this prevents double-doc entries for a base method and its override/extension pair.
- **Output is line-oriented text** (not an XML library) — one `fprintfn` per element, which keeps the module free of any XML serializer dependency and matches the file's hand-rolled format (the header/assembly/members wrapper is the same shape as the C# compiler's XML doc output).

**Cross-refs**
- Consumed by: `FSharp.Compiler.Driver` (fsc.fs `main6`).
- Depends on: `FSharp.Compiler.TypedTree` (`CcuThunk`, `ModuleOrNamespaceType`, `Val`, `Tycon`, `UnionCase`, `RecdField`, `XmlDocSig*`), `FSharp.Compiler.Xml` (`XmlDoc`, `XmlDocIncludeExpander`, `GetExpandedXmlText`), `FSharp.Compiler.TcGlobals` (for `ComputeUseMethodImpl` context), `FSharp.Compiler.IO` (`FileSystem.OpenFileForWriteShim`, `FileSystemUtils.checkSuffix`), `FSharp.Compiler.Diagnostics` (the `error (Error(FSComp.SR.docfileNoXmlSuffix (), Range.rangeStartup))` case).
