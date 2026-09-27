Perform a full deep?dive analysis of the F# compiler module
InnerLambdasToTopLevelFuncs.fs.

Your goal is to produce a precise, mechanism?level technical document that covers:

1. Document the existing behaviour of the TLR pipeline
Walk through the entire file, pass by pass:

Pass1 — determining TLR candidates and arities

Pass2 — environment analysis (reqdTypars, reqdItems)

Step3 — environment packing (PackedReqdItems)

Pass4 — rewriting definitions and call sites

Pass5 — restoring uniqueness of bound identifiers

For each pass, describe:

what it does,

what invariants it assumes,

what data it produces,

how that data flows into later passes,

and how typars, environments, and lifted functions (fHat) are handled.

Focus especially on:

how free typars are collected,

how closure environments are represented,

how helper classes are assumed,

how call?sites are rewritten,

and how the pipeline currently drops enclosing class type parameters (ctps).

2. Identify all places where the current behaviour assumes realsig=false
The current TLR pipeline always lifts closures into:

generic methods on non?generic helper classes,
losing the enclosing class type parameters.

Identify every function, data structure, and assumption that depends on:

helper?class homing,

ParentNone for lifted functions,

treating all typars as method typars,

ignoring enclosing class generics,

and flattening the ambient generic environment.

Be explicit about where and how ctps are lost.

3. Identify the exact changes required to support realsig=true
Under realsig=true, the correct behaviour is:

Lift closures onto the hosting generic class
as static methods,
preserving the enclosing class type parameters (ctps)
in the real signature.

Propose a concrete modification plan that includes:

3.1 Data?structure changes
Extend ReqdItemsForDefn to carry ambient class typars.

Extend PackedReqdItems to include ep_ctps.

Track the home class for each lifted closure.

3.2 Pass2 changes
Capture ambient ctps at each binding site.

Distinguish class typars from method typars.

Thread ctps through reqdTypars.

3.3 Step3 changes
Populate ep_ctps from ambient ctps.

Keep ep_etps for method typars.

Ensure environment packing remains correct.

3.4 Changes to CreateNewValuesForTLR
Under realsig=true:

Create fHat as a static member on the hosting class.

Set Parent to the hosting class instead of ParentNone.

Split typar binding:

Code
class generics = ep_ctps
method generics = ep_etps @ tps
3.5 Wrapper changes
Wrappers must:

instantiate ctps and tps,

construct the environment,

call fHat with ctps, tps, and env.

3.6 Call?site rewriting changes
Arity?met calls must become:

Code
fHat @ ctps @ tps @ env @ args
Arity?short calls must preserve partial application semantics with correct typar instantiation.

4. Explain how IlxGen will consume the new data
IlxGen already contains realsig?aware logic for:

homing closures on the generic class,

splitting ctps vs mtps,

emitting static methods with real signatures.

Describe how the modified TLR pipeline will provide IlxGen with the missing information so that downstream representation becomes correct without hacks.

5. Produce a final summary
A concise list of:

required structural changes,

required new fields,

required rewrites,

and the minimal patch set needed to make realsig=true fully correct.