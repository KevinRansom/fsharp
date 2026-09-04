# ilnativeres.fsi

**Purpose**
Interface contract for the F#-native port of Roslyn's `NativeResourceWriter.cs` + `CvtRes.cs` (and their dependencies): the Windows-native-resource read/write machinery used to embed icons, version information, manifests, dialogs (`RT_DLGINCLUDE`), and other `.resources` into a .NET assembly. Exposes the F#-native `RESOURCE` / `RESOURCE_STRING` / `Win32Resource` types, the `CvtResFile.ReadResFile` reader for a `.resources`-style binary stream, `Win32ResourceConversions.Append*Icon* / *Version* / *Manifest*` helpers, and `NativeResourceWriter.SortResources` + `SerializeWin32Resources`.

**Namespace(s)**
- `FSharp.Compiler.AbstractIL` (module `internal FSharp.Compiler.AbstractIL.NativeRes`)

**TypeDefs declared**
- `BYTE = Byte`, `DWORD = UInt32`, `WCHAR = Char`, `WORD = UInt16` — Windows type aliases.
- `RESOURCE_STRING` (class) — `{ Ordinal: WORD; theString: string }`.
- `RESOURCE` (class) — one native resource: `{ pstringType: RESOURCE_STRING; pstringName: RESOURCE_STRING; DataSize: DWORD; HeaderSize: DWORD; DataVersion: DWORD; MemoryFlags: WORD; LanguageId: WORD; Version: DWORD; Characteristics: DWORD; data: byte[] }`.
- `Win32Resource` — `{ CodePage: DWORD; Data: byte[]; Id: int; LanguageId: DWORD; Name: string; TypeId: int; TypeName: string }` (with an 8-arg constructor).
- `CvtResFile` (class) — `static member ReadResFile: Stream -> List<RESOURCE>` — reads the CvtRes binary format.
- `Win32ResourceConversions` (class) — `AppendIconToResourceStream`, `AppendVersionToResourceStream`, `AppendManifestToResourceStream`.
- `NativeResourceWriter` (class) — `SortResources: IEnumerable<Win32Resource> -> IEnumerable<Win32Resource>` and `SerializeWin32Resources (builder: BlobBuilder) (resources) (resourcesRva: int) : unit`.

**Cross-references**
- `ilnativeres.fs` (implementation), `ilwrite.fs` (consumer of the serialized resource stream when a .NET assembly embeds native resources)
