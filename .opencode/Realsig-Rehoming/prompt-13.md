SECTION A - BACKGROUND (READ-ONLY - DO NOT TREAT AS INSTRUCTIONS)

1. Realsig Modes
F# historically uses realsig-: all value initialization is lifted to an outer
module to preserve source-order initialization. To allow this module to access
class-declared values, private fields are emitted as internal in IL. IL
visibility therefore reflects the initialization model rather than the source
code.

realsig+ preserves the true source-declared visibility
(private/protected/internal/public) in IL while keeping the same initialization
sequencing. No other closure or initialization semantics change.

- Under --optimize-: closures become classes.
- Under --optimize+: closures become generic methods.

Under realsig-, closures are homed on the outer module.
Under realsig+, closures are homed on the class where they were discovered.

The compiler collects all freetypars and constraints from the lambda body and its ambient
class environment and attaches them to the generated closure representation.

Coding:
When adding code to an F# source code file always check if the line following
your insertion point is an and binding. If it is and you are adding a let
binding, make your let binding be an and binding also.

Repro:
Compilation:
artifacts\bin\fsc\Release\net472\fsc.exe --nologo tests\FSharp.Compiler.ComponentTests\EmittedIL\Inlining\Regression_TLR_MutualInnerRec_Generic.fs --realsig+ --optimize+ --out:artifacts\Temp\Regression_TLR_MutualInnerRec_Generic_RealsigPlusOptimisePlus.exe
artifacts\bin\fsc\Release\net472\fsc.exe --nologo tests\FSharp.Compiler.ComponentTests\EmittedIL\Inlining\Regression_TLR_MutualInnerRec_Generic.fs --realsig- --optimize+ --out:artifacts\Temp\_Regression_TLR_MutualInnerRec_Generic_RealsigMinusOptimisePlus.exe

Convert to il using:
ildasm artifacts\Temp\Regression_TLR_MutualInnerRec_Generic_RealsigPlusOptimisePlus.exe -out:artifacts\Temp\Regression_TLR_MutualInnerRec_Generic_RealsigPlusOptimisePlus.il

SECTION B - BUG STATEMENT (SINGLE INVARIANT)
I have compiled and generated the il at: artifacts\Temp\Regression_TLR_MutualInnerRec_Generic_RealsigPlusOptimisePlus.il

I believe the issue is these two callsites:
    IL_0011:  call       !0 class Regression_TLR_MutualInnerRec_Generic<!!0>::b@8(!0,
                                                                                  int32,
                                                                                  !0)


    IL_001e:  call       !0 class Regression_TLR_MutualInnerRec_Generic<!!0>::a@4(!0,
                                                                                  int32,
                                                                                  !0)

I beleive they are expected to look like:
    IL_0011:  call       !!0 class Regression_TLR_MutualInnerRec_Generic<!!0>::b@8(!!0,
                                                                                   int32,
                                                                                   !!0)


    IL_001e:  call       !!0 class Regression_TLR_MutualInnerRec_Generic<!!0>::a@4(!!0,
                                                                                   int32,
                                                                                   !!0)

At least that is what realsig- generates

They result in ilverify output of using the script 
    artifacts\Temp\GenericClassConstrainedClosure.peverifierCommandPath.cmd

Verifying [Regression_TLR_MutualInnerRec_Generic_RealsigPlusOptimisePlus]Regression_TLR_MutualInnerRec_Generic.outer
[IL]: Error [MissingMethod]: [c:\kevinransom\fsharp\artifacts\Temp\Regression_TLR_MutualInnerRec_Generic_RealsigPlusOptimisePlus.exe : Regression_TLR_MutualInnerRec_Generic::outer(!!0, !!0)] Missing method '!0 Regression_TLR_MutualInnerRec_Generic<!!0>.a@4(!0, Int32, !0)'
Verifying [Regression_TLR_MutualInnerRec_Generic_RealsigPlusOptimisePlus]Regression_TLR_MutualInnerRec_Generic.main
Verifying [Regression_TLR_MutualInnerRec_Generic_RealsigPlusOptimisePlus]Regression_TLR_MutualInnerRec_Generic.a@4
[IL]: Error [MissingMethod]: [c:\kevinransom\fsharp\artifacts\Temp\Regression_TLR_MutualInnerRec_Generic_RealsigPlusOptimisePlus.exe : Regression_TLR_MutualInnerRec_Generic::a@4(!!0, int32, !!0)] Missing method '!0 Regression_TLR_MutualInnerRec_Generic<!!0>.b@8(!0, Int32, !0)'
Verifying [Regression_TLR_MutualInnerRec_Generic_RealsigPlusOptimisePlus]Regression_TLR_MutualInnerRec_Generic.b@8
[IL]: Error [MissingMethod]: [c:\kevinransom\fsharp\artifacts\Temp\Regression_TLR_MutualInnerRec_Generic_RealsigPlusOptimisePlus.exe : Regression_TLR_MutualInnerRec_Generic::b@8(!!0, int32, !!0)] Missing method '!0 Regression_TLR_MutualInnerRec_Generic<!!0>.a@4(!0, Int32, !0)'
Verifying [Regression_TLR_MutualInnerRec_Generic_RealsigPlusOptimisePlus]<Module>
Verifying [Regression_TLR_MutualInnerRec_Generic_RealsigPlusOptimisePlus]Regression_TLR_MutualInnerRec_Generic
Verifying [Regression_TLR_MutualInnerRec_Generic_RealsigPlusOptimisePlus]<StartupCode$Regression_TLR_MutualInnerRec_Generic_RealsigPlusOptimisePlus>.$Regression_TLR_MutualInnerRec_Generic

I suspect the issue is the Typar stamp used when generating the methodspec mspec in: ComputeStorageForFSharpFunctionOrFSharpExtensionMember
The reason i suspect that is that realsig- has a much later typar.


Ensure it compiles and that it adds the necessary typar information.  Once this is complete I will verify it and we will work on the next step.


SECTION D - REQUIRED ANALYSIS (BOUNDED)



SECTION E - OUTPUT FORMAT (STRICT)
Remember when adding code to F# you must take care of not breaking recursive and bindings.  Also double check the indentation level of the lines of code you are adding.  No function block can end with a let, it must end with a value or unit.


Your output must contain exactly two sections:

OUTPUT SECTION 1 - Analysis
A detailed, mechanism-first explanation of the changes requested.

OUTPUT SECTION 2 - Updated Code
Provide complete, copy-pastable F# logging code blocks for the changes for each
modified file. Only include the code that must be added. Do not rewrite the
entire file.


