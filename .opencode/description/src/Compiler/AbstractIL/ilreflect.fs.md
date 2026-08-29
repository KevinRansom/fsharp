# ilreflect.fs

## Pipeline role

Part of the AbstractIL layer. This module writes Abstract IL structures at runtime using `System.Reflection.Emit` (Reflection.Emit). It is the emitter used for dynamic code generation, e.g. the interactive (fsi) execution loop and `CompilerService` dynamic assembly emission: it converts `ILModuleDef`/`ILTypeDef` trees into an `AssemblyBuilder`/`ModuleBuilder`, runs several ordered "build passes" over the type definitions (create builders, wire parents/interfaces, define members, then `CreateType` in dependency order), and finally invokes any entry-point methods. A `logRefEmitCalls` debug hook can print the equivalent C# Reflection.Emit calls for debugging.

## Namespaces and modules

- Module: `FSharp.Compiler.AbstractIL.ILDynamicAssemblyWriter` (module `internal`)
- Uses: `System`, `System.Reflection`, `System.Reflection.Emit` (the whole `*Builder`/`OpCode`/`ILGenerator` surface), `System.Runtime.InteropServices`, `System.Collections.Generic`, `Internal.Utilities.Collections` (`Zmap`), `Internal.Utilities.Library`, `FSharp.Compiler.AbstractIL.Diagnostics`, `FSharp.Compiler.AbstractIL.IL`, `FSharp.Compiler.DiagnosticsLogger`, `FSharp.Compiler.Text`/`Range` (`RichText`, `range0`), `FSharp.Compiler.IO` (`FileSystem.AssemblyLoader`), `FSharp.Core.Printf`.

## Types

- `cenv` (record) — the global emitter environment `{ ilg: ILGlobals; emitTailcalls: bool; tryFindSysILTypeRef: string -> ILTypeRef option; generatePdb: bool; resolveAssemblyRef: ILAssemblyRef -> Choice<string, Assembly> option }`. `ToString()` returns `"<cenv>"`.
- `ILDynamicAssemblyEmitEnv` (record, `[<AutoSerializable(false)>]`) — the (local) emitter state, effectively global accumulators:
  - `emTypMap: Zmap<ILTypeRef, Type * TypeBuilder * ILTypeDef * Type option>` (optional last element = the created `Type` proper, if any),
  - `emConsMap: Zmap<ILMethodRef, ConstructorBuilder>`,
  - `emMethMap: Zmap<ILMethodRef, MethodBuilder>`,
  - `emFieldMap: Zmap<ILFieldRef, FieldBuilder>`,
  - `emPropMap: Zmap<ILPropertyRef, PropertyBuilder>`,
  - `emLocals: LocalBuilder[]`,
  - `emLabels: Zmap<ILCodeLabel, Label>`,
  - `emTyvars: Type[] list` (a stack of generic-argument scopes),
  - `emEntryPts: (TypeBuilder * string) list`,
  - `delayedFieldInits: (unit -> unit) list` (deferred enum-field constant inits for FSI dynamic assemblies).
- `CollectTypes` (DU, `[<RequireQualifiedAccess>]`) — `ValueTypesOnly | All`, controls which constituent type references are collected for the CreateType ordering pass.
- `typeIsNotQueryable` behavior — no new type; the reflection-emitted `TypeBuilderInstantiation` internal type is discovered reflectively into `TypeBuilderInstantiationT`.

## Values and helper modules

- `codeLabelOrder = ComparisonIdentity.Structural<ILCodeLabel>` — comparer for labels.
- `richTextOfILTypeRef tref` — builds a `+"`-joined rich text name from `Enclosing @ [Name]`.
- `wrapCustomAttr setCustomAttr (cinfo, bytes)` — pass-through converting the `convCustomAttr` output to the `SetCustomAttribute` delegate shape.
- `logRefEmitCalls = false` — master switch for the logging extensions.
- `orderILTypeRef`, `orderILMethodRef`, `orderILFieldRef`, `orderILPropertyRef` — structural comparers for the Zmaps.
- `emEnv0` — the empty emit environment (all maps empty, `emLocals = [||]`, empty label/tv/entry-pt accumulators).
- `TypeBuilderInstantiationT` — `System.Reflection.Emit.TypeBuilderInstantiation` type obtained via `Type.GetType` (it is internal); used by `typeIsNotQueryable`.
- `definePInvokeMethod` — the 13-argument `TypeBuilder.DefinePInvokeMethod` overload located by reflection (it did not exist on netstandard); `enablePInvoke = not (isNull definePInvokeMethod)`.
- `verbose2 = false` — prints trace lines inside the Pass 4 type-creation traversal.
- `Zmap.force x m str` — `tryFind` or `failwithf` an error string.

## Extension members (the `*AndLog` logging wrappers)

When `logRefEmitCalls` is true each of these prints an equivalent C#/F# Reflection.Emit source line (using `abs <| hash builder` to name variables and `OpCode.RefEmitName` for opcode names); otherwise they simply forward to the underlying API:

- `AssemblyBuilder`: `DefineDynamicModuleAndLog`, `SetCustomAttributeAndLog` (ctor+bytes and `CustomAttributeBuilder` overloads).
- `ModuleBuilder`: `GetArrayMethodAndLog`, `GetTypeAndLog`, `DefineTypeAndLog`, `SetCustomAttributeAndLog`.
- `ConstructorBuilder`: `SetImplementationFlagsAndLog`, `DefineParameterAndLog`, `GetILGeneratorAndLog`.
- `MethodBuilder`: `SetImplementationFlagsAndLog`, `SetSignatureAndLog` (return + required/optional custom modifiers + parameter types + required/optional param modifiers), `DefineParameterAndLog`, `DefineGenericParametersAndLog`, `GetILGeneratorAndLog`, `SetCustomAttributeAndLog`.
- `TypeBuilder`: `CreateTypeAndLog` (uses `CreateTypeInfo()`; on NETSTANDARD wraps via `!! ` because of a buggy nullable annotation in ns20), `DefineNestedTypeAndLog`, `DefineMethodAndLog`, `DefineGenericParametersAndLog`, `DefineConstructorAndLog`, `DefineFieldAndLog`, `DefinePropertyAndLog`, `DefineEventAndLog`, `SetParentAndLog`, `AddInterfaceImplementationAndLog`, `InvokeMemberAndLog` (creates the type, finds the method by argument types, invokes it), `SetCustomAttributeAndLog`.
- `OpCode.RefEmitName` — capitalizes the first char and replaces `"."` with `"_"` and `"_i4"` with `"_I4"` so names match `OpCodes.X` field names.
- `ILGenerator`: `DeclareLocalAndLog`, `MarkLabelAndLog`, `BeginExceptionBlockAndLog`, `EndExceptionBlockAndLog`, `BeginFinallyBlockAndLog`, `BeginCatchBlockAndLog`, `BeginExceptFilterBlockAndLog`, `BeginFaultBlockAndLog`, `DefineLabelAndLog`, and `EmitAndLog` overloads for `OpCode` alone or with `Label`, `int16`, `int32`, `MethodInfo`, `string`, `Type`, `FieldInfo`, `ConstructorInfo`.

## Emit-environment helpers

- Binding/lookup: `envBindTypeRef` (rejects a null `Type`), `envGetTypB`, `envGetTypeDef`, `envUpdateCreatedTypeRef` (records the created `Type` proper into `emTypMap`, `Some ty`, once `typB.IsCreated()`), `envBindConsRef`/`envGetConsB`, `envBindMethodRef`/`envGetMethB`, `envBindFieldRef`/`envGetFieldB`, `envBindPropRef`/`envGetPropB`.
- Locals/labels: `envSetLocals` (asserts locals were not already set), `envSetLabel` (asserts not already bound), `envGetLabel`.
- Type variables: `envPushTyvars`/`envPopTyvars` (stack discipline), `envGetTyvar` (bounds-checked index into the top tv scope).
- Entry points: `envAddEntryPt`, `envPopEntryPts`.
- `isEmittedTypeRef emEnv tref` — `Zmap.mem` test used everywhere to distinguish locally-emitted types from previously loaded ones.
- `convTypeRef cenv emEnv preferCreated tref` — prefers the created type when `preferCreated` is set, else the stored `typT`, else falls back to `convTypeRefAux`.

## Conversion and lookup functions

- `convAssemblyRef aref` — builds an `AssemblyName` from an `ILAssemblyRef` (public key / public-key-token, version, invariant culture).
- `convResolveAssemblyRef cenv asmref tref` — loads the assembly via `FileSystem.AssemblyLoader.AssemblyLoad` (path-based load, pre-loaded assembly, or by constructed name) and looks up `tref.BasicQualifiedName`, raising `FSComp.SR.itemNotFoundDuringDynamicCodeGen` on failure.
- `convTypeRefAux cenv tref` — resolves a non-emitted type ref: `ILScopeRef.Assembly`/`PrimaryAssembly` via `convResolveAssemblyRef`, `ILScopeRef.Module`/`Local` via `Type.GetType tref.BasicQualifiedName`.
- `convCallConv` — maps `ILThisConvention`/`ILArgConvention` to `CallingConventions` (VarArgs for vararg; basic conventions map to 0).
- `convTypeAux cenv emEnv preferCreated ty` (recursive) — `Void` -> `System.Void`; arrays use `MakeArrayType()` for rank 1 and `MakeArrayType rank` otherwise (documented: `[]` vs `[*]` differ); value/boxed via `convTypeSpec`; pointer/byref via `MakePointerType`/`MakeByRefType`; `TypeVar` via `envGetTyvar`; `Modified` unwraps to the modified type; `FunctionPointer` fails.
  - `convTypeSpec` — resolves the type ref (created-or-not per `preferCreated`) and builds a generic instantiation with `MakeGenericType` when generic args are present.
  - `convType` = `convTypeAux false` (keeps `TypeBuilder`/`TypeBuilderInstantiation` for emitted types), `convCreatedType` = `convTypeAux true`.
  - `convTypeOrTypeDef` — for `ldtoken`: returns the bare type ref for an uninstantiated `Boxed` spec, else `convType`.
  - `convTypes`, `convTypesToArray`.
- Modifier helpers: `convParamModifiersOfType` collects required/optional `Type` values through chains of `ILType.Modified`; `splitModifiers` splits into (required, optional) arrays; `convParamModifiers`/`convReturnModifiers`.
- `convFieldSpec` — emitted type -> `envGetFieldB` + `nonQueryableTypeGetField`; prior type that is a builder/generic inst -> get type constructor and search then rebind (`TypeBuilder.GetField`); else queryable reflection `GetField`, raising `itemNotFoundInTypeDuringDynamicCodeGen`.
- `convMethodRef` — same three-way split via `envGetMethB` / `queryableTypeGetMethod` / `queryableTypeGetMethodBySearch` (searching by name, generic arity, parameter count and assignability incl. contravariance for delegates, then exact return/argument type equality; documented F# issue #2411), with `nonQueryableTypeGetMethod` (`TypeBuilder.GetMethod`) for generic instantiations.
- `convMethodSpec` — converts the declaring type then instantiates via `MakeGenericMethod` when the method has generic args.
- `convConstructorSpec` — three-way split for `.ctor`/`.cctor` (constructor builders, `queryableTypeGetConstructor`, `nonQueryableTypeGetConstructor` via `TypeBuilder.GetConstructor`), raising if not found.
- `LookupTypeRef cenv emEnv tref` / `LookupType cenv emEnv ty` — public post-emit lookups that prefer the created `Type` proper (`convCreatedTypeRef`/`convCreatedType`), with a comment explaining why `TypeBuilder` cast to `Type` is insufficient.

## Instruction and code emitters

- Small prefix/helper emitters used by `emitInstr`: `emitInstrCompare` (branch opcodes), `emitInstrVolatile`, `emitInstrAlign` (uses the "long" overload of `Unaligned` per the doc note), `emitInstrTail` (emits `tail.` + call + `ret` when `emitTailcalls`), `emitInstrNewobj`, `emitSilverlightCheck` (no-op).
- `emitInstrCall cenv emEnv ilG opCall tail mspec varargs` — routes `.ctor`/`.cctor` through constructors and uses `EmitCall` for vararg method specs.
- `emitInstr cenv modB emEnv ilG instr` (recursive) — the main instruction matcher: arithmetic/conversion (`AI_*`, `DT_*`), `ldc`/`ldarg`/`ldloc`/`starg`/`stloc`/index/load/store with align+volatile prefixes, branches/switch/`ret`, calls (`I_call`, `I_callvirt`, `I_callconstraint` via `Constrained` prefix, `I_calli` via `EmitCalli` with optional vararg types), `ldftn`/`ldvirtftn`, `newobj`, exceptions (`throw`/`endfinally`/`endfilter`/`leave`), field ops, `ldstr`/`isinst`/`castclass`/`ldtoken` (type/method/field), value-type ops (`cpobj`/`initobj`/`ldobj`/`stobj`/`box`/`unbox`/`unbox.any`/`sizeof`).
  - Multi-dimensional arrays use `ModuleBuilder.GetArrayMethodAndLog` for the pseudo-methods `Get`/`Set`/`Address`/`.ctor` (with a comment that the IL reader canonicalizes these calls so the emitter re-expands them); single-dimensional arrays use the direct opcodes.
  - `I_ldlen_multi` expands to a const + `Array.GetLength(int)` call; `I_seqpoint` emits nothing; unhandled instructions `failwithf`.
- `emitCode cenv modB emEnv ilG code` — pre-defines all labels (`pc2lab` maps program counter -> labels), builds a `pc2action` table from `code.Exceptions` (begin try / finally / fault / filter-catch / type-catch blocks and end block), then walks `pc = 0..instrs.Length` performing actions, marking labels, and emitting instructions; `I_br` targeting the immediately-following pc is compressed away.
- `emitLocal`, `emitILMethodBody` (declares locals then emits code with locals bound into the env), `emitMethodBody` (IL bodies emitted; PInvoke/Abstract do nothing; `Native`/`NotAvailable` fail).

## Custom attribute and generic-parameter building

- `convCustomAttr` -> `(ConstructorInfo, byte[])` via `getCustomAttrData`; `emitCustomAttr`/`emitCustomAttrs` add attributes through an `add` delegate.
- `buildGenParamsPass1` — `defineGenericParameters` with just the names (bodies of generic definitions are built later).
- `buildGenParamsPass1b cenv emEnv genArgs gps` — per generic parameter: partitions constraints into base type vs interfaces, calls `SetBaseTypeConstraint`/`SetInterfaceConstraints` (multiple base types fail), emits custom attributes, and sets `SetGenericParameterAttributes` from variance + class/struct/default-ctor/`HasAllowsRefStruct` (the last as raw flags `0x0020`, "AllowByRefLike from net9, not present in ns20").
- `emitParameter` — maps `IsIn`/`IsOut`/`IsOptional` to `ParameterAttributes`, defaults unnamed parameters to `"X" + (i+1)`, defines the parameter builder and emits its custom attributes.

## Member build passes

- Pass 2 (define, bind builders):
  - `buildMethodPass2` — registers entry points (`IsEntryPoint` with no args); PInvoke bodies (when `enablePInvoke`) are defined via the reflection-invoked `DefinePInvokeMethod` overload, mapping `PInvokeCallingConvention`/`PInvokeCharEncoding` to `CallingConvention`/`CharSet`; otherwise `.cctor`/`.ctor` -> `DefineConstructorAndLog` + `envBindConsRef`, other methods -> `DefineMethodAndLog`, method generic parms (`buildGenParamsPass1`/`Pass1b`), then `SetSignatureAndLog` with per-parameter and return custom modifiers, `SetImplementationFlagsAndLog`, `envBindMethodRef`.
  - `buildFieldPass2` — `Data`-carrying fields use `DefineInitializedData`, else `DefineFieldAndLog`; `LiteralValue` becomes `SetConstant` (deferred via `delayedFieldInits` when the field type is an enum defined in the FSI dynamic assembly, because the underlying type is not yet fixed); `Offset` via `SetOffset`; binds the field ref.
  - `buildPropertyPass2` — `DefinePropertyAndLog` with `RTSpecialName`/`SpecialName` flags, sets the accessor methods from the env, `SetConstant` for the default value, binds the property ref.
- Pass 3 (bodies, parameters, custom attributes):
  - `buildMethodPass3` — for ctors/`_name`: defines value parameters (`DefineParameterAndLog`), emits the method body via `emitMethodBody`, then the method's custom attributes; return attributes are emitted on a `ParameterBuilder` at index 0 with `Retval`; PInvoke bodies are skipped.
  - `buildFieldPass3`, `buildPropertyPass3`, `buildEventPass3` (add/remove/raise/other methods set from env, `EventType` asserted Some), `buildMethodImplsPass3` (`DefineMethodOverride`).
  - `typeAttributesOfTypeLayout` — synthesizes a `System.Runtime.InteropServices.StructLayoutAttribute` custom attribute for `Explicit` (0x02) / `Sequential` (0x00) layouts with optional `Pack`/`Size` named fields; `Auto` -> None.

## Type build passes (Pass 1 to 4)

- `buildTypeDefPass1` / `buildTypeTypeDef` — creates the root or nested `TypeBuilder` (`DefineTypeAndLog`/`DefineNestedTypeAndLog`), applies the layout attribute, creates generic parameters names, binds `TypeRef -> (typT, typB, tdef)` with `typT` obtained from `modB.GetTypeAndLog` (in the module type namespace), recurses into nested types.
- `buildTypeDefPass1b` — after all types exist: sets the base type (`SetParentAndLog`) and builds generic parameter constraints (both may reference types being defined).
- `buildTypeDefPass2` — adds interface implementations and folds `buildMethodPass2`/`buildFieldPass2`/`buildPropertyPass2`, then nested types.
- `buildTypeDefPass3` — emits method bodies, properties, events, field/method-impl custom attributes, then type custom attributes and nested types.
- Pass 4 (`buildTypeDefPass4` / `createTypeRef`) — critical, fragile `CreateType` ordering; `getTypeRefsInType` (parameterized by `CollectTypes`) collects all type references; the traversal visits enclosing type refs, generic parameter constraints (type and method, working around "bug 615" over-eager constraint resolution), the exact parent chain, interface chain, and value types appearing in fields. It installs a transient `AppDomain.CurrentDomain.TypeResolve` handler that lazily `CreateType`s nested types on demand, then calls `typB.CreateTypeAndLog()` once per type (visited/created dictionaries prevent rework).
- `buildModuleTypePass1/1b/2/3/4` — top-level delegators with empty nesting.
- `buildModuleFragment cenv emEnv modB m` — orchestrates all passes for a module: Pass1 over all top-level type defs, Pass1b, Pass2, runs deferred field inits (then clears them), Pass3, Pass4, updates created type refs in the env, and emits module custom attributes.

## Assembly-level entry points

- `defineDynamicAssemblyAndLog (asmName, flags, asmDir)` — `AssemblyBuilder.DefineDynamicAssembly` with opt-in logging of the equivalent call.
- `mkDynamicAssemblyAndModule (assemblyName, optimize, collectible)` — creates `AssemblyName`, `AssemblyBuilderAccess.Run` (or `RunAndCollect` when `collectible`), adds `DebuggableAttribute` with `DisableOptimizations` when `optimize = false`, and defines a dynamic module.
- `EmitDynamicAssemblyFragment(ilg, emitTailcalls, emEnv, asmB, modB, modul, debugInfo, resolveAssemblyRef, tryFindSysILTypeRef)` — the primary entry point (used by the compiler/fsi): builds the `cenv`, runs `buildModuleFragment`, emits manifest custom attributes on the assembly, and returns the updated env plus a list of `entryPtFun ()` continuations that invoke each entry-point method (via `InvokeMemberAndLog`), returning `TargetInvocationException.InnerException` on failure.

## Significant internal logic

- Two-timing trick for emitted types: while under construction, member lookups use the `*Builder` objects from the env maps; after `CreateType`, `LookupType`/`LookupTypeRef` and `convCreatedType` swap in the created `Type` proper, because `TypeBuilder :> Type` does not implement every `Type` method.
- Pass 4 handles Reflection.Emit's documented and undocumented `CreateType` ordering restrictions (nested before enclosing is forbidden; parents and interfaces must be created first; value-type fields trigger a `TypeResolve` event), which is why it eagerly traverses the type graph and installs a `TypeResolve` handler only during traversal.
- Emitted enum constants in the FSI dynamic assembly are deferred to after Pass 2 because the underlying type of a nested enum is only fixed when the first field is defined.