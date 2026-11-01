Now I have authoritative, token-level proof (metadata MetadataToken, not object identity):
realsig+ (broken)
class-T       token = 0x2A00000B
method-T      token = 0x2A000017          (new row, ≠ class-T)
method-U      token = 0x2A000018
U: > seq<T>   → T-arg token = 0x2A00000B  == CLASS-T   ✓   ≠ METHOD-T ✗
The method declares its own T (0x…017) and U (0x…018), but the constraint on U — U :> seq<T> — points its T argument at the class's T (0x…00B), not the method's T (0x…017). The body/signature use method-T. Mismatch → VerificationException.
realsig− (works)
class-T       token = 0x2A00000D
method-T      token = 0x2A00000F          (≠ class-T)
method-U      token = 0x2A000010
U: > seq<T>   → T-arg token = 0x2A00000F  == METHOD-T ✓   ≠ CLASS-T (class-T is 0x0D)
The constraint correctly points at the method's own T. Consistent.
Conclusion
This is exactly the "missing if realsig+" you suspected. In realsig− the constraint is re-pointed at the method's own generic-parameter row (0x…00F); in realsig+ that re-pointing is missing, so the constraint blob still references the class's T row (0x…00B) while the method has its own fresh T row (0x…017). The JIT validates U :> seq<class-T> against the method's own parameters at the constrained. !U / GetEnumerator call, and since the method's U is not a subtype of seq<that-other-T>, it throws VerificationException.
Where to fix
The fix belongs where the realsig+ path creates the method's own generic parameters from the class typars and must re-point the constraint's T. That's the copyTypars → then re-point constraints via the new T pattern (e.g. FixupNewTypars/CopyTyparConstraints with a renaming class-T → method-T). In realsig− that re-pointing already happens (produces 0x…00F); in realsig+ the if cenv.g.realsig branch takes the local-stay-on-class route and skips it.
The concrete place: GenGenericParam (IlxGen.fs:6214) emits tp.Constraints |> CoercesTo(ty) |> GenTypeAux ... eenv.tyenv. At that point eenv.tyenv maps the class typars, so when a method-local typar's constraint still carries the class-T, it resolves to the class-T token. The correct behavior under realsig+ is that the method's generic parameters carry constraints where the inner T has already been re-pointed to the method's own T before codegen.
So the right fix is upstream of codegen — at the TLR / closure pass that builds the method's fresh typars under realsig+ — to add the missing FixupNewTypars/instType classT→methodT re-point that realsig− already performs. Want me to instrument to find the exact eenv/tps where the realsig+ takeInner/takeOuter method typars get their fresh row, so we can add the one-line if (cenv.g.realsig) ... FixupNewTypars(...) re-point?