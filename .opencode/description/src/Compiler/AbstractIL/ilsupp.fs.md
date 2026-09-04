# ilsupp.fs

## Pipeline role

Part of the AbstractIL layer. This module provides support utilities for the IL assembler/disassembler and the PE/resource emission path: the PE/COFF time stamp computation, Win32 IMAGE structure models with conversion back to bytes, resource-directory parsing ("unlinking" embedded Win32 resources out of a linked PE-style resource blob), native-resource linking (`linkNativeResources`), and byte <-> word/dword helpers. It also aliases the COM `IStream` interface. It is the implementation behind `FSharp.Compiler.AbstractIL.Support` (module `internal`).

## Namespaces and modules

- Module: `FSharp.Compiler.AbstractIL.Support`
- Uses: `System`, `System.IO`, `System.Runtime.InteropServices`, `FSharp.Compiler.AbstractIL.NativeRes` (`CvtResFile`, `Win32Resource`, `NativeResourceWriter`), `FSharp.Compiler.IO`.

## Values and type aliases

- `DateTime1970Jan01` — `DateTime(1970,1,1,0,0,0,Utc)` (ECMA-335 II.24.2.2 PE File Header epoch).
- `absilWriteGetTimeStamp ()` — current UTC time minus the epoch, in whole seconds (PE TimeDateStamp).
- `type IStream = System.Runtime.InteropServices.ComTypes.IStream`.
- `E_FAIL = 0x80004005`.

## Byte-conversion functions

- `bytesToWord (b0, b1) : int16` — little-endian 2-byte read.
- `bytesToDWord (b0, b1, b2, b3)` — little-endian 4-byte read.
- `dwToBytes n` — little-endian 4-byte write, returning `(bytes, 4)`.
- `wToBytes (n: int16)` — little-endian 2-byte write, returning `(bytes, 2)`.

## IMAGE structure models (classes, each with mutable get/set properties, static `Width`, and `toBytes()`)

- `IMAGE_FILE_HEADER(m, secs, tds, ptst, nos, soh, c)` — 20 bytes; fields `Machine`, `NumberOfSections`, `TimeDateStamp`, `PointerToSymbolTable`, `NumberOfSymbols`, `SizeOfOptionalHeader`, `Characteristics`.
- `IMAGE_SECTION_HEADER(n, ai, va, srd, prd, pr, pln, nr, nl, c)` — 40 bytes; `Name` (int64), `PhysicalAddress`/`VirtualSize` (shared storage `addressInfo`), `VirtualAddress`, `SizeOfRawData`, `PointerToRawData`, `PointerToRelocations`, `PointerToLineNumbers`, `NumberOfRelocations`, `NumberOfLineNumbers`, `Characteristics`.
- `IMAGE_SYMBOL(n, v, sn, t, sc, nas)` — 18 bytes; `Name`, `Value`, `SectionNumber`, `Type`, `StorageClass`, `NumberOfAuxSymbols`.
- `IMAGE_RELOCATION(va, sti, t)` — 10 bytes; `VirtualAddress`/`RelocCount` (shared), `SymbolTableIndex`, `Type`.
- `IMAGE_RESOURCE_DIRECTORY(c, tds, mjv, mnv, nne, nie)` — 16 bytes; `Characteristics`, `TimeDateStamp`, `MajorVersion`, `MinorVersion`, `NumberOfNamedEntries`, `NumberOfIdEntries`; parsed from bytes by `bytesToIRD buffer offset`.
- `IMAGE_RESOURCE_DIRECTORY_ENTRY(n, o)` — 8 bytes; `Name`, `OffsetToData`; derived `OffsetToDirectory` (`offset &&& 0x7fffffff`) and `DataIsDirectory` (`offset &&& 0x80000000 <> 0`); parsed by `bytesToIRDE`.
- `IMAGE_RESOURCE_DATA_ENTRY(o, s, c, r)` — 16 bytes; `OffsetToData`, `Size`, `CodePage`, `Reserved`; parsed by `bytesToIRDataE`.

## Resource-format models

- `ResFormatHeader()` — 32-byte Win32 `.res`-style header; properties `DataSize`, `HeaderSize` (defaults 32), `TypeID` (default 0xffff), `NameID` (default 0xffff), `DataVersion`, `MemFlags`, `LangID`, `Version`, `Characteristics`; `toBytes()`.
- `ResFormatNode(tid, nid, lid, dataOffset, pbLinkedResource)` — one resource node. Constructor inspects high bits of `tid`/`nid` (0x80000000 = name string offsets into `pbLinkedResource`) to decode type/name UTF-16 strings and builds `Type`/`Name` byte arrays; numeric type/name IDs are encoded into the high 16 bits of the header IDs. Loads the `IMAGE_RESOURCE_DATA_ENTRY` at `dataOffset` and sets `DataSize`.
  - Members: `ResHdr`, `DataEntry`, `Type`, `Name`.
  - `Save(ulLinkedResourceBaseRVA, pbLinkedResource, pUnlinkedResource, offset)` — writes the header + data into an unlinked buffer: header size adjusted for name strings, DWORD alignment of the name fields (mirroring ildasm's dres.cpp), then constant part (DataVersion, MemFlags, LangID, Version, Characteristics), then the data chunk (offset corrected by the linked-base RVA) with trailing padding to 4 bytes. Returns total size.

## Native-resource functions

- `linkNativeResources (unlinkedResources: byte[] list) (rva: int32)` — reads each `.res` blob via `CvtResFile.ReadResFile`, flattens the entries into Roslyn `Win32Resource` records (mapping ordinals/strings for id/name and type), then uses `NativeResourceWriter.SerializeWin32Resources` (with a `System.Reflection.Metadata.BlobBuilder`) to produce the linked resource bytes at the given RVA. Mirrors Roslyn's `MakeWin32ResourceList`.
- `unlinkResource (ulLinkedResourceBaseRVA) (pbLinkedResource)` — parses a linked resource section into an array of `ResFormatNode`s by walking the three-level directory tree (Type -> Name -> Language). Skips `VERSION` (0x10) and `RT_MANIFEST` (0x18) resources; throws `E_FAIL` if the hierarchy exceeds three levels. Then serializes back into a linear `.res`-style buffer: a dummy `ResFormatHeader` (recomputed after first pass for size) followed by each node's `Save` output.

## Significant internal logic

- `unlinkResource` first walks the tree purely to count the nodes (allowing allocation), then walks again to fill the node array; the two-pass pattern is flagged for coalescing in a comment.
- Offsets returned by resource data entries are RVA-relative, so `ResFormatNode.Save` subtracts the linked base RVA when locating the payload bytes.
- `linkNativeResources` deliberately matches Roslyn's Win32 resource conversion to keep F#-linked resources byte-compatible with the C# compiler output.