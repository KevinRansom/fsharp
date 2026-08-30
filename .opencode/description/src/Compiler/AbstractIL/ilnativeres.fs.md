# ilnativeres.fs

## Pipeline role

Part of the AbstractIL layer. This is a focused F# port of Roslyn's native-resource support stack (`NativeResourceWriter.cs`, `CvtRes.cs` and dependencies). It reads/serializes Win32 resources and writes .resources-style output: reading `.res` files (`CvtResFile`), reading COFF `.rsrc$01`/`.rsrc$02` resource sections via PE headers, building `Win32Resource` trees, serializing them into the PE's `.rsrc` directory tree (type -> name -> language) as a `BlobBuilder`, converting .ico streams into RT_ICON/RT_GROUP_ICON resource entries, serializing the VS_VERSION_INFO version resource, appending RT_MANIFEST, and parsing assembly-version strings (including the `*` wildcard) through a `VersionHelper`.

## Namespaces and modules

- Module: `FSharp.Compiler.AbstractIL.NativeRes` (module `internal`)
- Uses: `System.Collections.Generic`, `System.Diagnostics`, `System.IO`, `System.Globalization`, `System.Reflection.Metadata` (`BlobBuilder`), `System.Reflection.PortableExecutable` (`PEHeaders`, `SectionHeader`), `System.Text`, `System.Linq` (`OrderBy\)), `Internal.Utilities.Library`; `open Checked`.

## Types

- Abbreviations: `BYTE = byte`, `DWORD = uint32`, `WCHAR = char`, `WORD = uint16`; `let inline WORD s = uint16 s`.
- `ResourceException(name, ?inner)` — exception type (message from `FSComp.SR.nativeResourceFormatError` / `nativeResourceHeaderMalformed`).
- `RESOURCE_STRING` (class) — `Ordinal: WORD`, `theString: string`.
- `RESOURCE` (class) — `pstringType`, `pstringName: RESOURCE_STRING`, `DataSize`, `HeaderSize`, `DataVersion`, `MemoryFlags`, `LanguageId`, `Version`, `Characteristics`, `data: byte[]`.
- `CvtResFile` (static class) — `RT_DLGINCLUDE = 17`; `ReadResFile(stream)` + private `ReadStringOrID(reader)`:
  - `ReadResFile` validates the `allzero` dword at stream start (non-zero -> `nativeResourceFormatError`), then loops over chunks (`cbData`, `cbHdr`; rejected if `cbHdr < 2 * sizeof DWORD` using `nativeResourceHeaderMalformed` with a hex position), reads the type/name (ID-or-string), aligns to 4, reads DataVersion/MemoryFlags/LanguageId/Version/Characteristics and the raw data. Entries with a null name whose type is `RT_DLGINCLUDE` are skipped.
  - `ReadStringOrID` reads a WCHAR; if it is `0xFFFF` the next WORD is the ordinal (numeric ID), else it reads chars up to the NUL terminator as a string.
- `SectionCharacteristics` (`[<Flags>]`) — the full IMAGE_SCN_* value set (bit masks for type/align/etc.).
- `ResourceSection` (class) — `new(sectionBytes, relocations)`; `SectionBytes: byte[]`, `Relocations: uint32[]`.
- `StreamExtensions` (`[<Extension>]`) — `TryReadAll(stream, buffer, offset, count)` (loop until full or EOF).
- `COFFResourceReader` (static class) — `ReadWin32ResourcesFromCOFF(stream)`:
  - Parses `PEHeaders`; must find exactly one `.rsrc$01` and one `.rsrc$02` section.
  - Validates raw-data extents (`ConfirmSectionValues`, `nativeResource.*` error strings) and relocation/symbol-table bounds (with overflow guards).
  - Reads both sections into one buffer; rewrites each relocation by looking up the symbol (IMAGE_SYM class must be null, section must be 3) and patching the value with `+ rsrc1.SizeOfRawData` into the merged blob.
- `ICONDIRENTRY` (`[<Struct>]`) — bWidth/bHeight/bColorCount/bReserved, wPlanes/wBitCount, dwBytesInRes/dwImageOffset.
- `VersionHelper` (static class) — version-string parsing:
  - `TryParse(s, byref version)` — "major[.minor[.build[.revision]]]".
  - `TryParseAssemblyVersion(s, allowWildcard, byref version)` — accepts up to 4 dot-separated components with optional trailing `*` (build/revision become `UInt16.MaxValue`), each component must be < `UInt16.MaxValue - 1`.
  - Private `TryParse(s, allowWildcard, maxValue, allowPartialParse, byref version)` — the shared parser: splits on '.', handles wildcard (sets trailing values to `UInt16.MaxValue`), rejects when count not in [3..4] or components exceed max, supports partial parsing (truncates at the first invalid char, e.g. "1.2.2a.1").
  - `TryGetValue` — bigint parse, `value <- uint16 (number % 65536)`.
  - `GenerateVersionFromPatternAndCurrentTime(time, pattern)` — the AssemblyVersionAttribute `*` semantics: build = days since 2000-01-01 (capped), revision = seconds-since-midnight / 2.
- `VersionResourceSerializer` — serializes a VS_VERSION_INFO resource:
  - Ctor takes `isDll` plus the standard version strings (comments, company, description, file version, internal name, copyright, trademarks, original filename, product name, product version, assembly version).
  - Constants: `vsVersionInfoKey = "VS_VERSION_INFO"`, `varFileInfoKey = "VarFileInfo"`, `translationKey = "Translation"`, `stringFileInfoKey = "StringFileInfo"`, `CP_WINUNICODE = 1200`, `sizeVS_FIXEDFILEINFO = 52` (`sizeof DWORD * 13`), `VFT_APP = 1`, `VFT_DLL = 2`; `_langIdAndCodePageKey = "000004b0"` (lang 0, codepage 1200).
  - `GetVerStrings()` — yields the key/value pairs ("FileVersion", "ProductVersion", and "Assembly Version" always present; others only when non-empty).
  - `FileType` — DLL vs app.
  - `WriteVSFixedFileInfo(writer)` — VS_FIXEDFILEINFO: signature `0xFEEF04BD`, version `0x00010000`, QWORD file-version (parsed via `VersionHelper.TryParse`, packed as `major<<16|minor`, `build<<16|revision`), product-version pair, flags, file OS/type, etc.
  - `PadKeyLen`/`PadToDword`/`HDRSIZE`/`SizeofVerString`/`WriteVersionString`/`KEYSIZE`/`KEYBYTES` — dword-aligned binary string blocks.
  - `GetStringsSize()` / `GetDataSize()` — block size math (uses checked arithmetic).
  - `WriteVerResource(writer)` — writes the full nested VS_VERSION_INFO tree: root vsVersionInfo block, VS_FIXEDFILEINFO, VarFileInfo{Translation{0, 1200}}, StringFileInfo{000004b0{...strings...}}, with dword alignment pads (asserted).
- `Win32ResourceConversions` (static class):
  - `AppendIconToResourceStream(resStream, iconStream)` — reads an .ico header (reserved 0, type 1), reads ICONDIRENTRYs, patches in the DIB's wPlanes/wBitCount when the image is a BITMAPINFOHEADER (first dword 40), then writes the RT_ICON resources and a RT_GROUP_ICON resource (GRPICONDIR).
  - `AppendVersionToResourceStream(resStream, isDll, fileVersion, originalFileName, internalName, productVersion, assemblyVersion, ...)` — writes the RT_VERSION header + `WriteVerResource`.
  - `AppendManifestToResourceStream(resStream, manifestStream, isDll)` — RT_MANIFEST with language 1 (exe) / 2 (dll).
- `Win32Resource(data, codePage, languageId, id, name, typeId, typeName)` — a leaf resource: `Data`, `CodePage`, `LanguageId`, `Id`, `Name`, `TypeId`, `TypeName`.
- `Directory(name, id)` — a directory node with `NumberOfNamedEntries`, `NumberOfIdEntries`, `Entries: List<objnull>` (containing `Directory` or `Win32Resource`).
- `NativeResourceWriter` (static class):
  - `CompareResources` / `CompareResourceIdentifiers` — ordinal identifiers sort before named; named compare case-insensitively.
  - `SortResources(enumerable)` — stable sort via `Comparer`.
  - `SerializeWin32Resources(builder, resources, resourcesRva)` — groups sorted resources into the 3-level type/name/language directory tree (tracking named vs id counts and `sizeOfDirectoryTree`), then `WriteDirectory`.
  - private `WriteDirectory(directory, writer, offset, level, sizeOfDirectoryTree, virtualAddressBase, dataWriter)` — recursive tree writer: directory header (reserved, named/id counts), 8-byte entries (id or `0x80000000|nameOffset` for names; `0x80000000|dirOffset` for subdirectories), and data entries with 4-byte aligned data.
  - private `SizeOfDirectory` — computed directory size.
  - A commented-out `SerializeWin32Resources` overload for `ResourceSection` based fixups.

## Significant internal logic

- The 3-level resource directory tree writes: name entries carry a 4-byte dword at offset zero of each name buffer (name length in WCHARs) followed by UTF-16 name bytes; direction entries use the high bit of the offset field.
- All resource stream appends begin by aligning to a 4-byte boundary (`Position + 3 &&& ~~~3`).
- The version serializer uses a charset key `000004b0` (language 0, codepage 1200) and emits Translation=0,1200 to match the CLR/cvtres layout.