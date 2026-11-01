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
artifacts\bin\fsc\Release\net472\fsc.exe --nologo tests\FSharp.Compiler.ComponentTests\EmittedIL\Inlining\GenericClassPrivateStatic.fs --realsig+ --optimize+ --out:artifacts\Temp\RealsigPlusOptimisePlus.exe
artifacts\bin\fsc\Release\net472\fsc.exe --nologo tests\FSharp.Compiler.ComponentTests\EmittedIL\Inlining\GenericClassPrivateStatic.fs --realsig- --optimize+ --out:artifacts\Temp\RealsigMinusOptimisePlus.exe

SECTION B - BUG STATEMENT (SINGLE INVARIANT)

We are working on the realsig+ feature it has been implemented, now our job is to write more tests.
our test case is tests\FSharp.Compiler.ComponentTests\EmittedIL\Inlining\GenericClassPrivateStatic.fs

It is a generic class Safe
This class generic closures go and skip with Generic Arguments.

The bug is that the compiler:
It gets the type of the arguments wrong for the method, I think it'a aomwthig to do with not mapping the cloned typars completely or correctly somewhere.

Please investigate and explain the issue and propose a fix.

Looking at the F# code:
module Sample
type Safe<'T>(mark: 'T) =
    static let mutable stage = 0
    static member Set v = stage <- v
    member _.Mark = mark
    [<NoCompilerInlining>]
    static member private Secret() = stage + 1
    member _.Run<'U>(u: 'U) =
        let rec go (n: int) (acc: int) (p: 'U) =
            if n <= 0 then acc
            elif box p = null then acc - 1
            else skip (n - 1) (acc + Safe<'T>.Secret()) p
        and skip (n: int) (acc: int) (p: 'U) =
            if n % 2 = 0 then skip (n - 1) acc p
            else go (n - 1) acc p
        go 1000 0 u
[<EntryPoint>]
let main _ =
    let s = Safe<int>(0)
    Safe<int>.Set 41
    if s.Run<string>("x") = 21000 then 0 else 1 

The Run<'U> method is a member of Safe<'T>. It takes a generic parameter 'U.
Within Run<'U>, it defines recursive functions go and skip which also use 'U.

Now let's look at the generated IL:
Safe is a generic class Safe1<T>.
Run is an instance method: .method public hidebysig instance int32 Run<U>(!!U u) cil managed.
It calls go@9<U>`.

Wait, look at go@9<U>'s signature in IL:
.method assembly static int32 go@9<U>(int32 n, int32 acc, !T p) cil managed

Here's the bug: go@9<U> is defined as a static method that is generic over U, but its third parameter p is of type !T (the class's generic parameter), NOT !!U (the method's generic parameter).

In the F# code, go is defined inside Run<'U>, and p is of type 'U.
So go's signature should be go (n: int) (acc: int) (p: 'U).
In IL, this should be go@9<U>(int32 n, int32 acc, !!U p).

But the IL shows:
.method assembly static int32 go@9<U>(int32 n, int32 acc, !T p) cil managed

This is why ILVerify is complaining:
[IL]: Error [StackUnexpected]: [ ... Safe1::Run(!!0)]offset 0x00000009expected value 'T'
When Run<U> calls go@9<U>, it pushes a value of type U on the stack. But go@9<U> expects a value of type T`.

Similarly for go@9 itself:
[IL]: Error [StackUnexpected]: [ ... Safe1::go@9(int32, int32, !0)]offset 0x00000007expected value 'U'
In go@9, it does ldarg.2 (which is T) and then box !!U. It should be boxing p (which should be U`).

IL:

//  Microsoft (R) .NET Framework IL Disassembler.  Version 4.7.3062.0
//  Copyright (c) Microsoft Corporation.  All rights reserved.



// Metadata version: v4.0.30319
.assembly extern mscorlib
{
  .publickeytoken = (B7 7A 5C 56 19 34 E0 89 )                         // .z\V.4..
  .ver 4:0:0:0
}
.assembly extern FSharp.Core
{
  .publickeytoken = (B0 3F 5F 7F 11 D5 0A 3A )                         // .?_....:
  .ver 11:0:0:0
}
.assembly '7632fb33'
{
  .custom instance void [FSharp.Core]Microsoft.FSharp.Core.FSharpInterfaceDataVersionAttribute::.ctor(int32,
                                                                                                      int32,
                                                                                                      int32) = ( 01 00 02 00 00 00 00 00 00 00 00 00 00 00 00 00 ) 
  .hash algorithm 0x00008004
  .ver 0:0:0:0
}
.mresource public 'FSharpSignatureCompressedData.7632fb33'
{
  // Offset: 0x00000000 Length: 0x000002D3
  // WARNING: managed resource file 'FSharpSignatureCompressedData.7632fb33' created
}
.mresource public 'FSharpSignatureCompressedDataB.7632fb33'
{
  // Offset: 0x000002D8 Length: 0x00000024
  // WARNING: managed resource file 'FSharpSignatureCompressedDataB.7632fb33' created
}
.mresource public 'FSharpOptimizationCompressedData.7632fb33'
{
  // Offset: 0x00000300 Length: 0x00000111
  // WARNING: managed resource file 'FSharpOptimizationCompressedData.7632fb33' created
}
.mresource public 'FSharpOptimizationCompressedDataB.7632fb33'
{
  // Offset: 0x00000418 Length: 0x00000016
  // WARNING: managed resource file 'FSharpOptimizationCompressedDataB.7632fb33' created
}
.module '7632fb33.exe'
// MVID: {6AD2F679-BE52-CABA-A745-038379F6D26A}
.imagebase 0x00400000
.file alignment 0x00000200
.stackreserve 0x00100000
.subsystem 0x0003       // WINDOWS_CUI
.corflags 0x00000001    //  ILONLY
// Image base: 0x06B40000


// =============== CLASS MEMBERS DECLARATION ===================

.class public abstract auto ansi sealed Sample
       extends [mscorlib]System.Object
{
  .custom instance void [FSharp.Core]Microsoft.FSharp.Core.CompilationMappingAttribute::.ctor(valuetype [FSharp.Core]Microsoft.FSharp.Core.SourceConstructFlags) = ( 01 00 07 00 00 00 00 00 ) 
  .class auto ansi serializable nested public Safe`1<T>
         extends [mscorlib]System.Object
  {
    .custom instance void [FSharp.Core]Microsoft.FSharp.Core.CompilationMappingAttribute::.ctor(valuetype [FSharp.Core]Microsoft.FSharp.Core.SourceConstructFlags) = ( 01 00 03 00 00 00 00 00 ) 
    .field assembly !T mark
    .field static assembly int32 stage
    .field static assembly int32 init@2
    .method public specialname rtspecialname 
            instance void  .ctor(!T mark) cil managed
    {
      // Code size       16 (0x10)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  callvirt   instance void [mscorlib]System.Object::.ctor()
      IL_0006:  ldarg.0
      IL_0007:  pop
      IL_0008:  ldarg.0
      IL_0009:  ldarg.1
      IL_000a:  stfld      !0 class Sample/Safe`1<!T>::mark
      IL_000f:  ret
    } // end of method Safe`1::.ctor

    .method private specialname rtspecialname static 
            void  .cctor() cil managed
    {
      // Code size       15 (0xf)
      .maxstack  8
      IL_0000:  ldc.i4.0
      IL_0001:  stsfld     int32 class Sample/Safe`1<!T>::stage
      IL_0006:  ldc.i4.1
      IL_0007:  volatile.
      IL_0009:  stsfld     int32 class Sample/Safe`1<!T>::init@2
      IL_000e:  ret
    } // end of method Safe`1::.cctor

    .method public static void  Set(int32 v) cil managed
    {
      // Code size       24 (0x18)
      .maxstack  8
      IL_0000:  volatile.
      IL_0002:  ldsfld     int32 class Sample/Safe`1<!T>::init@2
      IL_0007:  ldc.i4.1
      IL_0008:  bge.s      IL_0011

      IL_000a:  call       void [FSharp.Core]Microsoft.FSharp.Core.LanguagePrimitives/IntrinsicFunctions::FailStaticInit()
      IL_000f:  br.s       IL_0011

      IL_0011:  ldarg.0
      IL_0012:  stsfld     int32 class Sample/Safe`1<!T>::stage
      IL_0017:  ret
    } // end of method Safe`1::Set

    .method public hidebysig specialname 
            instance !T  get_Mark() cil managed
    {
      // Code size       7 (0x7)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  ldfld      !0 class Sample/Safe`1<!T>::mark
      IL_0006:  ret
    } // end of method Safe`1::get_Mark

    .method private static int32  Secret() cil managed
    {
      .custom instance void [FSharp.Core]Microsoft.FSharp.Core.NoCompilerInliningAttribute::.ctor() = ( 01 00 00 00 ) 
      // Code size       25 (0x19)
      .maxstack  8
      IL_0000:  volatile.
      IL_0002:  ldsfld     int32 class Sample/Safe`1<!T>::init@2
      IL_0007:  ldc.i4.1
      IL_0008:  bge.s      IL_0011

      IL_000a:  call       void [FSharp.Core]Microsoft.FSharp.Core.LanguagePrimitives/IntrinsicFunctions::FailStaticInit()
      IL_000f:  br.s       IL_0011

      IL_0011:  ldsfld     int32 class Sample/Safe`1<!T>::stage
      IL_0016:  ldc.i4.1
      IL_0017:  add
      IL_0018:  ret
    } // end of method Safe`1::Secret

    .method public hidebysig instance int32 
            Run<U>(!!U u) cil managed
    {
      // Code size       15 (0xf)
      .maxstack  8
      IL_0000:  ldc.i4     0x3e8
      IL_0005:  ldc.i4.0
      IL_0006:  ldarg.1
      IL_0007:  tail.
      IL_0009:  call       int32 class Sample/Safe`1<!T>::go@9<!!0>(int32,
                                                                    int32,
                                                                    !0)
      IL_000e:  ret
    } // end of method Safe`1::Run

    .method assembly static int32  go@9<U>(int32 n,
                                           int32 acc,
                                           !T p) cil managed
    {
      // Code size       43 (0x2b)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  ldc.i4.0
      IL_0002:  bgt.s      IL_0006

      IL_0004:  ldarg.1
      IL_0005:  ret

      IL_0006:  ldarg.2
      IL_0007:  box        !!U
      IL_000c:  ldnull
      IL_000d:  call       bool [FSharp.Core]Microsoft.FSharp.Core.LanguagePrimitives/HashCompare::GenericEqualityIntrinsic<object>(!!0,
                                                                                                                                    !!0)
      IL_0012:  brfalse.s  IL_0018

      IL_0014:  ldarg.1
      IL_0015:  ldc.i4.1
      IL_0016:  sub
      IL_0017:  ret

      IL_0018:  ldarg.0
      IL_0019:  ldc.i4.1
      IL_001a:  sub
      IL_001b:  ldarg.1
      IL_001c:  call       int32 class Sample/Safe`1<!T>::Secret()
      IL_0021:  add
      IL_0022:  ldarg.2
      IL_0023:  tail.
      IL_0025:  call       int32 class Sample/Safe`1<!T>::skip@13<!!0>(int32,
                                                                       int32,
                                                                       !0)
      IL_002a:  ret
    } // end of method Safe`1::go@9

    .method assembly static int32  skip@13<U>(int32 n,
                                              int32 acc,
                                              !T p) cil managed
    {
      // Code size       31 (0x1f)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  ldc.i4.2
      IL_0002:  rem
      IL_0003:  brtrue.s   IL_0012

      IL_0005:  ldarg.0
      IL_0006:  ldc.i4.1
      IL_0007:  sub
      IL_0008:  ldarg.1
      IL_0009:  ldarg.2
      IL_000a:  starg.s    p
      IL_000c:  starg.s    acc
      IL_000e:  starg.s    n
      IL_0010:  br.s       IL_0000

      IL_0012:  ldarg.0
      IL_0013:  ldc.i4.1
      IL_0014:  sub
      IL_0015:  ldarg.1
      IL_0016:  ldarg.2
      IL_0017:  tail.
      IL_0019:  call       int32 class Sample/Safe`1<!T>::go@9<!!0>(int32,
                                                                    int32,
                                                                    !0)
      IL_001e:  ret
    } // end of method Safe`1::skip@13

    .property instance !T Mark()
    {
      .get instance !T Sample/Safe`1::get_Mark()
    } // end of property Safe`1::Mark
  } // end of class Safe`1

  .method public static int32  main(string[] _arg1) cil managed
  {
    .entrypoint
    .custom instance void [FSharp.Core]Microsoft.FSharp.Core.EntryPointAttribute::.ctor() = ( 01 00 00 00 ) 
    // Code size       36 (0x24)
    .maxstack  4
    .locals init (class Sample/Safe`1<int32> V_0)
    IL_0000:  ldc.i4.0
    IL_0001:  newobj     instance void class Sample/Safe`1<int32>::.ctor(!0)
    IL_0006:  stloc.0
    IL_0007:  ldc.i4.s   41
    IL_0009:  call       void class Sample/Safe`1<int32>::Set(int32)
    IL_000e:  ldloc.0
    IL_000f:  ldstr      "x"
    IL_0014:  callvirt   instance int32 class Sample/Safe`1<int32>::Run<string>(!!0)
    IL_0019:  ldc.i4     0x5208
    IL_001e:  bne.un.s   IL_0022

    IL_0020:  ldc.i4.0
    IL_0021:  ret

    IL_0022:  ldc.i4.1
    IL_0023:  ret
  } // end of method Sample::main

} // end of class Sample

.class private abstract auto ansi sealed '<StartupCode$7632fb33>'.$Sample
       extends [mscorlib]System.Object
{
} // end of class '<StartupCode$7632fb33>'.$Sample


// =============================================================

// *********** DISASSEMBLY COMPLETE ***********************
// WARNING: Created Win32 resource file C:\kevinransom\fsharp\artifacts\Temp\FSharp.Test.Utilities\e983e238\f0006925\7632fb33.res

peverify:
peverify artifacts\Temp\FSharp.Test.Utilities\e983e238\f0006925\7632fb33.exe

Microsoft (R) .NET Framework PE Verifier.  Version  4.0.30319.0
Copyright (c) Microsoft Corporation.  All rights reserved.

[IL]: Error: [C:\kevinransom\fsharp\artifacts\Temp\FSharp.Test.Utilities\e983e238\f0006925\7632fb33.exe : Sample+Safe`1[T]::Run[U]][offset 0x00000009][found (unboxed) 'U'][expected (unboxed) 'T'] Unexpected type on the stack.
[IL]: Error: [C:\kevinransom\fsharp\artifacts\Temp\FSharp.Test.Utilities\e983e238\f0006925\7632fb33.exe : Sample+Safe`1[T]::go@9[U]][offset 0x00000007][found (unboxed) 'T'][expected (unboxed) 'U'] Unexpected type on the stack.
2 Error(s) Verifying C:\kevinransom\fsharp\artifacts\Temp\FSharp.Test.Utilities\e983e238\f0006925\7632fb33.exe

c:\kevinransom\fsharp>



SECTION D - REQUIRED ANALYSIS (BOUNDED)

SECTION E - OUTPUT FORMAT (STRICT)

Your output must contain exactly two sections:

OUTPUT SECTION 1 - Analysis
A detailed, mechanism-first explanation of the changes requested.

OUTPUT SECTION 2 - Updated Code
Provide complete, copy-pastable F# logging code blocks for the changes for each
modified file. Only include the code that must be added. Do not rewrite the
entire file.


