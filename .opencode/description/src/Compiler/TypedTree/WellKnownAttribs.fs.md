# WellKnownAttribs.fs

## Pipeline role

This file belongs to the TypedTree folder of the F# compiler. It defines the three `[<System.Flags>]` bit-mask enums for well-known attributes (`WellKnownEntityAttributes`, `WellKnownAssemblyAttributes`, `WellKnownValAttributes`), the `flags` module of inline bit operations over any `enum<uint64>`, and the `WellKnownAttribs<'TItem, 'TFlags>` struct that pairs an attribute list with its cached flags. This machinery is what lets the type checker avoid O(N) scans of attribute lists: flags are computed once by `TypedTreeOps.Attributes.fs` and then looked up in O(1).

## Header, namespace

- Copyright header (Microsoft, `License.txt`); `/// Flags enums and generic wrapper for well-known attribute flags.`
- `namespace FSharp.Compiler`.

## Flags enums (all `type internal … [<System.Flags>] enum<uint64>`)

### `WellKnownEntityAttributes`

Well-known attributes on `Entity` (types and modules); bits `0..48`, sentinel `NotComputed = 1uL <<< 63`:

`RequireQualifiedAccessAttribute`, `AutoOpenAttribute`, `AbstractClassAttribute`, `SealedAttribute_True`, `NoEqualityAttribute`, `NoComparisonAttribute`, `StructuralEqualityAttribute`, `StructuralComparisonAttribute`, `CustomEqualityAttribute`, `CustomComparisonAttribute`, `ReferenceEqualityAttribute`, `DefaultAugmentationAttribute_True`, `CLIMutableAttribute`, `AutoSerializableAttribute_True`, `StructLayoutAttribute`, `DllImportAttribute`, `ReflectedDefinitionAttribute`, `MeasureableAttribute`, `SkipLocalsInitAttribute`, `DebuggerTypeProxyAttribute`, `ComVisibleAttribute_True`, `IsReadOnlyAttribute`, `IsByRefLikeAttribute`, `ExtensionAttribute`, `AttributeUsageAttribute`, `WarnOnWithoutNullArgumentAttribute`, `AllowNullLiteralAttribute_True`, `ClassAttribute`, `InterfaceAttribute`, `StructAttribute`, `MeasureAttribute`, `DefaultAugmentationAttribute_False`, `AutoSerializableAttribute_False`, `ComVisibleAttribute_False`, `ObsoleteAttribute`, `ComImportAttribute_True`, `CompilationRepresentation_ModuleSuffix/PermitNull/Instance/Static`, `CLIEventAttribute`, `SealedAttribute_False`, `AllowNullLiteralAttribute_False`, `CompilerMessageAttribute`, `ExperimentalAttribute`, `UnverifiableAttribute`, `EditorBrowsableAttribute`, `CompiledNameAttribute`, `DebuggerDisplayAttribute`, `NotComputed`.

### `WellKnownAssemblyAttributes`

Well-known assembly-level attributes: `AutoOpenAttribute`, `InternalsVisibleToAttribute`, `AssemblyCultureAttribute`, `AssemblyVersionAttribute`, `TypeProviderAssemblyAttribute`, `NotComputed` (`1uL <<< 63`).

### `WellKnownValAttributes`

Well-known attributes on `Val` (values and members); bits `0..42`, `NotComputed = 1uL <<< 63`:

`DllImportAttribute`, `EntryPointAttribute`, `LiteralAttribute`, `ConditionalAttribute`, `ReflectedDefinitionAttribute_True`, `RequiresExplicitTypeArgumentsAttribute`, `DefaultValueAttribute_True`, `SkipLocalsInitAttribute`, `ThreadStaticAttribute`, `ContextStaticAttribute`, `VolatileFieldAttribute`, `NoDynamicInvocationAttribute_True`, `ExtensionAttribute`, `OptionalArgumentAttribute`, `InAttribute`, `OutAttribute`, `ParamArrayAttribute`, `CallerMemberNameAttribute`, `CallerFilePathAttribute`, `CallerLineNumberAttribute`, `DefaultParameterValueAttribute`, `ProjectionParameterAttribute`, `InlineIfLambdaAttribute`, `OptionalAttribute`, `StructAttribute`, `NoCompilerInliningAttribute`, `ReflectedDefinitionAttribute_False`, `DefaultValueAttribute_False`, `NoDynamicInvocationAttribute_False`, `GeneralizableValueAttribute`, `CLIEventAttribute`, `NonSerializedAttribute`, `MethodImplAttribute`, `PreserveSigAttribute`, `FieldOffsetAttribute`, `CompiledNameAttribute`, `WarnOnWithoutNullArgumentAttribute`, `MarshalAsAttribute`, `NoEagerConstraintApplicationAttribute`, `ValueAsStaticPropertyAttribute`, `TailCallAttribute`, `NotNullIfNotNullAttribute`, `OverloadResolutionPriorityAttribute`, `NotComputed`.

## `module internal Flags`

Inline bit helpers over any `enum<uint64>` flag type (converted via `LanguagePrimitives.EnumToValue`/`EnumOfValue`):

- `isEmpty` — zero bits.
- `union a b` — `a ||| b`.
- `intersect other flags` — `flags &&& other`.
- `except b a` — `a &&& ~~~b`.
- `intersects other flags` — non-zero intersection.
- `isSubsetOf superset subset` — `subset &&& ~~~superset = 0`.

## `type internal WellKnownAttribs<'TItem, 'TFlags when 'TFlags: enum<uint64>>`

`[<Struct; NoEquality; NoComparison>]` generic wrapper for an item list plus cached flags (O(1) well-known attribute lookup on entities and vals):

- Private vals: `attribs: 'TItem list`, `flags: 'TFlags`.
- `new(attribs, flags)`.
- `HasWellKnownAttribute(flag)` — `flags &&& flag <> 0uL`.
- `AsList()` — the underlying attribute list (for remap/display/serialization/full-data extraction).
- `Flags` — current flags.
- `Add(attrib, flag)` — prepends the item and ORs-in its flag (new wrapper).
- `WithRecomputedFlags()` — returns a copy with flags set to the `NotComputed` sentinel (`1uL <<< 63`) when the list is non-empty, or `0uL` for an empty list — i.e. "recompute flags from the list on next use".
- `CheckFlag(flag, compute)` — the lazy-computation protocol: if the current flags include the `NotComputed` sentinel, calls `compute x.attribs`, returns a wrapper with the recomputed flags, and signals `needsWriteBack = true`; otherwise returns `(HasWellKnownAttribute(flag), x, false)`. The caller must write back the returned wrapper when `needsWriteBack` is true.

## Notes

The flag enums are re-declared verbatim in the `.fsi` so both projects share the same layout; the `.fsi` omits the private `attribs`/`flags` accessors (`val private`). Consumers include `TypedTreeOps.Attributes.fs` (computes the flags) and `TypedTreePickle.fs`.