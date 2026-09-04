# BinaryResourceFormats.fsi

**Purpose** Signature file for `FSharp.Compiler.BinaryResourceFormats`. Exposes the subset of the internal binary-blob generation API that other compiler modules may use: the public `VS_VERSION_INFO_RESOURCE`, `VS_MANIFEST_RESOURCE` and `ResFileHeader` entry points. The F# compiler synthesizes these Win32 PE resources directly (it does not invoke an external `.res` linker or `mt.exe`), so this contract is the narrow surface through which the rest of the driver asks for a pre-built byte blob.

**Pipeline role** Consumed during final module creation — after `CreateILModule` has assembled the `ILModuleDef`, the manifest and version resources (when the user gave `--win32manifest` or a version flag) are attached as `ILResource`s built by these functions and then linked into the PE by Abstract IL (`linkNativeResources`).

**Namespace(s)** `FSharp.Compiler` — module `FSharp.Compiler.BinaryResourceFormats`, declared `internal`.

**Modules declared (contract)**

The file is a flat `module internal` containing three nested modules; the `.fsi` mirrors exactly those three.

- **`VersionResourceFormat`** — exposes `VS_VERSION_INFO_RESOURCE`, which renders a Win32 `VS_VERSION_INFO` version resource (fixed file info + StringFileInfo + VarFileInfo) as a self-contained `.res`-format node of bytes.
- **`ManifestResourceFormat`** — exposes `VS_MANIFEST_RESOURCE`, which wraps a compiled Win32 manifest byte buffer in a `.res` node (resource name id 1 for executables, 2 for libraries/dlls).
- **`ResFileFormat`** — exposes `ResFileHeader`, the `.res` container header node (zero-length data), the building block shared by both of the above.

**Public API surface (per signature)**

- `VersionResourceFormat.VS_VERSION_INFO_RESOURCE:`
  `(ILVersionInfo * ILVersionInfo * int32 * int32 * int32 * int32 * int32 * int64) *
   seq<string * #seq<string * string>> *
   seq<int32 * int32> -> byte[]`

  Builds the whole Win32 version-resource blob from its logical pieces. The first argument is the fixed-file-info tuple: file `ILVersionInfo`, product `ILVersionInfo`, then the four `dwFileFlagsMask / dwFileFlags / dwFileOS / dwFileType / dwFileSubtype` DWORDs, and finally the 64-bit file date. The second argument is the per-language string tables (language key → sequence of (name,value) pairs), rendered into `StringFileInfo`. The third argument is the sequence of (language, codePage) translation entries rendered into `VarFileInfo` ("Translation" children).

- `ManifestResourceFormat.VS_MANIFEST_RESOURCE: data: byte[] * isLibrary: bool -> byte[]`
  `data` is the manifest XML bytes (already serialized by the toolchain); `isLibrary` selects which resource name id is used (library/dll → 0x0002, exe → 0x0001).

- `ResFileFormat.ResFileHeader: unit -> byte[]`
  A header-only `.res` node — the minimum well-formed `.res` container.

**Internal helpers / active patterns**

Not exposed in the signature. The full `.fs` implementation — low-level `b0..b3` byte encoders, `i16`/`i32`, `Padded` (32-bit alignment), `ResFileNode`, `VersionInfoNode`, `VersionInfoElement`, `Version`, `String`, `StringTable`, `StringFileInfo`, `VarFileInfo`, `VS_FIXEDFILEINFO`, `VS_VERSION_INFO` — is module-internal to the `.fs` and is consumed only by the two public wrappers above.

**Significant internal logic**

- The contract fixes the *shape* of the inputs the version builder needs (two `ILVersionInfo`s — file and product — plus the fixed-info DWORDs and the 64-bit date), so callers do not need to understand the PE `VS_FIXEDFILEINFO` layout at all.
- The word-vs-byte `wValueLength` rule for string values, and the alignment of every node, is hidden behind `VS_VERSION_INFO_RESOURCE`.
- The signature deliberately keeps the three modules separate because callers typically use only one of them: the version info (most common), the manifest (when a Win32 manifest file is supplied), or a bare header (rare).
- `dwMemFlags`/`wLangID` in the version resource wrapper are hardcoded to English (0x0030 / 0x0) in the `.fs`; the signature does not surface this, which callers should know when localizing expected outputs.

**Cross-refs**

- `FSharp.Compiler.CreateILModule` — attaches the manifest resource to `ILManifest` and the version resource where appropriate.
- `FSharp.Compiler.AbstractIL.IL` — `ILVersionInfo` (input to `VS_VERSION_INFO_RESOURCE`).
- `FSharp.Compiler.IO` — `Bytes.stringAsUnicodeNullTerminated` used by the `.fs` builders.
- See sibling description `BinaryResourceFormats.fs.md` for the per-node implementation details.
