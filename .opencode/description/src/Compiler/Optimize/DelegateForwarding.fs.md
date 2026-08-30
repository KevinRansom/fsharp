# DelegateForwarding.fs

**Purpose**: Recognizes delegate constructions whose `Invoke` body is a transparent forwarding call to a known method (an F# value or a direct IL method). Recognizing this early — before the optimizer's inlining decisions peel the expression — lets the optimizer preserve the forwardable call from inlining and lets the ILX generator point the delegate directly at its target instead of generating an intermediate closure.

**Namespace / module declared**: `FSharp.Compiler.DelegateForwarding` (internal module, no .fsi)

**Types declared**:
- `DirectDelegateForwardingTargetCandidate` — discriminated union of direct-forwarding candidates: `FSharpVal` (a module-level function or member with type args and leading bound args), `ILMethod` (a direct IL method call, e.g. a BCL method, with virtual/struct/ctor flags and method ref), or `Other` (no forwarding possible).

**Public API surface** (internal module, used across the compiler):
- `classifyForwardingTarget` — peels wrappers around a delegate body and classifies the remaining call as a `FSharpVal` / `ILMethod` / `Other` candidate.
- `fsharpValDirectlyBindable` — decides whether a candidate `ValRef` target may be bound directly as the delegate Target (checks receiver shape, effect-free bindability, type constraints, and member-call info; returns `ValueSome (virtualCall, takesInstanceArg)` or `ValueNone`).
- `ilMethodDirectlyBindable` — the analogous check for an `ILMethodRef` target.
- `signatureMatches` — residual IL signature compatibility check (parameter count, exact return type for non-generic targets); parameter *types* are deliberately not compared.
- `receiverInfo` — extracts the receiver expression plus virtual/instance facts from leading args.

**Internal helpers**:
- `stripToForwardingCall` — recursively peels effect-free `let` bindings (via an alias map), single-argument lambdas, and curried applications to expose the underlying forwarding call.
- `matchForwarding` — verifies trailing args are exactly the `Invoke` parameters (in order, modulo an elided `unit`); returns the leading args that would become the delegate Target.
- `tryFlattenTupledArgs` — mirrors the code generator's arity-based de-tupling so tuple argument groups are matched against the target's individual IL parameters; requires the group count to equal the target arity exactly.
- `resolveAliases`, `receiverShapeOk`, `receiverNotByref`, `receiverNotTypar`, `receiverNotMutableStruct`, `receiverBindable`, `staticLeadingArgIsRefType` — small guard helpers constraining the receiver form (effect-free, not referring to Invoke parameters, not byref/typar/mutable-struct).

**Significant internal logic**:
- The file compiles *before* the optimizer (it takes `exprHasEffect` = `Optimizer.ExprHasEffect` as a parameter), precisely because the optimizer's lambda-inlining / beta-reduction runs only when deciding inlining and would change the shape the recognizer needs to see.
- Structural rules encoded: at most one leading arg may become the delegate Target (instance receiver, or static first-arg "closed-over" form); static leading receivers must be reference type; mutable-struct receivers are excluded; byref/typar receivers are excluded.
- Conservative design: anything that cannot be proven a pure forwarding call falls through to `Other`, keeping the plain closure.

**Cross-references**:
- Consumed by `Optimizer.fs` (inlining preservation) and `IlxGen.fs` (direct delegate target emission) in `src/Compiler/CodeGen/`.
- Uses `ExprHasEffect` from `src/Compiler/Optimize/Optimizer.fs`.
- Operates on TypedTree expressions (`FSharp.Compiler.TypedTree`) and IL types (`FSharp.Compiler.AbstractIL.IL`).