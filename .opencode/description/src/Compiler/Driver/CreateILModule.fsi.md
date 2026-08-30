# CreateILModule.fsi

**Purpose** Signature for creating the destination IL module for a completed compile. Declares the strong-name signing helpers (validate attributes/CLI flags, materialize the signer object) and `MainModuleBuilder.CreateMainModule`, the single function that assembles the finished `ILModuleDef` from the codegen results, resources, attributes, signature/optimization data, and version/security configuration.

**Pipeline role** Near-final stage (fsc `main5`): after `OptimizeInputs` produced `IlxGenResults` and `StaticLinking` (optionally) spliced foreign type bodies into the main module, this function stitches everything — types, security declarations, embedded/linked resources, forwarders, strong name, version, manifest — into the output `ILModuleDef` that the driver then saves (and around which it emits the PDB and XML doc file).

**Namespace(s)** `FSharp.Compiler` — module `FSharp.Compiler.CreateILModule`, declared `internal`.

**Types / functions (contract)**

- **`StrongNameSigningInfo`** — the record bundling the four signing inputs: `delaysign: bool`, `publicsign: bool`, `signer: byte array option` (the raw key bytes, normally already read from a `.snk`/key file), and `container: string option` (a key-container name). One type carries the whole "how to sign" decision.
- **`GetStrongNameSigningInfo (delaysign, publicsign, signer, container) -> StrongNameSigningInfo`** — the trivial record constructor, exposed so callers (or tests) can build the value directly from raw inputs.
- **`ValidateKeySigningAttributes (tcConfig, tcGlobals, topAttrs) -> StrongNameSigningInfo`** — the cross-check between the CLI flags (`--delaysign`, `--publicsign`, `--keyfile:`, `--keycontainer:`) and the assembly-level attributes on `topAttrs` (`[<DelaySign>]`, `[<PublicSign>]`, `[<AssemblyKeyFile>]`, `[<AssemblyOriginatorKeyFile>]`, `[<AssemblyKeyName>]`). Produces the final signing configuration; raises recoverable diagnostics on conflicts (e.g. both a key file and a container, or an attribute/flag disagreement) so the error surfaces *before* anything is emitted.
- **`GetStrongNameSigner signingInfo: StrongNameSigningInfo -> ILStrongNameSigner option`** — materializes the actual AbstractIL strong-name signer (delaysign signer, public-sign signer, or full-sign key signer); returns `None` when no signing is required.

- **`module AttributeHelpers`** — helpers for finding attributes on `topAttrs`:
  - `TryFindStringAttribute : TcGlobals -> attrib: string -> attribs: Attribs -> string option`
  - (The `.fs` also defines `TryFindIntAttribute`, `TryFindBoolAttribute`, and the `|ILVersion|_|` active pattern over version strings, used by the version-computation functions below.)

- **`module MainModuleBuilder`** — everything about final module assembly:
  - `CreateMainModule` — the main entry point. Signature (contract):
    `ctok * tcConfig * tcGlobals * tcImports * pdbfile * assemblyName * outfile *
     topAttrs * sigDataAttributes: ILAttribute list * sigDataResources: ILResource list *
     optDataResources: ILResource list * codegenResults: IlxGenResults *
     assemVerFromAttrib: ILVersionInfo option * metadataVersion: string *
     secDecls: ILSecurityDecls -> ILModuleDef`.
    Takes everything the earlier stages produced and returns the finished `ILModuleDef`. In the implementation this also emits type forwarders (compat types such as `System.Tuple*` and `System.Numerics.BigInteger`), reflected-definitions resources, the Win32 manifest (`Target <> Module`), and the embedded/linked resources from `tcConfig.embedResources` / `tcConfig.linkResources`.
  - `ComputeILFileVersion : (string -> string option) -> ILVersionInfo -> ILVersionInfo` — derive the IL file version, preferring `System.Reflection.AssemblyFileVersionAttribute` (doc comment: "For unit testing").
  - `ComputeProductVersion : (string -> string option) -> ILVersionInfo -> string` — derive the product-version *string*, preferring `System.Reflection.AssemblyInformationalVersionAttribute` (doc comment: "For unit testing").
  - `ConvertProductVersionToILVersionInfo : string -> ILVersionInfo` — parse a product-version string (possibly trailed, e.g. `"1.2.3-beta04"`) into the four-part `ILVersionInfo` (doc comment: "For unit testing").

**Public API surface**
- `CreateMainModule` — called by `FSharp.Compiler.Driver` (fsc.fs `main5`).
- `GetStrongNameSigningInfo` / `ValidateKeySigningAttributes` / `GetStrongNameSigner` — the signing trio, also called by `FSharp.Compiler.Driver` `main2` (`ValidateKeySigningAttributes` runs before codegen so signing errors surface early).
- `MainModuleBuilder.ComputeILFileVersion` / `ComputeProductVersion` / `ConvertProductVersionToILVersionInfo` — used by unit tests (per their doc comments) and by `FSharp.Compiler.Driver` when stamping the output.

**Internal helpers / active patterns**

- `|ILVersion|_|` (in `AttributeHelpers`, defined in the `.fs`) — parses a dotted version string into an `ILVersionInfo` so that version attributes whose argument is a string literal rather than a `Version` struct can still be read.
- `TryFindStringAttribute` / `TryFindIntAttribute` / `TryFindBoolAttribute` — the three lookup entry points used throughout the signing validation and version computation.
- The type-forwarder sets (`injectedCompatTypes`, `typesForwardedToMscorlib`, `typesForwardedToSystemNumerics`) and the two export-list builders (`createMscorlibExportList`, `createSystemNumericsExportList`) are internal to the `.fs`.

**Significant internal logic**

`CreateMainModule` is deliberately the single place where the whole "IL assembly" is put together. Separating it from the driver lets the pipeline be replayed with different identity/emit settings (implementation assembly vs reference assembly, different `outfile`, etc.) without re-doing the check or optimize passes, and it consumes the large `IlxGenResults` value exactly once. Strong-name signing is validated up front (`ValidateKeySigningAttributes`, invoked from `main2` before codegen) so a key/signer conflict is a recoverable error *before* any IL is generated, not a corrupted binary at save time.

**Cross-refs**

- Consumed by: `FSharp.Compiler.Driver` (fsc.fs `main2` for signing validation, `main5` for `CreateMainModule`).
- Depends on: `FSharp.Compiler.IlxGen` (`IlxGenResults`, `IlxGenBackend`, `GetGeneratedILModuleName`), `FSharp.Compiler.CompilerImports` (`ImportedAssembly` — looked up for the `System.Numerics` / `System.Runtime.Numerics` forwarder target), `FSharp.Compiler.AbstractIL.IL` + `.StrongNameSign` (the module & signer types), `FSharp.Compiler.BinaryResourceFormats` (the Win32 manifest / version resource blobs attached to the module), `FSharp.Compiler.TcGlobals` (system type refs, `tryRemoveEmbeddedILTypeDefs`), `FSharp.Compiler.TypedTree` (`TopAttribs`).
