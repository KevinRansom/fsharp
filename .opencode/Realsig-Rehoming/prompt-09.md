#  **Complete Document — Copy/Paste Ready**

## Title: **Diagnostic Description — Generic Method Typar Constraint Bug in realsig+**

### Overview

This document describes the precise mechanism behind the bug where **generic method parameter constraints** in the F# compiler’s **realsig+** pipeline incorrectly reference **class type parameters** instead of the **method’s cloned type parameters**. It explains:

- Where the typar is emitted in IL  
- How the compiler chooses between class vs method typars  
- Why realsig? behaves correctly  
- Why realsig+ behaves incorrectly  
- Why the emitted IL blobs appear identical even when semantically wrong  

This document does **not** propose or implement a fix.  
It is purely diagnostic.

---

## 1. **What the Bug Is**

In the function GenMethodBindings

When we are compiling with --realsig+ --optimize+ the arguments for the methodspecs for closures may be incorrectly specified.  When instantiating variables it uses !0 and !1.

The actual intent is to use the typars from the method signature.  Indeed for closures they should always be from the method signature.

Can you find exactly where the mspec is built and investigate whether we know at that exact point whether we are building a closure, and whether we can create the generic types to be !!0..!!n rather than !0 to !n.

The compiler is normally okay with !0 to !n because by default and realsig- closures are hosted on a non generic module.

Deliverable:
An experimental code fix with the mspec typars to utilize method typars only when building realsig+

Thank you

