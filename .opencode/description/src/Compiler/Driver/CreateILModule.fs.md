# CreateILModule.fs (implementation)

**Purpose** Assembles the final IL module (`ILModuleDef`) of the output assembly. Combines the optimized/type-checked code (the `IlxGenResults` from the optimizer/codegen pass), the F# signature + optimization data resources, reflected-definition resources, embedded/linked resources, strong-name signing config, type forwarders, and the Win32 manifest/version resources into a single output module. Also centralizes strong-name signing validation.

**Pipeline role** fsc `main5`: after `OptimizeInputs` produced `IlxGenResults` and static linking (when enabled) has been folded in, `CreateMainModule` is the last structural step before the driver writes bytes to disk.

**Namespace(s)** `FSharp.Compiler` — module `FSharp.Compiler.CreateILModule`, `internal`.

**Module `AttributeHelpers`** (line ~30)
- `TryFindStringAttribute (g: TcGlobals) attrib attribs -> string option` — locate a string-literal custom attribute by full type name (e.g. `System.Reflection.AssemblyCultureAttribute`).
- `TryFindIntAttribute` — same for `int32` argument (used for `AssemblyAlgorithmIdAttribute`, `AssemblyFlagsAttribute`).
- `TryFindBoolAttribute` — same for bool.
- `|ILVersion|_| (versionString: string)` active pattern (line ~58) — parses a dotted version string to an `ILVersionInfo` (used when a version attribute argument is a string rather than a `Version` struct literal).

**Top-level functions**
- `StrongNameSigningInfo` (line ~69) — record `{ delaysign; publicsign; signer: byte array option; container: string option }`.
- `GetStrongNameSigningInfo (delaysign, publicsign, signer, container)` (line ~72) — record constructor.
- `ValidateKeySigningAttributes (tcConfig, tcGlobals, topAttrs)` (line ~76) — cross-checks CLI flags and attributes:
  - Reads `[<DelaySign>]` (`delaySignAttrib`), `[<AssemblyKeyFile>]` (`signerAttrib`), `[<AssemblyOriginatorKeyFile>]` (`container`-side) from `topAttrs.assemblyAttrs`.
  - Merges with `tcConfig.delaysign`/`tcConfig.publicsign`/`tcConfig.signer`/`tcConfig.container`; errors via `ValidateStrongNameSigning`-style checks when both a key file and a container are specified, when a delay-sign conflicts, and when a signer key string is given as a file (loads the bytes).
  - Returns the combined `StrongNameSigningInfo`.
- `GetStrongNameSigner signingInfo` (line ~137) — destructures the record and builds the `ILStrongNameSigner` (delaysign signer, public-sign signer, or full-sign key signer; `None` when no signing).

**Module `MainModuleBuilder`** (line ~155)
- `injectedCompatTypes` (line ~157) — the set of compat types injected by the compiler that get *forwarded out* for binary compatibility: `System.Tuple`1..8``, `System.ITuple`, `System.Tuple`, `System.Collections.IStructuralComparable`, `System.Collections.IStructuralEquatable`.
- `typesForwardedToMscorlib` (line ~174) — types that must forward to the primary assembly (e.g. `System.AggregateException`, `System.Threading.CancellationToken{,Registration,Source}`, `System.Lazy`1``, `System.IObservable`1``, `System.IObserver`1``).
- `typesForwardedToSystemNumerics` (line ~186) — `System.Numerics.BigInteger`.
- `createMscorlibExportList (tcGlobals)` (line ~188) — builds `ILExportedType` forwarders toward `tcGlobals.ilg.primaryAssemblyScopeRef` for the union of the two sets *excluding* `System.ITuple` (comment: forwarding it causes FxCop failures on .NET 4.0); used only when `tcConfig.compilingFSharpCore`.
- `createSystemNumericsExportList (tcConfig, tcImports)` (line ~201) — finds the imported `System.Numerics` (or `System.Runtime.Numerics`, based on `primaryAssembly.Name`) and emits `BigInteger` forwarders toward that specific assembly ref (commented `0x00200000 ||| TypeAttributes.Public` flags = forwarder semantics).
- `ComputeILFileVersion findStringAttr assemblyVersion` (line ~237) — final file version: prefer `AssemblyFileVersionAttribute` when it parses as an `ILVersion` (otherwise keep the input and let CheckExpressions warn).
- `ComputeProductVersion findStringAttr fileVersion` (line ~247) — final product-version *string*: prefer `AssemblyInformationalVersionAttribute`, else dotted 4-part form.
- `ConvertProductVersionToILVersionInfo (version: string)` (line ~261) — tolerant parse: splits on `.`, parses each part as `UInt16` (zero on failure; the 4th part has trailing characters stripped, e.g. `"1.2.3-beta04"`), pads with zeros to four parts.
- `CreateMainModule (...)` (line ~286) — the main entry; sequence:
  1. `RequireCompilation ctok` — thread-safety guard.
  2. **Type defs:** merge `codegenResults.ilTypeDefs` with `tcGlobals.tryRemoveEmbeddedILTypeDefs ()` filtered by `isEmbeddableTypeWithLocalSourceImplementation` (types in the embeddable known set that are *not* already compiled locally — i.e. FSharp.Core types whose impl lives in-source and must be re-emitted for embedding).
  3. **Module skeleton:** read `AssemblyAlgorithmIdAttribute` (hash Alg), `AssemblyCultureAttribute` (locale — errors `fscAssemblyCultureAttributeError` if set on a non-Dll target), `AssemblyFlagsAttribute`; decide `isDLL` from `target`; build via `mkILSimpleModule assemblyName ilModuleName isDLL subsystemVersion useHighEntropyVA ilTypeDefs hashAlg locale flags (mkILExportedTypes exportedTypesList) metadataVersion` (where `ilModuleName = GetGeneratedILModuleName tcConfig.target assemblyName`).
  4. **Version:** `tcVersion = tcConfig.version.GetVersionInfo tcConfig.implicitIncludeDir` (i.e. the `-version:` string, parsed with `parseILVersion`).
  5. **Reflected definitions:** for each `(referencedTypeDefs, reflectedDefinitionBytes)` in `codegenResults.quotationResourceInfo`, generate a unique resource name (`SerializedReflectedDefinitionsResourceNameBase + "-" + assemblyName + "-" + newUnique + "-" + hash`), and when `QuotationGenerationScope.ComputeQuotationFormat` supports `DeserializeEx` emit the `CompilationMappingAttribute` for quotation resources; the bytes become a public local `ILResource`.
  6. **Manifest attributes:** compile-relaxations when `not internConstantStrings` (`CompilationRelaxationsAttribute(8)`), the F# signature-data attributes, `codegenResults.ilAssemAttrs`, the Debuggable attribute (only when a pdbfile is emitted, `tcGlobals.mkDebuggableAttributeV2 (jitTracking, disableJitOptimizations)`), and the reflected-definition attrs.
  7. **`ManifestOfAssembly`:** skip for `CompilerTarget.Module` (netmodule has no identity); otherwise set `Version = assemVerFromAttrib ?? tcVersion`, `CustomAttrsStored`, `DisableJitOptimizations` (when local optimizations are off), `JitTracking`, `SecurityDeclsStored` from `secDecls`.
  8. **Resources:** `tcConfig.embedResources` are read off disk (after `SplitCommandLineResourceInfo` + `ResolveSourceFile`) and turned into local `ILResource`s with the parsed privacy (`public`/`private`); followed by the reflected-definition resources, the signature-data resources, the optimization-data resources; then `tcConfig.linkResources` are turned into `ILResourceLocation.File (ILModuleRef.Create (name, hasMetadata=false, hash=sha1 bytes of file))` — i.e. `.resources`-side file *references* rather than embedded bytes.
  9. Returns the fully assembled `ILModuleDef` for `main5` to save (pdb emission, `CopyFSharpCore`, XML-doc writing happen around it in the driver).

**Public API surface** `CreateMainModule` (driver `main5`), `GetStrongNameSigningInfo`, `ValidateKeySigningAttributes`, `GetStrongNameSigner`, and the `MainModuleBuilder` version helpers (`ComputeILFileVersion`, `ComputeProductVersion`, `ConvertProductVersionToILVersionInfo` — also used by unit tests per the doc comments).

**Internal helpers / active patterns**
- `|ILVersion|_|` — parses version strings in attribute arguments.
- `isEmbeddableTypeWithLocalSourceImplementation` — the predicate that decides which of the compiler's "embeddable" known types get re-emitted as local type defs (embedding scenario).
- `SplitCommandLineResourceInfo` (in `CompilerConfig`) — parses `file[,name[,public|private]]` resource spec, reused here for both `embedResources` and `linkResources`.

**Significant internal logic**
- This is the single place where the whole "IL assembly" is put together. Splitting it out from the driver lets the pipeline replay cleanly with different identity/emit settings (e.g. reference-assembly vs implementation-assembly).
- Type forwarders solve the "compile against mscorlib, run against netstandard/System.Runtime" binary-compat problem for the known inject types and `BigInteger`.
- Strong-name signing is validated up front (`ValidateKeySigningAttributes`) so a key/signer conflict is a recoverable error *before* any IL is emitted, not a corrupted binary.
- Resource handling splits cleanly into three kinds: **embedded bytes** (`embedResources` → `ILResourceLocation.Local`), **data blobs** (signature/optimization/reflected-def) and **linked files** (`linkResources` → `ILResourceLocation.File` + `ILModuleRef` hash) — this is the exact `--resource:` vs `--linkresource:` distinction.

**Cross-refs**
- Consumed by: `FSharp.Compiler.Driver` (fsc.fs `main5`).
- Depends on: `FSharp.Compiler.IlxGen` (`IlxGenResults`, `GetGeneratedILModuleName`), `FSharp.Compiler.CompilerImports` (`ImportedAssembly` for the numerics lookup), `FSharp.Compiler.AbstractIL.IL` + `.StrongNameSign`, `FSharp.Compiler.QuotationPickler`/`QuotationTranslator` (reflected definitions + `CompilationMapping`), `FSharp.Compiler.BinaryResourceFormats` (version + manifest resource blobs), `FSharp.Compiler.TcGlobals` (sys type refs, `tryRemoveEmbeddedILTypeDefs`), `FSharp.Compiler.TypedTree` (`TopAttribs`).
