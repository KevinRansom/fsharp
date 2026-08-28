# DeltaTableLayout.fs

**Purpose**
Supports hot-reload delta metadata emission by computing the #~ stream header bit masks for delta streams: the Valid mask (which metadata tables have rows) and the Sorted mask (which tables are sorted, per ECMA-335), both as 64-bit values split into low/high 32-bit ints.

**Namespace(s)**
- `FSharp.Compiler.AbstractIL` (module `internal FSharp.Compiler.AbstractIL.DeltaTableLayout`)

**TypeDefs declared**
- `TableBitMasks` (record) — `{ ValidLow; ValidHigh; SortedLow; SortedHigh : int }`, the #~ header mask halves.

**Public API surface** (module-internal)
- `computeBitMasks (tableRowCounts:int[]) (isEncDelta:bool) : TableBitMasks` — main entry point.

**Internal helpers**
- `sortedTypeSystemTables` — ECMA-335 II.22 sorted tables (InterfaceImpl, Constant, CustomAttribute, FieldMarshal, Permission, ClassLayout, FieldLayout, MethodSemantics, MethodImpl, ImplMap, FieldRVA, Nested, GenericParam, GenericParamConstraint).
- `sortedDebugTables` — sorted Portable PDB tables not in ECMA-335 TableNames: `tableLocalScope` (0x32), `tableStateMachineMethod` (0x36), `tableCustomDebugInformation` (0x37); uses `DeltaTokens`.
- `maskForTables`, `toLow`/`toHigh` — uint64 → split int masks.

**Significant internal logic**
- Valid bit set = each table with non-zero row count.
- For EnC deltas the CustomAttribute bit is cleared from the sorted mask to match Roslyn's behavior — the delta CustomAttribute table is appended, not globally sorted.
- Sorted mask = type-system sorted tables (with the EnC CustomAttribute exception) OR present-and-sorted debug tables.

**Cross-references**
- `BinaryConstants.fs` (TableNames)
- `ILDeltaHandles.fs` (DeltaTokens table indices for PDB tables)
- `DeltaMetadataSerializer.fs` (writes these masks into the #~ stream header)
- `DeltaMetadataTypes.fs`, `DeltaMetadataTables.fs`
