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
FSharp is indendent significant before inserting code ensure the indent of the inserted code is correct

command to build the compiler.
.\build.cmd -c release

Repro:
Source file: .opencode\Issue_0001\test.fsx

Compilation:
artifacts\bin\fsc\Release\net472\fsc.exe --nologo --realsig+ --optimize+ .opencode\Issue_0001\test.fsx --out:artifacts\Temp\test_RealsigPlusOptimisePlus.exe
artifacts\bin\fsc\Release\net472\fsc.exe --nologo --realsig- --optimize+ .opencode\Issue_0001\test.fsx --out:artifacts\Temp\test_RealsigMinusOptimisePlus.exe

Compilation of .opencode\Issue_0001\test.fsx succeeds in both cases

Convert to il using:
ldasm artifacts\Temp\test_RealsigPlusOptimisePlus.exe -out:artifacts\Temp\test_RealsigPlusOptimisePlus.il

c:\kevinransom\fsharp>where ildasm
C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.7.2 Tools\ildasm.exe

SECTION B - BUG STATEMENT (SINGLE INVARIANT)
run one the script plus is for --realsig+ output: 
C:\kevinransom\fsharp\.opencode\Issue_0001\Issue_0001_plus.peverifierCommandPath.cmd

The verification script is hard coded to the file: 
artifacts\Temp\test_RealsigPlusOptimisePlus.exe

observe the output includes:
Verifying [test_RealsigPlusOptimisePlus]Test.get_failures
Verifying [test_RealsigPlusOptimisePlus]Test.reportFailure
Verifying [test_RealsigPlusOptimisePlus]Test.check
Verifying [test_RealsigPlusOptimisePlus]Test.test
Verifying [test_RealsigPlusOptimisePlus]Test.format_uint64
Verifying [test_RealsigPlusOptimisePlus]Test.get_aa
Verifying [test_RealsigPlusOptimisePlus]Test..cctor
Verifying [test_RealsigPlusOptimisePlus]Test.staticInitialization@
Verifying [test_RealsigPlusOptimisePlus]SeqTestsOnEnumerableEnforcingDisposalAtEnd.get_numActiveEnumerators
Verifying [test_RealsigPlusOptimisePlus]SeqTestsOnEnumerableEnforcingDisposalAtEnd.set_numActiveEnumerators
Verifying [test_RealsigPlusOptimisePlus]SeqTestsOnEnumerableEnforcingDisposalAtEnd.countEnumeratorsAndCheckedDisposedAtMostOnceAtEnd
Verifying [test_RealsigPlusOptimisePlus]SeqTestsOnEnumerableEnforcingDisposalAtEnd.countEnumeratorsAndCheckedDisposedAtMostOnce
Verifying [test_RealsigPlusOptimisePlus]SeqTestsOnEnumerableEnforcingDisposalAtEnd..cctor
Verifying [test_RealsigPlusOptimisePlus]SeqTestsOnEnumerableEnforcingDisposalAtEnd.staticInitialization@
Verifying [test_RealsigPlusOptimisePlus]SeqTestsOnEnumerableEnforcingDisposalAtEnd.enumerator@32
Error: Index was outside the bounds of the array.
System.IndexOutOfRangeException: Index was outside the bounds of the array.
   at Internal.TypeSystem.Instantiation.get_GenericParameters(Int32 index)
   at Internal.TypeSystem.SignatureMethodVariable.InstantiateSignature(Instantiation typeInstantiation, Instantiation methodInstantiation)
   at Internal.TypeSystem.InstantiatedType.InstantiateSignature(Instantiation typeInstantiation, Instantiation methodInstantiation)
   at Internal.IL.InstantiatedMethodIL.GetLocals()
   at Internal.IL.ILImporter..ctor(MethodDesc method, MethodIL methodIL)
   at ILVerify.Verifier.VerifyMethod(EcmaModule module, MethodIL methodIL, MethodDefinitionHandle methodHandle)
   at ILVerify.Verifier.VerifyMethods(EcmaModule module, IEnumerable`1 methodHandles)+MoveNext()
   at ILVerify.Verifier.Verify(PEReader peReader, MethodDefinitionHandle methodHandle)+MoveNext()
   at ILVerify.Program.VerifyMethods(PEReader peReader, EcmaModule module, String path, Int32& numErrors, Int32& verifiedMethodCounter, Int32& methodCounter)
   at ILVerify.Program.VerifyAssembly(PEReader peReader, EcmaModule module, String path)
..\..\   at ILVerify.Program.VerifyAssembly(AssemblyNameInfo name, String path)
   at ILVerify.Program.Run()
   at ILVerify.ILVerifyRootCommand.<.ctor>b__40_0(ParseResult result)
   
   
   
The same error occurs when you run the built .exe
c:\kevinransom\fsharp>artifacts\Temp\test_RealsigPlusOptimisePlus.exe

Unhandled Exception: System.TypeLoadException: The generic type 'SeqTestsOnEnumerableEnforcingDisposalAtEnd' was used with the wrong number of generic arguments in assembly 'test_RealsigPlusOptimisePlus, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null'.
   at Test.SeqTestsOnEnumerableEnforcingDisposalAtEnd.countEnumeratorsAndCheckedDisposedAtMostOnceAtEnd@62.System.Collections.Generic.IEnumerable<'a>.GetEnumerator()
   at Microsoft.FSharp.Collections.SeqModule.revamp@726.Invoke(Unit unitVar0)
   at Microsoft.FSharp.Collections.SeqModule.Length[T](IEnumerable`1 source)
   at Test.SeqTestsOnEnumerableEnforcingDisposalAtEnd.staticInitialization@()
   at Test.staticInitialization@()
   at <StartupCode$test_RealsigPlusOptimisePlus>.$Test$fsx.main@()




The IL can be found in the file: .opencode\Issue_0001\test_RealsigPlusOptimisePlus.il

Please investigate these errors and propose a fix, 


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


