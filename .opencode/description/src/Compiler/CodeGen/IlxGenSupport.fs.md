# IlxGenSupport.fs

**Purpose**: Shared support utilities for the ILX generator. Provides (a) builders for simple IL constructs (field getters, private local attribute types, local enums), (b) the "embeddable-when-not-in-FSharp.Core" machinery for framework attribute types (`[DynamicDependency]`, `[Nullable]`, `[NotNullWhen(true)]`, `[DynamicallyAccessedMembers]`, `[IsUnmanaged]`, `[ReadOnly]`), so that when compiling FSharp.Core the compiler can emit *local private copies* of those attributes instead of referencing them, and (c) nullness/`modreq(readonly)` derivation from F# types.

**Namespace / module declared**: `/// The ILX generator.` — `FSharp.Compiler.IlxGenSupport` (internal module; contract in `IlxGenSupport.fsi`)

**Public API surface** (mirrors the .fsi):
- `mkLdfldMethodDef: (name, access, isStatic, ilTy, fieldName, propTy, retTyAttrs, customAttrs) -> ILMethodDef` — "make a method that simply loads a field" (public or private, static or instance); the return instruction carries the given custom attributes.
- `GetDynamicDependencyAttribute: TcGlobals -> int32 -> ILType -> ILAttribute` — the `[DynamicDependency(memberTypes: DynamicallyAccessedMemberTypes, Type)]` attribute.
- `GenReadOnlyModReqIfNecessary: TcGlobals -> TType -> ILType -> ILType` — attach `modreq([IsReadOnly])` to a struct type reference when the F# type is a read-only record/struct.
- `GenAdditionalAttributesForTy: TcGlobals -> TType -> ILAttribute list` — any additional attributes a F# type implies (unmanaged, dynamicaly accessed members, etc.).
- `GetReadOnlyAttribute` / `GetIsUnmanagedAttribute` — the two simple single-argument attributes.
- `GetNullableAttribute: TcGlobals -> NullnessInfo list -> ILAttribute` — build `[System.Diagnostics.CodeAnalysis.Nullable]`: a single byte if one element, else a `byte[]` of the per-element nullness bytes (with-null = 2, ambivalent = 0, without-null = 1).
- `GetNullableContextAttribute: TcGlobals -> byte -> ILAttribute` — the `[NullableContext]` attribute; the doc-comment explains the default-`[1]` (withoutNull) heuristic: "Nested items not annotated with Nullable themselves are interpreted as being withoutNull ... a heuristical decision supporting limited usage of (| null) annotations".
- `GetNotNullWhenTrueAttribute: TcGlobals -> string array -> ILAttribute` — `[NotNullWhen(true)]` for named properties.
- `ChooseUniqueName: string -> Set<string> -> string` — unique-name generation (base, base0, base1, ...).

**Private / internal helpers** (not in the .fsi):
- `mkFlagsAttribute` — the `[Flags]` attribute.
- `mkLocalPrivateAttributeWithDefaultConstructor` — a local private `Attribute` subclass with only an empty ctor (used for parameterless attributes).
- `mkILNonGenericInstanceProperty` — small `ILPropertyDef` constructor.
- `type AttrDataGenerationStyle` — `PublicFields` (attribute data exposed as public fields) or `EncapsulatedProperties` (exposed as private fields + `get_*` properties).
- `mkLocalPrivateAttributeWithPropertyConstructors` — the general local-attribute-type builder; generates the ctor and, under `EncapsulatedProperties`, a private `<name>@` field plus a public `get_<name>` accessor.
- `mkLocalPrivateAttributeWithByteAndByteArrayConstructors` — for `NullableAttribute`-style types that accept both `byte` and `byte[]` (the `byte` overload wraps the scalar into a length-1 array).
- `mkLocalPrivateInt32Enum` — build a local private `Enum` with static literal fields + `value__` + `[Flags]` attribute.
- `getPotentiallyEmbeddableAttribute` — the driver: `g.TryEmbedILType(tref, embedFn)` only fires (emitting the local copy) when `g.compilingFSharpCore` is in effect; otherwise it returns an attribute referencing the framework type.
- `GetDynamicallyAccessedMemberTypes` — build or reference the `DynamicallyAccessedMemberTypes` enum (with all 16 flags from `All` = -1 up to `Interfaces` = 8192).
- `GenReadOnlyIfNecessary` / `GenNullnessIfNecessary` / `GetNullnessFromTType` — derive the `NullableAttribute` bytes from a `TType` (the comment at line 388 describes the "type parameter reference: nullability 0, 1, or 2" convention).

**Significant internal logic**:
- **Local embedding for FSharp.Core self-hosting**: all attribute getters route through `g.TryEmbedILType(tref, embedFn)`, which calls `embedFn` to generate a *local private copy* of the attribute type when the compiler is compiling FSharp.Core (so FSharp.Core is not self-referential); when not, it simply builds a `CustomAttribute` over the framework type ref.
- Per-attribute-type shape:
  - default-ctor-only: `[IsReadOnly]`, `[IsUnmanaged]`;
  - property-ctor (public or encapsulated): `[DynamicDependency]`, `[NullableContext]`, `[NotNullWhen(true)]`;
  - byte/byte-array dual ctor: `[Nullable]`;
  - int32 enum: `DynamicallyAccessedMemberTypes`.
- `mkLocalPrivateAttributeWithPropertyConstructors` is the workhorse: it generates a field per property (`<name>@` in encapsulated mode), a `get_<name>` instance accessor (via `mkLdfldMethodDef`), and a `mkILSimpleStorageCtorWithParamNames` ctor that sets all fields in order.
- Nullness convention: `WithNull = 2`, `AmbivalentToNull = 0`, `WithoutNull = 1`. A list of one element emits the single-byte form (smaller metadata); multiple elements emit the `byte[]` form. The `NullableContext` default of `1` is deliberately conservative (the doc-comment notes it avoids metadata bloat for the >50%-of-code case).
- All generated member types are attributed with `[CompilerGenerated]` (via `g.AddXxxGeneratedAttributes`) so tools/trimmers can identify them.

**Cross-references**:
- Signature: `IlxGenSupport.fsi`.
- Main consumer: `IlxGen.fs` (attribute emission during type def and method def construction); used by `EraseUnions.fs` / `EraseUnions.Emit.fs` (for union tag / field attribute stamping via the `addXxxGeneratedAttrs` callbacks passed down from `IlxGen.fs`).
- Depends on `FSharp.Compiler.AbstractIL.IL` for the IL construction primitives, `FSharp.Compiler.TcGlobals` for the attribute type refs and `TryEmbedILType`, and `FSharp.Compiler.TypedTree`/`TypedTreeOps` for `TType` / `NullnessInfo` shape.