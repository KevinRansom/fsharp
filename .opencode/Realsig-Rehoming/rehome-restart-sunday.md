RESTART PROMPT
Context: You are implementing --realsig+ for the F# compiler. In realsig+ mode, a lambda (DeclKind.ExpressionBinding) discovered in a member body of a generic class C<'T,'U> is re-hosted as a nested static method of C (see IlxGen.fs:11128, AllocValReprWithinExpr). A nested method inherits its containing type's typars, so the closure's GeneralizedType must not re-declare them. But TLR generates reqdTypars from the body of the closure (InnerLambdasToTopLevelFuncs.fs:558-560, via FreeInBindings), which does see 'T/'U, causing invalid IL.
Repro:
artifacts\bin\fsc\Debug\net11.0\fsc.exe --nologo ^
  tests\FSharp.Compiler.ComponentTests\EmittedIL\RealInternalSignature\nested_generic_closure.fs ^
  --realsig+ --optimize+ --out:artifacts\Temp\RealsigPlusOptimisePlus.exe
Design (agreed with the user):
1. TcGlobals (class in src/Compiler/TypedTree/TcGlobals.fs, .fsi at TcGlobals.fsi): add a record RealsigClosureParentInfo { closureVal: Val; ownerTypars: Typars }, plus two let mutable maps (keyed by Val.Stamp: int64 because Val is NoEquality):
- realsigClosureParents : Map<int64, RealsigClosureParentInfo>
- realsigClosureStamps : Map<int64, int64 list>
- Guard with let realsigClosureParentsLock = obj() and use lock for writes.
- Accessors: AddRealsigClosureParent : Val * Typars -> unit, RealsigClosureParentTryGet : Val -> RealsigClosureParentInfo option, RealsigClosureStamps : Val -> int64 list, RecordCloneOfOwnerTypar : Val * int64 * int64 -> bool.
- Important F# constraints discovered:
- let/let mutable in a class body must come before any member definitions (FS0960).
- Class constructor parameter list in .fs must match the .fsi exactly.
- In .fsi, types from the open-ed TypedTree module must still be qualified (TypedTree.Val, TypedTree.Typars), even if the .fsi has open FSharp.Compiler.TypedTree — the convention in this file uses qualified names.
- Do NOT accidentally remove existing member declarations from the .fsi — member realsig: bool is used by ~15 other files.
2. Write at typecheck time. In TcNormalizedBinding (CheckExpressions.fs:11740), if g.realsig is true AND the parent is a real type (not a module, Parent tcref from parentRef) AND enclosingDeclaredTypars is non-empty, call g.AddRealsigClosureParent(v, enclosingDeclaredTypars) for each closure Val v in the letrec group.
3. Record at clone time. In copyAndRemapAndBindTyparsFull (TypedTreeOps.Remap.fs:382-411, already instrumented with [TRACE PROVENANCE]), when a typar (orig ? cloned) is being copied, for each registered parent whose ownerTypars includes orig, call g.RecordCloneOfOwnerTypar(closureVal, orig, cloned). Note: at clone time, closureVal is not directly available — it has to be threaded through, or inferred from context (need to trace copyAndRemapAndBindTyparsFull callers; it's called from GenNewVal path in InnerLambdasToTopLevelFuncs.fs:795-825).
4. Consume at TLR. In accBinds (InnerLambdasToTopLevelFuncs.fs:558-560), after let frees = FreeInBindings tlrBs; let reqdTypars0 = frees.FreeTyvars.FreeTypars, subtract the stamps from g.RealsigClosureStamps(<closure>) for each closure Val in tlrBs.
Current state (after user's rebuild): TcGlobals.fs + TcGlobals.fsi should compile. The user fixed a member realsig: bool that was accidentally removed from the .fsi. Confirm that dotnet build src/Compiler/FSharp.Compiler.Service.fsproj -c Debug succeeds, then check whether g.AddRealsigClosureParent, g.RecordCloneOfOwnerTypar, g.RealsigClosureStamps are visible to CheckExpressions.fs, TypedTreeOps.Remap.fs, and InnerLambdasToTopLevelFuncs.fs respectively. They are internal (the .fsi says type internal RealsigClosureParentInfo), so all these files in the same assembly can see them.
Rules (from AGENTS.md / copilot-instructions.md):
- Build: dotnet build <changed>.fsproj -c Debug
- After code changes: dotnet fantomas .
- Public API change ? update .fsi
- Surface area change ? run SurfaceAreaTest in Release
- Final validation: ./build.sh -c Release --testcoreclr
What to do next:
1. Run dotnet build src/Compiler/FSharp.Compiler.Service.fsproj -c Debug to confirm the TcGlobals change is clean.
2. Grep the codebase for existing [TRACE PROVENANCE] markers in Remap.fs to find the exact clone-time instrumentation site where RecordCloneOfOwnerTypar should be called.
3. Wire up step 2 (write at TcNormalizedBinding).
4. Wire up step 4 (subtract at accBinds).
5. Build, run the repro, and confirm takeInner / takeOuter / iter now come out with the class typars trimmed from their TLR reqdTypars.
Key gotcha the user corrected during the previous session: the let mutable realsigClosureParents field in TcGlobals.fs was accidentally placed after the existing let definitions and before the member declarations — this is fine in F#. But when the .fsi was edited, the existing member realsig: bool was accidentally deleted. That's been fixed by the user. Verify this is still the case before proceeding.
Rebuild both Debug and Release before running tests. dotnet fantomas . before committing.