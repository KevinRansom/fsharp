These two files are for background information: what we thought we needed to do:
.opencode\Realsig-Rehoming\Constraint Analysis.md
.opencode\Realsig-Rehoming\Constraint Prompt.md

Also We have written a dumper: .opencode\tools\dumper
It can be executed using:
dotnet run -c debug "nameOf.exe" "NameOfHostingClass"  "nameOfClosure"
E.g.
dotnet run -c debug "New folder\Minus.exe" "RuntimeHelpers"  "takeInner@301"
This should stop future you from cycling on trying to build this :-) 

This file is a sample file that demonstrates the issue we see:
.opencode\Realsig-Rehoming\nested_generic_closure.fs

Compile it using --realsig+ and at runtime it raise a verification error:
..\..\artifacts\bin\fsc\Debug\net472\fsc.exe  nested_generic_closure.fs   --realsig+ --optimize+ --out:..\..\artifacts\rp_op.exe
c:\kevinransom\fsharp\.opencode\ConstraintIssue>..\..\artifacts\rp_op.exe

Unhandled Exception: System.Security.VerificationException: Method Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers+ConcatEnumerator`2[T,U].takeInner@301: type argument 'System.ArraySegment`1[System.Byte]' violates the constraint of type parameter 'U'.
   at Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers.ConcatEnumerator`2.System.Collections.IEnumerator.MoveNext()
   at Microsoft.FSharp.Core.CompilerServices.doIt.loop()
   at <StartupCode$rp_op>.$Nested_generic_closure.main@() 

Compile using --realsig- and at runtime it works properly
c:\kevinransom\fsharp\.opencode\ConstraintIssue>..\..\artifacts\rm_op.exe
1
2
3
1
2
3
1
2
3 

Also the debug build has extra diagnostics if you set the environmentvariable FSharp_CopyTyparTrace=1 before compiling, it prints a trace to allow you to follow the copying and SetConstraints of the compiler.

The dumper program shows that when completed the realsig+ has a bug in the constraints blob.  The constraints are using typars from the containing class rather than the method typars.

c:\kevinransom\fsharp>pushd .opencode\tools\dumper&dotnet run "..\..\..\artifacts\rp_op.exe" "ConcatEnumerator`2"  "takeInner@301"&popd
Type: ConcatEnumerator`2
Token: 0x0200000D
  GP: T (index 0)
  GP: U (index 1)
    Constraint token: 0x1B000006
    Constraint Blob:
15 12 2D 01 13 00
    Decoded: genericinst(class UnknownHandleKind(ModuleDefinition)<var(0)> )

Method: takeInner@301
Token: 0x0600002A
  GP: T (index 0)
  GP: U (index 1)
    Constraint token: 0x1B000006
    Constraint Blob:
15 12 2D 01 13 00
    Decoded: genericinst(class UnknownHandleKind(ModuleDefinition)<var(0)> )

c:\kevinransom\fsharp>pushd .opencode\tools\dumper&dotnet run "..\..\..\artifacts\rm_op.exe" "RuntimeHelpers"  "takeInner@301"&popd
Type: RuntimeHelpers
Token: 0x02000005
  (No generic parameters)

Method: takeInner@301
Token: 0x0600000F
  GP: T (index 0)
  GP: U (index 1)
    Constraint token: 0x1B000013
    Constraint Blob:
15 12 2D 01 1E 00
    Decoded: genericinst(class UnknownHandleKind(ModuleDefinition)<mvar(0)> )

c:\kevinransom\fsharp> 

As you can see the realsig+ optmize+ is usimg the class typars for the constraint.

It looks to me as if the issue is finally pinned down to codegen for the constraint needs improvemet for realsig+ towork correctly.

Please find and fix the code that causes this issue.