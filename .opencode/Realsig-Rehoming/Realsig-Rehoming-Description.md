Realsig Modes, TLR Pipeline, and Their Interaction
==================================================

Realsig Modes
=============
F# historically preserves source-order initialization by lifting all value
initializations into an outer module that sequences them. To allow this module
to access values declared inside classes, private fields are emitted as internal
in IL, meaning the IL signature reflects the initialization model rather than
the true source visibility. This is realsig-. In realsig+, the compiler instead
emits the actual source-declared visibility of members—private, protected,
internal, public—while retaining the same source-order initialization semantics,
allowing IL signatures to faithfully represent the original F# code.

TLR Pipeline
============
The TLR pipeline identifies inner lambdas and nested functions, determines their
closure environments, and lifts them into IL-shaped representations. Under
--optimize-, closures are materialized as classes; under --optimize+, they are
materialized as generic methods. The pipeline collects all free type parameters
and constraints arising from both the lambda body and its ambient class
environment, and attaches them to the generated closure representation. This
stage establishes the “home” of each closure and fixes its type parameters,
constraints, and callable shape.

Interaction Between Realsig Modes and TLR
=========================================
Under realsig-, closures produced by the TLR pipeline are homed on the outer
module so that initialization sequencing can be centrally managed; this forces
closure fields and methods to adopt internal visibility regardless of their
source-declared scope.
Under realsig+, closures are homed on the class where
they were discovered, allowing their visibility, type parameters, and
constraints to be emitted exactly as written in the source. The TLR pipeline
thus produces the same closure structure in both modes, but realsig+ restores
the correct IL signature and visibility while preserving the initialization
guarantees established by realsig-.