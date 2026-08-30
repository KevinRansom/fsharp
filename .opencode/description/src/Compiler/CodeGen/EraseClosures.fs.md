# EraseClosures.fs

**Purpose**: The ILX-level "closure erasure" pass. Given a typed `IlxClosureDef` produced during optimization, it decides the .NET-level representation (a `FSharpFunc`/`OptimizedClosures.FSharpFunc` delegate, a class with free-variable fields, or a direct method) and rewrites method bodies so that indirect calls through closures (`Apps_app` / `Apps_tyapp` chains) become direct, statically-typed `callvirt`/`call` IL calls.

**Namespace / module declared**: `FSharp.Compiler.AbstractIL.ILX.EraseClosures` (internal module; contract in `EraseClosures.fsi`)

**Types declared**:
- `cenv` — the closure-erasure context. Holds `ilg: ILGlobals`, the pre-resolved `tref_Func` array (10 common `FSharpFunc`/`FSharpFunc` arities), `mkILTyFuncTy` (the boxed `FSharpTypeFunc` type), and the attribute-stamping callbacks `addMethodGeneratedAttrs` / `addFieldGeneratedAttrs` / `addFieldNeverAttrs`.

**API surface** (per the .fsi — everything else below is internal):
- `newIlxPubCloEnv: ILGlobals * (ILMethodDef -> ILMethodDef) * (ILFieldDef -> ILFieldDef) * (ILFieldDef -> ILFieldDef) -> cenv` — construct an erasure context.
- `mkILTyFuncTy: cenv -> ILType` — the special "type function" used for generic (`forall`) closures.
- `mkILFuncTy: cenv -> ILType -> ILType -> ILType` — build a single-arg `FSharpFunc<'Arg,'Ret>` type.
- `mkTyOfLambdas: cenv -> IlxClosureLambdas -> ILType` — map an abstract closure-lambda shape to its .NET delegate type.
- `mkCallFunc: cenv -> (ILType -> uint16) -> int -> ILTailcall -> IlxClosureApps -> ILInstr list` — the main call-site rewrite: turn an abstract indirect application into IL.
- `convIlxClosureDef: cenv -> string list -> ILTypeDef -> IlxClosureInfo -> ILTypeDef list` — the top-level translation: given a closure type def, emit the .NET types (delegate, helper class, etc.) and the per-method conversion.

**Helpers / internals**:
- The `FSharp.Core`/`Microsoft.FSharp.Core` namespace constant and the `FSharpFunc` / `OptimizedClosures.FSharpFunc` type reference builders (`mkFuncTypeRef`) — up to 10 arities are pre-baked; larger arities construct refs on demand.
- `stripUpTo n test dest` — small generic "strip an n-deep chain" recursive helper used to walk `Lambdas` / `Apps` chains.
- `destTyLambda`, `isTyLambda`, `isTyApp`, `stripTyLambdasUpTo` — decomposition of `Lambdas_forall` nodes.
- `stripSupportedIndirectCall` — decompose a chain into 0..5 direct args + rest, recognizing that the compiler only supports up to 5 curried args per step (plus one type application) in a single step.
- `stripSupportedAbstraction` — the lambda-side mirror.
- `addMethodGeneratedAttrsToTypeDef` — apply the `addMethodGeneratedAttrs` callback to every method in a `ILTypeDef`.
- `fixVoidPtrForGenericArg` — replace `void*` in generic args with `IntPtr` (CLR constraint).
- `mkLdFreeVar` — emit the load of a free variable from the closure object (via `IlxClosureSpec`/`IlxClosureFreeVar`).
- `mkILFreeVarForParam`, `mkILLocalForFreeVar`, `mkILCloFldSpecs`, `mkILCloFldDefs` — build the IL-side locals / fields representing free variables.
- `convReturnInstr` — adjust the `ret` of a method body to the boxed type if needed.

**Significant internal logic**:
- A closure in ILX can appear in three shapes, and this file handles all of them:
  1. **Curried function type** (each lambda level is an `FSharpFunc` delegate) — the default representation for top-level functions.
  2. **Optimized closure** (a class with free-variable fields + an `Invoke` method) — used for multi-arg inner functions. `convIlxClosureDef` is where the closure's free-variable fields, methods, and any nested `FSharpFunc<>` types are materialized.
  3. **Type function** (`forall` lambda) — represented by `FSharpTypeFunc` + an `Invoke` that returns a function.
- `mkCallFunc` is the workhorse for call-site rewriting. It matches the closure against the supported indirect-call shapes and emits the appropriate `ldarg`/`ldloc` sequence followed by an `Invoke`/`InvokeFast` call. For multi-value (multi-result) applications it uses `mkCallBlockForMultiValueApp`.
- Tailcall-ness (`ILTailcall`) is propagated through `mkCallFunc` to the emitted `call`/`callvirt`.
- The "closure object" representation (for inner functions that close over free variables) is a class with the free variables as fields, an `Invoke` method for the curried entry, and a `InvokeFast` static wrapper for the optimized multi-arg path.
- All generated methods/fields are re-annotated with the `addXxxGeneratedAttrs` callbacks so they carry the right `[System.Runtime.CompilerServices.CompilerGenerated]` / `[CompilerVisibleOnly]`-equivalent attributes.

**Cross-references**:
- Signature: `EraseClosures.fsi`.
- Consumes `FSharp.Compiler.AbstractIL.ILX.Types` for `IlxClosureLambdas`, `IlxClosureApps`, `IlxClosureDef`, `IlxClosureInfo`, `IlxClosureSpec`, `IlxClosureFreeVar`.
- Uses `FSharp.Compiler.IlxGenSupport` for attribute helpers and `Morphs` for type-shape rewrites.
- Downstream of `Optimizer.fs`; feeds `IlxGen.fs` (the final ILX emitter).
