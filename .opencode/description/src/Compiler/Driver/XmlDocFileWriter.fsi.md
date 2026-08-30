# XmlDocFileWriter.fsi

**Purpose** Signature for the XML documentation file writer. Declares the two entry points of the `XmlDocWriter` module: `ComputeXmlDocSigs`, which assigns each documented element its unique documentation signature (the `M:`/`T:`/`P:`/… id used as the `<member name="…">` key), and `WriteXmlDocFile`, which renders the documented CCU into a `.xml` documentation file.

**Pipeline role** Last optional stage (fsc `main6`): runs only when `tcConfig.xmlDocOutputFile` is set. It walks the *already-checked* assembly (`CcuThunk`) — no type checking happens here — and emits the C#/F#-compatible XML documentation file.

**Namespace(s)** `FSharp.Compiler` — module `FSharp.Compiler.XmlDocFileWriter` (internal), with one public submodule `XmlDocWriter`.

**Functions declared (contract)**

- **`XmlDocWriter.ComputeXmlDocSigs : tcGlobals: TcGlobals * generatedCcu: CcuThunk -> unit`**
  "Writes the XML document signature to the `XmlDocSig` property of each element (field, union case, etc.) of the specified compilation unit."
  - Populates `v.XmlDocSig <- XmlDocSigOfVal g false ptext v` for documented vals, `tc.XmlDocSig <- XmlDocSigOfTycon [ ptext; tc.CompiledName ]` for documented type constructors, union cases (`XmlDocSigOfUnionCase [ ptext; tc.CompiledName; uc.Id.idText ]`), union-case fields and record fields exposed as properties (`XmlDocSigOfProperty …`), and plain fields (`XmlDocSigOfField …`), and sub-modules (`XmlDocSigOfSubModul`).
  - The signature is *the unique identifier of the XML doc entry in the generated XML documentation file* — i.e. the `name="…"` attribute value of a `<member>` element.
  - The "full format" is described at the C# documentation-comments ID string spec (linked in the doc comment; e.g. `T:Namespace.Type`, `M:…`, `P:Namespace.Type.Member`, `F:…`).
  - Runs as a side-effecting pass (`unit` return) so that other consumers of the CCU (e.g. FCS) can read the same ids later.

- **`XmlDocWriter.WriteXmlDocFile : g: TcGlobals * assemblyName: string * generatedCcu: CcuThunk * xmlFile: string -> unit`**
  "Writes the `XmlDocSig` property of each element (field, union case, etc.) of the specified compilation unit to an XML document in a new text file."
  - Requires the `.xml` suffix (the .fs errors with `docfileNoXmlSuffix` otherwise).
  - Emits `<?xml version="1.0" encoding="utf-8"?>`, `<doc>`, `<assembly><name>…</name></assembly>`, `<members>`, one `<member name="id">…doc…</member>` per documented item, closing tags — via `fprintfn` to a `TextWriter` opened by `FileSystem.OpenFileForWriteShim(xmlFile, FileMode.Create)`.
  - `<include>` elements are **expanded at write time** using an `XmlDocIncludeExpander` environment (`GetExpandedXmlText(true, includeEnv)`).
  - `<inheritdoc>` elements are **written to the XML file as-is** — the doc comment states "resolution happens at tooling time" (i.e. DocFX/Sandcastle resolve inheritance later).

**Public API surface** Just these two functions. There are no other public bindings in the module.

**Internal helpers / active patterns** In the .fs: the small `hasDoc (doc) = not doc.IsEmpty` predicate, and the two families of recursive walkers (`doValSig`/`doTyconSig`/`doModuleSig` in `ComputeXmlDocSigs`; `doVal`/`doField`/`doUnionCase`/`doTycon`/`doModule` in `WriteXmlDocFile`) — both are `private` (not in the .fsi, but visible to the same assembly). Member lists are filtered to `not x.IsCompilerGenerated && (x.MemberInfo.IsNone || x.IsExtensionMember)` (i.e. skip compiler-generated helpers; keep extension members), and `doTycon` skips vals for which `ComputeUseMethodImpl g v` is true unless they have their own doc.

**Significant internal logic**
- **Two passes are deliberate.** `ComputeXmlDocSigs` is a *mutation* pass (it writes the `XmlDocSig` fields on the checked tree), and `WriteXmlDocFile` is a pure *read + emit* pass. `ComputeXmlDocSigs` is also called for assemblies that don't end up writing an XML file, because tooling may want the ids.
- **Property-vs-field ids.** Union-case fields and record fields are exposed through the *property* surface in the IL, so they get `P:` ids (not `F:`), which is the F# XML file's interop story with the C# doc-id scheme.
- **`<include>` vs `<inheritdoc>`.** `<include href="…"/>` is expanded during emit (self-contained XML), while `<inheritdoc/>` is intentionally left for the consuming tool — this is the documented behavior in the .fsi.
- Skips **compiler-generated vals** (`IsCompilerGenerated`) and **method-impl pairs** (`MethodInfo.IsSome && not IsExtensionMember`) at the top level of a module, matching the C# convention that a "method" has one doc entry.

**Notes / caveats**
- Both functions are pure over the *checked* CCU: they read from (and `ComputeXmlDocSigs` mutates only the doc-sig fields of) the `CcuThunk`. No parsing, no checking, no code generation happens here — placing this last in the pipeline (fsc `main6`, after the `.dll` and `.pdb` are written) means a doc-file failure cannot corrupt the emitted binary.
- The output document is deliberately *flat and order-preserving* (`members` in tree order) so that doc tooling that expects a stable, dependency-free file (DocFX, Sandcastle, VS) can consume it directly; it is not an XML-schema-validating writer.
- Because `ComputeXmlDocSigs` is a separate public function of the same module, hosts (e.g. FCS / FSharp.LanguageService) can compute doc-sigs for completion/intellisense without ever writing a file — the two functions are the two halves of one capability.

**Cross-refs** `FSharp.Compiler.Driver` (fsc.fs `main6`), `FSharp.Compiler.TypedTree` (`CcuThunk`, `ModuleOrNamespaceType`, `Val`, `Tycon`, `UnionCase`, `RecdField`, the `XmlDocSig*` id builders), `FSharp.Compiler.Xml` (`XmlDoc`, `XmlDocIncludeExpander`), `FSharp.Compiler.TcGlobals`, `FSharp.Compiler.IO` (`FileSystem.OpenFileForWriteShim`), `FSharp.Compiler.Diagnostics` (the `error (Error...)` on wrong suffix).
