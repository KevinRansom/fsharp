# BinaryResourceFormats.fs

**Purpose** Low-level generators for the binary resource formats the F# compiler synthesizes into PE files: `.res` (Win32 resource) nodes, the Win32 version resource (`VS_VERSION_INFO`) and the Win32 application/assembly manifest resource. Emits little-endian byte arrays that Abstract IL later links into the output assembly (via `linkNativeResources`), so the compiler needs no external .res or mt.exe tooling.

**Pipeline role** Final emit stage: once `CreateILModule` has the `ILModuleDef`, and the user requested a Win32 manifest (e.g. `--win32manifest` / `includewin32manifest`) and/or a version resource (via `-version:` / `--win32res`-adjacent settings), these functions produce the byte blobs that become `ILResource`s on the module.

**Namespace(s)** `FSharp.Compiler` — module `FSharp.Compiler.BinaryResourceFormats`, declared `internal`.

**Modules declared**

- **`BinaryGenerationUtilities`** — little-endian byte encoding primitives used by every other node builder in the file:
  - `b0/b1/b2/b3 n` — extract byte 0..3 of an `int32` (mask + unsigned shift), so `i16`/`i32` can emit pure little-endian bytes regardless of host endianness.
  - `i16 (i: int32) -> byte[]` — two-byte little-endian word; `i32 (i: int32) -> byte[]` — four-byte little-endian DWORD.
  - `Padded initialAlignment (v: byte[]) -> byte[]` — appends zero bytes until the cumulative length (`initialAlignment + v.Length`) is a multiple of 4, matching the PE resource alignment rule.

- **`ResFileFormat`** — the `.res` container node format (what a `.res` file actually is: a stream of these nodes):
  - `ResFileNode (dwTypeID, dwNameID, wMemFlags, wLangID, data: byte[])` — emits the 28-byte header (dwDataSize, dwHeaderSize=0x20, dwTypeID with the 0xFFFF "by value" low marker, dwNameID likewise, dwDataVersion, wMemFlags, wLangID, dwVersion, dwCharacteristics) followed by `Padded 0 data`.
  - `ResFileHeader ()` — the empty node (`ResFileNode 0x0 0x0 0x0 0x0 [||]`), i.e. a `.res` file with only a header.

- **`VersionResourceFormat`** — builds the full `VS_VERSION_INFO` tree laid out as nested `RESERVED` nodes:
  - `VersionInfoNode (data: byte[])` — the two-word `wLength` prefix (total node length in bytes, including itself) that every `VS_VERSION_INFO` sub-node must carry.
  - `VersionInfoElement (wType, szKey, valueOpt, children, isString)` — one element: `wValueLength` (for strings this is the **word** count, so `value.Length/2`; for binary values the byte count), `wType`, the padded null-terminated Unicode key, the padded value (if any), and then all children in order.
  - `Version (version: ILVersionInfo)` — packs the four version parts into the two DWORDs (MS/LS) per the spec (Major/Minor in MS, Build/Revision in LS).
  - `String (string, value)` — a leaf string element (wType 0x1).
  - `StringTable (language, strings)` — a named string table under a language key.
  - `StringFileInfo (stringTables)` — the "StringFileInfo" wrapper element.
  - `VarFileInfo (vars: #seq<int32 * int32>)` — the "VarFileInfo" wrapper; each `(lang, codePage)` becomes a `Translation` element (wType 0x0) whose value is the two little-endian words.
  - `VS_FIXEDFILEINFO (fileVersion, productVersion, dwFileFlagsMask, dwFileFlags, dwFileOS, dwFileType, dwFileSubtype, lwFileDate)` — the fixed block: 0xFEEF04BD signature, 0x00010000 structure version, file version (2 DWORDs), product version (2 DWORDs), the flag mask, flags (VS_FF_DEBUG/PRERELEASE/SPECIALBUILD/… semantics documented in-line), OS (VOS_DOS/NT/WINDOWS…), file type (VFT_APP/DLL/DRV/…), subtype, and the 64-bit file date split into the two high/low DWORDs.
  - `VS_VERSION_INFO (fixedFileInfo, stringFileInfo, varFileInfo)` — the root node (wType 0x0, key "VS_VERSION_INFO") carrying the fixed block as its value and the two file-info children.
  - `VS_VERSION_INFO_RESOURCE data` — public wrapper: embeds the `VS_VERSION_INFO` tree in a `.res` node of resource type 0x0010 (RT_VERSION), name id 0x0001, with `wMemFlags = 0x0030` (a comment in the file notes this is *hardwired to English*), `wLangID = 0x0`.

- **`ManifestResourceFormat`** —
  - `VS_MANIFEST_RESOURCE (data, isLibrary)` — wraps the manifest XML bytes in a `.res` node of resource type 0x0018 (RT_MANIFEST), name id 0x0002 if `isLibrary` else 0x0001, memFlags 0, langId 0.

**Public API surface** `ResFileFormat.ResFileHeader`, `VersionResourceFormat.VS_VERSION_INFO_RESOURCE`, `ManifestResourceFormat.VS_MANIFEST_RESOURCE` (signatures in the .fsi).

**Internal helpers / active patterns**
- `Padded` — the only helper shared across all modules in the file; everything else is a local builder.
- Keys/values are produced by `FSharp.Compiler.IO.Bytes.stringAsUnicodeNullTerminated` (UTF-16LE + NUL), which is what the PE format requires for these string fields.
- All numeric fields use the explicit little-endian encoders (no `Marshal` dependency), so the output is identical on LE and BE hosts.

**Significant internal logic**
- The `wValueLength` asymmetry (words for text, bytes for binary) is the main correctness trap; the file carries a comment explaining it in `VersionInfoElement`.
- The `children` arrays are emitted *after* the value, in declaration order — the PE reader walks the stream positionally, so ordering matters.
- The file's purpose comment refers to the `VS_VERSION_INFO` spec (piclist link) — the layout matches the SDK headers verbatim, which is why `wMemFlags`/`wLangID` can safely be constants in the wrapper.

**Cross-refs**
- `FSharp.Compiler.CreateILModule` — consumes `VS_MANIFEST_RESOURCE` when building the module's `ManifestOfAssembly`, and `VS_VERSION_INFO_RESOURCE` when a version is set.
- `FSharp.Compiler.IO` — `Bytes` helpers.
- `FSharp.Compiler.AbstractIL.IL` — `ILVersionInfo` (the four-part version type used as the file/product version input).
