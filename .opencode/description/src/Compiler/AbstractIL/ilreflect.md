# ilreflect.fs

**Purpose**
Implementation of the .NET "dynamic assembly writer" (`ILDynamicAssemblyWriter`) — materializes F# abstract-IL structures as in-memory .NET assemblies via `System.Reflection.Emit`. Used when the compiler/FSI/FCS needs to "execute" F# code without writing a PE file to disk (e.g. inside F# interactive). The module provides: (1) a small set of `Type`/`TypeBuilder`/`MethodBuilder`/`FieldBuilder`/`PropertyBuilder`/`ConstructorBuilder`/`OpCode`/`ILGenerator` extension members, (2) a `Zmap` module for key-value maps, (3) a `cenv` compile-context record, (4) an `ILDynamicAssemblyEmitEnv` accumulated environment with per-entity bind/get hooks, and (5) the `EmitDynamicAssemblyFragment` entry point that walks the `ILModuleDef` and produces the runtime types via emit.

**Namespace(s)**
- `FSharp.Compiler.AbstractIL` (module `internal FSharp.Compiler.AbstractIL.ILDynamicAssemblyWriter`)

**Key extensions (type-level)**
- `AssemblyBuilder`, `ModuleBuilder`, `ConstructorBuilder`, `MethodBuilder`, `TypeBuilder`, `OpCode`, `ILGenerator` — extension members (F#-style) used throughout: e.g. `TypeBuilder.DefineGenericParameters`, `MethodBuilder.DefineParameter`, `ILGenerator.EmitCall`, etc.

**Key bindings (one-line descriptions)**
- `codeLabelOrder`, `richTextOfILTypeRef` — order and render of `ILCodeLabel` / `ILTypeRef` for diagnostics.
- `wrapCustomAttr`, `logRefEmitCalls` — custom-attr wrapping and optional logging switch.
- `flagsIf`, `equalTypes`, `equalTypeLists`, `getGenericArgumentsOfType`, `getGenericArgumentsOfMethod`, `getTypeConstructor` — small `System.Type` helpers.
- `convAssemblyRef`, `convResolveAssemblyRef (cenv) (asmref) (tref)` — resolution helpers for assembly refs (using `resolveAssemblyRef` or `AppDomain` fallback).
- `convTypeRefAux`, `orderILTypeRef`, `orderILMethodRef`, `orderILFieldRef`, `orderILPropertyRef` — ordering keys used in `Zmap` lookups.
- `emEnv0` — the empty emit-environment.
- Environment bind/get hooks (over `Zmap`): `envBindTypeRef/envUpdateCreatedTypeRef`, `envBindConsRef/envGetConsB`, `envBindMethodRef/envGetMethB`, `envBindFieldRef/envGetFieldB`, `envBindPropRef/envGetPropB`, `envGetTypB/envGetTypeDef`; `envSetLocals`, `envSetLabel/envGetLabel`, `envPushTyvars/envPopTyvars/envGetTyvar`, `isEmittedTypeRef`, `envAddEntryPt/envPopEntryPt`.
- `convCallConv (callConv) : CallingConventions` — map `ILCallingConv` to `System.Reflection.CallingConventions` (instance/explicit + Cdecl/Stdcall/Thiscall/Vararg).
- `convTypeSpec cenv emEnv preferCreated (tspec)` — recursively convert `ILTypeSpec` to a `System.Type`; `convType`, `convTypeOrTypeDef`, `convTypes`, `convTypesToArray`, `convCreatedType`, `convCreatedTypeRef`.
- `convParamModifiersOfType` / `splitModifiers` / `convParamModifiers` / `convReturnModifiers` — map `ILParameterModifier` (in/ref/out) onto `ParameterAttributes` and `ReturnParameterAttributes`.
- `TypeBuilderInstantiationT`, `typeIsNotQueryable`, `queryableTypeGetField`, `nonQueryableTypeGetField`, `convFieldSpec` — field lookup on a `System.Type` (handles `System.Linq.Expressions.Parameter` and queryable type wrappers).
- `queryableTypeGetMethodBySearch` / `queryableTypeGetMethod` / `nonQueryableTypeGetMethod` / `convMethodRef` — method lookup (handles generic, explicit-impl, and queryable `Type`); `convMethodSpec` / `convConstructorSpec` — for `ILMethodSpec` (constructor or method).
- `emitInstrCompare/Volatile/Align/Tail`, `emitInstrNewobj`, `emitSilverlightCheck` (legacy), `emitInstrCall`, `emitInstr cenv (modB) emEnv (ilG) instr` — the main per-instruction emitter (~400 lines of pattern matching over `ILInstr` and produce `ILGenerator.Emit*` calls).
- `emitCode`, `emitLocal`, `emitILMethodBody`, `emitMethodBody` — emit the full IL code of a method (instructions, exception handlers, local variables).
- `convCustomAttr`, `emitCustomAttr`, `emitCustomAttrs` — emit custom attributes.
- `buildGenParamsPass1/Pass1b` — generic parameters.
- `emitParameter`, `definePInvokeMethod`, `enablePInvoke`.
- `buildMethodPass2` (define the method signature on the `TypeBuilder`) and `buildMethodPass3` (emit the body via `emitMethodBody`) — two-pass method emission.
- `buildFieldPass2/Pass3`, `buildPropertyPass2/Pass3`, `buildEventPass3`, `buildMethodImplsPass3` — fields/properties/events/method-impls.
- `typeAttributesOfTypeLayout` — pick `TypeAttributes` from the `ILTypeLayout` (Class/Interface/Sealed/Abstract/BeforeFieldInit, etc.).
- `buildTypeDefPass1` (declare the type, push the type onto the nesting stack), `buildTypeDefPass1b` (generic params + constraints), `buildTypeDefPass2` (members), `buildTypeDefPass3` (nested types, finalize), `getEnclosingTypeRefs`, `getTypeRefsInType` — the top-level type construction.
- `EmitDynamicAssemblyFragment` — the main entry point.
- `LookupTypeRef`, `LookupType` — convert `ILTypeRef`/`ILType` to `System.Type` (used by emit-environment consumers).
- `type CollectTypes` — a helper record used to enumerate the distinct `ILTypeRef`s reachable from a type (for diagnostics, not for emission).

**Significant internal logic**
- Type emission is 4-pass: Pass 1 declares the type on the parent (with nesting), Pass 1b adds generic parameters/constraints, Pass 2 adds members (methods/fields/properties/events/method-impls), Pass 3 adds nested types and finalizes the parent.
- Method emission is 2-pass: Pass 2 defines the signature on the type, Pass 3 gets an `ILGenerator` and emits the body using `emitInstr` (which dispatches on `ILInstr` and calls `ILGenerator.Emit*`).
- The `Zmap` (typed map) is key-ordered by `ComparisonIdentity.Structural<ILTypeRef>` etc., so the same reference from different code sites resolves to the same emitted entity.
- The `ILDynamicAssemblyEmitEnv` also carries `emLabels: Zmap<ILCodeLabel, Label>` (code labels), `emTyvarStack` (generic-parameter stack), `emEntryPoints` (entry-point method refs), `emLocals` (local variables), `emTypMap`, `emConsMap`, `emMethMap`, `emFieldMap`, `emPropMap`.
- `emitInstr` is the biggest helper (~400 lines); every `ILInstr` case is matched (I_call, I_callvirt, I_newobj, I_isinst, I_box, I_castclass, I_unbox, I_unbox_any, I_ldarga, I_ldloca, I_ldloc, I_starg, I_stloc, I_calli, I_conv*, I_conv_ovf*, I_ldc_i4*, I_ldc_i8, I_ldc_r4, I_ldc_r8, I_ldstr, I_ldftn, I_ldvirtftn, I_unaligned, I_volatile, I_constrained, I_tail, I_rethrow, I_endfilter, I_endfinally, I_leave, I_leave_s, I_br_s..., I_br..., I_switch, I_cpobj, I_ldobj, I_stobj, I_ldfld, I_ldsfld, I_ldflda, I_ldsflda, I_stfld, I_stsfld, I_ldelem*, I_stelem*, I_ldind*, I_stind*, I_newarr, I_ldlen, I_ldelema, I_initobj, I_cpblk, I_initblk, I_sizeof, I_refanytype, I_refanyval, I_mkrefany, I_ldtoken, I_localloc, I_arglist, I_dup, I_pop, I_jmp, I_ret, I_break, B*, ...).
- `definePInvokeMethod` is optional; `enablePInvoke` (bool) indicates whether the host supports it (e.g. Silverlight).
- `TypeBuilderInstantiationT` is the `System.Type` of `System.Reflection.Emit.TypeBuilder` (cached for runtime checks).

**Cross-references**
- `ilreflect.fsi` (contract), `il.fs` (ILModuleDef, ILMethodDef, ILType, ILInstr, ...), `System.Reflection.Emit` (the emit API itself)
