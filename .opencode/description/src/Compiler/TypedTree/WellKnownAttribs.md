# WellKnownAttribs.fs

**Purpose**: Flags enums and a generic wrapper for well-known .NET attribute flags. Rather than doing O(N) linear scans of attribute lists, these bit-flag enums (backed by `[<System.Flags>]` uint64 enums) cache which well-known attributes are present on an `Entity` (type/module), an `Assembly`, or a `Val` (value/member). The `WellKnownAttribs<'TItem,'TFlags>` struct pairs an attribute/item list with the cached flags for O(1) lookup.

**Namespace(s)**: `FSharp.Compiler` (namespace, not module-only).

**Declared types**:
- `WellKnownEntityAttributes` (`[<System.Flags>]`, internal) — bit flags for well-known entity attributes, e.g. `RequireQualifiedAccessAttribute`, `AutoOpenAttribute`, `AbstractClassAttribute`, `SealedAttribute_True/_False`, `NoEquality/NoComparison`, `StructuralEquality/Comparison`, `Custom*`, `ReferenceEquality`, `DefaultAugmentationAttribute_True/_False`, `CLIMutableAttribute`, `AutoSerializableAttribute_True/_False`, `StructLayoutAttribute`, `DllImportAttribute`, `ReflectedDefinitionAttribute`, `MeasureableAttribute`, `SkipLocalsInitAttribute`, `DebuggerTypeProxyAttribute`, `ComVisibleAttribute_True/_False`, `IsReadOnlyAttribute`, `IsByRefLikeAttribute`, `ExtensionAttribute`, `AttributeUsageAttribute`, `WarnOnWithoutNullArgumentAttribute`, `AllowNullLiteralAttribute_True/_False`, `Class/Interface/Struct/MeasureAttribute`, `ObsoleteAttribute`, `ComImportAttribute_True`, `CompilationRepresentation_{ModuleSuffix,PermitNull,Instance,Static}`, `CLIEventAttribute`, `CompilerMessageAttribute`, `ExperimentalAttribute`, `UnverifiableAttribute`, `EditorBrowsableAttribute`, `CompiledNameAttribute`, `DebuggerDisplayAttribute`, `NotComputed` (bit 63 sentinel).
- `WellKnownAssemblyAttributes` (`[<System.Flags>]`, internal) — `AutoOpenAttribute`, `InternalsVisibleToAttribute`, `AssemblyCultureAttribute`, `AssemblyVersionAttribute`, `TypeProviderAssemblyAttribute`, `NotComputed`.
- `WellKnownValAttributes` (`[<System.Flags>]`, internal) — e.g. `DllImportAttribute`, `EntryPointAttribute`, `LiteralAttribute`, `ConditionalAttribute`, `ReflectedDefinitionAttribute_True/_False`, `RequiresExplicitTypeArgumentsAttribute`, `DefaultValueAttribute_True/_False`, `SkipLocalsInitAttribute`, `ThreadStaticAttribute`, `ContextStaticAttribute`, `VolatileFieldAttribute`, `NoDynamicInvocationAttribute_True/_False`, `ExtensionAttribute`, `OptionalArgumentAttribute`, `InAttribute`/`OutAttribute`, `ParamArrayAttribute`, `CallerMember/FilePath/LineNumberAttribute`, `DefaultParameterValueAttribute`, `ProjectionParameterAttribute`, `InlineIfLambdaAttribute`, `OptionalAttribute`, `StructAttribute`, `NoCompilerInliningAttribute`, `GeneralizableValueAttribute`, `CLIEventAttribute`, `NonSerializedAttribute`, `MethodImplAttribute`, `PreserveSigAttribute`, `FieldOffsetAttribute`, `CompiledNameAttribute`, `WarnOnWithoutNullArgumentAttribute`, `MarshalAsAttribute`, `NoEagerConstraintApplicationAttribute`, `ValueAsStaticPropertyAttribute`, `TailCallAttribute`, `NotNullIfNotNullAttribute`, `OverloadResolutionPriorityAttribute`, `NotComputed`.
- `WellKnownAttribs<'TItem, 'TFlags when 'TFlags: enum<uint64>>` (`[<Struct; NoEquality; NoComparison>]`, internal) — generic wrapper: `attribs: 'TItem list` + cached `flags: 'TFlags`.

**Public/used API surface** (`WellKnownAttribs`):
- `new(attribs, flags)`
- `HasWellKnownAttribute(flag) : bool`
- `AsList() : 'TItem list` (for remap/display/serialization)
- `Flags : 'TFlags`
- `Add(attrib, flag)` — cons an item and ORs in the flag
- `WithRecomputedFlags()` — returns a copy with flags = `NotComputed` (or 0 if empty)
- `CheckFlag(flag, compute) : struct (bool * WellKnownAttribs * bool)` — if the `NotComputed` sentinel is set, computes flags via `compute`, returns `(result, newWrapper, needsWriteBack=true)`, else `(HasWellKnownAttribute, this, false)`.

**Internal module `Flags`** (generic flag-set algebra): `isEmpty`, `union`, `intersect`, `except`, `intersects`, `isSubsetOf`, all `inline` over `enum<uint64>` via `LanguagePrimitives.EnumToValue/EnumOfValue`.

**Significant internal logic**: The bit-63 `NotComputed` sentinel implements lazy flag computation — `CheckFlag` re-derives flags when the sentinel is present and reports whether the caller must write the wrapper back. Attribute lists are kept as F# lists so they remain remappable/serializable.

**Cross-references**: `WellKnownAttribs.fsi` (contract), `TypedTree.fs` (Entities/Vals carry these), `TypedTreeOps.Attributes.fs` (attribute classification/computation), `TypedTreePickle.fs` (serialization of the wrapper), `AssemblyInfo.fs` (assembly-level usage).
