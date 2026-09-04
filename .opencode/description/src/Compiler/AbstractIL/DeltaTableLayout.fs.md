# DeltaTableLayout.fs

## Pipeline role

Part of the AbstractIL delta metadata (EnC hot-reload) writer infrastructure. This module computes the metadata table bit masks emitted in the `#~` metadata stream header. The header carries two 64-bit masks — `Valid` (which tables have rows) and `Sorted` (which tables are sorted, per ECMA-335 II.22) — and the delta writer needs these masks to match what the runtime expects for an EnC delta. It uses `TableNames` from `BinaryConstants.fs` for ECMA-335 metadata tables and `DeltaTokens` for Portable PDB tables (which are not part of `TableNames`).

## Namespaces and modules

- Module: `FSharp.Compiler.AbstractIL.DeltaTableLayout` (module `internal`)
- Uses: `FSharp.Compiler.AbstractIL.BinaryConstants` (for `TableNames`), `FSharp.Compiler.AbstractIL.ILDeltaHandles` (for `DeltaTokens`).

## Types

- `TableBitMasks` (record) — the four 32-bit halves of the two 64-bit header masks:
  - `ValidLow: int`, `ValidHigh: int` — lower/upper 32 bits of the Valid mask.
  - `SortedLow: int`, `SortedHigh: int` — lower/upper 32 bits of the Sorted mask.

## Private data

- `sortedTypeSystemTables: int list` — ECMA-335 metadata tables that are sorted by primary key: InterfaceImpl (by Class), Constant (by Parent), CustomAttribute (by Parent), FieldMarshal (by Parent), Permission (by Parent, DeclSecurity), ClassLayout (by Parent), FieldLayout (by Field), MethodSemantics (by Association), MethodImpl (by Class), ImplMap (by MemberForwarded), FieldRVA (by Field), Nested (by NestedClass), GenericParam (by Owner), GenericParamConstraint (by Owner).
- `sortedDebugTables: int list` — Portable PDB tables that are sorted (referenced via `DeltaTokens`, not `TableNames`): `tableLocalScope` (0x32, by Method), `tableStateMachineMethod` (0x36, by MoveNextMethod), `tableCustomDebugInformation` (0x37, by Parent).

## Functions

- `maskForTables (tables: int list) : uint64` — private; folds `1UL <<< tableIndex` over the list to build a bit mask.
- `toLow (mask: uint64) : int` / `toHigh (mask: uint64) : int` — private; split a 64-bit mask into its lower/upper 32-bit halves.
- `computeBitMasks (tableRowCounts: int[]) (isEncDelta: bool) : TableBitMasks` — the main entry point.
  - Computes `presentMask` (Valid): bit set for each table whose row count is non-zero.
  - Computes the Sorted mask: the type-system sorted set, except that for EnC deltas the `CustomAttribute` bit is cleared to match Roslyn's `MetadataSizes` behavior (the CustomAttribute table in deltas is appended rather than globally sorted).
  - The final sorted mask ORs the type-system sorted tables with the present debug tables that are marked sorted.
  - Returns the low/high halves of both masks.

## Significant internal logic

- The Valid mask is derived purely from observed row counts of the delta tables; the Sorted mask is computed as the intersection of "sorted by spec" and "present", with a deliberate Roslyn-compatible exception for `CustomAttribute` in EnC deltas.
- Portable PDB tables are handled through `DeltaTokens`, keeping the module independent from `TableNames`, which does not cover debug tables.