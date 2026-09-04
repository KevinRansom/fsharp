# TypedTreePickle.fsi

**Purpose**: Contract for the TAST pickling framework: "Defines the framework for serializing and de-serializing TAST data structures as binary blobs for the F# metadata format." Declares the `PickledDataWithReferences<'RawData>` record (with `Fixup`/`OptionalFixup` for resolving dangling CCU references), the `pickler<'T>` / `unpikler<'T>` function types over the stateful `WriterState`/`ReaderState`, and one pickler per AST node (`p_const`, `p_vref`, `p_tcref`, `p_ucref`, `p_expr`, `p_ty`, plus primitives `p_byte/bool/int/string/lazy/tup2..4/array/namemap`), with the symmetric unpickers, and the top-level entry points `pickleObjWithDanglingCcus` and `unpickleObjWithDanglingCcus`, plus `pickleCcuInfo`/`unpickleCcuInfo`.

**Namespace(s)**: `FSharp.Compiler` — `module internal FSharp.Compiler.TypedTreePickle`.

**Declared types (signatures)**:
- `type PickledDataWithReferences<'RawData>` — `RawData: 'RawData`; `FixupThunks: CcuThunk[]`; `member Fixup: (CcuReference -> CcuThunk) -> 'RawData`; `member OptionalFixup: (CcuReference -> CcuThunk option) -> 'RawData` (loader may return `None`, in which case there is no fixup).
- `type WriterState` (opaque), `type pickler<'T> = 'T -> WriterState -> unit`.
- `type ReaderState` (opaque), `type unpikler<'T> = ReaderState -> 'T`.

**Primitive signatures**: `p_byte: int ->`, `p_bool: bool ->`, `p_int: int ->`, `p_string: string ->`, `p_lazy: pickler<'T> -> InterruptibleLazy<'T> pickler`, `inline p_tup2/tup3/tup4`, `p_array: pickler<'T> -> pickler<'T[]>`, `p_namemap: pickler<'T> -> pickler<NameMap<'T>>`; symmetric `u_byte/u_bool/u_int/u_string/u_lazy/u_tup2..4/u_array/u_namemap`.

**AST picklers**: `p_const: pickler<Const>`, `p_vref: string -> pickler<ValRef>`, `p_tcref: string -> pickler<TyconRef>`, `p_ucref: pickler<UnionCaseRef>`, `p_expr: pickler<Expr>`, `p_ty: pickler<TType>`, `pickleCcuInfo: pickler<PickledCcuInfo>`; symmetric `u_const`, `u_vref`, `u_tcref`, `u_ucref`, `u_expr`, `u_ty`, `unpickleCcuInfo: ReaderState -> PickledCcuInfo`.

**Top-level (signatures)**:
- `val pickleObjWithDanglingCcus: inMem: bool -> file: string -> TcGlobals -> scope: CcuThunk -> pickler<'T> -> 'T -> ByteBuffer * ByteBuffer` — "Serialize an arbitrary object using the given pickler".
- `val unpickleObjWithDanglingCcus: file: string -> viewedScope: ILScopeRef -> ilModule: ILModuleDef option -> 'T unpikler -> ReadOnlyByteMemory -> ReadOnlyByteMemory -> PickledDataWithReferences<'T>` — "Deserialize an arbitrary object which may have holes referring to other compilation units".

**Notes**: The `.fs` also contains internal table types (`Table<'T>`, `InputTable<'T>`, `NodeOutTable`/`NodeInTable`) and many more primitive/node picklers (`p_trait`, `p_measure_*`, `p_tyar_spec*`, etc.) that are not in the contract.

**Cross-references**: `TypedTreePickle.fs` (implementation), `TypedTree.fs` (`Expr`, `ValRef`, `TyconRef`, `CcuThunk`, `PickledCcuInfo`), `TcGlobals.fs`, `Checker.fs`/`AssemblyLoader` (producer/consumer).
