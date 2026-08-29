# TypedTreePickle.fs

> Pipeline role: The TAST serialization (pickling) framework. Serializes/de-serializes the typed abstract syntax tree — and its interfaces (`TAssemblySignature`, `CCU` info) — into binary "phase-1 + phase-2" byte buffers used by the F# binary metadata format produced by `fsc` and consumed by `importer`. Handles dangling CCU references via `CcuThunk` fixups, integer compression (CLR-metadata-style), interned string/CCU/pubpath/nleref/simpletype tables, and node-interned entity/typar/val/anonymous-record extraction. Everything is `p_*` (pickle) / `u_*` (unpickle) pairs.
> Namespace: `FSharp.Compiler` — `module internal FSharp.Compiler.TypedTreePickle` (declared at line 3).

---

## Data structures

- `[<NoEquality; NoComparison>] type PickledDataWithReferences<'RawData>` (line 43): `{ RawData: 'RawData; FixupThunks: CcuThunk[] }`.
  - `member Fixup loader` (51) — resolves every listed thunk by name via `reqd.Fixup(loader reqd.AssemblyName)`; `OptionalFixup` (56) — only fixes up `reqd.IsUnresolvedReference` thunks, tolerating the loader returning `None`.
  - `ffailwith fileName str` (36) — "reading/writing metadata" error lifted to `FSComp.SR.pickleErrorReadingWritingMetadata`, with `Debug.Assert(false, ...)` fail-fast then `failwith`.

- `type Table<'T when 'T: not null>` (74) — the writer-side interning table: `Dictionary<'T,int>` (`FindOrAdd`), `ResizeArray<'T> rows`, `count`; `static member Create name`.
- `type InputTable<'T>` (106) — reader-side `{ itbl_name; itbl_rows: 'T[] }`; `new_itbl` and `lookup_uniq`/`encode_uniq` helpers (lines 615/617).
- `type NodeOutTable<'Data, 'Node>` (115) — writer-side extraction table for stamped nodes (tycons/typars/vals/anon-records) that phase-2 emits as arrays and the phase-1 body refers to by index; `static member inline Create(stampF, nameF, rangeF, derefF, nm)`; also gives `Size`. Extraction creates the "phase-1" sub-trees.
- `type NodeInTable<'Data, 'Node>` (171) — reader-side: `{ LinkNode: 'Node -> 'Data -> unit; IsLinked: 'Node -> bool; Name; Nodes: 'Node[] }`; reads each node, then `LinkNode` builds it from phase-1 data. `check` (1026) warns on any unlinked entry ("pickleMissingDefinition").

**WriterState** (147): `os`/`osB` (two `ByteBuffer`s — the B stream is an appending side-channel for value-struct/member type info), `oscope: CcuThunk` (the scope for `NonLocalEntityRef`s), intern tables `occus`, `oentities`, `otypars`, `ovals`, `oanoninfos`, `ostrings`, `opubpaths`, `onlerefs`, `osimpletys`, `oglobals: TcGlobals`, `isStructThisArgPos: bool` (computed for `byref-like` member shapes), `ofile`, `oInMem` (in-memory format also serializes XML docs).

**ReaderState** (191): `is`/`isB` (`ByteStream`s), `iilscope: ILScopeRef`, `iccus`/`ientities`/`itypars`/`ivals`/`ianoninfos`/`istrings`/`ipubpaths`/`inlerefs`/`isimpletys` (in tables), `ifile`, `iILModule: ILModuleDef option` (the AbstractIL module read, for cross-linked members).

- `'T pickler = 'T -> WriterState -> unit` and `'T unpikler = ReaderState -> 'T` (lines 216/373).

---

## Primitive & structured picklers

- **Byte/bool**: `p_byte`, `p_byteB` (`EmitIntAsByte`).
- **Integers**: `prim_p_int32`/`prim_p_int32B` = 4 raw bytes; `p_int32`/`p_int32B` (240/251) = **CLR-metadata compressed** ints (values ≤ 0x7F in one byte, ≤ 0x3FFF in two with high-bit tag, else `0xFF` marker followed by 4 bytes). `p_int`/`p_uint`/`p_int64`/`p_uint64` and B-stream variants plus `p_int64Z`? zigzag encodings; `u_*` readers mirroring.
- **Other**: `p_string`/`u_string` (UTF-8 length-prefixed), `p_bytes`/`u_bytes`, `p_space`/`u_space`, `p_used_space1`, `p_bool`.
- **Compositors** (`inline` in `.fsi`): `p_tupN`, `p_list_ext`/`p_list`, `p_array`, `p_option`, `p_lazy`/`p_interruptiblelazy`, `p_namemap`, `p_multimap`? ; matching `u_*`.
- **Topological ordering**: `p_expr_sl`/`u_expr_sl` — expressions are pickled in **reverse postorder** so recursive definitions desugar naturally; `p_osgn_decl`-based ordering split into locals within the current `Val` batching.

**Extraction-validated recursion** (`p_hole`/`fill_p_*`): letrec-holes such as `p_Expr`, `p_binds`, `p_targets`, `p_constraints`, `p_Vals`, `p_attribs` are forcibly filled at the bottom of the file (`let _ = fill_...`) so structure stays mutually recursive but terminating (lines 3951–3965).

---

## Typed-tree picklers (selection)

- Types: `p_ty` (line 1963, via `p_ty2 isStructThisArgPos` — the `isStructThisArgPos` state affects byref/simple-ty encoding), `p_tyar_spec*`, `p_measure_*`, `p_trait`/`p_trait_sln` (2108/2133), `p_anonInfo`, `p_MemberFlags`, `u_*` mirrors.
- Entities: `p_entity_spec` (2856) with `p_tycon_objmodel_data` (2744), `p_exnc_repr` (2763), `p_recdfield_spec` (2778), `p_tcaug` (2826), `p_parentref`, `p_access`, `p_cpath`. `p_tycon_repr`/`u_tycon_repr` for TAST-structured tycon representations (not the IL-based ones).
- Values: `p_ValData` (2933), `p_Val` (2956), plus `p_vrefFlags` (2923), member info `p_member_info` (2894), attributes `p_attrib`/`p_attrib_expr`/`p_attrib_arg` (2875/2878/2891) — note AttributeTargets are **not preserved**.
- Refs & fixup machinery: `p_vref`/`p_tcref`/`p_ucref`/`p_rfref` (1922–1935); `p_ccu_thunk`? — CCU references as `p_nleref`-indexed `p_encoded_ccuref` names.
- Interning encoders: `encode_nleref` (901 area) — "CCU + (namespace path) + name" → single table row; `encode_pubpath`, `encode_simpletyp` (917) where **simple types** (`int`, `string`...) are interned because they dominate pickled data ("NULLNESS - the simpletyp table now holds KnownAmbivalentToNull by default", line 907). `decode_simpletyp`/`u_simpletyp` restore via `lookup_nleref`.
- Abstract IL touchpoints: `p_ILTypeRef`/`p_ILTypeSpec`/`p_ILCallSig`/`p_ILCallConv`/`p_ILBasicCallConv`/`p_ILTypes` (1275–1297) and `u_*` mirrors — needed because some TAST nodes reference AbsIL directly.

---

## Top-level entry points

- `pickleObjWithDanglingCcus inMem file g scope p x` (929) — two-phase serialization:
  - **Phase 1**: run `p x st1`, giving `ctys`-processed sub-trees and the interned `ccuNameTab`, `stringTab`, `pubpathTab`, `nlerefTab`, `simpleTyTab`, plus sizes (`ntycons/ntypars/nvals/nanoninfos`) and `phase1bytes`/`phase1bytesB`.
  - **Phase 2**: write header (`p_array p_encoded_ccuref` for referenced CCUs; `z1` trick — if anonymous records exist, first count integer is `-ntycons - 1` and an extra `nanoninfos` integer follows, lines 997–1003), then `(strings, pubpaths, nlerefs, simpletys, phase1bytes)` tuples.
  - Returns `(phase2bytes, phase1bytesB)` — the two streams stored in the `.fsi`/metadata chunk of the compiled assembly.
- `unpickleObjWithDanglingCcus file viewedScope ilModule u phase2bytes phase1bytesB` (1037) — reads the header tables (creating **delayed** `CcuThunk`s via `CcuThunk.CreateDelayed`/`NewUnlinked` stubs), then unpickles phase-1 data, wiring node tables through `NodeInTable.LinkNode`; returns `PickledDataWithReferences<'T>` whose `Fixup` the importer calls with the real CCU loader.
- `pickleCcuInfo (minfo: PickledCcuInfo) st` (3973) / `unpickleCcuInfo` (3978) — `{ mspec; compileTimeWorkingDir; usesQuotations }` plus 3 reserved bytes pickled as `p_tup4 pickleModuleOrNamespace p_string p_bool (p_space 3)`.
- Also `pickleModuleOrNamespace`/`unpickleModuleOrNamespace` (3971/3976).

---

## Related

- Builds on: `TypedTree` (`Expr`, `Val`, `Tycon`, `CcuThunk`, `PickledCcuInfo`), `TypedTreeBasics`/`TypedTreeOps`, `TcGlobals`, `FSharp.Compiler.AbstractIL` (`ILModuleDef`, `ILScopeRef`, `ILTypeRef`), `Internal.Utilities` (`ByteBuffer`, `ByteStream`, `Bits`).
- Used by: `Checker.fs`/`AssemblyLoader` (production of the `.fsi` metadata blob), `Importer` (consumption), and the in-memory format used by IDE tooling (`UnmergeInterfaceData`).