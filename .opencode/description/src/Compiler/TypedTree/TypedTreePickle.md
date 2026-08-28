# TypedTreePickle.fs

**Purpose**: "Defines the framework for serializing and de-serializing TAST (typed abstract syntax tree) data structures as binary blobs for the F# metadata format." Implements the pickler / unpickler for `TypedTree` values (`Expr`, `Val`, `Tycon`, `UnionCase`, `RecdField`, `Attrib`, `Const`, `TType`, `Typar`, `Trait`, `ValRef`, `TyconRef`, `UnionCaseRef`, `RecdFieldRef`, `TyparInstantiation`, `PickledCcuInfo`, ...) into a binary format with a shared string table (`Table`/`InputTable`/`NodeOutTable`/`NodeInTable`) and a "dangling CCU" mechanism (`pickleObjWithDanglingCcus`/`unpickleObjWithDanglingCcus` + `PickledDataWithReferences<'RawData>` with `Fixup`/`OptionalFixup`) so a value can be pickled with references to other CCUs, and those references resolved (or left as `None`) when the value is later loaded.

**Namespace(s)**: `FSharp.Compiler` (module `internal FSharp.Compiler.TypedTreePickle`).

**Declared types**:
- `PickledDataWithReferences<'RawData>` (`[<NoEquality; NoComparison>]`) — `{ RawData: 'RawData; FixupThunks: CcuThunk[] }`; members `Fixup: (CcuReference -> CcuThunk) -> 'RawData`, `OptionalFixup: (CcuReference -> CcuThunk option) -> 'RawData`.
- `Table<'T when 'T: not null>` — a string/dedup table (name → unique id) with row list.
- `InputTable<'T>` — deserialization-side table.
- `NodeOutTable<'Data,'Node>` / `NodeInTable<'Data,'Node>` — table of nodes keyed by their unique id in the pickle stream.
- `WriterState` — state for a pickler: `{ os: ByteBuffer (main); osB: ByteBuffer (string table); ostrings: Table<string>; occus: Table<string> }` plus `ofile`, etc.
- `ReaderState` — state for an unpickler (mirror of `WriterState` with `is/isB` inputs + `istrings`, `iccus` tables).
- `type 'T pickler = 'T -> WriterState -> unit` / `type 'T unpickler = ReaderState -> 'T`.

**Public API surface**:
- Low-level picklers/parsers: `p_byte(B)`, `p_bool`, `p_int32(B)`, `p_bytes`, `p_int8/16/32/64`, `p_char`, `p_list(B|_ext)`, `p_array(_core)`, `p_lazy`, `p_string(s)`, `p_ccuref(s)`, `p_ucref`, `p_ty2`/`p_ty`, `p_tys`, `p_trait`, `p_trait_sln`, `p_measure_*`, `p_tyar_spec(s/data)`, `p_tyar_constraint(s)`, `p_ValReprInfo`, `p_TyparReprInfo`.
- Unpicklers/parsers (mirror of the above): `u_byte(B)`, `u_bool`, `u_int32(B)`, `u_bytes`, `u_int8/16/32/64`, `u_char`, `u_list(B|_ext|_revi)`, `u_array(_core)`, `u_lazy`, `u_string(s)`, `u_ccuref`, `u_ucref`, `u_ty`, `u_tys`, `u_trait(_sln)`, `u_measure_*`, `u_tyar_spec(s/data)`, `u_tyar_constraint(s)`, `u_ValReprInfo`, `u_TyparReprInfo`.
- `pickleObjWithDanglingCcus: inMem -> file -> TcGlobals -> CcuThunk -> pickler<'T> -> 'T -> ByteBuffer * ByteBuffer` (top-level: pickle a value with dangling CCU refs; returns the main blob + the string-table blob).
- `unpickleObjWithDanglingCcus: file -> ILScopeRef -> ILModuleDef option -> 'T unpickler -> ReadOnlyByteMemory * ReadOnlyByteMemory -> PickledDataWithReferences<'T>` (top-level: unpickle a value and its dangling CCU fixups).
- `pickleCcuInfo: PickledCcuInfo pickler` and `unpickleCcuInfo: ReaderState -> PickledCcuInfo` (the "serialize a TAST description of a compilation unit").

**Significant internal logic**: The pickle stream is a tagged binary format (each value gets a discriminant byte, plus a dedup table lookup for strings). The "dangling CCU" mechanism works by collecting every `CcuReference` (assembly name) encountered during pickling into an array in `FixupThunks`, then emitting it in a header so the unpickler can build the list fixup thunks and call `Fixup`/`OptionalFixup` to resolve them against the actual CCUs (or leave them unresolved for "optional" loading). `p_lazy` / `u_lazy` support `InterruptibleLazy` (for the F#+ lazy-evaluation machinery).

**Cross-references**: `TypedTreePickle.fsi` (contract), `TypedTree.fs` (the tree types), `TcGlobals.fs` (well-known refs), `QuotationPickler.fsi` (a similar but simpler pickle format for quotations), `Checker.fs` (produces `PickledCcuInfo`), `AssemblyLoader` (consumes).
