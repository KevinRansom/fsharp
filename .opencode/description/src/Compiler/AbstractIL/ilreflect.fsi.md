# ilreflect.fsi

**Purpose**
Interface contract for the .NET "dynamic assembly writer" (`ILDynamicAssemblyWriter`) — the Reflection.Emit-based writer used to materialize F# abstract-IL structures as in-memory .NET assemblies. Provides the entry point `EmitDynamicAssemblyFragment` (build an assembly from an `ILModuleDef` + global context, returning an emit-environment and a list of deferred error lambdas), the `mkDynamicAssemblyAndModule` helper for constructing a fresh `AssemblyBuilder`/`ModuleBuilder` pair, the `cenv` compile-time-context record (IL globals, tail-call emit, PDB emit, system-type lookup, assembly-ref resolution), and `LookupTypeRef`/`LookupType` helpers that translate an `ILTypeRef`/`ILType` back into a `System.Type` for the emit environment.

**Namespace(s)**
- `FSharp.Compiler.AbstractIL` (module `internal FSharp.Compiler.AbstractIL.ILDynamicAssemblyWriter`)

**Public API surface**
- `richTextOfILTypeRef (tref: ILTypeRef) : RichText` — classify and render a type ref's name/namespace/enclosing types into a `RichText` for diagnostics.
- `mkDynamicAssemblyAndModule (assemblyName, optimize, collectible) : AssemblyBuilder * ModuleBuilder`.
- `cenv` (record) — `{ ilg: ILGlobals; emitTailcalls: bool; tryFindSysILTypeRef: string -> ILTypeRef option; generatePdb: bool; resolveAssemblyRef: ILAssemblyRef -> Choice<string, Assembly> option }`.
- `ILDynamicAssemblyEmitEnv` (opaque class) — accumulated emit-environment: `System.Type` map for created types, `MethodBuilder`/`FieldBuilder`/`PropertyBuilder` maps for the methods/fields/properties, `label` map, etc.
- `emEnv0 : ILDynamicAssemblyEmitEnv` — the empty emit-environment.
- `EmitDynamicAssemblyFragment (ilg) (emitTailcalls) (emEnv) (asmB) (modB) (modul) (debugInfo) (resolveAssemblyRef) (tryFindSysILTypeRef) : ILDynamicAssemblyEmitEnv * (unit -> exn option) list` — the main entry point; builds types/fields/properties/methods into the provided `AssemblyBuilder`/`ModuleBuilder`, returning the filled emit-environment and a list of deferred error lambdas (each `unit -> exn option` — `None` means "no exception").
- `LookupTypeRef (cenv) (emEnv) (tref: ILTypeRef) : System.Type`.
- `LookupType (cenv) (emEnv) (ty: ILType) : System.Type`.

**Significant internal logic**
- The emit uses `AssemblyBuilder`/`ModuleBuilder`/`TypeBuilder`/`ConstructorBuilder`/`MethodBuilder`/`ILGenerator` (all with F# extension members defined in `ilreflect.fs`).
- `envBindTypeRef/envBindMethodRef/envBindFieldRef/envBindPropRef` + `envGet*` — a per-emit environment keyed by `ILTypeRef`/`ILMethodRef`/`ILFieldRef`/`ILPropertyRef` (Zmap) so that each entity is emitted at most once.
- `emitInstr` is the per-instruction emitter — dispatches on `ILInstr` and produces `ILGenerator.Emit*` calls.

**Cross-references**
- `ilreflect.fs` (implementation), `il.fs` (ILModuleDef, ILMethodDef, ILType, ...), `System.Reflection.Emit`
