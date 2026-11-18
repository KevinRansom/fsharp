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


Your task is to investigate a specific issue in the F# compiler related to realsig+.

Context:
- In realsig+, free class type parameters are copied into the method as new method type parameters.
- Their constraints are also copied.
- However, the copied constraints still reference the original class typar instead of the method’s cloned typar.
- This produces incorrect IL metadata: the method generic parameter constraints refer to the class generic parameter, not the method parameter.

Your goal:
Determine whether the F# compiler has a correct and supported mechanism for expressing “typar substitution inside constraints” at the TAST level, or whether this must be fixed later in IlxGen/codegen.

Investigate the following:

1. **Typar identity**
   - Can constraints be rewritten by matching on typar identity (stamp)?
   - Is stamp-based substitution sufficient to express “replace class typar with method typar” inside constraint types?

2. **Constraint representation**
   - Are constraints stored as TTypes that contain Typar nodes?
   - Can we walk these TTypes and substitute typars safely?
   - Does the TAST allow constraints to be rewritten after type checking?

3. **Phase correctness**
   - Is InnerLambdasToTopLevelFuncs.fs (or the realsig+ transform) the correct phase to perform typar substitution?
   - Or is this phase too late, meaning constraints must be fixed in IlxGen.fs during IL generic parameter emission?

4. **Semantic invariants**
   - If we rewrite constraints at the TAST level, does this preserve the checker’s semantic assumptions?
   - Are we only alpha-renaming typars, not changing constraint meaning?

5. **Fallback**
   - If TAST-level substitution is not supported or not safe, identify the minimal fix in IlxGen.fs:
     - How to rewrite IL generic parameter constraints so they reference the method typar instead of the class typar.
     - Whether this requires reconstructing constraint types at IL emission time.

Deliverables:
- A clear determination: “Yes, TAST-level constraint rewriting is supported and safe” or “No, this must be fixed in codegen.”
- A justification based on the compiler’s constraint representation and typar identity model.
- If TAST rewriting is possible, outline the substitution function.
- If not, outline the correct codegen fix.

Do not attempt to fix the test. Focus only on whether the architecture supports constraint substitution at the TAST level or requires a codegen fix.
