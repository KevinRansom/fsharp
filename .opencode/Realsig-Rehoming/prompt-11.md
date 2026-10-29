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
artifacts\bin\fsc\Release\net472\fsc.exe --nologo tests\FSharp.Compiler.ComponentTests\EmittedIL\Inlining\GenericStructPrivateStatic.fs --realsig+ --optimize+ --out:artifacts\Temp\RealsigPlusOptimisePlus.exe
artifacts\bin\fsc\Release\net472\fsc.exe --nologo tests\FSharp.Compiler.ComponentTests\EmittedIL\Inlining\GenericStructPrivateStatic.fs --realsig- --optimize+ --out:artifacts\Temp\RealsigMinusOptimisePlus.exe

SECTION B - BUG STATEMENT (SINGLE INVARIANT)

We are working on the realsig+ feature it has been implemented, now our job is to write more tests.
our test case is tests\FSharp.Compiler.ComponentTests\EmittedIL\Inlining\GenericStructPrivateStatic.fs

It is a generic class Ticker<'T>
This class has a generic closures walk.

The bug is that the compiler:
When we compile it as above, peverify fails with the following error:

c:\kevinransom\fsharp>peverify artifacts\Temp\RealsigPlusOptimisePlus.exe

Microsoft (R) .NET Framework PE Verifier.  Version  4.0.30319.0
Copyright (c) Microsoft Corporation.  All rights reserved.

[MD]: .NET Framework Internal error: 0x80131252 [token:0x1B000005]
1 Error(s) Verifying artifacts\Temp\RealsigPlusOptimisePlus.exe

When we execute the program it fails with the following error.
c:\kevinransom\fsharp>artifacts\Temp\RealsigPlusOptimisePlus.exe

Unhandled Exception: System.TypeLoadException: Could not load type 'Ticker`1' from assembly 'RealsigPlusOptimisePlus, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null' due to value type mismatch.
   at Sample.Ticker`1.Run()
   at Sample.main(String[] _arg1)


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
.assembly RealsigPlusOptimisePlus
{
  .custom instance void [FSharp.Core]Microsoft.FSharp.Core.FSharpInterfaceDataVersionAttribute::.ctor(int32,
                                                                                                      int32,
                                                                                                      int32) = ( 01 00 02 00 00 00 00 00 00 00 00 00 00 00 00 00 ) 
  .hash algorithm 0x00008004
  .ver 0:0:0:0
}
.mresource public FSharpSignatureCompressedData.RealsigPlusOptimisePlus
{
  // Offset: 0x00000000 Length: 0x000003F8
  // WARNING: managed resource file FSharpSignatureCompressedData.RealsigPlusOptimisePlus created
}
.mresource public FSharpSignatureCompressedDataB.RealsigPlusOptimisePlus
{
  // Offset: 0x00000400 Length: 0x0000004A
  // WARNING: managed resource file FSharpSignatureCompressedDataB.RealsigPlusOptimisePlus created
}
.mresource public FSharpOptimizationCompressedData.RealsigPlusOptimisePlus
{
  // Offset: 0x00000450 Length: 0x00000370
  // WARNING: managed resource file FSharpOptimizationCompressedData.RealsigPlusOptimisePlus created
}
.mresource public FSharpOptimizationCompressedDataB.RealsigPlusOptimisePlus
{
  // Offset: 0x000007C8 Length: 0x0000004C
  // WARNING: managed resource file FSharpOptimizationCompressedDataB.RealsigPlusOptimisePlus created
}
.module RealsigPlusOptimisePlus.exe
// MVID: {6AD467E9-D07F-21E7-A745-0383E967D46A}
.imagebase 0x00400000
.file alignment 0x00000200
.stackreserve 0x00100000
.subsystem 0x0003       // WINDOWS_CUI
.corflags 0x00000001    //  ILONLY
// Image base: 0x05960000


// =============== CLASS MEMBERS DECLARATION ===================

.class public abstract auto ansi sealed Sample
       extends [mscorlib]System.Object
{
  .custom instance void [FSharp.Core]Microsoft.FSharp.Core.CompilationMappingAttribute::.ctor(valuetype [FSharp.Core]Microsoft.FSharp.Core.SourceConstructFlags) = ( 01 00 07 00 00 00 00 00 ) 
  .class sequential ansi serializable sealed nested public Ticker`1<T>
         extends [mscorlib]System.ValueType
         implements class [mscorlib]System.IEquatable`1<valuetype Sample/Ticker`1<!T>>,
                    [mscorlib]System.Collections.IStructuralEquatable,
                    class [mscorlib]System.IComparable`1<valuetype Sample/Ticker`1<!T>>,
                    [mscorlib]System.IComparable,
                    [mscorlib]System.Collections.IStructuralComparable
  {
    .custom instance void [FSharp.Core]Microsoft.FSharp.Core.StructAttribute::.ctor() = ( 01 00 00 00 ) 
    .custom instance void [FSharp.Core]Microsoft.FSharp.Core.CompilationMappingAttribute::.ctor(valuetype [FSharp.Core]Microsoft.FSharp.Core.SourceConstructFlags) = ( 01 00 03 00 00 00 00 00 ) 
    .field assembly int32 Stage@
    .method public hidebysig specialname 
            instance int32  get_Stage() cil managed
    {
      .custom instance void [mscorlib]System.Runtime.CompilerServices.IsReadOnlyAttribute::.ctor() = ( 01 00 00 00 ) 
      .custom instance void [mscorlib]System.Runtime.CompilerServices.CompilerGeneratedAttribute::.ctor() = ( 01 00 00 00 ) 
      .custom instance void [mscorlib]System.Diagnostics.DebuggerNonUserCodeAttribute::.ctor() = ( 01 00 00 00 ) 
      // Code size       7 (0x7)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  ldfld      int32 valuetype Sample/Ticker`1<!T>::Stage@
      IL_0006:  ret
    } // end of method Ticker`1::get_Stage

    .method public hidebysig virtual final 
            instance int32  CompareTo(valuetype Sample/Ticker`1<!T> obj) cil managed
    {
      .custom instance void [mscorlib]System.Runtime.CompilerServices.CompilerGeneratedAttribute::.ctor() = ( 01 00 00 00 ) 
      // Code size       31 (0x1f)
      .maxstack  5
      .locals init (class [mscorlib]System.Collections.IComparer V_0,
               int32 V_1,
               int32 V_2)
      IL_0000:  call       class [mscorlib]System.Collections.IComparer [FSharp.Core]Microsoft.FSharp.Core.LanguagePrimitives::get_GenericComparer()
      IL_0005:  stloc.0
      IL_0006:  ldarg.0
      IL_0007:  ldfld      int32 valuetype Sample/Ticker`1<!T>::Stage@
      IL_000c:  stloc.1
      IL_000d:  ldarga.s   obj
      IL_000f:  ldfld      int32 valuetype Sample/Ticker`1<!T>::Stage@
      IL_0014:  stloc.2
      IL_0015:  ldloc.1
      IL_0016:  ldloc.2
      IL_0017:  cgt
      IL_0019:  ldloc.1
      IL_001a:  ldloc.2
      IL_001b:  clt
      IL_001d:  sub
      IL_001e:  ret
    } // end of method Ticker`1::CompareTo

    .method public hidebysig virtual final 
            instance int32  CompareTo(object obj) cil managed
    {
      .custom instance void [mscorlib]System.Runtime.CompilerServices.CompilerGeneratedAttribute::.ctor() = ( 01 00 00 00 ) 
      // Code size       13 (0xd)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  ldarg.1
      IL_0002:  unbox.any  valuetype Sample/Ticker`1<!T>
      IL_0007:  call       instance int32 valuetype Sample/Ticker`1<!T>::CompareTo(valuetype Sample/Ticker`1<!0>)
      IL_000c:  ret
    } // end of method Ticker`1::CompareTo

    .method public hidebysig virtual final 
            instance int32  CompareTo(object obj,
                                      class [mscorlib]System.Collections.IComparer comp) cil managed
    {
      .custom instance void [mscorlib]System.Runtime.CompilerServices.CompilerGeneratedAttribute::.ctor() = ( 01 00 00 00 ) 
      // Code size       32 (0x20)
      .maxstack  5
      .locals init (valuetype Sample/Ticker`1<!T> V_0,
               int32 V_1,
               int32 V_2)
      IL_0000:  ldarg.1
      IL_0001:  unbox.any  valuetype Sample/Ticker`1<!T>
      IL_0006:  stloc.0
      IL_0007:  ldarg.0
      IL_0008:  ldfld      int32 valuetype Sample/Ticker`1<!T>::Stage@
      IL_000d:  stloc.1
      IL_000e:  ldloca.s   V_0
      IL_0010:  ldfld      int32 valuetype Sample/Ticker`1<!T>::Stage@
      IL_0015:  stloc.2
      IL_0016:  ldloc.1
      IL_0017:  ldloc.2
      IL_0018:  cgt
      IL_001a:  ldloc.1
      IL_001b:  ldloc.2
      IL_001c:  clt
      IL_001e:  sub
      IL_001f:  ret
    } // end of method Ticker`1::CompareTo

    .method public hidebysig virtual final 
            instance int32  GetHashCode(class [mscorlib]System.Collections.IEqualityComparer comp) cil managed
    {
      .custom instance void [mscorlib]System.Runtime.CompilerServices.CompilerGeneratedAttribute::.ctor() = ( 01 00 00 00 ) 
      // Code size       25 (0x19)
      .maxstack  7
      .locals init (int32 V_0)
      IL_0000:  ldc.i4.0
      IL_0001:  stloc.0
      IL_0002:  ldc.i4     0x9e3779b9
      IL_0007:  ldarg.0
      IL_0008:  ldfld      int32 valuetype Sample/Ticker`1<!T>::Stage@
      IL_000d:  ldloc.0
      IL_000e:  ldc.i4.6
      IL_000f:  shl
      IL_0010:  ldloc.0
      IL_0011:  ldc.i4.2
      IL_0012:  shr
      IL_0013:  add
      IL_0014:  add
      IL_0015:  add
      IL_0016:  stloc.0
      IL_0017:  ldloc.0
      IL_0018:  ret
    } // end of method Ticker`1::GetHashCode

    .method public hidebysig virtual final 
            instance int32  GetHashCode() cil managed
    {
      .custom instance void [mscorlib]System.Runtime.CompilerServices.CompilerGeneratedAttribute::.ctor() = ( 01 00 00 00 ) 
      // Code size       12 (0xc)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  call       class [mscorlib]System.Collections.IEqualityComparer [FSharp.Core]Microsoft.FSharp.Core.LanguagePrimitives::get_GenericEqualityComparer()
      IL_0006:  call       instance int32 valuetype Sample/Ticker`1<!T>::GetHashCode(class [mscorlib]System.Collections.IEqualityComparer)
      IL_000b:  ret
    } // end of method Ticker`1::GetHashCode

    .method public hidebysig instance bool 
            Equals(valuetype Sample/Ticker`1<!T> obj,
                   class [mscorlib]System.Collections.IEqualityComparer comp) cil managed
    {
      .custom instance void [mscorlib]System.Runtime.CompilerServices.CompilerGeneratedAttribute::.ctor() = ( 01 00 00 00 ) 
      // Code size       16 (0x10)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  ldfld      int32 valuetype Sample/Ticker`1<!T>::Stage@
      IL_0006:  ldarga.s   obj
      IL_0008:  ldfld      int32 valuetype Sample/Ticker`1<!T>::Stage@
      IL_000d:  ceq
      IL_000f:  ret
    } // end of method Ticker`1::Equals

    .method public hidebysig virtual final 
            instance bool  Equals(object obj,
                                  class [mscorlib]System.Collections.IEqualityComparer comp) cil managed
    {
      .custom instance void [mscorlib]System.Runtime.CompilerServices.CompilerGeneratedAttribute::.ctor() = ( 01 00 00 00 ) 
      // Code size       33 (0x21)
      .maxstack  4
      .locals init (valuetype Sample/Ticker`1<!T> V_0)
      IL_0000:  ldarg.1
      IL_0001:  isinst     valuetype Sample/Ticker`1<!T>
      IL_0006:  brfalse.s  IL_001f

      IL_0008:  ldarg.1
      IL_0009:  unbox.any  valuetype Sample/Ticker`1<!T>
      IL_000e:  stloc.0
      IL_000f:  ldarg.0
      IL_0010:  ldfld      int32 valuetype Sample/Ticker`1<!T>::Stage@
      IL_0015:  ldloca.s   V_0
      IL_0017:  ldfld      int32 valuetype Sample/Ticker`1<!T>::Stage@
      IL_001c:  ceq
      IL_001e:  ret

      IL_001f:  ldc.i4.0
      IL_0020:  ret
    } // end of method Ticker`1::Equals

    .method private static int32  Advance(int32 v) cil managed
    {
      .custom instance void [FSharp.Core]Microsoft.FSharp.Core.NoCompilerInliningAttribute::.ctor() = ( 01 00 00 00 ) 
      // Code size       4 (0x4)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  ldc.i4.1
      IL_0002:  add
      IL_0003:  ret
    } // end of method Ticker`1::Advance

    .method public hidebysig instance int32 
            Run() cil managed
    {
      // Code size       17 (0x11)
      .maxstack  8
      IL_0000:  ldc.i4     0x3e8
      IL_0005:  ldarg.0
      IL_0006:  ldfld      int32 valuetype Sample/Ticker`1<!T>::Stage@
      IL_000b:  call       int32 class Sample/Ticker`1<!T>::walk@8(int32,
                                                                   int32)
      IL_0010:  ret
    } // end of method Ticker`1::Run

    .method public hidebysig virtual final 
            instance bool  Equals(valuetype Sample/Ticker`1<!T> obj) cil managed
    {
      .custom instance void [mscorlib]System.Runtime.CompilerServices.CompilerGeneratedAttribute::.ctor() = ( 01 00 00 00 ) 
      // Code size       16 (0x10)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  ldfld      int32 valuetype Sample/Ticker`1<!T>::Stage@
      IL_0006:  ldarga.s   obj
      IL_0008:  ldfld      int32 valuetype Sample/Ticker`1<!T>::Stage@
      IL_000d:  ceq
      IL_000f:  ret
    } // end of method Ticker`1::Equals

    .method public hidebysig virtual final 
            instance bool  Equals(object obj) cil managed
    {
      .custom instance void [mscorlib]System.Runtime.CompilerServices.CompilerGeneratedAttribute::.ctor() = ( 01 00 00 00 ) 
      // Code size       35 (0x23)
      .maxstack  4
      .locals init (valuetype Sample/Ticker`1<!T> V_0,
               valuetype Sample/Ticker`1<!T> V_1)
      IL_0000:  ldarg.1
      IL_0001:  isinst     valuetype Sample/Ticker`1<!T>
      IL_0006:  brfalse.s  IL_0021

      IL_0008:  ldarg.1
      IL_0009:  unbox.any  valuetype Sample/Ticker`1<!T>
      IL_000e:  stloc.0
      IL_000f:  ldloc.0
      IL_0010:  stloc.1
      IL_0011:  ldarg.0
      IL_0012:  ldfld      int32 valuetype Sample/Ticker`1<!T>::Stage@
      IL_0017:  ldloca.s   V_1
      IL_0019:  ldfld      int32 valuetype Sample/Ticker`1<!T>::Stage@
      IL_001e:  ceq
      IL_0020:  ret

      IL_0021:  ldc.i4.0
      IL_0022:  ret
    } // end of method Ticker`1::Equals

    .method assembly static int32  walk@8(int32 n,
                                          int32 acc) cil managed
    {
      // Code size       21 (0x15)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  ldc.i4.0
      IL_0002:  bgt.s      IL_0006

      IL_0004:  ldarg.1
      IL_0005:  ret

      IL_0006:  ldarg.0
      IL_0007:  ldc.i4.1
      IL_0008:  sub
      IL_0009:  ldarg.1
      IL_000a:  call       int32 valuetype Sample/Ticker`1<!T>::Advance(int32)
      IL_000f:  starg.s    acc
      IL_0011:  starg.s    n
      IL_0013:  br.s       IL_0000
    } // end of method Ticker`1::walk@8

    .property instance int32 Stage()
    {
      .custom instance void [FSharp.Core]Microsoft.FSharp.Core.CompilationMappingAttribute::.ctor(valuetype [FSharp.Core]Microsoft.FSharp.Core.SourceConstructFlags,
                                                                                                  int32) = ( 01 00 04 00 00 00 00 00 00 00 00 00 ) 
      .get instance int32 Sample/Ticker`1::get_Stage()
    } // end of property Ticker`1::Stage
  } // end of class Ticker`1

  .method public static int32  main(string[] _arg1) cil managed
  {
    .entrypoint
    .custom instance void [FSharp.Core]Microsoft.FSharp.Core.EntryPointAttribute::.ctor() = ( 01 00 00 00 ) 
    // Code size       18 (0x12)
    .maxstack  4
    .locals init (valuetype Sample/Ticker`1<int32> V_0)
    IL_0000:  ldloca.s   V_0
    IL_0002:  call       instance int32 valuetype Sample/Ticker`1<int32>::Run()
    IL_0007:  ldc.i4     0x3e8
    IL_000c:  bne.un.s   IL_0010

    IL_000e:  ldc.i4.0
    IL_000f:  ret

    IL_0010:  ldc.i4.1
    IL_0011:  ret
  } // end of method Sample::main

} // end of class Sample

.class private abstract auto ansi sealed '<StartupCode$RealsigPlusOptimisePlus>'.$Sample
       extends [mscorlib]System.Object
{
} // end of class '<StartupCode$RealsigPlusOptimisePlus>'.$Sample


// =============================================================

// *********** DISASSEMBLY COMPLETE ***********************
// WARNING: Created Win32 resource file artifacts\Temp\RealsigPlusOptimisePlus.res

if we use mdv.exe to read the metadata tables it produces this output:
C:\Users\kevinr\.dotnet\tools\mdv.exe artifacts\Temp\RealsigPlusOptimisePlus.exe

MetadataVersion: v4.0.30319

Module (0x00):
=============================================================================================================
   Gen  Name                                Mvid                                         EncId  EncBaseId  
=============================================================================================================
1: 0    'RealsigPlusOptimisePlus.exe' (#1)  {6ad467e9-d07f-21e7-a745-0383e967d46a} (#1)  nil    nil        

TypeRef (0x01):
====================================================================================================================================
    Scope                     Name                                          Namespace                                                
====================================================================================================================================
 1: 0x23000001 (AssemblyRef)  'Object' (#10d)                               'System' (#106)                                          
 2: 0x23000001 (AssemblyRef)  'ValueType' (#12d)                            'System' (#106)                                          
 3: 0x23000001 (AssemblyRef)  'IEquatable`1' (#137)                         'System' (#106)                                          
 4: 0x23000001 (AssemblyRef)  'IStructuralEquatable' (#157)                 'System.Collections' (#144)                              
 5: 0x23000001 (AssemblyRef)  'IComparable`1' (#16c)                        'System' (#106)                                          
 6: 0x23000001 (AssemblyRef)  'IComparable' (#17a)                          'System' (#106)                                          
 7: 0x23000001 (AssemblyRef)  'IStructuralComparable' (#186)                'System.Collections' (#144)                              
 8: 0x23000002 (AssemblyRef)  'FSharpInterfaceDataVersionAttribute' (#1f8)  'Microsoft.FSharp.Core' (#1e2)                           
 9: 0x23000002 (AssemblyRef)  'LanguagePrimitives' (#241)                   'Microsoft.FSharp.Core' (#1e2)                           
 a: 0x01000009 (TypeRef)      'IntrinsicOperators' (#22e)                   nil                                                      
 b: 0x23000002 (AssemblyRef)  'LowPriority' (#283)                          'Microsoft.FSharp.Control.TaskBuilderExtensions' (#254)  
 c: 0x23000002 (AssemblyRef)  'LowPlusPriority' (#28f)                      'Microsoft.FSharp.Control.TaskBuilderExtensions' (#254)  
 d: 0x23000002 (AssemblyRef)  'MediumPriority' (#29f)                       'Microsoft.FSharp.Control.TaskBuilderExtensions' (#254)  
 e: 0x23000002 (AssemblyRef)  'HighPriority' (#2ae)                         'Microsoft.FSharp.Control.TaskBuilderExtensions' (#254)  
 f: 0x23000002 (AssemblyRef)  'LowPriority' (#283)                          'Microsoft.FSharp.Linq.QueryRunExtensions' (#2bb)        
10: 0x23000002 (AssemblyRef)  'HighPriority' (#2ae)                         'Microsoft.FSharp.Linq.QueryRunExtensions' (#2bb)        
11: 0x23000002 (AssemblyRef)  'EntryPointAttribute' (#2f3)                  'Microsoft.FSharp.Core' (#1e2)                           
12: 0x23000002 (AssemblyRef)  'CompilationMappingAttribute' (#307)          'Microsoft.FSharp.Core' (#1e2)                           
13: 0x23000002 (AssemblyRef)  'SourceConstructFlags' (#323)                 'Microsoft.FSharp.Core' (#1e2)                           
14: 0x23000001 (AssemblyRef)  'IsReadOnlyAttribute' (#36f)                  'System.Runtime.CompilerServices' (#34f)                 
15: 0x23000001 (AssemblyRef)  'CompilerGeneratedAttribute' (#383)           'System.Runtime.CompilerServices' (#34f)                 
16: 0x23000001 (AssemblyRef)  'DebuggerNonUserCodeAttribute' (#3b1)         'System.Diagnostics' (#39e)                              
17: 0x23000001 (AssemblyRef)  'IComparer' (#3e2)                            'System.Collections' (#144)                              
18: 0x23000001 (AssemblyRef)  'IEqualityComparer' (#40b)                    'System.Collections' (#144)                              
19: 0x23000002 (AssemblyRef)  'NoCompilerInliningAttribute' (#44a)          'Microsoft.FSharp.Core' (#1e2)                           
1a: 0x23000002 (AssemblyRef)  'StructAttribute' (#473)                      'Microsoft.FSharp.Core' (#1e2)                           

TypeDef (0x02):
==============================================================================================================================================================================================================================================================================================================================
   Name               Namespace                                       EnclosingType         BaseType              Interfaces                                                  Fields                 Methods                Attributes                                                         ClassSize  PackingSize  
==============================================================================================================================================================================================================================================================================================================================
1: '<Module>' (#fd)   nil                                             nil (TypeDef)         0x01000001 (TypeRef)  nil                                                         nil                    nil                    0                                                                  n/a        n/a          
2: 'Sample' (#11d)    nil                                             nil (TypeDef)         0x01000001 (TypeRef)  nil                                                         nil                    0x06000001-0x06000001  0x00000181 (Public, Abstract, Sealed)                              n/a        n/a          
3: 'Ticker`1' (#124)  nil                                             0x02000002 (TypeDef)  0x01000002 (TypeRef)  0x1b000001, 0x01000004, 0x1b000002, 0x01000006, 0x01000007  0x04000001-0x04000001  0x06000002-0x0600000e  0x0000210a (NestedPublic, SequentialLayout, Sealed, Serializable)  n/a        n/a          
4: '$Sample' (#1c2)   '<StartupCode$RealsigPlusOptimisePlus>' (#19c)  nil (TypeDef)         0x01000001 (TypeRef)  nil                                                         nil                    nil                    0x00000180 (Abstract, Sealed)                                      n/a        n/a          

Field (0x04):
=====================================================================================
   Name             Signature    Attributes             Marshalling  Offset  RVA  
=====================================================================================
1: 'Stage@' (#33e)  int32 (#89)  0x00000003 (Assembly)  nil          n/a     0    

Method (0x06, 0x1C):
=============================================================================================================================================================================================================================================================================
   Name                  Signature                                                               RVA         Parameters             GenericParameters  Attributes                                      ImplAttributes  ImportAttributes  ImportName  ImportModule     
=============================================================================================================================================================================================================================================================================
1: 'main' (#2e8)         int32 (string[]) (#53)                                                  0x00002050  0x08000001-0x08000001  nil                0x00000016 (Public, Static)                     0               0                 nil         nil (ModuleRef)  
2: 'get_Stage' (#345)    int32 () (#47)                                                          0x00002070  nil                    nil                0x00000886 (Public, HideBySig, SpecialName)     0               0                 nil         nil (ModuleRef)  
3: 'CompareTo' (#3ec)    int32 (Sample.Ticker`1<!0>) (#9f)                                       0x00002078  0x08000002-0x08000002  nil                0x000000e6 (Public, Final, Virtual, HideBySig)  0               0                 nil         nil (ModuleRef)  
4: 'CompareTo' (#3ec)    int32 (object) (#a9)                                                    0x000020A4  0x08000003-0x08000003  nil                0x000000e6 (Public, Final, Virtual, HideBySig)  0               0                 nil         nil (ModuleRef)  
5: 'CompareTo' (#3ec)    int32 (object, System.Collections.IComparer) (#b9)                      0x000020B4  0x08000004-0x08000005  nil                0x000000e6 (Public, Final, Virtual, HideBySig)  0               0                 nil         nil (ModuleRef)  
6: 'GetHashCode' (#3ff)  int32 (System.Collections.IEqualityComparer) (#c4)                      0x000020E0  0x08000006-0x08000006  nil                0x000000e6 (Public, Final, Virtual, HideBySig)  0               0                 nil         nil (ModuleRef)  
7: 'GetHashCode' (#3ff)  int32 () (#47)                                                          0x00002108  nil                    nil                0x000000e6 (Public, Final, Virtual, HideBySig)  0               0                 nil         nil (ModuleRef)  
8: 'Equals' (#439)       bool (Sample.Ticker`1<!0>, System.Collections.IEqualityComparer) (#cf)  0x00002118  0x08000007-0x08000008  nil                0x00000086 (Public, HideBySig)                  0               0                 nil         nil (ModuleRef)  
9: 'Equals' (#439)       bool (object, System.Collections.IEqualityComparer) (#e4)               0x0000212C  0x08000009-0x0800000a  nil                0x000000e6 (Public, Final, Virtual, HideBySig)  0               0                 nil         nil (ModuleRef)  
a: 'Advance' (#440)      int32 (int32) (#eb)                                                     0x0000215C  0x0800000b-0x0800000b  nil                0x00000011 (Private, Static)                    0               0                 nil         nil (ModuleRef)  
b: 'Run' (#2e4)          int32 () (#47)                                                          0x00002164  nil                    nil                0x00000086 (Public, HideBySig)                  0               0                 nil         nil (ModuleRef)  
c: 'Equals' (#439)       bool (Sample.Ticker`1<!0>) (#fd)                                        0x00002178  0x0800000c-0x0800000c  nil                0x000000e6 (Public, Final, Virtual, HideBySig)  0               0                 nil         nil (ModuleRef)  
d: 'Equals' (#439)       bool (object) (#116)                                                    0x0000218C  0x0800000d-0x0800000d  nil                0x000000e6 (Public, Final, Virtual, HideBySig)  0               0                 nil         nil (ModuleRef)  
e: 'walk@8' (#466)       int32 (int32, int32) (#f7)                                              0x000021BC  0x0800000e-0x0800000f  nil                0x00000013 (Assembly, Static)                   0               0                 nil         nil (ModuleRef)  

Param (0x08):
===================================================
   Name            Seq#  Attributes  Marshalling  
===================================================
1: '_arg1' (#2ed)  1     0           nil          
2: 'obj' (#3f6)    1     0           nil          
3: 'obj' (#3f6)    1     0           nil          
4: 'obj' (#3f6)    1     0           nil          
5: 'comp' (#3fa)   2     0           nil          
6: 'comp' (#3fa)   1     0           nil          
7: 'obj' (#3f6)    1     0           nil          
8: 'comp' (#3fa)   2     0           nil          
9: 'obj' (#3f6)    1     0           nil          
a: 'comp' (#3fa)   2     0           nil          
b: 'v' (#448)      1     0           nil          
c: 'obj' (#3f6)    1     0           nil          
d: 'obj' (#3f6)    1     0           nil          
e: 'n' (#46d)      1     0           nil          
f: 'acc' (#46f)    2     0           nil          

MemberRef (0x0a):
================================================================================================================================
    Parent                 Name                                  Signature                                                       
================================================================================================================================
 1: 0x01000008 (TypeRef)   '.ctor' (#228)                        void (int32, int32, int32) (#29)                                
 2: 0x1b000003 (TypeSpec)  'Run' (#2e4)                          int32 () (#47)                                                  
 3: 0x01000011 (TypeRef)   '.ctor' (#228)                        void () (#59)                                                   
 4: 0x01000012 (TypeRef)   '.ctor' (#228)                        void (Microsoft.FSharp.Core.SourceConstructFlags) (#62)         
 5: 0x01000012 (TypeRef)   '.ctor' (#228)                        void (Microsoft.FSharp.Core.SourceConstructFlags, int32) (#75)  
 6: 0x1b000004 (TypeSpec)  'Stage@' (#33e)                       int32 (#89)                                                     
 7: 0x01000014 (TypeRef)   '.ctor' (#228)                        void () (#59)                                                   
 8: 0x01000015 (TypeRef)   '.ctor' (#228)                        void () (#59)                                                   
 9: 0x01000016 (TypeRef)   '.ctor' (#228)                        void () (#59)                                                   
 a: 0x01000009 (TypeRef)   'get_GenericComparer' (#3ce)          System.Collections.IComparer () (#93)                           
 b: 0x1b000004 (TypeSpec)  'CompareTo' (#3ec)                    int32 (Sample.Ticker`1<!0>) (#9f)                               
 c: 0x01000009 (TypeRef)   'get_GenericEqualityComparer' (#41d)  System.Collections.IEqualityComparer () (#ca)                   
 d: 0x1b000004 (TypeSpec)  'GetHashCode' (#3ff)                  int32 (System.Collections.IEqualityComparer) (#c4)              
 e: 0x01000019 (TypeRef)   '.ctor' (#228)                        void () (#59)                                                   
 f: 0x1b000005 (TypeSpec)  'walk@8' (#466)                       int32 (int32, int32) (#f7)                                      
10: 0x1b000004 (TypeSpec)  'Advance' (#440)                      int32 (int32) (#eb)                                             
11: 0x0100001a (TypeRef)   '.ctor' (#228)                        void () (#59)                                                   

CustomAttribute (0x0c):
==========================================================================================================
    Parent                  Constructor             Value                                                  
==========================================================================================================
 1: 0x06000001 (MethodDef)  0x0a000003 (MemberRef)  01-00-00-00 (#5d)                                      
 2: 0x17000001 (Property)   0x0a000005 (MemberRef)  01-00-04-00-00-00-00-00-00-00-00-00 (#7c)              
 3: 0x20000001 (Assembly)   0x0a000001 (MemberRef)  01-00-02-00-00-00-00-00-00-00-00-00-00-00-00-00 (#30)  
 4: 0x06000002 (MethodDef)  0x0a000007 (MemberRef)  01-00-00-00 (#5d)                                      
 5: 0x06000002 (MethodDef)  0x0a000008 (MemberRef)  01-00-00-00 (#5d)                                      
 6: 0x06000002 (MethodDef)  0x0a000009 (MemberRef)  01-00-00-00 (#5d)                                      
 7: 0x02000002 (TypeDef)    0x0a000004 (MemberRef)  01-00-07-00-00-00-00-00 (#68)                          
 8: 0x06000003 (MethodDef)  0x0a000008 (MemberRef)  01-00-00-00 (#5d)                                      
 9: 0x02000003 (TypeDef)    0x0a000011 (MemberRef)  01-00-00-00 (#5d)                                      
 a: 0x02000003 (TypeDef)    0x0a000004 (MemberRef)  01-00-03-00-00-00-00-00 (#11b)                         
 b: 0x06000004 (MethodDef)  0x0a000008 (MemberRef)  01-00-00-00 (#5d)                                      
 c: 0x06000005 (MethodDef)  0x0a000008 (MemberRef)  01-00-00-00 (#5d)                                      
 d: 0x06000006 (MethodDef)  0x0a000008 (MemberRef)  01-00-00-00 (#5d)                                      
 e: 0x06000007 (MethodDef)  0x0a000008 (MemberRef)  01-00-00-00 (#5d)                                      
 f: 0x06000008 (MethodDef)  0x0a000008 (MemberRef)  01-00-00-00 (#5d)                                      
10: 0x06000009 (MethodDef)  0x0a000008 (MemberRef)  01-00-00-00 (#5d)                                      
11: 0x0600000a (MethodDef)  0x0a00000e (MemberRef)  01-00-00-00 (#5d)                                      
12: 0x0600000c (MethodDef)  0x0a000008 (MemberRef)  01-00-00-00 (#5d)                                      
13: 0x0600000d (MethodDef)  0x0a000008 (MemberRef)  01-00-00-00 (#5d)                                      

StandAloneSig (0x11):
===================================================
   Signature                                         
===================================================
1: Sample.Ticker`1<int32> (#4b)                      
2: System.Collections.IComparer, int32, int32 (#98)  
3: Sample.Ticker`1<!0>, int32, int32 (#ae)           
4: int32 (#c0)                                       
5: Sample.Ticker`1<!0> (#db)                         
6: Sample.Ticker`1<!0>, Sample.Ticker`1<!0> (#107)   

Property (0x15, 0x17, 0x18):
=========================================================================
   Name            Get                     Set              Attributes  
=========================================================================
1: 'Stage' (#338)  0x06000002 (MethodDef)  nil (MethodDef)  0           

TypeSpec (0x1b):
==================================================
   Name                                             
==================================================
1: System.IEquatable`1<Sample.Ticker`1<!0>> (#a)    
2: System.IComparable`1<Sample.Ticker`1<!0>> (#15)  
3: Sample.Ticker`1<int32> (#41)                     
4: Sample.Ticker`1<!0> (#8c)                        
5: Sample.Ticker`1<!0> (#f0)                        

Assembly (0x20):
===============================================================================================
   Name                              Version  Culture  PublicKey  Flags  HashAlgorithm      
===============================================================================================
1: 'RealsigPlusOptimisePlus' (#1ca)  0.0.0.0  nil      nil        0      0x00008004 (Sha1)  

AssemblyRef (0x23):
====================================================================================
   Name                  Version   Culture  PublicKeyOrToken               Flags  
====================================================================================
1: 'mscorlib' (#114)     4.0.0.0   nil      B7-7A-5C-56-19-34-E0-89 (#1)   0      
2: 'FSharp.Core' (#21c)  11.0.0.0  nil      B0-3F-5F-7F-11-D5-0A-3A (#20)  0      

ManifestResource (0x28):
===========================================================================================================
   Name                                                               Attributes  Offset  Implementation  
===========================================================================================================
1: 'FSharpSignatureCompressedData.RealsigPlusOptimisePlus' (#1d)      Public      0       nil (File)      
2: 'FSharpSignatureCompressedDataB.RealsigPlusOptimisePlus' (#53)     Public      1024    nil (File)      
3: 'FSharpOptimizationCompressedData.RealsigPlusOptimisePlus' (#8a)   Public      1104    nil (File)      
4: 'FSharpOptimizationCompressedDataB.RealsigPlusOptimisePlus' (#c3)  Public      1992    nil (File)      

GenericParam (0x2a):
==========================================================================
   Name        Seq#  Attributes  Parent                TypeConstraints  
==========================================================================
1: 'T' (#483)  0     0           0x02000003 (TypeDef)  nil              

#US (size = 4):
  0: ''
  1: ''
  2: ''
  3: ''

#String (size = 1157):
  0: ''
  1: 'RealsigPlusOptimisePlus.exe' (ModuleName)
  1d: 'FSharpSignatureCompressedData.RealsigPlusOptimisePlus' (ResourceName)
  53: 'FSharpSignatureCompressedDataB.RealsigPlusOptimisePlus' (ResourceName)
  8a: 'FSharpOptimizationCompressedData.RealsigPlusOptimisePlus' (ResourceName)
  c3: 'FSharpOptimizationCompressedDataB.RealsigPlusOptimisePlus' (ResourceName)
  fd: '<Module>' (TypeName)
  106: 'System' (NamespaceName)
  10d: 'Object' (TypeName)
  114: 'mscorlib' (AssemblyName)
  11d: 'Sample' (TypeName)
  124: 'Ticker`1' (TypeName)
  12d: 'ValueType' (TypeName)
  137: 'IEquatable`1' (TypeName)
  144: 'System.Collections' (NamespaceName)
  157: 'IStructuralEquatable' (TypeName)
  16c: 'IComparable`1' (TypeName)
  17a: 'IComparable' (TypeName)
  186: 'IStructuralComparable' (TypeName)
  19c: '<StartupCode$RealsigPlusOptimisePlus>' (NamespaceName)
  1c2: '$Sample' (TypeName)
  1ca: 'RealsigPlusOptimisePlus' (AssemblyName)
  1e2: 'Microsoft.FSharp.Core' (NamespaceName)
  1f8: 'FSharpInterfaceDataVersionAttribute' (TypeName)
  21c: 'FSharp.Core' (AssemblyName)
  228: '.ctor' (MemberName)
  22e: 'IntrinsicOperators' (TypeName)
  241: 'LanguagePrimitives' (TypeName)
  254: 'Microsoft.FSharp.Control.TaskBuilderExtensions' (NamespaceName)
  283: 'LowPriority' (TypeName)
  28f: 'LowPlusPriority' (TypeName)
  29f: 'MediumPriority' (TypeName)
  2ae: 'HighPriority' (TypeName)
  2bb: 'Microsoft.FSharp.Linq.QueryRunExtensions' (NamespaceName)
  2e4: 'Run' (MethodName, MemberName)
  2e8: 'main' (MethodName)
  2ed: '_arg1' (ParamName)
  2f3: 'EntryPointAttribute' (TypeName)
  307: 'CompilationMappingAttribute' (TypeName)
  323: 'SourceConstructFlags' (TypeName)
  338: 'Stage' (PropertyName)
  33e: 'Stage@' (FieldName, MemberName)
  345: 'get_Stage' (MethodName)
  34f: 'System.Runtime.CompilerServices' (NamespaceName)
  36f: 'IsReadOnlyAttribute' (TypeName)
  383: 'CompilerGeneratedAttribute' (TypeName)
  39e: 'System.Diagnostics' (NamespaceName)
  3b1: 'DebuggerNonUserCodeAttribute' (TypeName)
  3ce: 'get_GenericComparer' (MemberName)
  3e2: 'IComparer' (TypeName)
  3ec: 'CompareTo' (MethodName, MemberName)
  3f6: 'obj' (ParamName)
  3fa: 'comp' (ParamName)
  3ff: 'GetHashCode' (MethodName, MemberName)
  40b: 'IEqualityComparer' (TypeName)
  41d: 'get_GenericEqualityComparer' (MemberName)
  439: 'Equals' (MethodName)
  440: 'Advance' (MethodName, MemberName)
  448: 'v' (ParamName)
  44a: 'NoCompilerInliningAttribute' (TypeName)
  466: 'walk@8' (MethodName, MemberName)
  46d: 'n' (ParamName)
  46f: 'acc' (ParamName)
  473: 'StructAttribute' (TypeName)
  483: 'T' (GenericParamName)

#Blob (size = 292):
  0: <empty>
  1: B7-7A-5C-56-19-34-E0-89 (Key)
  a: 15-12-0D-01-15-11-0C-01-13-00 (TypeSpec)
  15: 15-12-15-01-15-11-0C-01-13-00 (TypeSpec)
  20: B0-3F-5F-7F-11-D5-0A-3A (Key)
  29: 20-03-01-08-08-08 (MemberRefSignature)
  30: 01-00-02-00-00-00-00-00-00-00-00-00-00-00-00-00 (CustomAttribute)
  41: 15-11-0C-01-08 (TypeSpec)
  47: 20-00-08 (MethodSignature, MemberRefSignature)
  4b: 07-01-15-11-0C-01-08 (StandAloneSignature)
  53: 00-01-08-1D-0E (MethodSignature)
  59: 20-00-01 (MemberRefSignature)
  5d: 01-00-00-00 (CustomAttribute)
  62: 20-01-01-11-4D (MemberRefSignature)
  68: 01-00-07-00-00-00-00-00 (CustomAttribute)
  71: 28-00-08
  75: 20-02-01-11-4D-08 (MemberRefSignature)
  7c: 01-00-04-00-00-00-00-00-00-00-00-00 (CustomAttribute)
  89: 06-08 (FieldSignature, MemberRefSignature)
  8c: 15-11-0C-01-13-00 (TypeSpec)
  93: 00-00-12-5D (MemberRefSignature)
  98: 07-03-12-5D-08-08 (StandAloneSignature)
  9f: 20-01-08-15-11-0C-01-13-00 (MethodSignature, MemberRefSignature)
  a9: 20-01-08-1C (MethodSignature)
  ae: 07-03-15-11-0C-01-13-00-08-08 (StandAloneSignature)
  b9: 20-02-08-1C-12-5D (MethodSignature)
  c0: 07-01-08 (StandAloneSignature)
  c4: 20-01-08-12-61 (MethodSignature, MemberRefSignature)
  ca: 00-00-12-61 (MemberRefSignature)
  cf: 20-02-02-15-11-0C-01-13-00-12-61 (MethodSignature)
  db: 07-01-15-11-0C-01-13-00 (StandAloneSignature)
  e4: 20-02-02-1C-12-61 (MethodSignature)
  eb: 00-01-08-08 (MethodSignature, MemberRefSignature)
  f0: 15-12-0C-01-13-00 (TypeSpec)
  f7: 00-02-08-08-08 (MethodSignature, MemberRefSignature)
  fd: 20-01-02-15-11-0C-01-13-00 (MethodSignature)
  107: 07-02-15-11-0C-01-13-00-15-11-0C-01-13-00 (StandAloneSignature)
  116: 20-01-02-1C (MethodSignature)
  11b: 01-00-03-00-00-00-00-00 (CustomAttribute)
#Guid (size = 16):
  1: {6ad467e9-d07f-21e7-a745-0383e967d46a}


CustomAttribute sizes by constructor:
  Microsoft.FSharp.Core.FSharpInterfaceDataVersionAttribute: 16 bytes
  Microsoft.FSharp.Core.CompilationMappingAttribute: 16 bytes
  Microsoft.FSharp.Core.CompilationMappingAttribute: 12 bytes
  Microsoft.FSharp.Core.EntryPointAttribute: 4 bytes

Method 'Sample.main' (0x06000001)
  Locals: Sample.Ticker`1<int32> (#4b)
{
  // Code size       18 (0x12)
  .maxstack  4
  IL_0000:  ldloca.s   V_0
  IL_0002:  call       'Sample.Ticker`1<int32>.Run' (0x0a000002)
  IL_0007:  ldc.i4     0x3e8
  IL_000c:  bne.un.s   IL_0010
  IL_000e:  ldc.i4.0
  IL_000f:  ret
  IL_0010:  ldc.i4.1
  IL_0011:  ret
}

Method 'Sample.Ticker`1.get_Stage' (0x06000002)
{
  // Code size        7 (0x7)
  .maxstack  8
  IL_0000:  ldarg.0
  IL_0001:  ldfld      'Sample.Ticker`1<!0>.Stage@' (0x0a000006)
  IL_0006:  ret
}

Method 'Sample.Ticker`1.CompareTo' (0x06000003)
  Locals: System.Collections.IComparer, int32, int32 (#98)
{
  // Code size       31 (0x1f)
  .maxstack  5
  IL_0000:  call       'Microsoft.FSharp.Core.LanguagePrimitives.get_GenericComparer' (0x0a00000a)
  IL_0005:  stloc.0
  IL_0006:  ldarg.0
  IL_0007:  ldfld      'Sample.Ticker`1<!0>.Stage@' (0x0a000006)
  IL_000c:  stloc.1
  IL_000d:  ldarga.s   V_1
  IL_000f:  ldfld      'Sample.Ticker`1<!0>.Stage@' (0x0a000006)
  IL_0014:  stloc.2
  IL_0015:  ldloc.1
  IL_0016:  ldloc.2
  IL_0017:  cgt
  IL_0019:  ldloc.1
  IL_001a:  ldloc.2
  IL_001b:  clt
  IL_001d:  sub
  IL_001e:  ret
}

Method 'Sample.Ticker`1.CompareTo' (0x06000004)
{
  // Code size       13 (0xd)
  .maxstack  8
  IL_0000:  ldarg.0
  IL_0001:  ldarg.1
  IL_0002:  unbox.any  'Sample.Ticker`1<!0>' (0x1b000004)
  IL_0007:  call       'Sample.Ticker`1<!0>.CompareTo' (0x0a00000b)
  IL_000c:  ret
}

Method 'Sample.Ticker`1.CompareTo' (0x06000005)
  Locals: Sample.Ticker`1<!0>, int32, int32 (#ae)
{
  // Code size       32 (0x20)
  .maxstack  5
  IL_0000:  ldarg.1
  IL_0001:  unbox.any  'Sample.Ticker`1<!0>' (0x1b000004)
  IL_0006:  stloc.0
  IL_0007:  ldarg.0
  IL_0008:  ldfld      'Sample.Ticker`1<!0>.Stage@' (0x0a000006)
  IL_000d:  stloc.1
  IL_000e:  ldloca.s   V_0
  IL_0010:  ldfld      'Sample.Ticker`1<!0>.Stage@' (0x0a000006)
  IL_0015:  stloc.2
  IL_0016:  ldloc.1
  IL_0017:  ldloc.2
  IL_0018:  cgt
  IL_001a:  ldloc.1
  IL_001b:  ldloc.2
  IL_001c:  clt
  IL_001e:  sub
  IL_001f:  ret
}

Method 'Sample.Ticker`1.GetHashCode' (0x06000006)
  Locals: int32 (#c0)
{
  // Code size       25 (0x19)
  .maxstack  7
  IL_0000:  ldc.i4.0
  IL_0001:  stloc.0
  IL_0002:  ldc.i4     0x9e3779b9
  IL_0007:  ldarg.0
  IL_0008:  ldfld      'Sample.Ticker`1<!0>.Stage@' (0x0a000006)
  IL_000d:  ldloc.0
  IL_000e:  ldc.i4.6
  IL_000f:  shl
  IL_0010:  ldloc.0
  IL_0011:  ldc.i4.2
  IL_0012:  shr
  IL_0013:  add
  IL_0014:  add
  IL_0015:  add
  IL_0016:  stloc.0
  IL_0017:  ldloc.0
  IL_0018:  ret
}

Method 'Sample.Ticker`1.GetHashCode' (0x06000007)
{
  // Code size       12 (0xc)
  .maxstack  8
  IL_0000:  ldarg.0
  IL_0001:  call       'Microsoft.FSharp.Core.LanguagePrimitives.get_GenericEqualityComparer' (0x0a00000c)
  IL_0006:  call       'Sample.Ticker`1<!0>.GetHashCode' (0x0a00000d)
  IL_000b:  ret
}

Method 'Sample.Ticker`1.Equals' (0x06000008)
{
  // Code size       16 (0x10)
  .maxstack  8
  IL_0000:  ldarg.0
  IL_0001:  ldfld      'Sample.Ticker`1<!0>.Stage@' (0x0a000006)
  IL_0006:  ldarga.s   V_1
  IL_0008:  ldfld      'Sample.Ticker`1<!0>.Stage@' (0x0a000006)
  IL_000d:  ceq
  IL_000f:  ret
}

Method 'Sample.Ticker`1.Equals' (0x06000009)
  Locals: Sample.Ticker`1<!0> (#db)
{
  // Code size       33 (0x21)
  .maxstack  4
  IL_0000:  ldarg.1
  IL_0001:  isinst     'Sample.Ticker`1<!0>' (0x1b000004)
  IL_0006:  brfalse.s  IL_001f
  IL_0008:  ldarg.1
  IL_0009:  unbox.any  'Sample.Ticker`1<!0>' (0x1b000004)
  IL_000e:  stloc.0
  IL_000f:  ldarg.0
  IL_0010:  ldfld      'Sample.Ticker`1<!0>.Stage@' (0x0a000006)
  IL_0015:  ldloca.s   V_0
  IL_0017:  ldfld      'Sample.Ticker`1<!0>.Stage@' (0x0a000006)
  IL_001c:  ceq
  IL_001e:  ret
  IL_001f:  ldc.i4.0
  IL_0020:  ret
}

Method 'Sample.Ticker`1.Advance' (0x0600000a)
{
  // Code size        4 (0x4)
  .maxstack  8
  IL_0000:  ldarg.0
  IL_0001:  ldc.i4.1
  IL_0002:  add
  IL_0003:  ret
}

Method 'Sample.Ticker`1.Run' (0x0600000b)
{
  // Code size       17 (0x11)
  .maxstack  8
  IL_0000:  ldc.i4     0x3e8
  IL_0005:  ldarg.0
  IL_0006:  ldfld      'Sample.Ticker`1<!0>.Stage@' (0x0a000006)
  IL_000b:  call       'Sample.Ticker`1<!0>.walk@8' (0x0a00000f)
  IL_0010:  ret
}

Method 'Sample.Ticker`1.Equals' (0x0600000c)
{
  // Code size       16 (0x10)
  .maxstack  8
  IL_0000:  ldarg.0
  IL_0001:  ldfld      'Sample.Ticker`1<!0>.Stage@' (0x0a000006)
  IL_0006:  ldarga.s   V_1
  IL_0008:  ldfld      'Sample.Ticker`1<!0>.Stage@' (0x0a000006)
  IL_000d:  ceq
  IL_000f:  ret
}

Method 'Sample.Ticker`1.Equals' (0x0600000d)
  Locals: Sample.Ticker`1<!0>, Sample.Ticker`1<!0> (#107)
{
  // Code size       35 (0x23)
  .maxstack  4
  IL_0000:  ldarg.1
  IL_0001:  isinst     'Sample.Ticker`1<!0>' (0x1b000004)
  IL_0006:  brfalse.s  IL_0021
  IL_0008:  ldarg.1
  IL_0009:  unbox.any  'Sample.Ticker`1<!0>' (0x1b000004)
  IL_000e:  stloc.0
  IL_000f:  ldloc.0
  IL_0010:  stloc.1
  IL_0011:  ldarg.0
  IL_0012:  ldfld      'Sample.Ticker`1<!0>.Stage@' (0x0a000006)
  IL_0017:  ldloca.s   V_1
  IL_0019:  ldfld      'Sample.Ticker`1<!0>.Stage@' (0x0a000006)
  IL_001e:  ceq
  IL_0020:  ret
  IL_0021:  ldc.i4.0
  IL_0022:  ret
}

Method 'Sample.Ticker`1.walk@8' (0x0600000e)
{
  // Code size       21 (0x15)
  .maxstack  8
  IL_0000:  ldarg.0
  IL_0001:  ldc.i4.0
  IL_0002:  bgt.s      IL_0006
  IL_0004:  ldarg.1
  IL_0005:  ret
  IL_0006:  ldarg.0
  IL_0007:  ldc.i4.1
  IL_0008:  sub
  IL_0009:  ldarg.1
  IL_000a:  call       'Sample.Ticker`1<!0>.Advance' (0x0a000010)
  IL_000f:  starg.s    V_1
  IL_0011:  starg.s    V_0
  IL_0013:  br.s       IL_0000
}


This table is suspicious to me
TypeSpec (0x1b):
==================================================
   Name                                             
==================================================
1: System.IEquatable`1<Sample.Ticker`1<!0>> (#a)    
2: System.IComparable`1<Sample.Ticker`1<!0>> (#15)  
3: Sample.Ticker`1<int32> (#41)                     
4: Sample.Ticker`1<!0> (#8c)                        
5: Sample.Ticker`1<!0> (#f0)                        

Lines 4 and 5 seem incorrect.


Please investigate how in the code I may get the runtime error reported earlier, perhaps using instrumentation

Describe why, and where in the code it occurs, and what might cause it.

SECTION D - REQUIRED ANALYSIS (BOUNDED)



SECTION E - OUTPUT FORMAT (STRICT)

Your output must contain exactly two sections:

OUTPUT SECTION 1 - Analysis
A detailed, mechanism-first explanation of the changes requested.

OUTPUT SECTION 2 - Updated Code
Provide complete, copy-pastable F# logging code blocks for the changes for each
modified file. Only include the code that must be added. Do not rewrite the
entire file.


