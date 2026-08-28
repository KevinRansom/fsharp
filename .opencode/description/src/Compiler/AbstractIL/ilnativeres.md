# ilnativeres.fs

**Purpose**
F#-native port of Roslyn's `NativeResourceWriter.cs` and `CvtRes.cs` (and their dependencies) — the Windows-native-resource reading/writing machinery the F# compiler uses when embedding `.resources` (icons, version info, manifests, `RT_DLGINCLUDE`, etc.) into a .NET assembly. Provides: F#-native `RESOURCE`/`RESOURCE_STRING`/`Win32Resource` types, a `CvtResFile.ReadResFile` reader for a `.resources`-style binary stream, `StreamExtensions`/`COFFResourceReader` for the raw COFF-format resource directory, `VersionHelper`/`VersionResourceSerializer`/`ICONDIRENTRY` for `VS_VERSION_INFO` and icon resources, the `Win32ResourceConversions` aggregator (Append*Icon* / *Version* / *Manifest*), and `NativeResourceWriter` (sort + serialize the resource tree into a `BlobBuilder`).

**Namespace(s)**
- `FSharp.Compiler.AbstractIL` (module `internal FSharp.Compiler.AbstractIL.NativeRes`)

**Key type declarations (selected)**
- `BYTE = byte`, `DWORD = uint32`, `WCHAR = Char`, `WORD = uint16`; inline `WORD s : uint16`.
- `ResourceException(name, ?inner)` — exception type with a localized `FSComp.SR` name.
- `RESOURCE_STRING()`, `RESOURCE()` — F#-native mirror of the C structures (Ordinal/theString; pstringType/pstringName/DataSize/HeaderSize/DataVersion/MemoryFlags/LanguageId/Version/Characteristics/data).
- `CvtResFile()` — has `ReadResFile(stream) : List<RESOURCE>`; parses the CvtRes format: header (initial 32-bit zero), then per-resource: (cbData, cbHdr) followed by the `ResFormatHeader` and the type/name `IMAGE_RESOURCE_DIR_STRING` structures.
- `SectionCharacteristics` — enum-like flags for the `.rsrc` section (READ, WRITE, etc.).
- `ResourceSection()` — the in-memory representation of a single output section.
- `StreamExtensions()` — `Stream` helpers (seek/length).
- `COFFResourceReader()` — reader for a COFF `RT_RSRC` (or similar) directory from a Windows `.lib`-style or `.res` stream.
- `ICONDIRENTRY` — F#-native icon-directory entry.
- `VersionHelper()` — helpers for the VS_VERSION_INFO structure.
- `VersionResourceSerializer()` — serializer for `VS_VERSION_INFO` with the `STRINGTABLE` / `VAR` sub-structures.
- `Win32ResourceConversions()` — `AppendIconToResourceStream`, `AppendVersionToResourceStream`, `AppendManifestToResourceStream` (all per the `ilnativeres.fsi` contract).
- `Win32Resource(data, codePage, languageId, id, name, typeId, typeName)` — high-level wrapper used by `NativeResourceWriter`.
- `Directory(name, id)` — internal type/name pair helper.
- `NativeResourceWriter()` — `SortResources`, `SerializeWin32Resources(builder, theResources, resourcesRva)` (per contract).

**Significant internal logic**
- The CvtRes file format (Roslyn's) is: an initial 4-byte zero, then per-resource a (cbData, cbHdr) pair where cbHdr >= 8 (two dwords: type and name ordinals as `IMAGE_RESOURCE_DIR_STRING`), and the payload (cbData) which is either a `ResFormatHeader` (cbData > 0) or a reference to a `Directory` (cbData = 0).
- Sorting of resources for deterministic output is done in `NativeResourceWriter.SortResources` by (typeId, name, languageId, data).
- All serialization emits little-endian via `ByteBuffer` / `BlobBuilder` (from `System.Reflection.Metadata`).

**Cross-references**
- `ilnativeres.fsi` (contract), `ilwrite.fs` (consumer: native-resource emission into a .NET assembly), `ilsupp.fs` (linking / unlinking of the resource buffers)
