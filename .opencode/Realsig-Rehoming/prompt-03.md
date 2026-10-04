# Preamble for Qwen (Realsig+, TLR, and Constraint-Serialization Bug)

## 1. Realsig Modes
F# historically uses realsig-: all value initialization is lifted to an outer
module to preserve source-order initialization. To allow this module to access
class-declared values, private fields are emitted as internal in IL. IL
visibility therefore reflects the initialization model rather than the source
code.

realsig+ preserves the true source-declared visibility
(private/protected/internal/public) in IL while keeping the same initialization
sequencing. No other closure or initialization semantics change.

## 2. TLR Pipeline
The TLR pipeline (InnerLambdasToTopLevelFuncs.fs) discovers inner lambdas and
nested functions, determines closure environments, and lifts them into IL-shaped
forms.

- Under --optimize-: closures become classes.
- Under --optimize+: closures become generic methods.

TLR collects all freetypars and constraints from the lambda body and its ambient
class environment and attaches them to the generated closure representation.

Under realsig-, closures are homed on the outer module.
Under realsig+, closures are homed on the class where they were discovered.

## 3. The Bug
With --realsig+ --optimize+, inner lambdas such as takeInner and takeOuter are
lowered to generic methods. Their generic parameters correctly include the
class’s 'T and 'U, and the compiler intends to duplicate the class’s constraints
onto the method.

However, the constraint blob for the method incorrectly serializes the
constraint using var(0) (class typar 'T) instead of mvar(0) (method typar 'T).
This produces invalid IL metadata and causes a VerificationException.

The dumper shows identical constraint blobs on both the class and the method:
Decoded: genericinst(class IEnumerable`1<var(0)>)

The method constraint must instead reference mvar(0).

## 4. Relevant Serialization Code
| ILType.TypeVar tv ->
    let cgparams = env.EnclosingTyparCount
    if tv < cgparams then
        bb.EmitByte et_VAR
        bb.EmitZ32 tv
    else
        bb.EmitByte et_MVAR
        bb.EmitZ32 (tv - cgparams)

Debug traces show tv is never larger than cgparams, meaning the environment
incorrectly believes the method typars are class typars.

## 5. Suspected Source
In GenMethodForBinding, the environment is rewritten:

let eenvUnderMethLambdaTypars = EnvForTypars methLambdaTypars eenv
let eenvUnderMethTypeClassTypars = EnvForTypars ctps eenv
let eenvUnderMethTypeTypars = AddTyparsToEnv mtps eenvUnderMethTypeClassTypars

This elides class typars and reintroduces only source-declared typars. Under
realsig+, closures are homed on the class, so the method must have access to the
class typars in the correct order during constraint serialization.

Right now, the environment used during constraint emission does not correctly
reflect the method’s generic parameter ordering under realsig+.

## 6. Required Fix
Under realsig+, when generating generic methods for closures:

- The environment used for constraint serialization must treat the method’s
typars as method typars, not class typars.
- The constraint blob must serialize constraints using mvar(k) for method
typars.
- The environment must include the class typars in the correct order so that tv
>= cgparams is true for method typars.

This is a local fix in the environment used during constraint emission, not a
redesign of TLR or IlxGen.

## 7. Boundaries (Do NOT Change)
Do not modify:
- TLR pipeline structure
- closure homing rules
- initialization sequencing
- optimize+ generic method generation
- witness generation
- constraint inference
- global typar ordering

The fix is local: ensure the environment used during constraint serialization
correctly distinguishes class typars from method typars under realsig+.

## 8. Summary
Under realsig+, the environment used when serializing constraints for optimize+
generic methods must correctly classify method typars as mvars, not vars. Adjust
the environment passed to GenGenericParams and/or the environment used in
EmitILType so that env.EnclosingTyparCount reflects the class typars, not the
method typars.
