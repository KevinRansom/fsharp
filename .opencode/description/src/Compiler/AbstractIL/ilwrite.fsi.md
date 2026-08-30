# ilwrite.fsi

**Purpose**
Interface contract for the IL binary writer (`ILBinaryWriter`). Declares the writer's `options` record (the full configuration for producing a .NET PE file: IL globals, output path, PDB options, checksum algorithm, strong-name signer, deterministic output, reference-assembly-only mode, path mapping, and the hot-reload baseline side channels for EnC CustomDebugInformation rows) and the two top-level entry points that serialize an `ILModuleDef` to a PE image (file or in-memory bytes).

**Namespace(s)**
- `FSharp.Compiler.AbstractIL` (module `internal FSharp.Compiler.AbstractIL.ILBinaryWriter`)

**TypeDefs declared**
- `options` (record) — all writer configuration: `ilg: ILGlobals`, `outfile: string`, `pdbfile: string option`, `portablePDB/emittedEmbeddedPDB/embedAllSource/embedSourceList`, `allGivenSources: ILSourceDocument list`, `sourceLink: string`, `checksumAlgorithm: HashAlgorithm`, `signer: ILStrongNameSigner option`, `emitTailcalls: bool`, `deterministic: bool`, `dumpDebugInfo: bool`, `referenceAssemblyOnly: bool`, `referenceAssemblyAttribOpt: ILAttribute option`, `referenceAssemblySignatureHash: int option`, `pathMap: PathMap`, plus the hot-reload EnC side channels `moduleCustomDebugInfoRows: PdbModuleCustomDebugInfo list` and `methodCustomDebugInfoRows: Map<string, PdbMethodCustomDebugInfo list>` (empty for ordinary compiles so flag-off output stays byte-identical).

**Public API surface**
- `markerForUnicodeBytes: byte[] -> int` — computes the trailing marker byte for a user-string blob (per ECMA-335 II.24.2.4).
- `WriteILBinaryFile (options) (inputModule: ILModuleDef) (normalizeAssemblyRefs: ILAssemblyRef -> ILAssemblyRef) : unit` — write the full assembly to the file system.
- `WriteILBinaryInMemory (options) (inputModule) (normalizeAssemblyRefs) : byte[] * byte[] option` — write the assembly to in-memory bytes (e.g. for dynamic loading); the second tuple element is the PDB bytes when a PDB was emitted.

**Cross-references**
- `ilwrite.fs` (implementation), `il.fs` (ILModuleDef, ILAssemblyRef), `ILPdbWriter.fs` (`PdbModuleCustomDebugInfo`, `PdbMethodCustomDebugInfo`), `ilsign.fsi` (`ILStrongNameSigner`), `EncMethodDebugInformation.fs` (producer of the EnC CDI rows), `FSharpDeltaMetadataWriter.fs` (hot-reload PE emitter building on top)
