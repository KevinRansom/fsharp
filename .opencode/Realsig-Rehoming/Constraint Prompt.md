Hand‑off prompt for a fresh opencode instance
Copy the whole block below. It is self‑contained.
Task
Fix the realsig+ VerificationException at runtime for tests/FSharp.Compiler.ComponentTests/EmittedIL/RealInternalSignature/nested_generic_closure.fs. See AGENTS.md / .opencode/AGENTS.md for build/test rules.
Repro
.\build.cmd -c Release
artifacts\bin\fsc\Release\net472\fsc.exe --nologo ^
  tests\FSharp.Compiler.ComponentTests\EmittedIL\RealInternalSignature\nested_generic_closure.fs ^
  --realsig+ --optimize+ --out:artifacts\Temp\RealsigPlusOptimisePlus.exe
artifacts\Temp\RealsigPlusOptimisePlus.exe
Current failure:
System.Security.VerificationException: Method ...ConcatEnumerator`2[T,U].takeInner@301:
  type argument 'System.ArraySegment`1[System.Byte]' violates the constraint of type parameter 'U'.
Root cause — PROVEN at the metadata-token level (authoritative)
Both realsig+ and realsig− declare takeInner@301/takeOuter@308 as generic statics with their own T,U. The only difference is the token of the T referenced inside the constraint U :> seq<T>:
 	class-T token	method-T token	U :> seq<T> → T-arg token
realsig+	0x2A00000B	0x2A000017	0x2A00000B = CLASS‑T ✗
realsig−	0x2A00000D	0x2A00000F	0x2A00000F = METHOD‑T ✓
Dumped via Type.MetadataToken of System.Type.GetGenericParameterConstraints() in a net472 Assembly.LoadFrom tool (authoritative — not object identity, not stamp).
So under realsig+ a fresh method-T row is created (good) but the constraint on the method's U still references the class's T (bad). The realsig− path re-points the constraint to the fresh T and works.
The canonical re-point helper (already in the tree)
src/Compiler/Checking/TypeHierarchy.fs:
// line 410
let CopyTyparConstraints (traitCtxt: ITraitContext option) m tprefInst (tporig: Typar) =
    tporig.Constraints
    |> List.filter (fun tp -> match tp with | TyparConstraint.AllowsRefStruct _ -> false | _ -> true)
    |> List.map (fun tpc ->
        match tpc with
        | TyparConstraint.CoercesTo(ty, _)        -> TyparConstraint.CoercesTo (instType tprefInst ty, m)
        | TyparConstraint.DefaultsTo(p, ty, _)    -> TyparConstraint.DefaultsTo (p, instType tprefInst ty, m)
        | TyparConstraint.IsEnum (ty, _)          -> TyparConstraint.IsEnum (instType tprefInst ty, m)
        | TyparConstraint.IsDelegate(a, r, _)     -> TyparConstraint.IsDelegate (instType tprefInst a, instType tprefInst r, m)
        | TyparConstraint.SimpleChoice (tys, _)   -> TyparConstraint.SimpleChoice (List.map (instType tprefInst) tys, m)
        | TyparConstraint.MayResolveMember(i,_)   -> TyparConstraint.MayResolveMember (instTrait tprefInst i, m)
        | other                                   -> other)

// line 453
let FixupNewTypars (traitCtxt: ITraitContext option) m formalEnclosingTypars tinst tpsorig tps =
    ...
    let renaming, tptys = mkTyparToTyparRenaming tpsorig tps
    let tprefInst = mkTyparInst formalEnclosingTypars tinst @ renaming
    (tpsorig, tps) ||> List.iter2 (fun tporig tp -> tp.SetConstraints (CopyTyparConstraints traitCtxt m tprefInst tporig))
    renaming, tptys
And copyTypar is the shortcut that does NOT re-point — it copies typar_constraints by reference:
// src/Compiler/TypedTree/TypedTreeBasics.fs line 199
let copyTypar clearStaticReq (tp: Typar) =
    let optData = tp.typar_opt_data |> Option.map (fun tg ->
        { typar_il_name = tg.typar_il_name; ...
          typar_constraints = tg.typar_constraints;  // ← shared by reference — not re-pointed
          ... })
    Typar.New { typar_id = tp.typar_id; typar_stamp = newStamp(); ... }
realsig− takes the copyTypars + FixupNewTypars path and correctly re-points. realsig+ takes the copyTypars-only path — the constraint's T still resolves to the class's T. That is the missing step.
Where to fix
The realsig+ path that creates fresh method typars while preserving class-T in their constraints. Strong candidates (check both):
1. TAST/TLR path — where a local function's typars become the method's typars. Look in:
- src/Compiler/Optimize/InnerLambdasToTopLevelFuncs.fs — especially AdjustValForExpectedValReprInfo and TransTLRBindings (line 1008).
- src/Compiler/TypedTree/TypedTreeOps.Remap.fs:353 — copyAndRemapAndBindTyparsFull. This does re-point today (line 366). Verify it's the path realsig− uses and that realsig+ takes a different branch.
- src/Compiler/Checking/infos.fs:1456-1461 — the standard copyTypars + FixupNewTypars pairing — this is the working pattern.
- src/Compiler/Optimizer.fs:4026-4160 (specLambda/freeTypars) — freeTypars construction.
2. Codegen path — fallback (if (1) is the right place but the re-point still doesn't take for the nested case):
- src/Compiler/CodeGen/IlxGen.fs:6214 GenGenericParam cenv eenv tp — reads tp.Constraints and emits each CoercesTo(ty) via GenTypeAux cenv tp.Range eenv.tyenv ... ty. If under realsig+ the eenv.tyenv doesn't map the method's own T but only the class's T, the emitted T inside the constraint will be the class's T.
The fix (concretely)
Wherever realsig+ (or the shared path that realsig+ happens to flow through) creates a fresh method-T and method-U as copies of the enclosing class's T and U, the constraint on the fresh U must be re-pointed so its inner T references the fresh T, not the class's T.
The one-line shape of the fix, applied at the call site that owns both the old and the new typar lists:
// Given:  oldTps = enclosing class's T,U   (source of the copies)
//         newTps = freshly created method's T,U   (the copies)
// Currently: newTps is produced by copyTypars and never re-pointed.
let () =
    let renaming, _ = mkTyparToTyparRenaming oldTps newTps
    (oldTps, newTps) ||> List.iter2 (fun o f ->
        f.SetConstraints(CopyTyparConstraints traitCtxtNone m renaming o))
Equivalently, one call to the public helper:
FixupNewTypars traitCtxtNone m oldTps [] oldTps newTps |> ignore
traitCtxt: ITraitContext option — check what the surrounding function has. Many sites use traitCtxtNone.
Localise the exact caller (verify before committing)
Add this temporary debug instrumentation (already verified to compile and to fire) at the exact site that produces the fresh typars in realsig+; remove it after you confirm the fix:
// In src/Compiler/TypedTree/TypedTreeBasics.fs after the line
let copyTypars clearStaticReq tps = List.map (copyTypar clearStaticReq) tps
// add:
#if DEBUG
open FSharp.Compiler.AbstractIL.Diagnostics
#endif
#let traceCopyTypars = (System.Environment.GetEnvironmentVariable("FSharp_CopyTyparTrace") = "1")
// and inside copyTypar, right after the line `let optData = ...`:
#if DEBUG
    if traceCopyTypars then
        let cs = tp.typar_opt_data |> Option.map (fun tg -> tg.typar_constraints) |> Option.defaultValue []
        let hasCo = cs |> List.exists (function TyparConstraint.CoercesTo _ -> true | _ -> false)
        if hasCo then
            let mutable stamps = []
            let rec gather ty =
                match ty with
                | TType_var(tp, _) -> stamps <- (string tp.Stamp) :: stamps
                | TType_app(_, args, _) -> args |> List.iter gather
                | _ -> ()
            cs |> List.iter (function
                | TyparConstraint.CoercesTo(ty, _) -> gather ty
                | _ -> ())
            dprintf "copyTypar NEW stamp=%d -> refs=[ %s ]\n" tp.typar_stamp (String.concat ", " (List.rev stamps))
#endif
Also instrument Typar.SetConstraints (src/Compiler/TypedTree/TypedTree.fs:2554) with the same env gate to log when a U-typar receives a CoercesTo and which typars are referenced inside. After the fix, the trace should show copyTypar NEW producing the new stamp and then a Subsequent SetConstraints that re-points its refs to the fresh T.
To run: .\build.cmd -c Debug, then
$env:FSharp_CopyTyparTrace="1"; artifacts\bin\fsc\Debug\net472\fsc.exe --nologo tests\...\nested_generic_closure.fs --realsig+ --optimize+ --out:artifacts\Temp\T.exe — and compare stamps against the realsig− run.
Verify
1. .\build.cmd -c Release (or Debug).
2. Regenerate both IL files:
ildasm artifacts\Temp\RealsigPlusOptimisePlus.exe -out:artifacts\Temp\P.il
ildasm artifacts\Temp\RealsigMinusOptimisePlus.exe -out:artifacts\Temp\M.il
3. Confirm P.il now shows takeOuter@308<T,...U> with IEnumerable1<!!T>` (double-bang = class-T resolved to the method's own T) — i.e. the class-T and method-T rows are the same in the method-scope view. (Or run the token dump tool at hand.)
4. Run the exe. It should print the 9 elements in 3 groups.
5. Run: .\build.cmd -testCompilerComponentTests -c Release -filter '/*/*/EmittedIL/*' (check your local TESTGUIDE for the exact filter pattern).
6. dotnet fantomas . --check.
Guardrails
- Do NOT mass-reformat. F# indentation is semantic — spaces only.
- Do NOT touch eng/common/**.
- Prefer the TAST/TLR-level fix (item 1). Avoid fixing in GenGenericParam (item 2) unless the TAST path genuinely cannot see the mapping.
- Do NOT change realsig− behavior — it already works.
- Keep the PR minimal, no FCS public-surface or FSharp.Core binary breaking change.
Context you may be missing
- --realsig+ refuses TLR when the body references class-private members (InnerLambdasToTopLevelFuncs.fs:219). Our test file's takeInner/takeOuter capture x : ConcatEnumerator<'T,'U> — so TLR is refused and they become class-nested members.
- The class ConcatEnumerator<'T,'U when 'U :> seq<'T>>. That constraint is declared exactly once, on the class. It is U :> seq<T>(class).
- The realsig− path produces a fresh T,U for the method and re-points the constraint's inner T to the fresh T (token 0x...00F).
- The realsig+ path produces a fresh T,U but skips the re-point (token in constraint still 0x...00B, the class-T).
- If you want a quick sanity check that the bug is exactly "missing re-point", change nothing, and in IlxGen.fs:6214 GenGenericParam just before GenTypeAux ... ty, temporarily replace eenv.tyenv with an env that also maps eenv's enclosing-class T to the method's own T. It should fix the verification. If that works, the actual fix belongs one level up in the TAST where the fresh typars are created.