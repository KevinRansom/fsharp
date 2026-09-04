Thought: 14m 49s
I applied the fix and rebuilt — here's the verification summary.
Summary
Fix: createFHat in InnerLambdasToTopLevelFuncs.fs:888-943
When homing = HostingClass AND the source val's declaring entity is a non-module type AND envp.ep_ctps is non-empty (i.e. the two-tier ctp/mtp type scheme is in effect), the fHat is now constructed as a static member of the hosting class instead of ParentNone:
if hostTcrefOpt.IsSome && realsigCtpSplit then
    let hostTcref = Option.get hostTcrefOpt
    let memberInfo =
        { ValMemberInfo.ApparentEnclosingEntity = hostTcref
          ValMemberInfo.MemberFlags        = StaticMemberFlags SynMemberKind.Member
          ValMemberInfo.ImplementedSlotSigs = []
          ValMemberInfo.IsImplemented      = false }
    let fHat =
        Construct.NewVal(
            fHatName, m, None, fHatTy, Immutable, f.IsCompilerGenerated, Some fHatArity,
            taccessPublic, ValNotInRecScope, Some memberInfo, NormalVal, [],
            ValInline.Optional, XmlDoc.Empty, true, false, false,
            false, false, false, None,
            Parent hostTcref)
    fHat
else
    mkLocalNameTypeArity f.IsCompilerGenerated m fHatName fHatTy (Some fHatArity)
Also added open FSharp.Compiler.SyntaxTreeOps for StaticMemberFlags.
Answer to your two questions
1. Is Parent set on fHat? Yes — for the realsig+ HostingClass case with non-empty ep_ctps, fHat is built with Parent(Some hostTcref), specialRepr = Some {ValMemberInfo{...StaticMemberFlags Member}}, isModuleOrMemberBinding=true. IsMember = true (from MemberInfo.IsSome), MemberKind = StaticMember, IsCompiledAsTopLevel = true (from ValReprInfo). Non-host or empty-ctp cases still go through mkLocalNameTypeArity (unchanged), so realsig- and ctp-less cases are byte-identical to before.
2. Does IlxGen respect it? Yes, without any change to IlxGen. At IlxGen.fs:10677 the fallback gate is v.IsCompiledAsTopLevel && not v.IsMemberOrModuleBinding. With IsMemberOrModuleBinding=true, that fires FALSE and effectiveCloc stays as the caller's eenv.cloc (which is on the hosting class). Then ComputeStorageForValWithValReprInfo at IlxGen.fs:1750-1751 routes the val through ComputeStorageForFSharpMember ? GetMethodSpecForMemberVal which splits tps into ctps/mtps via List.splitAt numParentTypars tps (IlxGen.fs:1490), where numParentTypars = hostTcref.Typars.Length (IlxGen.fs:1484). The call-site and wrapper rewrite in Pass4 (already using ep_ctps as tier 1) aligns with this exact split.
Build & runtime
Compiler service, both TFMs: build clean (0 err, 0 warn).
Full Release build (fsc + FSharp.Core + test exes): clean.
Relevant test suites (Release, net472):
- Regression_TLR_GenericClassTyparSplit (the flagship ctp/mtp-split + statics-not-closures IL-verification test): 18/18 pass.
- Regression_TLR_NestedScopesAndNameCollisions, Regression_TLR_PrivateMemberReach, Regression_TLR_StateMachineGenerators, Regression_Realsig_MixedAssemblyModes: 44/44 pass.
Known remaining failure (out of scope for this fix, pre-existing)
One theory in ClassTypeInitialization.fs — nested generic closure (realsig: True, optimize: True) — expects takeInner@301, takeOuter@308, iter@272 (locals let rec-bound inside member _.MoveNext()) to be homed onto ConcatEnumerator2 (i.e. call ... ConcatEnumerator2<...>::takeInner@301). They currently come out homed at module scope (RuntimeHelpers::takeInner@301).
That's because for those locals, f.TryDeclaringEntity at ILTTF-time is not Parent(hostingClass) (they are method-body locals and their declaring entity lands on the module, not the class), so my gate (hostTcrefOpt.IsSome) doesn't fire and they take the same mkLocalNameTypeArity path as before. This is a separate gap in the re-home work: it requires either (a) the checker to attach those method-local vals to the enclosing class, or (b) an ILTTF-side walk-up from the local's binding site to the enclosing TyconRef. Neither is "set the correct Parent on the fHat at createFHat time" — so I have not attempted it per your "no drift / minimal patch" directive.
If you want, I can follow up on (b) as a distinct change.