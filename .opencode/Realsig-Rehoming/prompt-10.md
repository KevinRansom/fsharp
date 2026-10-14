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
binding, make your let binding an and binding also.

Repro:
Compilation:
artifacts\bin\fsc\Release\net472\fsc.exe --nologo tests\FSharp.Compiler.ComponentTests\EmittedIL\RealInternalSignature\nested_generic_closure.fs --realsig+ --optimize+ --out:artifacts\Temp\RealsigPlusOptimisePlus.exe
artifacts\bin\fsc\Release\net472\fsc.exe --nologo tests\FSharp.Compiler.ComponentTests\EmittedIL\RealInternalSignature\nested_generic_closure.fs --realsig- --optimize+ --out:artifacts\Temp\RealsigMinusOptimisePlus.exe

SECTION B - BUG STATEMENT (SINGLE INVARIANT)

When nested_generic_closure.fs is compiled with the --realsig+ setting, It generatess incorrect il.

When the program runs it produces this output:

c:\kevinransom\fsharp>artifacts\Temp\RealsigPlusOptimisePlus.exe

Unhandled Exception: System.TypeLoadException: The generic type 'MyCollections.IEnumerator' was used with the wrong number of generic arguments in assembly 'RealsigPlusOptimisePlus, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null'.
   at Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers.ConcatEnumerator`2.GetCurrent()
   at Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers.ConcatEnumerator`2.System.Collections.IEnumerator.get_Current()
   at Microsoft.FSharp.Core.CompilerServices.doIt.loop()
   at <StartupCode$RealsigPlusOptimisePlus>.$Nested_generic_closure.main@()


This is the offending line:
IL_0006: call void class MyCollections.IEnumerator<!T, !U>::check(bool)


MyCollections.IEnumerator is not actually generic, I expect we need to put more guards around the line

The repro source code is: tests\FSharp.Compiler.ComponentTests\EmittedIL\RealInternalSignature\nested_generic_closure.fs


This is the IL for the program:


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
.assembly extern netstandard
{
  .publickeytoken = (CC 7B 13 FF CD 2D DD 51 )                         // .{...-.Q
  .ver 2:0:0:0
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
  // Offset: 0x00000000 Length: 0x00001013
  // WARNING: managed resource file FSharpSignatureCompressedData.RealsigPlusOptimisePlus created
}
.mresource public FSharpSignatureCompressedDataB.RealsigPlusOptimisePlus
{
  // Offset: 0x00001018 Length: 0x000000BB
  // WARNING: managed resource file FSharpSignatureCompressedDataB.RealsigPlusOptimisePlus created
}
.mresource public FSharpOptimizationCompressedData.RealsigPlusOptimisePlus
{
  // Offset: 0x000010D8 Length: 0x000002CB
  // WARNING: managed resource file FSharpOptimizationCompressedData.RealsigPlusOptimisePlus created
}
.mresource public FSharpOptimizationCompressedDataB.RealsigPlusOptimisePlus
{
  // Offset: 0x000013A8 Length: 0x00000032
  // WARNING: managed resource file FSharpOptimizationCompressedDataB.RealsigPlusOptimisePlus created
}
.module RealsigPlusOptimisePlus.exe
// MVID: {6ACEDC8E-D07F-21E7-A745-03838EDCCE6A}
.imagebase 0x00400000
.file alignment 0x00000200
.stackreserve 0x00100000
.subsystem 0x0003       // WINDOWS_CUI
.corflags 0x00000001    //  ILONLY
// Image base: 0x055C0000


// =============== CLASS MEMBERS DECLARATION ===================

.class public abstract auto ansi sealed Microsoft.FSharp.Core.CompilerServices.doIt
       extends [mscorlib]System.Object
{
  .custom instance void [FSharp.Core]Microsoft.FSharp.Core.CompilationMappingAttribute::.ctor(valuetype [FSharp.Core]Microsoft.FSharp.Core.SourceConstructFlags) = ( 01 00 07 00 00 00 00 00 ) 
  .class auto autochar serializable sealed nested assembly beforefieldinit specialname x@375
         extends class [FSharp.Core]Microsoft.FSharp.Core.CompilerServices.GeneratedSequenceBase`1<valuetype [mscorlib]System.ArraySegment`1<uint8>>
  {
    .custom instance void [FSharp.Core]Microsoft.FSharp.Core.CompilationMappingAttribute::.ctor(valuetype [FSharp.Core]Microsoft.FSharp.Core.SourceConstructFlags) = ( 01 00 06 00 00 00 00 00 ) 
    .field public int32 pc
    .custom instance void [mscorlib]System.Diagnostics.DebuggerBrowsableAttribute::.ctor(valuetype [mscorlib]System.Diagnostics.DebuggerBrowsableState) = ( 01 00 00 00 00 00 00 00 ) 
    .custom instance void [mscorlib]System.Runtime.CompilerServices.CompilerGeneratedAttribute::.ctor() = ( 01 00 00 00 ) 
    .custom instance void [mscorlib]System.Diagnostics.DebuggerNonUserCodeAttribute::.ctor() = ( 01 00 00 00 ) 
    .field public valuetype [mscorlib]System.ArraySegment`1<uint8> current
    .custom instance void [mscorlib]System.Diagnostics.DebuggerBrowsableAttribute::.ctor(valuetype [mscorlib]System.Diagnostics.DebuggerBrowsableState) = ( 01 00 00 00 00 00 00 00 ) 
    .custom instance void [mscorlib]System.Runtime.CompilerServices.CompilerGeneratedAttribute::.ctor() = ( 01 00 00 00 ) 
    .custom instance void [mscorlib]System.Diagnostics.DebuggerNonUserCodeAttribute::.ctor() = ( 01 00 00 00 ) 
    .method public specialname rtspecialname 
            instance void  .ctor(int32 pc,
                                 valuetype [mscorlib]System.ArraySegment`1<uint8> current) cil managed
    {
      // Code size       21 (0x15)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  ldarg.1
      IL_0002:  stfld      int32 Microsoft.FSharp.Core.CompilerServices.doIt/x@375::pc
      IL_0007:  ldarg.0
      IL_0008:  ldarg.2
      IL_0009:  stfld      valuetype [mscorlib]System.ArraySegment`1<uint8> Microsoft.FSharp.Core.CompilerServices.doIt/x@375::current
      IL_000e:  ldarg.0
      IL_000f:  call       instance void class [FSharp.Core]Microsoft.FSharp.Core.CompilerServices.GeneratedSequenceBase`1<valuetype [mscorlib]System.ArraySegment`1<uint8>>::.ctor()
      IL_0014:  ret
    } // end of method x@375::.ctor

    .method public strict virtual instance int32 
            GenerateNext(class [mscorlib]System.Collections.Generic.IEnumerable`1<valuetype [mscorlib]System.ArraySegment`1<uint8>>& next) cil managed
    {
      // Code size       166 (0xa6)
      .maxstack  8
      .locals init (valuetype [mscorlib]System.ArraySegment`1<uint8> V_0)
      IL_0000:  ldarg.0
      IL_0001:  ldfld      int32 Microsoft.FSharp.Core.CompilerServices.doIt/x@375::pc
      IL_0006:  ldc.i4.1
      IL_0007:  sub
      IL_0008:  switch     ( 
                            IL_001f,
                            IL_0021,
                            IL_0023,
                            IL_0025)
      IL_001d:  br.s       IL_0027

      IL_001f:  br.s       IL_004c

      IL_0021:  br.s       IL_0071

      IL_0023:  br.s       IL_0096

      IL_0025:  br.s       IL_009d

      IL_0027:  ldarg.0
      IL_0028:  ldc.i4.1
      IL_0029:  stfld      int32 Microsoft.FSharp.Core.CompilerServices.doIt/x@375::pc
      IL_002e:  ldarg.0
      IL_002f:  ldc.i4.3
      IL_0030:  newarr     [mscorlib]System.Byte
      IL_0035:  dup
      IL_0036:  ldtoken    field valuetype Microsoft.FSharp.Core.CompilerServices.doIt/T_3Bytes@ Microsoft.FSharp.Core.CompilerServices.doIt::field375_1@
      IL_003b:  call       void [mscorlib]System.Runtime.CompilerServices.RuntimeHelpers::InitializeArray(class [mscorlib]System.Array,
                                                                                                          valuetype [mscorlib]System.RuntimeFieldHandle)
      IL_0040:  newobj     instance void valuetype [mscorlib]System.ArraySegment`1<uint8>::.ctor(!0[])
      IL_0045:  stfld      valuetype [mscorlib]System.ArraySegment`1<uint8> Microsoft.FSharp.Core.CompilerServices.doIt/x@375::current
      IL_004a:  ldc.i4.1
      IL_004b:  ret

      IL_004c:  ldarg.0
      IL_004d:  ldc.i4.2
      IL_004e:  stfld      int32 Microsoft.FSharp.Core.CompilerServices.doIt/x@375::pc
      IL_0053:  ldarg.0
      IL_0054:  ldc.i4.3
      IL_0055:  newarr     [mscorlib]System.Byte
      IL_005a:  dup
      IL_005b:  ldtoken    field valuetype Microsoft.FSharp.Core.CompilerServices.doIt/T_3Bytes@ Microsoft.FSharp.Core.CompilerServices.doIt::field375_2@
      IL_0060:  call       void [mscorlib]System.Runtime.CompilerServices.RuntimeHelpers::InitializeArray(class [mscorlib]System.Array,
                                                                                                          valuetype [mscorlib]System.RuntimeFieldHandle)
      IL_0065:  newobj     instance void valuetype [mscorlib]System.ArraySegment`1<uint8>::.ctor(!0[])
      IL_006a:  stfld      valuetype [mscorlib]System.ArraySegment`1<uint8> Microsoft.FSharp.Core.CompilerServices.doIt/x@375::current
      IL_006f:  ldc.i4.1
      IL_0070:  ret

      IL_0071:  ldarg.0
      IL_0072:  ldc.i4.3
      IL_0073:  stfld      int32 Microsoft.FSharp.Core.CompilerServices.doIt/x@375::pc
      IL_0078:  ldarg.0
      IL_0079:  ldc.i4.3
      IL_007a:  newarr     [mscorlib]System.Byte
      IL_007f:  dup
      IL_0080:  ldtoken    field valuetype Microsoft.FSharp.Core.CompilerServices.doIt/T_3Bytes@ Microsoft.FSharp.Core.CompilerServices.doIt::field375_3@
      IL_0085:  call       void [mscorlib]System.Runtime.CompilerServices.RuntimeHelpers::InitializeArray(class [mscorlib]System.Array,
                                                                                                          valuetype [mscorlib]System.RuntimeFieldHandle)
      IL_008a:  newobj     instance void valuetype [mscorlib]System.ArraySegment`1<uint8>::.ctor(!0[])
      IL_008f:  stfld      valuetype [mscorlib]System.ArraySegment`1<uint8> Microsoft.FSharp.Core.CompilerServices.doIt/x@375::current
      IL_0094:  ldc.i4.1
      IL_0095:  ret

      IL_0096:  ldarg.0
      IL_0097:  ldc.i4.4
      IL_0098:  stfld      int32 Microsoft.FSharp.Core.CompilerServices.doIt/x@375::pc
      IL_009d:  ldarg.0
      IL_009e:  ldloc.0
      IL_009f:  stfld      valuetype [mscorlib]System.ArraySegment`1<uint8> Microsoft.FSharp.Core.CompilerServices.doIt/x@375::current
      IL_00a4:  ldc.i4.0
      IL_00a5:  ret
    } // end of method x@375::GenerateNext

    .method public strict virtual instance void 
            Close() cil managed
    {
      // Code size       8 (0x8)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  ldc.i4.4
      IL_0002:  stfld      int32 Microsoft.FSharp.Core.CompilerServices.doIt/x@375::pc
      IL_0007:  ret
    } // end of method x@375::Close

    .method public strict virtual instance bool 
            get_CheckClose() cil managed
    {
      // Code size       51 (0x33)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  ldfld      int32 Microsoft.FSharp.Core.CompilerServices.doIt/x@375::pc
      IL_0006:  switch     ( 
                            IL_0021,
                            IL_0023,
                            IL_0025,
                            IL_0027,
                            IL_0029)
      IL_001f:  br.s       IL_002b

      IL_0021:  br.s       IL_0031

      IL_0023:  br.s       IL_002f

      IL_0025:  br.s       IL_002d

      IL_0027:  br.s       IL_002b

      IL_0029:  br.s       IL_0031

      IL_002b:  ldc.i4.0
      IL_002c:  ret

      IL_002d:  ldc.i4.0
      IL_002e:  ret

      IL_002f:  ldc.i4.0
      IL_0030:  ret

      IL_0031:  ldc.i4.0
      IL_0032:  ret
    } // end of method x@375::get_CheckClose

    .method public strict virtual instance valuetype [mscorlib]System.ArraySegment`1<uint8> 
            get_LastGenerated() cil managed
    {
      .custom instance void [mscorlib]System.Runtime.CompilerServices.CompilerGeneratedAttribute::.ctor() = ( 01 00 00 00 ) 
      .custom instance void [mscorlib]System.Diagnostics.DebuggerNonUserCodeAttribute::.ctor() = ( 01 00 00 00 ) 
      // Code size       7 (0x7)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  ldfld      valuetype [mscorlib]System.ArraySegment`1<uint8> Microsoft.FSharp.Core.CompilerServices.doIt/x@375::current
      IL_0006:  ret
    } // end of method x@375::get_LastGenerated

    .method public strict virtual instance class [mscorlib]System.Collections.Generic.IEnumerator`1<valuetype [mscorlib]System.ArraySegment`1<uint8>> 
            GetFreshEnumerator() cil managed
    {
      .custom instance void [mscorlib]System.Runtime.CompilerServices.CompilerGeneratedAttribute::.ctor() = ( 01 00 00 00 ) 
      .custom instance void [mscorlib]System.Diagnostics.DebuggerNonUserCodeAttribute::.ctor() = ( 01 00 00 00 ) 
      // Code size       8 (0x8)
      .maxstack  6
      .locals init (valuetype [mscorlib]System.ArraySegment`1<uint8> V_0)
      IL_0000:  ldc.i4.0
      IL_0001:  ldloc.0
      IL_0002:  newobj     instance void Microsoft.FSharp.Core.CompilerServices.doIt/x@375::.ctor(int32,
                                                                                                  valuetype [mscorlib]System.ArraySegment`1<uint8>)
      IL_0007:  ret
    } // end of method x@375::GetFreshEnumerator

  } // end of class x@375

  .class explicit ansi sealed nested assembly beforefieldinit T_3Bytes@
         extends [mscorlib]System.ValueType
  {
    .pack 0
    .size 3
  } // end of class T_3Bytes@

  .field static assembly class [mscorlib]System.Collections.Generic.IEnumerable`1<valuetype [mscorlib]System.ArraySegment`1<uint8>> x@375
  .custom instance void [mscorlib]System.Diagnostics.DebuggerBrowsableAttribute::.ctor(valuetype [mscorlib]System.Diagnostics.DebuggerBrowsableState) = ( 01 00 00 00 00 00 00 00 ) 
  .field static assembly valuetype Microsoft.FSharp.Core.CompilerServices.doIt/T_3Bytes@ field375_1@ at I_0000702A
  .custom instance void [mscorlib]System.Diagnostics.DebuggerBrowsableAttribute::.ctor(valuetype [mscorlib]System.Diagnostics.DebuggerBrowsableState) = ( 01 00 00 00 00 00 00 00 ) 
  .field static assembly valuetype Microsoft.FSharp.Core.CompilerServices.doIt/T_3Bytes@ field375_2@ at I_0000702D
  .custom instance void [mscorlib]System.Diagnostics.DebuggerBrowsableAttribute::.ctor(valuetype [mscorlib]System.Diagnostics.DebuggerBrowsableState) = ( 01 00 00 00 00 00 00 00 ) 
  .field static assembly valuetype Microsoft.FSharp.Core.CompilerServices.doIt/T_3Bytes@ field375_3@ at I_00007030
  .custom instance void [mscorlib]System.Diagnostics.DebuggerBrowsableAttribute::.ctor(valuetype [mscorlib]System.Diagnostics.DebuggerBrowsableState) = ( 01 00 00 00 00 00 00 00 ) 
  .field static assembly class [mscorlib]System.Collections.IEnumerator enumerator@376
  .custom instance void [mscorlib]System.Diagnostics.DebuggerBrowsableAttribute::.ctor(valuetype [mscorlib]System.Diagnostics.DebuggerBrowsableState) = ( 01 00 00 00 00 00 00 00 ) 
  .method public specialname static class [mscorlib]System.Collections.Generic.IEnumerable`1<valuetype [mscorlib]System.ArraySegment`1<uint8>> 
          get_x() cil managed
  {
    // Code size       6 (0x6)
    .maxstack  8
    IL_0000:  ldsfld     class [mscorlib]System.Collections.Generic.IEnumerable`1<valuetype [mscorlib]System.ArraySegment`1<uint8>> Microsoft.FSharp.Core.CompilerServices.doIt::x@375
    IL_0005:  ret
  } // end of method doIt::get_x

  .method public specialname static class [mscorlib]System.Collections.IEnumerator 
          get_enumerator() cil managed
  {
    // Code size       6 (0x6)
    .maxstack  8
    IL_0000:  ldsfld     class [mscorlib]System.Collections.IEnumerator Microsoft.FSharp.Core.CompilerServices.doIt::enumerator@376
    IL_0005:  ret
  } // end of method doIt::get_enumerator

  .method public static void  loop() cil managed
  {
    // Code size       67 (0x43)
    .maxstack  7
    .locals init (class [FSharp.Core]Microsoft.FSharp.Core.PrintfFormat`4<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [mscorlib]System.IO.TextWriter,class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [FSharp.Core]Microsoft.FSharp.Core.Unit> V_0)
    IL_0000:  call       class [mscorlib]System.Collections.IEnumerator Microsoft.FSharp.Core.CompilerServices.doIt::get_enumerator()
    IL_0005:  callvirt   instance bool [mscorlib]System.Collections.IEnumerator::MoveNext()
    IL_000a:  brfalse.s  IL_0042

    IL_000c:  ldstr      "%P()"
    IL_0011:  ldc.i4.1
    IL_0012:  newarr     [mscorlib]System.Object
    IL_0017:  dup
    IL_0018:  ldc.i4.0
    IL_0019:  call       class [mscorlib]System.Collections.IEnumerator Microsoft.FSharp.Core.CompilerServices.doIt::get_enumerator()
    IL_001e:  callvirt   instance object [mscorlib]System.Collections.IEnumerator::get_Current()
    IL_0023:  box        [mscorlib]System.Object
    IL_0028:  stelem     [mscorlib]System.Object
    IL_002d:  ldnull
    IL_002e:  newobj     instance void class [FSharp.Core]Microsoft.FSharp.Core.PrintfFormat`5<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [mscorlib]System.IO.TextWriter,class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [FSharp.Core]Microsoft.FSharp.Core.Unit,object>::.ctor(string,
                                                                                                                                                                                                                                                                                             object[],
                                                                                                                                                                                                                                                                                             class [mscorlib]System.Type[])
    IL_0033:  stloc.0
    IL_0034:  call       class [netstandard]System.IO.TextWriter [netstandard]System.Console::get_Out()
    IL_0039:  ldloc.0
    IL_003a:  call       !!0 [FSharp.Core]Microsoft.FSharp.Core.PrintfModule::PrintFormatLineToTextWriter<class [FSharp.Core]Microsoft.FSharp.Core.Unit>(class [mscorlib]System.IO.TextWriter,
                                                                                                                                                         class [FSharp.Core]Microsoft.FSharp.Core.PrintfFormat`4<!!0,class [mscorlib]System.IO.TextWriter,class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [FSharp.Core]Microsoft.FSharp.Core.Unit>)
    IL_003f:  pop
    IL_0040:  br.s       IL_0000

    IL_0042:  ret
  } // end of method doIt::loop

  .method private specialname rtspecialname static 
          void  .cctor() cil managed
  {
    // Code size       13 (0xd)
    .maxstack  8
    IL_0000:  ldc.i4.0
    IL_0001:  stsfld     int32 '<StartupCode$RealsigPlusOptimisePlus>'.$Nested_generic_closure::init@
    IL_0006:  ldsfld     int32 '<StartupCode$RealsigPlusOptimisePlus>'.$Nested_generic_closure::init@
    IL_000b:  pop
    IL_000c:  ret
  } // end of method doIt::.cctor

  .method assembly static void  staticInitialization@() cil managed
  {
    // Code size       33 (0x21)
    .maxstack  4
    .locals init (valuetype [mscorlib]System.ArraySegment`1<uint8> V_0)
    IL_0000:  ldc.i4.0
    IL_0001:  ldloc.0
    IL_0002:  newobj     instance void Microsoft.FSharp.Core.CompilerServices.doIt/x@375::.ctor(int32,
                                                                                                valuetype [mscorlib]System.ArraySegment`1<uint8>)
    IL_0007:  stsfld     class [mscorlib]System.Collections.Generic.IEnumerable`1<valuetype [mscorlib]System.ArraySegment`1<uint8>> Microsoft.FSharp.Core.CompilerServices.doIt::x@375
    IL_000c:  call       class [mscorlib]System.Collections.Generic.IEnumerable`1<valuetype [mscorlib]System.ArraySegment`1<uint8>> Microsoft.FSharp.Core.CompilerServices.doIt::get_x()
    IL_0011:  newobj     instance void class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/ConcatEnumerator`2<uint8,valuetype [mscorlib]System.ArraySegment`1<uint8>>::.ctor(class [mscorlib]System.Collections.Generic.IEnumerable`1<!1>)
    IL_0016:  stsfld     class [mscorlib]System.Collections.IEnumerator Microsoft.FSharp.Core.CompilerServices.doIt::enumerator@376
    IL_001b:  call       void Microsoft.FSharp.Core.CompilerServices.doIt::loop()
    IL_0020:  ret
  } // end of method doIt::staticInitialization@

  .property class [mscorlib]System.Collections.Generic.IEnumerable`1<valuetype [mscorlib]System.ArraySegment`1<uint8>>
          x()
  {
    .custom instance void [FSharp.Core]Microsoft.FSharp.Core.CompilationMappingAttribute::.ctor(valuetype [FSharp.Core]Microsoft.FSharp.Core.SourceConstructFlags) = ( 01 00 09 00 00 00 00 00 ) 
    .get class [mscorlib]System.Collections.Generic.IEnumerable`1<valuetype [mscorlib]System.ArraySegment`1<uint8>> Microsoft.FSharp.Core.CompilerServices.doIt::get_x()
  } // end of property doIt::x
  .property class [mscorlib]System.Collections.IEnumerator
          enumerator()
  {
    .custom instance void [FSharp.Core]Microsoft.FSharp.Core.CompilationMappingAttribute::.ctor(valuetype [FSharp.Core]Microsoft.FSharp.Core.SourceConstructFlags) = ( 01 00 09 00 00 00 00 00 ) 
    .get class [mscorlib]System.Collections.IEnumerator Microsoft.FSharp.Core.CompilerServices.doIt::get_enumerator()
  } // end of property doIt::enumerator
} // end of class Microsoft.FSharp.Core.CompilerServices.doIt

.class public abstract auto ansi sealed Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers
       extends [mscorlib]System.Object
{
  .custom instance void [FSharp.Core]Microsoft.FSharp.Core.CompilationMappingAttribute::.ctor(valuetype [FSharp.Core]Microsoft.FSharp.Core.SourceConstructFlags) = ( 01 00 07 00 00 00 00 00 ) 
  .class sequential ansi serializable sealed nested assembly StructBox`1<T>
         extends [mscorlib]System.ValueType
  {
    .custom instance void [FSharp.Core]Microsoft.FSharp.Core.StructAttribute::.ctor() = ( 01 00 00 00 ) 
    .custom instance void [FSharp.Core]Microsoft.FSharp.Core.NoComparisonAttribute::.ctor() = ( 01 00 00 00 ) 
    .custom instance void [FSharp.Core]Microsoft.FSharp.Core.NoEqualityAttribute::.ctor() = ( 01 00 00 00 ) 
    .custom instance void [FSharp.Core]Microsoft.FSharp.Core.CompilationMappingAttribute::.ctor(valuetype [FSharp.Core]Microsoft.FSharp.Core.SourceConstructFlags) = ( 01 00 03 00 00 00 00 00 ) 
    .class auto autochar serializable sealed nested assembly beforefieldinit specialname get_Comparer@195<T>
           extends [mscorlib]System.Object
           implements class [mscorlib]System.Collections.Generic.IEqualityComparer`1<valuetype Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/StructBox`1<!T>>
    {
      .custom instance void [FSharp.Core]Microsoft.FSharp.Core.CompilationMappingAttribute::.ctor(valuetype [FSharp.Core]Microsoft.FSharp.Core.SourceConstructFlags) = ( 01 00 06 00 00 00 00 00 ) 
      .field public class [mscorlib]System.Collections.Generic.IEqualityComparer`1<!T> gcomparer
      .method public specialname rtspecialname 
              instance void  .ctor(class [mscorlib]System.Collections.Generic.IEqualityComparer`1<!T> gcomparer) cil managed
      {
        // Code size       16 (0x10)
        .maxstack  8
        IL_0000:  ldarg.0
        IL_0001:  ldarg.1
        IL_0002:  stfld      class [mscorlib]System.Collections.Generic.IEqualityComparer`1<!0> class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/StructBox`1/get_Comparer@195<!T>::gcomparer
        IL_0007:  ldarg.0
        IL_0008:  callvirt   instance void [mscorlib]System.Object::.ctor()
        IL_000d:  ldarg.0
        IL_000e:  pop
        IL_000f:  ret
      } // end of method get_Comparer@195::.ctor

      .method private hidebysig newslot virtual final 
              instance int32  'System.Collections.Generic.IEqualityComparer<Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers.StructBox<\'T>>.GetHashCode'(valuetype Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/StructBox`1<!T> v) cil managed
      {
        .override  method instance int32 class [mscorlib]System.Collections.Generic.IEqualityComparer`1<valuetype Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/StructBox`1<!T>>::GetHashCode(!0)
        // Code size       21 (0x15)
        .maxstack  8
        IL_0000:  ldarg.0
        IL_0001:  ldfld      class [mscorlib]System.Collections.Generic.IEqualityComparer`1<!0> class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/StructBox`1/get_Comparer@195<!T>::gcomparer
        IL_0006:  ldarga.s   v
        IL_0008:  ldfld      !0 valuetype Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/StructBox`1<!T>::'value'
        IL_000d:  tail.
        IL_000f:  callvirt   instance int32 class [mscorlib]System.Collections.Generic.IEqualityComparer`1<!T>::GetHashCode(!0)
        IL_0014:  ret
      } // end of method get_Comparer@195::'System.Collections.Generic.IEqualityComparer<Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers.StructBox<\'T>>.GetHashCode'

      .method private hidebysig newslot virtual final 
              instance bool  'System.Collections.Generic.IEqualityComparer<Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers.StructBox<\'T>>.Equals'(valuetype Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/StructBox`1<!T> v1,
                                                                                                                                                         valuetype Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/StructBox`1<!T> v2) cil managed
      {
        .override  method instance bool class [mscorlib]System.Collections.Generic.IEqualityComparer`1<valuetype Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/StructBox`1<!T>>::Equals(!0,
                                                                                                                                                                                                !0)
        // Code size       28 (0x1c)
        .maxstack  8
        IL_0000:  ldarg.0
        IL_0001:  ldfld      class [mscorlib]System.Collections.Generic.IEqualityComparer`1<!0> class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/StructBox`1/get_Comparer@195<!T>::gcomparer
        IL_0006:  ldarga.s   v1
        IL_0008:  ldfld      !0 valuetype Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/StructBox`1<!T>::'value'
        IL_000d:  ldarga.s   v2
        IL_000f:  ldfld      !0 valuetype Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/StructBox`1<!T>::'value'
        IL_0014:  tail.
        IL_0016:  callvirt   instance bool class [mscorlib]System.Collections.Generic.IEqualityComparer`1<!T>::Equals(!0,
                                                                                                                      !0)
        IL_001b:  ret
      } // end of method get_Comparer@195::'System.Collections.Generic.IEqualityComparer<Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers.StructBox<\'T>>.Equals'

    } // end of class get_Comparer@195

    .field assembly !T 'value'
    .method public specialname rtspecialname 
            instance void  .ctor(!T 'value') cil managed
    {
      // Code size       8 (0x8)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  ldarg.1
      IL_0002:  stfld      !0 valuetype Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/StructBox`1<!T>::'value'
      IL_0007:  ret
    } // end of method StructBox`1::.ctor

    .method public hidebysig specialname 
            instance !T  get_Value() cil managed
    {
      // Code size       7 (0x7)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  ldfld      !0 valuetype Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/StructBox`1<!T>::'value'
      IL_0006:  ret
    } // end of method StructBox`1::get_Value

    .method public specialname static class [mscorlib]System.Collections.Generic.IEqualityComparer`1<valuetype Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/StructBox`1<!T>> 
            get_Comparer() cil managed
    {
      // Code size       13 (0xd)
      .maxstack  3
      .locals init (class [mscorlib]System.Collections.Generic.IEqualityComparer`1<!T> V_0)
      IL_0000:  call       class [mscorlib]System.Collections.Generic.IEqualityComparer`1<!0> class [FSharp.Core]Microsoft.FSharp.Core.LanguagePrimitives<!T>::FastGenericEqualityComparerFromTable<!0>()
      IL_0005:  stloc.0
      IL_0006:  ldloc.0
      IL_0007:  newobj     instance void class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/StructBox`1/get_Comparer@195<!T>::.ctor(class [mscorlib]System.Collections.Generic.IEqualityComparer`1<!0>)
      IL_000c:  ret
    } // end of method StructBox`1::get_Comparer

    .property instance !T Value()
    {
      .get instance !T Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/StructBox`1::get_Value()
    } // end of property StructBox`1::Value
    .property class [mscorlib]System.Collections.Generic.IEqualityComparer`1<valuetype Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/StructBox`1<!T>>
            Comparer()
    {
      .get class [mscorlib]System.Collections.Generic.IEqualityComparer`1<valuetype Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/StructBox`1<!T>> Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/StructBox`1::get_Comparer()
    } // end of property StructBox`1::Comparer
  } // end of class StructBox`1

  .class auto ansi serializable sealed nested assembly beforefieldinit Generate@200<a,T>
         extends class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [mscorlib]System.Collections.Generic.IEnumerator`1<!T>>
  {
    .field public class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,!a> openf
    .field public class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<!a,class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!T>> compute
    .field public class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<!a,class [FSharp.Core]Microsoft.FSharp.Core.Unit> closef
    .method assembly specialname rtspecialname 
            instance void  .ctor(class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,!a> openf,
                                 class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<!a,class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!T>> compute,
                                 class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<!a,class [FSharp.Core]Microsoft.FSharp.Core.Unit> closef) cil managed
    {
      .custom instance void [mscorlib]System.Runtime.CompilerServices.CompilerGeneratedAttribute::.ctor() = ( 01 00 00 00 ) 
      .custom instance void [mscorlib]System.Diagnostics.DebuggerNonUserCodeAttribute::.ctor() = ( 01 00 00 00 ) 
      // Code size       28 (0x1c)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  call       instance void class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [mscorlib]System.Collections.Generic.IEnumerator`1<!T>>::.ctor()
      IL_0006:  ldarg.0
      IL_0007:  ldarg.1
      IL_0008:  stfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,!0> class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/Generate@200<!a,!T>::openf
      IL_000d:  ldarg.0
      IL_000e:  ldarg.2
      IL_000f:  stfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<!0,class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!1>> class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/Generate@200<!a,!T>::compute
      IL_0014:  ldarg.0
      IL_0015:  ldarg.3
      IL_0016:  stfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<!0,class [FSharp.Core]Microsoft.FSharp.Core.Unit> class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/Generate@200<!a,!T>::closef
      IL_001b:  ret
    } // end of method Generate@200::.ctor

    .method public strict virtual instance class [mscorlib]System.Collections.Generic.IEnumerator`1<!T> 
            Invoke(class [FSharp.Core]Microsoft.FSharp.Core.Unit unitVar0) cil managed
    {
      // Code size       24 (0x18)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  ldfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,!0> class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/Generate@200<!a,!T>::openf
      IL_0006:  ldarg.0
      IL_0007:  ldfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<!0,class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!1>> class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/Generate@200<!a,!T>::compute
      IL_000c:  ldarg.0
      IL_000d:  ldfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<!0,class [FSharp.Core]Microsoft.FSharp.Core.Unit> class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/Generate@200<!a,!T>::closef
      IL_0012:  newobj     instance void class MyCollections.IEnumerator/GeneratedEnumerable`2<!T,!a>::.ctor(class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,!1>,
                                                                                                             class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<!1,class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!0>>,
                                                                                                             class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<!1,class [FSharp.Core]Microsoft.FSharp.Core.Unit>)
      IL_0017:  ret
    } // end of method Generate@200::Invoke

  } // end of class Generate@200

  .class auto ansi serializable sealed nested assembly beforefieldinit EnumerateFromFunctions@205<a,b>
         extends class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<!a,class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!b>>
  {
    .field public class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<!a,bool> moveNext
    .field public class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<!a,!b> current
    .method assembly specialname rtspecialname 
            instance void  .ctor(class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<!a,bool> moveNext,
                                 class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<!a,!b> current) cil managed
    {
      .custom instance void [mscorlib]System.Runtime.CompilerServices.CompilerGeneratedAttribute::.ctor() = ( 01 00 00 00 ) 
      .custom instance void [mscorlib]System.Diagnostics.DebuggerNonUserCodeAttribute::.ctor() = ( 01 00 00 00 ) 
      // Code size       21 (0x15)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  call       instance void class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<!a,class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!b>>::.ctor()
      IL_0006:  ldarg.0
      IL_0007:  ldarg.1
      IL_0008:  stfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<!0,bool> class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/EnumerateFromFunctions@205<!a,!b>::moveNext
      IL_000d:  ldarg.0
      IL_000e:  ldarg.2
      IL_000f:  stfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<!0,!1> class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/EnumerateFromFunctions@205<!a,!b>::current
      IL_0014:  ret
    } // end of method EnumerateFromFunctions@205::.ctor

    .method public strict virtual instance class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!b> 
            Invoke(!a x) cil managed
    {
      // Code size       34 (0x22)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  ldfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<!0,bool> class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/EnumerateFromFunctions@205<!a,!b>::moveNext
      IL_0006:  ldarg.1
      IL_0007:  callvirt   instance !1 class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<!a,bool>::Invoke(!0)
      IL_000c:  brfalse.s  IL_0020

      IL_000e:  ldarg.0
      IL_000f:  ldfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<!0,!1> class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/EnumerateFromFunctions@205<!a,!b>::current
      IL_0014:  ldarg.1
      IL_0015:  callvirt   instance !1 class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<!a,!b>::Invoke(!0)
      IL_001a:  call       class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!0> class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!b>::Some(!0)
      IL_001f:  ret

      IL_0020:  ldnull
      IL_0021:  ret
    } // end of method EnumerateFromFunctions@205::Invoke

  } // end of class EnumerateFromFunctions@205

  .class auto ansi serializable sealed nested assembly beforefieldinit 'EnumerateFromFunctions@206-1'<a>
         extends class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<!a,class [FSharp.Core]Microsoft.FSharp.Core.Unit>
  {
    .field static assembly initonly class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/'EnumerateFromFunctions@206-1'<!a> @_instance
    .method assembly specialname rtspecialname 
            instance void  .ctor() cil managed
    {
      .custom instance void [mscorlib]System.Runtime.CompilerServices.CompilerGeneratedAttribute::.ctor() = ( 01 00 00 00 ) 
      .custom instance void [mscorlib]System.Diagnostics.DebuggerNonUserCodeAttribute::.ctor() = ( 01 00 00 00 ) 
      // Code size       7 (0x7)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  call       instance void class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<!a,class [FSharp.Core]Microsoft.FSharp.Core.Unit>::.ctor()
      IL_0006:  ret
    } // end of method 'EnumerateFromFunctions@206-1'::.ctor

    .method public strict virtual instance class [FSharp.Core]Microsoft.FSharp.Core.Unit 
            Invoke(!a x) cil managed
    {
      // Code size       29 (0x1d)
      .maxstack  5
      .locals init (object V_0,
               class [mscorlib]System.IDisposable V_1,
               class [mscorlib]System.IDisposable V_2)
      IL_0000:  ldarg.1
      IL_0001:  box        !a
      IL_0006:  stloc.0
      IL_0007:  ldloc.0
      IL_0008:  isinst     [mscorlib]System.IDisposable
      IL_000d:  stloc.1
      IL_000e:  ldloc.1
      IL_000f:  brfalse.s  IL_001b

      IL_0011:  ldloc.1
      IL_0012:  stloc.2
      IL_0013:  ldloc.2
      IL_0014:  callvirt   instance void [mscorlib]System.IDisposable::Dispose()
      IL_0019:  ldnull
      IL_001a:  ret

      IL_001b:  ldnull
      IL_001c:  ret
    } // end of method 'EnumerateFromFunctions@206-1'::Invoke

    .method private specialname rtspecialname static 
            void  .cctor() cil managed
    {
      // Code size       11 (0xb)
      .maxstack  10
      IL_0000:  newobj     instance void class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/'EnumerateFromFunctions@206-1'<!a>::.ctor()
      IL_0005:  stsfld     class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/'EnumerateFromFunctions@206-1'<!0> class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/'EnumerateFromFunctions@206-1'<!a>::@_instance
      IL_000a:  ret
    } // end of method 'EnumerateFromFunctions@206-1'::.cctor

  } // end of class 'EnumerateFromFunctions@206-1'

  .class interface abstract auto ansi serializable nested public IFinallyEnumerator
  {
    .custom instance void [FSharp.Core]Microsoft.FSharp.Core.CompilationMappingAttribute::.ctor(valuetype [FSharp.Core]Microsoft.FSharp.Core.SourceConstructFlags) = ( 01 00 03 00 00 00 00 00 ) 
    .method public hidebysig abstract virtual 
            instance void  AppendFinallyAction(class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [FSharp.Core]Microsoft.FSharp.Core.Unit> A_1) cil managed
    {
    } // end of method IFinallyEnumerator::AppendFinallyAction

  } // end of class IFinallyEnumerator

  .class auto ansi serializable sealed nested public FinallyEnumerable`1<T>
         extends [mscorlib]System.Object
         implements [mscorlib]System.Collections.IEnumerable,
                    class [mscorlib]System.Collections.Generic.IEnumerable`1<!T>
  {
    .custom instance void [FSharp.Core]Microsoft.FSharp.Core.SealedAttribute::.ctor() = ( 01 00 00 00 ) 
    .custom instance void [FSharp.Core]Microsoft.FSharp.Core.CompilationMappingAttribute::.ctor(valuetype [FSharp.Core]Microsoft.FSharp.Core.SourceConstructFlags) = ( 01 00 03 00 00 00 00 00 ) 
    .field assembly class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [mscorlib]System.Collections.Generic.IEnumerable`1<!T>> restf
    .field assembly class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [FSharp.Core]Microsoft.FSharp.Core.Unit> compensation
    .method public specialname rtspecialname 
            instance void  .ctor(class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [FSharp.Core]Microsoft.FSharp.Core.Unit> compensation,
                                 class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [mscorlib]System.Collections.Generic.IEnumerable`1<!T>> restf) cil managed
    {
      // Code size       23 (0x17)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  callvirt   instance void [mscorlib]System.Object::.ctor()
      IL_0006:  ldarg.0
      IL_0007:  pop
      IL_0008:  ldarg.0
      IL_0009:  ldarg.1
      IL_000a:  stfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [FSharp.Core]Microsoft.FSharp.Core.Unit> class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/FinallyEnumerable`1<!T>::compensation
      IL_000f:  ldarg.0
      IL_0010:  ldarg.2
      IL_0011:  stfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [mscorlib]System.Collections.Generic.IEnumerable`1<!0>> class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/FinallyEnumerable`1<!T>::restf
      IL_0016:  ret
    } // end of method FinallyEnumerable`1::.ctor

    .method private hidebysig newslot virtual 
            instance class [mscorlib]System.Collections.Generic.IEnumerator`1<!T> 
            'System.Collections.Generic.IEnumerable<\'T>.GetEnumerator'() cil managed
    {
      .override  method instance class [mscorlib]System.Collections.Generic.IEnumerator`1<!0> class [mscorlib]System.Collections.Generic.IEnumerable`1<!T>::GetEnumerator()
      // Code size       94 (0x5e)
      .maxstack  4
      .locals init (class [mscorlib]System.Collections.Generic.IEnumerator`1<!T> V_0,
               class [mscorlib]System.Collections.Generic.IEnumerator`1<!T> V_1,
               class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/IFinallyEnumerator V_2,
               class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/IFinallyEnumerator V_3,
               class [mscorlib]System.Exception V_4)
      .try
      {
        IL_0000:  ldarg.0
        IL_0001:  ldfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [mscorlib]System.Collections.Generic.IEnumerable`1<!0>> class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/FinallyEnumerable`1<!T>::restf
        IL_0006:  ldnull
        IL_0007:  callvirt   instance !1 class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [mscorlib]System.Collections.Generic.IEnumerable`1<!T>>::Invoke(!0)
        IL_000c:  callvirt   instance class [mscorlib]System.Collections.Generic.IEnumerator`1<!0> class [mscorlib]System.Collections.Generic.IEnumerable`1<!T>::GetEnumerator()
        IL_0011:  stloc.1
        IL_0012:  ldloc.1
        IL_0013:  isinst     Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/IFinallyEnumerator
        IL_0018:  stloc.2
        IL_0019:  ldloc.2
        IL_001a:  brfalse.s  IL_002e

        IL_001c:  ldloc.2
        IL_001d:  stloc.3
        IL_001e:  ldloc.3
        IL_001f:  ldarg.0
        IL_0020:  ldfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [FSharp.Core]Microsoft.FSharp.Core.Unit> class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/FinallyEnumerable`1<!T>::compensation
        IL_0025:  callvirt   instance void Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/IFinallyEnumerator::AppendFinallyAction(class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [FSharp.Core]Microsoft.FSharp.Core.Unit>)
        IL_002a:  ldloc.1
        IL_002b:  stloc.0
        IL_002c:  leave.s    IL_005c

        IL_002e:  ldarg.0
        IL_002f:  ldfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [FSharp.Core]Microsoft.FSharp.Core.Unit> class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/FinallyEnumerable`1<!T>::compensation
        IL_0034:  ldloc.1
        IL_0035:  call       class [mscorlib]System.Collections.Generic.IEnumerator`1<!0> class MyCollections.IEnumerator<!T>::EnumerateThenFinally<!0>(class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [FSharp.Core]Microsoft.FSharp.Core.Unit>,
                                                                                                                                                        class [mscorlib]System.Collections.Generic.IEnumerator`1<!0>)
        IL_003a:  stloc.0
        IL_003b:  leave.s    IL_005c

      }  // end .try
      catch [mscorlib]System.Object 
      {
        IL_003d:  castclass  [mscorlib]System.Exception
        IL_0042:  stloc.s    V_4
        IL_0044:  ldarg.0
        IL_0045:  ldfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [FSharp.Core]Microsoft.FSharp.Core.Unit> class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/FinallyEnumerable`1<!T>::compensation
        IL_004a:  ldnull
        IL_004b:  callvirt   instance !1 class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [FSharp.Core]Microsoft.FSharp.Core.Unit>::Invoke(!0)
        IL_0050:  pop
        IL_0051:  rethrow
        IL_0053:  ldnull
        IL_0054:  unbox.any  class [mscorlib]System.Collections.Generic.IEnumerator`1<!T>
        IL_0059:  stloc.0
        IL_005a:  leave.s    IL_005c

      }  // end handler
      IL_005c:  ldloc.0
      IL_005d:  ret
    } // end of method FinallyEnumerable`1::'System.Collections.Generic.IEnumerable<\'T>.GetEnumerator'

    .method private hidebysig newslot virtual 
            instance class [mscorlib]System.Collections.IEnumerator 
            System.Collections.IEnumerable.GetEnumerator() cil managed
    {
      .override [mscorlib]System.Collections.IEnumerable::GetEnumerator
      // Code size       7 (0x7)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  callvirt   instance class [mscorlib]System.Collections.Generic.IEnumerator`1<!0> class [mscorlib]System.Collections.Generic.IEnumerable`1<!T>::GetEnumerator()
      IL_0006:  ret
    } // end of method FinallyEnumerable`1::System.Collections.IEnumerable.GetEnumerator

  } // end of class FinallyEnumerable`1

  .class auto ansi serializable sealed nested public ConcatEnumerator`2<T,(class [mscorlib]System.Collections.Generic.IEnumerable`1<!T>) U>
         extends [mscorlib]System.Object
         implements [mscorlib]System.IDisposable,
                    [mscorlib]System.Collections.IEnumerator,
                    class [mscorlib]System.Collections.Generic.IEnumerator`1<!T>,
                    Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/IFinallyEnumerator
  {
    .custom instance void [FSharp.Core]Microsoft.FSharp.Core.SealedAttribute::.ctor() = ( 01 00 00 00 ) 
    .custom instance void [FSharp.Core]Microsoft.FSharp.Core.CompilationMappingAttribute::.ctor(valuetype [FSharp.Core]Microsoft.FSharp.Core.SourceConstructFlags) = ( 01 00 03 00 00 00 00 00 ) 
    .field assembly class [mscorlib]System.Collections.Generic.IEnumerator`1<!U> outerEnum
    .field assembly class [mscorlib]System.Collections.Generic.IEnumerator`1<!T> currInnerEnum
    .field assembly bool started
    .field assembly bool finished
    .field assembly class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [FSharp.Core]Microsoft.FSharp.Core.Unit>> compensations
    .field assembly !T currElement
    .custom instance void [FSharp.Core]Microsoft.FSharp.Core.DefaultValueAttribute::.ctor(bool) = ( 01 00 00 00 00 ) 
    .method public specialname rtspecialname 
            instance void  .ctor(class [mscorlib]System.Collections.Generic.IEnumerable`1<!U> sources) cil managed
    {
      // Code size       57 (0x39)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  callvirt   instance void [mscorlib]System.Object::.ctor()
      IL_0006:  ldarg.0
      IL_0007:  pop
      IL_0008:  ldarg.0
      IL_0009:  ldarg.1
      IL_000a:  callvirt   instance class [mscorlib]System.Collections.Generic.IEnumerator`1<!0> class [mscorlib]System.Collections.Generic.IEnumerable`1<!U>::GetEnumerator()
      IL_000f:  stfld      class [mscorlib]System.Collections.Generic.IEnumerator`1<!1> class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/ConcatEnumerator`2<!T,!U>::outerEnum
      IL_0014:  ldarg.0
      IL_0015:  newobj     instance void class MyCollections.IEnumerator/EmptyEnumerator`1<!T>::.ctor()
      IL_001a:  stfld      class [mscorlib]System.Collections.Generic.IEnumerator`1<!0> class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/ConcatEnumerator`2<!T,!U>::currInnerEnum
      IL_001f:  ldarg.0
      IL_0020:  ldc.i4.0
      IL_0021:  stfld      bool class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/ConcatEnumerator`2<!T,!U>::started
      IL_0026:  ldarg.0
      IL_0027:  ldc.i4.0
      IL_0028:  stfld      bool class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/ConcatEnumerator`2<!T,!U>::finished
      IL_002d:  ldarg.0
      IL_002e:  call       class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<!0> class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [FSharp.Core]Microsoft.FSharp.Core.Unit>>::get_Empty()
      IL_0033:  stfld      class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [FSharp.Core]Microsoft.FSharp.Core.Unit>> class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/ConcatEnumerator`2<!T,!U>::compensations
      IL_0038:  ret
    } // end of method ConcatEnumerator`2::.ctor

    .method public hidebysig instance void 
            Finish() cil managed
    {
      // Code size       106 (0x6a)
      .maxstack  4
      IL_0000:  ldarg.0
      IL_0001:  ldc.i4.1
      IL_0002:  stfld      bool class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/ConcatEnumerator`2<!T,!U>::finished
      .try
      {
        IL_0007:  ldarg.0
        IL_0008:  ldfld      class [mscorlib]System.Collections.Generic.IEnumerator`1<!0> class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/ConcatEnumerator`2<!T,!U>::currInnerEnum
        IL_000d:  brtrue.s   IL_0011

        IL_000f:  leave.s    IL_0069

        .try
        {
          IL_0011:  ldarg.0
          IL_0012:  ldfld      class [mscorlib]System.Collections.Generic.IEnumerator`1<!0> class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/ConcatEnumerator`2<!T,!U>::currInnerEnum
          IL_0017:  callvirt   instance void [mscorlib]System.IDisposable::Dispose()
          IL_001c:  leave.s    IL_0026

        }  // end .try
        finally
        {
          IL_001e:  ldarg.0
          IL_001f:  ldnull
          IL_0020:  stfld      class [mscorlib]System.Collections.Generic.IEnumerator`1<!0> class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/ConcatEnumerator`2<!T,!U>::currInnerEnum
          IL_0025:  endfinally
        }  // end handler
        IL_0026:  leave.s    IL_0069

      }  // end .try
      finally
      {
        .try
        {
          IL_0028:  ldarg.0
          IL_0029:  ldfld      class [mscorlib]System.Collections.Generic.IEnumerator`1<!1> class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/ConcatEnumerator`2<!T,!U>::outerEnum
          IL_002e:  brtrue.s   IL_0032

          IL_0030:  leave.s    IL_0068

          .try
          {
            IL_0032:  ldarg.0
            IL_0033:  ldfld      class [mscorlib]System.Collections.Generic.IEnumerator`1<!1> class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/ConcatEnumerator`2<!T,!U>::outerEnum
            IL_0038:  callvirt   instance void [mscorlib]System.IDisposable::Dispose()
            IL_003d:  leave.s    IL_0047

          }  // end .try
          finally
          {
            IL_003f:  ldarg.0
            IL_0040:  ldnull
            IL_0041:  stfld      class [mscorlib]System.Collections.Generic.IEnumerator`1<!1> class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/ConcatEnumerator`2<!T,!U>::outerEnum
            IL_0046:  endfinally
          }  // end handler
          IL_0047:  leave.s    IL_0068

        }  // end .try
        finally
        {
          .try
          {
            IL_0049:  ldarg.0
            IL_004a:  ldfld      class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [FSharp.Core]Microsoft.FSharp.Core.Unit>> class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/ConcatEnumerator`2<!T,!U>::compensations
            IL_004f:  call       class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<!0> class [FSharp.Core]Microsoft.FSharp.Collections.ListModule<!T,!U>::Reverse<class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [FSharp.Core]Microsoft.FSharp.Core.Unit>>(class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<!0>)
            IL_0054:  call       void class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/ConcatEnumerator`2<!T,!U>::iter@272(class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [FSharp.Core]Microsoft.FSharp.Core.Unit>>)
            IL_0059:  leave.s    IL_0067

          }  // end .try
          finally
          {
            IL_005b:  ldarg.0
            IL_005c:  call       class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<!0> class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [FSharp.Core]Microsoft.FSharp.Core.Unit>>::get_Empty()
            IL_0061:  stfld      class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [FSharp.Core]Microsoft.FSharp.Core.Unit>> class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/ConcatEnumerator`2<!T,!U>::compensations
            IL_0066:  endfinally
          }  // end handler
          IL_0067:  endfinally
        }  // end handler
        IL_0068:  endfinally
      }  // end handler
      IL_0069:  ret
    } // end of method ConcatEnumerator`2::Finish

    .method public hidebysig instance !T 
            GetCurrent() cil managed
    {
      // Code size       37 (0x25)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  ldfld      bool class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/ConcatEnumerator`2<!T,!U>::started
      IL_0006:  call       void class MyCollections.IEnumerator<!T,!U>::check(bool)
      IL_000b:  ldarg.0
      IL_000c:  ldfld      bool class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/ConcatEnumerator`2<!T,!U>::finished
      IL_0011:  brfalse.s  IL_001e

      IL_0013:  ldstr      "SR.GetString(SR.enumerationAlreadyFinished)"
      IL_0018:  newobj     instance void [mscorlib]System.InvalidOperationException::.ctor(string)
      IL_001d:  throw

      IL_001e:  ldarg.0
      IL_001f:  ldfld      !0 class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/ConcatEnumerator`2<!T,!U>::currElement
      IL_0024:  ret
    } // end of method ConcatEnumerator`2::GetCurrent

    .method private hidebysig newslot virtual 
            instance void  Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers.IFinallyEnumerator.AppendFinallyAction(class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [FSharp.Core]Microsoft.FSharp.Core.Unit> f) cil managed
    {
      .override Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/IFinallyEnumerator::AppendFinallyAction
      // Code size       19 (0x13)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  ldarg.1
      IL_0002:  ldarg.0
      IL_0003:  ldfld      class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [FSharp.Core]Microsoft.FSharp.Core.Unit>> class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/ConcatEnumerator`2<!T,!U>::compensations
      IL_0008:  call       class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<!0> class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [FSharp.Core]Microsoft.FSharp.Core.Unit>>::Cons(!0,
                                                                                                                                                                                                                                                                                                                   class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<!0>)
      IL_000d:  stfld      class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [FSharp.Core]Microsoft.FSharp.Core.Unit>> class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/ConcatEnumerator`2<!T,!U>::compensations
      IL_0012:  ret
    } // end of method ConcatEnumerator`2::Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers.IFinallyEnumerator.AppendFinallyAction

    .method private hidebysig newslot specialname virtual 
            instance !T  'System.Collections.Generic.IEnumerator<\'T>.get_Current'() cil managed
    {
      .override  method instance !0 class [mscorlib]System.Collections.Generic.IEnumerator`1<!T>::get_Current()
      // Code size       7 (0x7)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  callvirt   instance !0 class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/ConcatEnumerator`2<!T,!U>::GetCurrent()
      IL_0006:  ret
    } // end of method ConcatEnumerator`2::'System.Collections.Generic.IEnumerator<\'T>.get_Current'

    .method private hidebysig newslot specialname virtual 
            instance object  System.Collections.IEnumerator.get_Current() cil managed
    {
      .override [mscorlib]System.Collections.IEnumerator::get_Current
      // Code size       12 (0xc)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  callvirt   instance !0 class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/ConcatEnumerator`2<!T,!U>::GetCurrent()
      IL_0006:  box        !T
      IL_000b:  ret
    } // end of method ConcatEnumerator`2::System.Collections.IEnumerator.get_Current

    .method private hidebysig newslot virtual 
            instance bool  System.Collections.IEnumerator.MoveNext() cil managed
    {
      .custom instance void [mscorlib]System.Diagnostics.DebuggerStepThroughAttribute::.ctor() = ( 01 00 00 00 ) 
      .override [mscorlib]System.Collections.IEnumerator::MoveNext
      // Code size       41 (0x29)
      .maxstack  4
      .locals init (class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/ConcatEnumerator`2<!T,!U> V_0)
      IL_0000:  ldarg.0
      IL_0001:  ldfld      bool class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/ConcatEnumerator`2<!T,!U>::started
      IL_0006:  brfalse.s  IL_000a

      IL_0008:  br.s       IL_0013

      IL_000a:  ldarg.0
      IL_000b:  ldc.i4.1
      IL_000c:  stfld      bool class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/ConcatEnumerator`2<!T,!U>::started
      IL_0011:  br.s       IL_0013

      IL_0013:  ldarg.0
      IL_0014:  ldfld      bool class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/ConcatEnumerator`2<!T,!U>::finished
      IL_0019:  brfalse.s  IL_001d

      IL_001b:  ldc.i4.0
      IL_001c:  ret

      IL_001d:  ldarg.0
      IL_001e:  stloc.0
      IL_001f:  ldarg.0
      IL_0020:  ldnull
      IL_0021:  tail.
      IL_0023:  call       bool class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/ConcatEnumerator`2<!T,!U>::takeInner@301(class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/ConcatEnumerator`2<!0,!1>,
                                                                                                                                     class [FSharp.Core]Microsoft.FSharp.Core.Unit)
      IL_0028:  ret
    } // end of method ConcatEnumerator`2::System.Collections.IEnumerator.MoveNext

    .method private hidebysig newslot virtual 
            instance void  System.Collections.IEnumerator.Reset() cil managed
    {
      .override [mscorlib]System.Collections.IEnumerator::Reset
      // Code size       11 (0xb)
      .maxstack  8
      IL_0000:  ldstr      "SR.GetString(SR.resetNotSupported)"
      IL_0005:  newobj     instance void [mscorlib]System.NotSupportedException::.ctor(string)
      IL_000a:  throw
    } // end of method ConcatEnumerator`2::System.Collections.IEnumerator.Reset

    .method private hidebysig newslot virtual 
            instance void  System.IDisposable.Dispose() cil managed
    {
      .custom instance void [mscorlib]System.Diagnostics.DebuggerStepThroughAttribute::.ctor() = ( 01 00 00 00 ) 
      .override [mscorlib]System.IDisposable::Dispose
      // Code size       18 (0x12)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  ldfld      bool class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/ConcatEnumerator`2<!T,!U>::finished
      IL_0006:  brfalse.s  IL_000a

      IL_0008:  br.s       IL_0011

      IL_000a:  ldarg.0
      IL_000b:  callvirt   instance void class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/ConcatEnumerator`2<!T,!U>::Finish()
      IL_0010:  ret

      IL_0011:  ret
    } // end of method ConcatEnumerator`2::System.IDisposable.Dispose

    .method assembly static void  iter@272(class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [FSharp.Core]Microsoft.FSharp.Core.Unit>> comps) cil managed
    {
      // Code size       45 (0x2d)
      .maxstack  4
      .locals init (class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [FSharp.Core]Microsoft.FSharp.Core.Unit>> V_0,
               class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [FSharp.Core]Microsoft.FSharp.Core.Unit>> V_1,
               class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [FSharp.Core]Microsoft.FSharp.Core.Unit> V_2)
      IL_0000:  ldarg.0
      IL_0001:  call       instance class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<!0> class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [FSharp.Core]Microsoft.FSharp.Core.Unit>>::get_TailOrNull()
      IL_0006:  brfalse.s  IL_000a

      IL_0008:  br.s       IL_000b

      IL_000a:  ret

      IL_000b:  ldarg.0
      IL_000c:  stloc.0
      IL_000d:  ldloc.0
      IL_000e:  call       instance class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<!0> class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [FSharp.Core]Microsoft.FSharp.Core.Unit>>::get_TailOrNull()
      IL_0013:  stloc.1
      IL_0014:  ldloc.0
      IL_0015:  call       instance !0 class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [FSharp.Core]Microsoft.FSharp.Core.Unit>>::get_HeadOrDefault()
      IL_001a:  stloc.2
      .try
      {
        IL_001b:  ldloc.2
        IL_001c:  ldnull
        IL_001d:  callvirt   instance !1 class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [FSharp.Core]Microsoft.FSharp.Core.Unit>::Invoke(!0)
        IL_0022:  pop
        IL_0023:  leave.s    IL_002c

      }  // end .try
      finally
      {
        IL_0025:  ldloc.1
        IL_0026:  call       void class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/ConcatEnumerator`2<!T,!U>::iter@272(class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [FSharp.Core]Microsoft.FSharp.Core.Unit>>)
        IL_002b:  endfinally
      }  // end handler
      IL_002c:  ret
    } // end of method ConcatEnumerator`2::iter@272

    .method assembly static bool  takeOuter@308(class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/ConcatEnumerator`2<!T,!U> x,
                                                class [FSharp.Core]Microsoft.FSharp.Core.Unit unitVar0) cil managed
    {
      // Code size       100 (0x64)
      .maxstack  4
      .locals init (!U V_0,
               object V_1,
               class MyCollections.IEnumerator/EmptyEnumerable`1<!T> V_2,
               !U V_3)
      IL_0000:  ldarg.0
      IL_0001:  ldfld      class [mscorlib]System.Collections.Generic.IEnumerator`1<!1> class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/ConcatEnumerator`2<!T,!U>::outerEnum
      IL_0006:  callvirt   instance bool [mscorlib]System.Collections.IEnumerator::MoveNext()
      IL_000b:  brfalse.s  IL_005c

      IL_000d:  ldarg.0
      IL_000e:  ldfld      class [mscorlib]System.Collections.Generic.IEnumerator`1<!1> class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/ConcatEnumerator`2<!T,!U>::outerEnum
      IL_0013:  callvirt   instance !0 class [mscorlib]System.Collections.Generic.IEnumerator`1<!U>::get_Current()
      IL_0018:  stloc.0
      IL_0019:  ldloc.0
      IL_001a:  box        !U
      IL_001f:  stloc.1
      IL_0020:  ldloc.1
      IL_0021:  isinst     class MyCollections.IEnumerator/EmptyEnumerable`1<!T>
      IL_0026:  stloc.2
      IL_0027:  ldloc.2
      IL_0028:  brfalse.s  IL_0032

      IL_002a:  ldarg.0
      IL_002b:  ldnull
      IL_002c:  starg.s    unitVar0
      IL_002e:  starg.s    x
      IL_0030:  br.s       IL_0000

      IL_0032:  ldarg.0
      IL_0033:  ldfld      class [mscorlib]System.Collections.Generic.IEnumerator`1<!0> class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/ConcatEnumerator`2<!T,!U>::currInnerEnum
      IL_0038:  callvirt   instance void [mscorlib]System.IDisposable::Dispose()
      IL_003d:  ldarg.0
      IL_003e:  ldloc.0
      IL_003f:  stloc.3
      IL_0040:  ldloca.s   V_3
      IL_0042:  constrained. !U
      IL_0048:  callvirt   instance class [mscorlib]System.Collections.Generic.IEnumerator`1<!0> class [mscorlib]System.Collections.Generic.IEnumerable`1<!T>::GetEnumerator()
      IL_004d:  stfld      class [mscorlib]System.Collections.Generic.IEnumerator`1<!0> class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/ConcatEnumerator`2<!T,!U>::currInnerEnum
      IL_0052:  ldarg.0
      IL_0053:  ldnull
      IL_0054:  tail.
      IL_0056:  call       bool class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/ConcatEnumerator`2<!T,!U>::takeInner@301(class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/ConcatEnumerator`2<!0,!1>,
                                                                                                                                     class [FSharp.Core]Microsoft.FSharp.Core.Unit)
      IL_005b:  ret

      IL_005c:  ldarg.0
      IL_005d:  callvirt   instance void class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/ConcatEnumerator`2<!T,!U>::Finish()
      IL_0062:  ldc.i4.0
      IL_0063:  ret
    } // end of method ConcatEnumerator`2::takeOuter@308

    .method assembly static bool  takeInner@301(class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/ConcatEnumerator`2<!T,!U> x,
                                                class [FSharp.Core]Microsoft.FSharp.Core.Unit unitVar0) cil managed
    {
      // Code size       44 (0x2c)
      .maxstack  4
      .locals init (class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/ConcatEnumerator`2<!T,!U> V_0)
      IL_0000:  ldarg.0
      IL_0001:  ldfld      class [mscorlib]System.Collections.Generic.IEnumerator`1<!0> class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/ConcatEnumerator`2<!T,!U>::currInnerEnum
      IL_0006:  callvirt   instance bool [mscorlib]System.Collections.IEnumerator::MoveNext()
      IL_000b:  brfalse.s  IL_0020

      IL_000d:  ldarg.0
      IL_000e:  ldarg.0
      IL_000f:  ldfld      class [mscorlib]System.Collections.Generic.IEnumerator`1<!0> class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/ConcatEnumerator`2<!T,!U>::currInnerEnum
      IL_0014:  callvirt   instance !0 class [mscorlib]System.Collections.Generic.IEnumerator`1<!T>::get_Current()
      IL_0019:  stfld      !0 class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/ConcatEnumerator`2<!T,!U>::currElement
      IL_001e:  ldc.i4.1
      IL_001f:  ret

      IL_0020:  ldarg.0
      IL_0021:  stloc.0
      IL_0022:  ldarg.0
      IL_0023:  ldnull
      IL_0024:  tail.
      IL_0026:  call       bool class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/ConcatEnumerator`2<!T,!U>::takeOuter@308(class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/ConcatEnumerator`2<!0,!1>,
                                                                                                                                     class [FSharp.Core]Microsoft.FSharp.Core.Unit)
      IL_002b:  ret
    } // end of method ConcatEnumerator`2::takeInner@301

  } // end of class ConcatEnumerator`2

  .method public static class [mscorlib]System.Collections.Generic.IEnumerable`1<!!T> 
          Generate<a,T>(class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,!!a> openf,
                        class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<!!a,class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!!T>> compute,
                        class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<!!a,class [FSharp.Core]Microsoft.FSharp.Core.Unit> closef) cil managed
  {
    .custom instance void [FSharp.Core]Microsoft.FSharp.Core.CompilationArgumentCountsAttribute::.ctor(int32[]) = ( 01 00 03 00 00 00 01 00 00 00 01 00 00 00 01 00 
                                                                                                                    00 00 00 00 ) 
    // Code size       14 (0xe)
    .maxstack  8
    IL_0000:  ldarg.0
    IL_0001:  ldarg.1
    IL_0002:  ldarg.2
    IL_0003:  newobj     instance void class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/Generate@200<!!a,!!T>::.ctor(class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,!0>,
                                                                                                                                class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<!0,class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!1>>,
                                                                                                                                class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<!0,class [FSharp.Core]Microsoft.FSharp.Core.Unit>)
    IL_0008:  call       class [mscorlib]System.Collections.Generic.IEnumerable`1<!0> class MyCollections.IEnumerator<!!1>::mkSeq<!!1>(class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [mscorlib]System.Collections.Generic.IEnumerator`1<!0>>)
    IL_000d:  ret
  } // end of method RuntimeHelpers::Generate

  .method public static class [mscorlib]System.Collections.Generic.IEnumerable`1<!!b> 
          EnumerateFromFunctions<a,b>(class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,!!a> create,
                                      class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<!!a,bool> moveNext,
                                      class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<!!a,!!b> current) cil managed
  {
    .custom instance void [FSharp.Core]Microsoft.FSharp.Core.CompilationArgumentCountsAttribute::.ctor(int32[]) = ( 01 00 03 00 00 00 01 00 00 00 01 00 00 00 01 00 
                                                                                                                    00 00 00 00 ) 
    // Code size       19 (0x13)
    .maxstack  8
    IL_0000:  ldarg.0
    IL_0001:  ldarg.1
    IL_0002:  ldarg.2
    IL_0003:  newobj     instance void class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/EnumerateFromFunctions@205<!!a,!!b>::.ctor(class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<!0,bool>,
                                                                                                                                              class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<!0,!1>)
    IL_0008:  ldsfld     class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/'EnumerateFromFunctions@206-1'<!0> class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers/'EnumerateFromFunctions@206-1'<!!a>::@_instance
    IL_000d:  call       class [mscorlib]System.Collections.Generic.IEnumerable`1<!!1> Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers::Generate<!!0,!!1>(class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,!!0>,
                                                                                                                                                                class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<!!0,class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!!1>>,
                                                                                                                                                                class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<!!0,class [FSharp.Core]Microsoft.FSharp.Core.Unit>)
    IL_0012:  ret
  } // end of method RuntimeHelpers::EnumerateFromFunctions

} // end of class Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers

.class private abstract auto ansi sealed MyCollections.IEnumerator
       extends [mscorlib]System.Object
{
  .custom instance void [FSharp.Core]Microsoft.FSharp.Core.CompilationMappingAttribute::.ctor(valuetype [FSharp.Core]Microsoft.FSharp.Core.SourceConstructFlags) = ( 01 00 07 00 00 00 00 00 ) 
  .class auto autochar serializable sealed nested assembly beforefieldinit specialname cast@21<T>
         extends [mscorlib]System.Object
         implements [mscorlib]System.Collections.IEnumerator,
                    [mscorlib]System.IDisposable,
                    class [mscorlib]System.Collections.Generic.IEnumerator`1<!T>
  {
    .custom instance void [FSharp.Core]Microsoft.FSharp.Core.CompilationMappingAttribute::.ctor(valuetype [FSharp.Core]Microsoft.FSharp.Core.SourceConstructFlags) = ( 01 00 06 00 00 00 00 00 ) 
    .field public class [mscorlib]System.Collections.IEnumerator e
    .method public specialname rtspecialname 
            instance void  .ctor(class [mscorlib]System.Collections.IEnumerator e) cil managed
    {
      // Code size       16 (0x10)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  ldarg.1
      IL_0002:  stfld      class [mscorlib]System.Collections.IEnumerator class MyCollections.IEnumerator/cast@21<!T>::e
      IL_0007:  ldarg.0
      IL_0008:  callvirt   instance void [mscorlib]System.Object::.ctor()
      IL_000d:  ldarg.0
      IL_000e:  pop
      IL_000f:  ret
    } // end of method cast@21::.ctor

    .method private hidebysig newslot virtual final 
            instance !T  'System.Collections.Generic.IEnumerator<\'T>.get_Current'() cil managed
    {
      .override  method instance !0 class [mscorlib]System.Collections.Generic.IEnumerator`1<!T>::get_Current()
      // Code size       19 (0x13)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  ldfld      class [mscorlib]System.Collections.IEnumerator class MyCollections.IEnumerator/cast@21<!T>::e
      IL_0006:  callvirt   instance object [mscorlib]System.Collections.IEnumerator::get_Current()
      IL_000b:  tail.
      IL_000d:  call       !0 class [FSharp.Core]Microsoft.FSharp.Core.LanguagePrimitives/IntrinsicFunctions<!T>::UnboxGeneric<!0>(object)
      IL_0012:  ret
    } // end of method cast@21::'System.Collections.Generic.IEnumerator<\'T>.get_Current'

    .method private hidebysig newslot virtual final 
            instance object  System.Collections.IEnumerator.get_Current() cil managed
    {
      .override [mscorlib]System.Collections.IEnumerator::get_Current
      // Code size       22 (0x16)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  ldfld      class [mscorlib]System.Collections.IEnumerator class MyCollections.IEnumerator/cast@21<!T>::e
      IL_0006:  callvirt   instance object [mscorlib]System.Collections.IEnumerator::get_Current()
      IL_000b:  call       !0 class [FSharp.Core]Microsoft.FSharp.Core.LanguagePrimitives/IntrinsicFunctions<!T>::UnboxGeneric<!0>(object)
      IL_0010:  box        !T
      IL_0015:  ret
    } // end of method cast@21::System.Collections.IEnumerator.get_Current

    .method private hidebysig newslot virtual final 
            instance bool  System.Collections.IEnumerator.MoveNext() cil managed
    {
      .custom instance void [mscorlib]System.Diagnostics.DebuggerStepThroughAttribute::.ctor() = ( 01 00 00 00 ) 
      .override [mscorlib]System.Collections.IEnumerator::MoveNext
      // Code size       14 (0xe)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  ldfld      class [mscorlib]System.Collections.IEnumerator class MyCollections.IEnumerator/cast@21<!T>::e
      IL_0006:  tail.
      IL_0008:  callvirt   instance bool [mscorlib]System.Collections.IEnumerator::MoveNext()
      IL_000d:  ret
    } // end of method cast@21::System.Collections.IEnumerator.MoveNext

    .method private hidebysig newslot virtual final 
            instance void  System.Collections.IEnumerator.Reset() cil managed
    {
      .override [mscorlib]System.Collections.IEnumerator::Reset
      // Code size       11 (0xb)
      .maxstack  8
      IL_0000:  ldstr      "SR.GetString(SR.resetNotSupported)"
      IL_0005:  newobj     instance void [mscorlib]System.NotSupportedException::.ctor(string)
      IL_000a:  throw
    } // end of method cast@21::System.Collections.IEnumerator.Reset

    .method private hidebysig newslot virtual final 
            instance void  System.IDisposable.Dispose() cil managed
    {
      .override [mscorlib]System.IDisposable::Dispose
      // Code size       27 (0x1b)
      .maxstack  5
      .locals init (class [mscorlib]System.IDisposable V_0,
               class [mscorlib]System.IDisposable V_1)
      IL_0000:  ldarg.0
      IL_0001:  ldfld      class [mscorlib]System.Collections.IEnumerator class MyCollections.IEnumerator/cast@21<!T>::e
      IL_0006:  isinst     [mscorlib]System.IDisposable
      IL_000b:  stloc.0
      IL_000c:  ldloc.0
      IL_000d:  brfalse.s  IL_001a

      IL_000f:  ldloc.0
      IL_0010:  stloc.1
      IL_0011:  ldloc.1
      IL_0012:  tail.
      IL_0014:  callvirt   instance void [mscorlib]System.IDisposable::Dispose()
      IL_0019:  ret

      IL_001a:  ret
    } // end of method cast@21::System.IDisposable.Dispose

  } // end of class cast@21

  .class auto ansi serializable sealed nested public EmptyEnumerator`1<T>
         extends [mscorlib]System.Object
         implements [mscorlib]System.IDisposable,
                    [mscorlib]System.Collections.IEnumerator,
                    class [mscorlib]System.Collections.Generic.IEnumerator`1<!T>
  {
    .custom instance void [FSharp.Core]Microsoft.FSharp.Core.SealedAttribute::.ctor() = ( 01 00 00 00 ) 
    .custom instance void [FSharp.Core]Microsoft.FSharp.Core.CompilationMappingAttribute::.ctor(valuetype [FSharp.Core]Microsoft.FSharp.Core.SourceConstructFlags) = ( 01 00 03 00 00 00 00 00 ) 
    .field assembly bool started
    .method public specialname rtspecialname 
            instance void  .ctor() cil managed
    {
      // Code size       16 (0x10)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  callvirt   instance void [mscorlib]System.Object::.ctor()
      IL_0006:  ldarg.0
      IL_0007:  pop
      IL_0008:  ldarg.0
      IL_0009:  ldc.i4.0
      IL_000a:  stfld      bool class MyCollections.IEnumerator/EmptyEnumerator`1<!T>::started
      IL_000f:  ret
    } // end of method EmptyEnumerator`1::.ctor

    .method private hidebysig newslot specialname virtual 
            instance !T  'System.Collections.Generic.IEnumerator<\'T>.get_Current'() cil managed
    {
      .override  method instance !0 class [mscorlib]System.Collections.Generic.IEnumerator`1<!T>::get_Current()
      // Code size       22 (0x16)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  ldfld      bool class MyCollections.IEnumerator/EmptyEnumerator`1<!T>::started
      IL_0006:  call       void class MyCollections.IEnumerator<!T>::check(bool)
      IL_000b:  ldstr      "SR.GetString(SR.enumerationAlreadyFinished)"
      IL_0010:  newobj     instance void [mscorlib]System.InvalidOperationException::.ctor(string)
      IL_0015:  throw
    } // end of method EmptyEnumerator`1::'System.Collections.Generic.IEnumerator<\'T>.get_Current'

    .method private hidebysig newslot specialname virtual 
            instance object  System.Collections.IEnumerator.get_Current() cil managed
    {
      .override [mscorlib]System.Collections.IEnumerator::get_Current
      // Code size       22 (0x16)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  ldfld      bool class MyCollections.IEnumerator/EmptyEnumerator`1<!T>::started
      IL_0006:  call       void class MyCollections.IEnumerator<!T>::check(bool)
      IL_000b:  ldstr      "SR.GetString(SR.enumerationAlreadyFinished)"
      IL_0010:  newobj     instance void [mscorlib]System.InvalidOperationException::.ctor(string)
      IL_0015:  throw
    } // end of method EmptyEnumerator`1::System.Collections.IEnumerator.get_Current

    .method private hidebysig newslot virtual 
            instance bool  System.Collections.IEnumerator.MoveNext() cil managed
    {
      .custom instance void [mscorlib]System.Diagnostics.DebuggerStepThroughAttribute::.ctor() = ( 01 00 00 00 ) 
      .override [mscorlib]System.Collections.IEnumerator::MoveNext
      // Code size       21 (0x15)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  ldfld      bool class MyCollections.IEnumerator/EmptyEnumerator`1<!T>::started
      IL_0006:  brfalse.s  IL_000a

      IL_0008:  br.s       IL_0013

      IL_000a:  ldarg.0
      IL_000b:  ldc.i4.1
      IL_000c:  stfld      bool class MyCollections.IEnumerator/EmptyEnumerator`1<!T>::started
      IL_0011:  br.s       IL_0013

      IL_0013:  ldc.i4.0
      IL_0014:  ret
    } // end of method EmptyEnumerator`1::System.Collections.IEnumerator.MoveNext

    .method private hidebysig newslot virtual 
            instance void  System.Collections.IEnumerator.Reset() cil managed
    {
      .override [mscorlib]System.Collections.IEnumerator::Reset
      // Code size       11 (0xb)
      .maxstack  8
      IL_0000:  ldstr      "SR.GetString(SR.resetNotSupported)"
      IL_0005:  newobj     instance void [mscorlib]System.NotSupportedException::.ctor(string)
      IL_000a:  throw
    } // end of method EmptyEnumerator`1::System.Collections.IEnumerator.Reset

    .method private hidebysig newslot virtual 
            instance void  System.IDisposable.Dispose() cil managed
    {
      .override [mscorlib]System.IDisposable::Dispose
      // Code size       1 (0x1)
      .maxstack  8
      IL_0000:  ret
    } // end of method EmptyEnumerator`1::System.IDisposable.Dispose

  } // end of class EmptyEnumerator`1

  .class auto autochar serializable sealed nested public beforefieldinit EmptyEnumerable`1<T>
         extends [mscorlib]System.Object
         implements [mscorlib]System.Collections.IEnumerable,
                    class [mscorlib]System.Collections.Generic.IEnumerable`1<!T>
  {
    .custom instance void [FSharp.Core]Microsoft.FSharp.Core.NoEqualityAttribute::.ctor() = ( 01 00 00 00 ) 
    .custom instance void [FSharp.Core]Microsoft.FSharp.Core.NoComparisonAttribute::.ctor() = ( 01 00 00 00 ) 
    .custom instance void [mscorlib]System.Diagnostics.DebuggerDisplayAttribute::.ctor(string) = ( 01 00 15 7B 5F 5F 44 65 62 75 67 44 69 73 70 6C   // ...{__DebugDispl
                                                                                                   61 79 28 29 2C 6E 71 7D 00 00 )                   // ay(),nq}..
    .custom instance void [FSharp.Core]Microsoft.FSharp.Core.CompilationMappingAttribute::.ctor(valuetype [FSharp.Core]Microsoft.FSharp.Core.SourceConstructFlags) = ( 01 00 21 00 00 00 00 00 )                         // ..!.....
    .field static assembly initonly class MyCollections.IEnumerator/EmptyEnumerable`1<!T> _unique_EmptyEnumerable
    .custom instance void [mscorlib]System.Diagnostics.DebuggerBrowsableAttribute::.ctor(valuetype [mscorlib]System.Diagnostics.DebuggerBrowsableState) = ( 01 00 00 00 00 00 00 00 ) 
    .custom instance void [mscorlib]System.Runtime.CompilerServices.CompilerGeneratedAttribute::.ctor() = ( 01 00 00 00 ) 
    .custom instance void [mscorlib]System.Diagnostics.DebuggerNonUserCodeAttribute::.ctor() = ( 01 00 00 00 ) 
    .method private specialname rtspecialname static 
            void  .cctor() cil managed
    {
      // Code size       11 (0xb)
      .maxstack  8
      IL_0000:  newobj     instance void class MyCollections.IEnumerator/EmptyEnumerable`1<!T>::.ctor()
      IL_0005:  stsfld     class MyCollections.IEnumerator/EmptyEnumerable`1<!0> class MyCollections.IEnumerator/EmptyEnumerable`1<!T>::_unique_EmptyEnumerable
      IL_000a:  ret
    } // end of method EmptyEnumerable`1::.cctor

    .method assembly specialname rtspecialname 
            instance void  .ctor() cil managed
    {
      .custom instance void System.Diagnostics.CodeAnalysis.DynamicDependencyAttribute::.ctor(valuetype System.Diagnostics.CodeAnalysis.DynamicallyAccessedMemberTypes,
                                                                                              class [mscorlib]System.Type) = ( 01 00 E0 07 00 00 2B 4D 79 43 6F 6C 6C 65 63 74   // ......+MyCollect
                                                                                                                               69 6F 6E 73 2E 49 45 6E 75 6D 65 72 61 74 6F 72   // ions.IEnumerator
                                                                                                                               2B 45 6D 70 74 79 45 6E 75 6D 65 72 61 62 6C 65   // +EmptyEnumerable
                                                                                                                               60 31 00 00 )                                     // `1..
      .custom instance void [mscorlib]System.Runtime.CompilerServices.CompilerGeneratedAttribute::.ctor() = ( 01 00 00 00 ) 
      .custom instance void [mscorlib]System.Diagnostics.DebuggerNonUserCodeAttribute::.ctor() = ( 01 00 00 00 ) 
      // Code size       7 (0x7)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  call       instance void [mscorlib]System.Object::.ctor()
      IL_0006:  ret
    } // end of method EmptyEnumerable`1::.ctor

    .method assembly static class MyCollections.IEnumerator/EmptyEnumerable`1<!T> 
            get_EmptyEnumerable() cil managed
    {
      .custom instance void [FSharp.Core]Microsoft.FSharp.Core.CompilationMappingAttribute::.ctor(valuetype [FSharp.Core]Microsoft.FSharp.Core.SourceConstructFlags,
                                                                                                  int32) = ( 01 00 08 00 00 00 00 00 00 00 00 00 ) 
      .custom instance void [mscorlib]System.Runtime.CompilerServices.CompilerGeneratedAttribute::.ctor() = ( 01 00 00 00 ) 
      .custom instance void [mscorlib]System.Diagnostics.DebuggerNonUserCodeAttribute::.ctor() = ( 01 00 00 00 ) 
      // Code size       6 (0x6)
      .maxstack  8
      IL_0000:  ldsfld     class MyCollections.IEnumerator/EmptyEnumerable`1<!0> class MyCollections.IEnumerator/EmptyEnumerable`1<!T>::_unique_EmptyEnumerable
      IL_0005:  ret
    } // end of method EmptyEnumerable`1::get_EmptyEnumerable

    .method assembly hidebysig instance int32 
            get_Tag() cil managed
    {
      .custom instance void [mscorlib]System.Runtime.CompilerServices.CompilerGeneratedAttribute::.ctor() = ( 01 00 00 00 ) 
      .custom instance void [mscorlib]System.Diagnostics.DebuggerNonUserCodeAttribute::.ctor() = ( 01 00 00 00 ) 
      // Code size       4 (0x4)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  pop
      IL_0002:  ldc.i4.0
      IL_0003:  ret
    } // end of method EmptyEnumerable`1::get_Tag

    .method assembly hidebysig specialname 
            instance object  __DebugDisplay() cil managed
    {
      .custom instance void [mscorlib]System.Runtime.CompilerServices.CompilerGeneratedAttribute::.ctor() = ( 01 00 00 00 ) 
      .custom instance void [mscorlib]System.Diagnostics.DebuggerNonUserCodeAttribute::.ctor() = ( 01 00 00 00 ) 
      // Code size       22 (0x16)
      .maxstack  8
      IL_0000:  ldstr      "%+0.8A"
      IL_0005:  newobj     instance void class [FSharp.Core]Microsoft.FSharp.Core.PrintfFormat`5<class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class MyCollections.IEnumerator/EmptyEnumerable`1<!T>,string>,class [FSharp.Core]Microsoft.FSharp.Core.Unit,string,string,string>::.ctor(string)
      IL_000a:  call       !!0 [FSharp.Core]Microsoft.FSharp.Core.ExtraTopLevelOperators::PrintFormatToString<class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class MyCollections.IEnumerator/EmptyEnumerable`1<!T>,string>>(class [FSharp.Core]Microsoft.FSharp.Core.PrintfFormat`4<!!0,class [FSharp.Core]Microsoft.FSharp.Core.Unit,string,string>)
      IL_000f:  ldarg.0
      IL_0010:  callvirt   instance !1 class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class MyCollections.IEnumerator/EmptyEnumerable`1<!T>,string>::Invoke(!0)
      IL_0015:  ret
    } // end of method EmptyEnumerable`1::__DebugDisplay

    .method public strict virtual instance string 
            ToString() cil managed
    {
      .custom instance void [mscorlib]System.Runtime.CompilerServices.CompilerGeneratedAttribute::.ctor() = ( 01 00 00 00 ) 
      // Code size       22 (0x16)
      .maxstack  8
      IL_0000:  ldstr      "%+A"
      IL_0005:  newobj     instance void class [FSharp.Core]Microsoft.FSharp.Core.PrintfFormat`5<class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class MyCollections.IEnumerator/EmptyEnumerable`1<!T>,string>,class [FSharp.Core]Microsoft.FSharp.Core.Unit,string,string,class MyCollections.IEnumerator/EmptyEnumerable`1<!T>>::.ctor(string)
      IL_000a:  call       !!0 [FSharp.Core]Microsoft.FSharp.Core.ExtraTopLevelOperators::PrintFormatToString<class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class MyCollections.IEnumerator/EmptyEnumerable`1<!T>,string>>(class [FSharp.Core]Microsoft.FSharp.Core.PrintfFormat`4<!!0,class [FSharp.Core]Microsoft.FSharp.Core.Unit,string,string>)
      IL_000f:  ldarg.0
      IL_0010:  callvirt   instance !1 class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class MyCollections.IEnumerator/EmptyEnumerable`1<!T>,string>::Invoke(!0)
      IL_0015:  ret
    } // end of method EmptyEnumerable`1::ToString

    .method private hidebysig newslot virtual 
            instance class [mscorlib]System.Collections.Generic.IEnumerator`1<!T> 
            'System.Collections.Generic.IEnumerable<\'T>.GetEnumerator'() cil managed
    {
      .override  method instance class [mscorlib]System.Collections.Generic.IEnumerator`1<!0> class [mscorlib]System.Collections.Generic.IEnumerable`1<!T>::GetEnumerator()
      // Code size       6 (0x6)
      .maxstack  8
      IL_0000:  newobj     instance void class MyCollections.IEnumerator/EmptyEnumerator`1<!T>::.ctor()
      IL_0005:  ret
    } // end of method EmptyEnumerable`1::'System.Collections.Generic.IEnumerable<\'T>.GetEnumerator'

    .method private hidebysig newslot virtual 
            instance class [mscorlib]System.Collections.IEnumerator 
            System.Collections.IEnumerable.GetEnumerator() cil managed
    {
      .override [mscorlib]System.Collections.IEnumerable::GetEnumerator
      // Code size       6 (0x6)
      .maxstack  8
      IL_0000:  newobj     instance void class MyCollections.IEnumerator/EmptyEnumerator`1<!T>::.ctor()
      IL_0005:  ret
    } // end of method EmptyEnumerable`1::System.Collections.IEnumerable.GetEnumerator

    .property instance int32 Tag()
    {
      .custom instance void [mscorlib]System.Runtime.CompilerServices.CompilerGeneratedAttribute::.ctor() = ( 01 00 00 00 ) 
      .custom instance void [mscorlib]System.Diagnostics.DebuggerNonUserCodeAttribute::.ctor() = ( 01 00 00 00 ) 
      .custom instance void [mscorlib]System.Diagnostics.DebuggerBrowsableAttribute::.ctor(valuetype [mscorlib]System.Diagnostics.DebuggerBrowsableState) = ( 01 00 00 00 00 00 00 00 ) 
      .get instance int32 MyCollections.IEnumerator/EmptyEnumerable`1::get_Tag()
    } // end of property EmptyEnumerable`1::Tag
    .property class MyCollections.IEnumerator/EmptyEnumerable`1<!T>
            EmptyEnumerable()
    {
      .custom instance void [mscorlib]System.Runtime.CompilerServices.CompilerGeneratedAttribute::.ctor() = ( 01 00 00 00 ) 
      .custom instance void [mscorlib]System.Diagnostics.DebuggerNonUserCodeAttribute::.ctor() = ( 01 00 00 00 ) 
      .custom instance void [mscorlib]System.Diagnostics.DebuggerBrowsableAttribute::.ctor(valuetype [mscorlib]System.Diagnostics.DebuggerBrowsableState) = ( 01 00 00 00 00 00 00 00 ) 
      .get class MyCollections.IEnumerator/EmptyEnumerable`1<!T> MyCollections.IEnumerator/EmptyEnumerable`1::get_EmptyEnumerable()
    } // end of property EmptyEnumerable`1::EmptyEnumerable
  } // end of class EmptyEnumerable`1

  .class auto ansi serializable nested public GeneratedEnumerable`2<T,State>
         extends [mscorlib]System.Object
         implements [mscorlib]System.IDisposable,
                    [mscorlib]System.Collections.IEnumerator,
                    class [mscorlib]System.Collections.Generic.IEnumerator`1<!T>
  {
    .custom instance void [FSharp.Core]Microsoft.FSharp.Core.CompilationMappingAttribute::.ctor(valuetype [FSharp.Core]Microsoft.FSharp.Core.SourceConstructFlags) = ( 01 00 03 00 00 00 00 00 ) 
    .field assembly class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<!State,class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!T>> compute
    .field assembly class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<!State,class [FSharp.Core]Microsoft.FSharp.Core.Unit> closef
    .field assembly bool started
    .field assembly class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!T> curr
    .field assembly class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!State>> state
    .method public specialname rtspecialname 
            instance void  .ctor(class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,!State> openf,
                                 class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<!State,class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!T>> compute,
                                 class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<!State,class [FSharp.Core]Microsoft.FSharp.Core.Unit> closef) cil managed
    {
      // Code size       62 (0x3e)
      .maxstack  5
      .locals init (!State V_0)
      IL_0000:  ldarg.0
      IL_0001:  callvirt   instance void [mscorlib]System.Object::.ctor()
      IL_0006:  ldarg.0
      IL_0007:  pop
      IL_0008:  ldarg.0
      IL_0009:  ldarg.2
      IL_000a:  stfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<!1,class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!0>> class MyCollections.IEnumerator/GeneratedEnumerable`2<!T,!State>::compute
      IL_000f:  ldarg.0
      IL_0010:  ldarg.3
      IL_0011:  stfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<!1,class [FSharp.Core]Microsoft.FSharp.Core.Unit> class MyCollections.IEnumerator/GeneratedEnumerable`2<!T,!State>::closef
      IL_0016:  ldarg.0
      IL_0017:  ldc.i4.0
      IL_0018:  stfld      bool class MyCollections.IEnumerator/GeneratedEnumerable`2<!T,!State>::started
      IL_001d:  ldarg.0
      IL_001e:  ldnull
      IL_001f:  stfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!0> class MyCollections.IEnumerator/GeneratedEnumerable`2<!T,!State>::curr
      IL_0024:  ldarg.0
      IL_0025:  ldarg.1
      IL_0026:  ldnull
      IL_0027:  callvirt   instance !1 class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,!State>::Invoke(!0)
      IL_002c:  stloc.0
      IL_002d:  ldloc.0
      IL_002e:  call       class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!0> class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!State>::Some(!0)
      IL_0033:  newobj     instance void class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!State>>::.ctor(!0)
      IL_0038:  stfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!1>> class MyCollections.IEnumerator/GeneratedEnumerable`2<!T,!State>::state
      IL_003d:  ret
    } // end of method GeneratedEnumerable`2::.ctor

    .method private hidebysig newslot specialname virtual 
            instance !T  'System.Collections.Generic.IEnumerator<\'T>.get_Current'() cil managed
    {
      .override  method instance !0 class [mscorlib]System.Collections.Generic.IEnumerator`1<!T>::get_Current()
      // Code size       7 (0x7)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  callvirt   instance !0 class MyCollections.IEnumerator/GeneratedEnumerable`2<!T,!State>::getCurr()
      IL_0006:  ret
    } // end of method GeneratedEnumerable`2::'System.Collections.Generic.IEnumerator<\'T>.get_Current'

    .method private hidebysig newslot specialname virtual 
            instance object  System.Collections.IEnumerator.get_Current() cil managed
    {
      .override [mscorlib]System.Collections.IEnumerator::get_Current
      // Code size       12 (0xc)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  callvirt   instance !0 class MyCollections.IEnumerator/GeneratedEnumerable`2<!T,!State>::getCurr()
      IL_0006:  box        !T
      IL_000b:  ret
    } // end of method GeneratedEnumerable`2::System.Collections.IEnumerator.get_Current

    .method private hidebysig newslot virtual 
            instance bool  System.Collections.IEnumerator.MoveNext() cil managed
    {
      .custom instance void [mscorlib]System.Diagnostics.DebuggerStepThroughAttribute::.ctor() = ( 01 00 00 00 ) 
      .override [mscorlib]System.Collections.IEnumerator::MoveNext
      // Code size       100 (0x64)
      .maxstack  4
      .locals init (class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!State> V_0,
               class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!State> V_1,
               !State V_2,
               class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!T> V_3,
               class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!T> V_4,
               class [mscorlib]System.Exception V_5)
      IL_0000:  ldarg.0
      IL_0001:  callvirt   instance void class MyCollections.IEnumerator/GeneratedEnumerable`2<!T,!State>::start()
      IL_0006:  ldarg.0
      IL_0007:  ldfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!1>> class MyCollections.IEnumerator/GeneratedEnumerable`2<!T,!State>::state
      IL_000c:  call       instance !0 class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!State>>::get_contents()
      IL_0011:  stloc.0
      IL_0012:  ldloc.0
      IL_0013:  brfalse.s  IL_0017

      IL_0015:  br.s       IL_0019

      IL_0017:  ldc.i4.0
      IL_0018:  ret

      IL_0019:  ldloc.0
      IL_001a:  stloc.1
      IL_001b:  ldloc.1
      IL_001c:  call       instance !0 class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!State>::get_Value()
      IL_0021:  stloc.2
      .try
      {
        IL_0022:  ldarg.0
        IL_0023:  ldfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<!1,class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!0>> class MyCollections.IEnumerator/GeneratedEnumerable`2<!T,!State>::compute
        IL_0028:  ldloc.2
        IL_0029:  callvirt   instance !1 class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<!State,class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!T>>::Invoke(!0)
        IL_002e:  stloc.s    V_4
        IL_0030:  leave.s    IL_004b

      }  // end .try
      catch [mscorlib]System.Object 
      {
        IL_0032:  castclass  [mscorlib]System.Exception
        IL_0037:  stloc.s    V_5
        IL_0039:  ldarg.0
        IL_003a:  callvirt   instance void class MyCollections.IEnumerator/GeneratedEnumerable`2<!T,!State>::finish()
        IL_003f:  rethrow
        IL_0041:  ldnull
        IL_0042:  unbox.any  class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!T>
        IL_0047:  stloc.s    V_4
        IL_0049:  leave.s    IL_004b

      }  // end handler
      IL_004b:  ldloc.s    V_4
      IL_004d:  stloc.3
      IL_004e:  ldloc.3
      IL_004f:  brfalse.s  IL_0053

      IL_0051:  br.s       IL_005b

      IL_0053:  ldarg.0
      IL_0054:  callvirt   instance void class MyCollections.IEnumerator/GeneratedEnumerable`2<!T,!State>::finish()
      IL_0059:  ldc.i4.0
      IL_005a:  ret

      IL_005b:  ldarg.0
      IL_005c:  ldloc.3
      IL_005d:  stfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!0> class MyCollections.IEnumerator/GeneratedEnumerable`2<!T,!State>::curr
      IL_0062:  ldc.i4.1
      IL_0063:  ret
    } // end of method GeneratedEnumerable`2::System.Collections.IEnumerator.MoveNext

    .method private hidebysig newslot virtual 
            instance void  System.Collections.IEnumerator.Reset() cil managed
    {
      .override [mscorlib]System.Collections.IEnumerator::Reset
      // Code size       11 (0xb)
      .maxstack  8
      IL_0000:  ldstr      "SR.GetString(SR.resetNotSupported)"
      IL_0005:  newobj     instance void [mscorlib]System.NotSupportedException::.ctor(string)
      IL_000a:  throw
    } // end of method GeneratedEnumerable`2::System.Collections.IEnumerator.Reset

    .method private hidebysig newslot virtual 
            instance void  System.IDisposable.Dispose() cil managed
    {
      .override [mscorlib]System.IDisposable::Dispose
      // Code size       9 (0x9)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  tail.
      IL_0003:  callvirt   instance void class MyCollections.IEnumerator/GeneratedEnumerable`2<!T,!State>::dispose()
      IL_0008:  ret
    } // end of method GeneratedEnumerable`2::System.IDisposable.Dispose

    .method public hidebysig instance !T 
            getCurr() cil managed
    {
      .custom instance void [mscorlib]System.Runtime.CompilerServices.CompilerGeneratedAttribute::.ctor() = ( 01 00 00 00 ) 
      // Code size       41 (0x29)
      .maxstack  3
      .locals init (class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!T> V_0)
      IL_0000:  ldarg.0
      IL_0001:  ldfld      bool class MyCollections.IEnumerator/GeneratedEnumerable`2<!T,!State>::started
      IL_0006:  call       void class MyCollections.IEnumerator<!T,!State>::check(bool)
      IL_000b:  ldarg.0
      IL_000c:  ldfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!0> class MyCollections.IEnumerator/GeneratedEnumerable`2<!T,!State>::curr
      IL_0011:  stloc.0
      IL_0012:  ldloc.0
      IL_0013:  brfalse.s  IL_0017

      IL_0015:  br.s       IL_0022

      IL_0017:  ldstr      "SR.GetString(SR.enumerationAlreadyFinished)"
      IL_001c:  newobj     instance void [mscorlib]System.InvalidOperationException::.ctor(string)
      IL_0021:  throw

      IL_0022:  ldloc.0
      IL_0023:  call       instance !0 class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!T>::get_Value()
      IL_0028:  ret
    } // end of method GeneratedEnumerable`2::getCurr

    .method public hidebysig instance class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!State> 
            readAndClear() cil managed
    {
      .custom instance void [mscorlib]System.Runtime.CompilerServices.CompilerGeneratedAttribute::.ctor() = ( 01 00 00 00 ) 
      // Code size       67 (0x43)
      .maxstack  4
      .locals init (class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!State>> V_0,
               bool V_1,
               class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!State> V_2,
               class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!State> V_3)
      IL_0000:  ldarg.0
      IL_0001:  ldfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!1>> class MyCollections.IEnumerator/GeneratedEnumerable`2<!T,!State>::state
      IL_0006:  stloc.0
      IL_0007:  ldc.i4.0
      IL_0008:  stloc.1
      .try
      {
        IL_0009:  ldloc.0
        IL_000a:  ldloca.s   V_1
        IL_000c:  call       void [netstandard]System.Threading.Monitor::Enter(object,
                                                                               bool&)
        IL_0011:  ldarg.0
        IL_0012:  ldfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!1>> class MyCollections.IEnumerator/GeneratedEnumerable`2<!T,!State>::state
        IL_0017:  call       instance !0 class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!State>>::get_contents()
        IL_001c:  stloc.3
        IL_001d:  ldloc.3
        IL_001e:  brfalse.s  IL_0022

        IL_0020:  br.s       IL_0026

        IL_0022:  ldnull
        IL_0023:  stloc.2
        IL_0024:  leave.s    IL_0041

        IL_0026:  ldarg.0
        IL_0027:  ldfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!1>> class MyCollections.IEnumerator/GeneratedEnumerable`2<!T,!State>::state
        IL_002c:  ldnull
        IL_002d:  call       instance void class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!State>>::set_contents(!0)
        IL_0032:  ldloc.3
        IL_0033:  stloc.2
        IL_0034:  leave.s    IL_0041

      }  // end .try
      finally
      {
        IL_0036:  ldloc.1
        IL_0037:  brfalse.s  IL_0040

        IL_0039:  ldloc.0
        IL_003a:  call       void [netstandard]System.Threading.Monitor::Exit(object)
        IL_003f:  endfinally
        IL_0040:  endfinally
      }  // end handler
      IL_0041:  ldloc.2
      IL_0042:  ret
    } // end of method GeneratedEnumerable`2::readAndClear

    .method public hidebysig instance void 
            start() cil managed
    {
      .custom instance void [mscorlib]System.Runtime.CompilerServices.CompilerGeneratedAttribute::.ctor() = ( 01 00 00 00 ) 
      // Code size       19 (0x13)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  ldfld      bool class MyCollections.IEnumerator/GeneratedEnumerable`2<!T,!State>::started
      IL_0006:  brfalse.s  IL_000a

      IL_0008:  br.s       IL_0012

      IL_000a:  ldarg.0
      IL_000b:  ldc.i4.1
      IL_000c:  stfld      bool class MyCollections.IEnumerator/GeneratedEnumerable`2<!T,!State>::started
      IL_0011:  ret

      IL_0012:  ret
    } // end of method GeneratedEnumerable`2::start

    .method public hidebysig instance void 
            dispose() cil managed
    {
      .custom instance void [mscorlib]System.Runtime.CompilerServices.CompilerGeneratedAttribute::.ctor() = ( 01 00 00 00 ) 
      // Code size       36 (0x24)
      .maxstack  4
      .locals init (class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!State> V_0,
               class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<!State,class [FSharp.Core]Microsoft.FSharp.Core.Unit> V_1,
               class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!State> V_2)
      IL_0000:  ldarg.0
      IL_0001:  callvirt   instance class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!1> class MyCollections.IEnumerator/GeneratedEnumerable`2<!T,!State>::readAndClear()
      IL_0006:  stloc.0
      IL_0007:  ldarg.0
      IL_0008:  ldfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<!1,class [FSharp.Core]Microsoft.FSharp.Core.Unit> class MyCollections.IEnumerator/GeneratedEnumerable`2<!T,!State>::closef
      IL_000d:  stloc.1
      IL_000e:  ldloc.0
      IL_000f:  brfalse.s  IL_0013

      IL_0011:  br.s       IL_0014

      IL_0013:  ret

      IL_0014:  ldloc.0
      IL_0015:  stloc.2
      IL_0016:  ldloc.1
      IL_0017:  ldloc.2
      IL_0018:  call       instance !0 class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!State>::get_Value()
      IL_001d:  callvirt   instance !1 class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<!State,class [FSharp.Core]Microsoft.FSharp.Core.Unit>::Invoke(!0)
      IL_0022:  pop
      IL_0023:  ret
    } // end of method GeneratedEnumerable`2::dispose

    .method public hidebysig instance void 
            finish() cil managed
    {
      .custom instance void [mscorlib]System.Runtime.CompilerServices.CompilerGeneratedAttribute::.ctor() = ( 01 00 00 00 ) 
      // Code size       17 (0x11)
      .maxstack  4
      .try
      {
        IL_0000:  ldarg.0
        IL_0001:  callvirt   instance void class MyCollections.IEnumerator/GeneratedEnumerable`2<!T,!State>::dispose()
        IL_0006:  leave.s    IL_0010

      }  // end .try
      finally
      {
        IL_0008:  ldarg.0
        IL_0009:  ldnull
        IL_000a:  stfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpOption`1<!0> class MyCollections.IEnumerator/GeneratedEnumerable`2<!T,!State>::curr
        IL_000f:  endfinally
      }  // end handler
      IL_0010:  ret
    } // end of method GeneratedEnumerable`2::finish

  } // end of class GeneratedEnumerable`2

  .class auto ansi serializable sealed nested public Singleton`1<T>
         extends [mscorlib]System.Object
         implements [mscorlib]System.IDisposable,
                    [mscorlib]System.Collections.IEnumerator,
                    class [mscorlib]System.Collections.Generic.IEnumerator`1<!T>
  {
    .custom instance void [FSharp.Core]Microsoft.FSharp.Core.SealedAttribute::.ctor() = ( 01 00 00 00 ) 
    .custom instance void [FSharp.Core]Microsoft.FSharp.Core.CompilationMappingAttribute::.ctor(valuetype [FSharp.Core]Microsoft.FSharp.Core.SourceConstructFlags) = ( 01 00 03 00 00 00 00 00 ) 
    .field assembly !T v
    .field assembly bool started
    .method public specialname rtspecialname 
            instance void  .ctor(!T v) cil managed
    {
      // Code size       23 (0x17)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  callvirt   instance void [mscorlib]System.Object::.ctor()
      IL_0006:  ldarg.0
      IL_0007:  pop
      IL_0008:  ldarg.0
      IL_0009:  ldarg.1
      IL_000a:  stfld      !0 class MyCollections.IEnumerator/Singleton`1<!T>::v
      IL_000f:  ldarg.0
      IL_0010:  ldc.i4.0
      IL_0011:  stfld      bool class MyCollections.IEnumerator/Singleton`1<!T>::started
      IL_0016:  ret
    } // end of method Singleton`1::.ctor

    .method private hidebysig newslot specialname virtual 
            instance !T  'System.Collections.Generic.IEnumerator<\'T>.get_Current'() cil managed
    {
      .override  method instance !0 class [mscorlib]System.Collections.Generic.IEnumerator`1<!T>::get_Current()
      // Code size       7 (0x7)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  ldfld      !0 class MyCollections.IEnumerator/Singleton`1<!T>::v
      IL_0006:  ret
    } // end of method Singleton`1::'System.Collections.Generic.IEnumerator<\'T>.get_Current'

    .method private hidebysig newslot specialname virtual 
            instance object  System.Collections.IEnumerator.get_Current() cil managed
    {
      .override [mscorlib]System.Collections.IEnumerator::get_Current
      // Code size       12 (0xc)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  ldfld      !0 class MyCollections.IEnumerator/Singleton`1<!T>::v
      IL_0006:  box        !T
      IL_000b:  ret
    } // end of method Singleton`1::System.Collections.IEnumerator.get_Current

    .method private hidebysig newslot virtual 
            instance bool  System.Collections.IEnumerator.MoveNext() cil managed
    {
      .custom instance void [mscorlib]System.Diagnostics.DebuggerStepThroughAttribute::.ctor() = ( 01 00 00 00 ) 
      .override [mscorlib]System.Collections.IEnumerator::MoveNext
      // Code size       19 (0x13)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  ldfld      bool class MyCollections.IEnumerator/Singleton`1<!T>::started
      IL_0006:  brfalse.s  IL_000a

      IL_0008:  ldc.i4.0
      IL_0009:  ret

      IL_000a:  ldarg.0
      IL_000b:  ldc.i4.1
      IL_000c:  stfld      bool class MyCollections.IEnumerator/Singleton`1<!T>::started
      IL_0011:  ldc.i4.1
      IL_0012:  ret
    } // end of method Singleton`1::System.Collections.IEnumerator.MoveNext

    .method private hidebysig newslot virtual 
            instance void  System.Collections.IEnumerator.Reset() cil managed
    {
      .override [mscorlib]System.Collections.IEnumerator::Reset
      // Code size       11 (0xb)
      .maxstack  8
      IL_0000:  ldstr      "SR.GetString(SR.resetNotSupported)"
      IL_0005:  newobj     instance void [mscorlib]System.NotSupportedException::.ctor(string)
      IL_000a:  throw
    } // end of method Singleton`1::System.Collections.IEnumerator.Reset

    .method private hidebysig newslot virtual 
            instance void  System.IDisposable.Dispose() cil managed
    {
      .override [mscorlib]System.IDisposable::Dispose
      // Code size       1 (0x1)
      .maxstack  8
      IL_0000:  ret
    } // end of method Singleton`1::System.IDisposable.Dispose

  } // end of class Singleton`1

  .class auto autochar serializable sealed nested assembly beforefieldinit specialname EnumerateThenFinally@148<T>
         extends [mscorlib]System.Object
         implements [mscorlib]System.Collections.IEnumerator,
                    [mscorlib]System.IDisposable,
                    class [mscorlib]System.Collections.Generic.IEnumerator`1<!T>
  {
    .custom instance void [FSharp.Core]Microsoft.FSharp.Core.CompilationMappingAttribute::.ctor(valuetype [FSharp.Core]Microsoft.FSharp.Core.SourceConstructFlags) = ( 01 00 06 00 00 00 00 00 ) 
    .field public class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [FSharp.Core]Microsoft.FSharp.Core.Unit> f
    .field public class [mscorlib]System.Collections.Generic.IEnumerator`1<!T> e
    .method public specialname rtspecialname 
            instance void  .ctor(class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [FSharp.Core]Microsoft.FSharp.Core.Unit> f,
                                 class [mscorlib]System.Collections.Generic.IEnumerator`1<!T> e) cil managed
    {
      // Code size       23 (0x17)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  ldarg.1
      IL_0002:  stfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [FSharp.Core]Microsoft.FSharp.Core.Unit> class MyCollections.IEnumerator/EnumerateThenFinally@148<!T>::f
      IL_0007:  ldarg.0
      IL_0008:  ldarg.2
      IL_0009:  stfld      class [mscorlib]System.Collections.Generic.IEnumerator`1<!0> class MyCollections.IEnumerator/EnumerateThenFinally@148<!T>::e
      IL_000e:  ldarg.0
      IL_000f:  callvirt   instance void [mscorlib]System.Object::.ctor()
      IL_0014:  ldarg.0
      IL_0015:  pop
      IL_0016:  ret
    } // end of method EnumerateThenFinally@148::.ctor

    .method private hidebysig newslot virtual final 
            instance !T  'System.Collections.Generic.IEnumerator<\'T>.get_Current'() cil managed
    {
      .override  method instance !0 class [mscorlib]System.Collections.Generic.IEnumerator`1<!T>::get_Current()
      // Code size       14 (0xe)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  ldfld      class [mscorlib]System.Collections.Generic.IEnumerator`1<!0> class MyCollections.IEnumerator/EnumerateThenFinally@148<!T>::e
      IL_0006:  tail.
      IL_0008:  callvirt   instance !0 class [mscorlib]System.Collections.Generic.IEnumerator`1<!T>::get_Current()
      IL_000d:  ret
    } // end of method EnumerateThenFinally@148::'System.Collections.Generic.IEnumerator<\'T>.get_Current'

    .method private hidebysig newslot virtual final 
            instance object  System.Collections.IEnumerator.get_Current() cil managed
    {
      .override [mscorlib]System.Collections.IEnumerator::get_Current
      // Code size       14 (0xe)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  ldfld      class [mscorlib]System.Collections.Generic.IEnumerator`1<!0> class MyCollections.IEnumerator/EnumerateThenFinally@148<!T>::e
      IL_0006:  tail.
      IL_0008:  callvirt   instance object [mscorlib]System.Collections.IEnumerator::get_Current()
      IL_000d:  ret
    } // end of method EnumerateThenFinally@148::System.Collections.IEnumerator.get_Current

    .method private hidebysig newslot virtual final 
            instance bool  System.Collections.IEnumerator.MoveNext() cil managed
    {
      .custom instance void [mscorlib]System.Diagnostics.DebuggerStepThroughAttribute::.ctor() = ( 01 00 00 00 ) 
      .override [mscorlib]System.Collections.IEnumerator::MoveNext
      // Code size       14 (0xe)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  ldfld      class [mscorlib]System.Collections.Generic.IEnumerator`1<!0> class MyCollections.IEnumerator/EnumerateThenFinally@148<!T>::e
      IL_0006:  tail.
      IL_0008:  callvirt   instance bool [mscorlib]System.Collections.IEnumerator::MoveNext()
      IL_000d:  ret
    } // end of method EnumerateThenFinally@148::System.Collections.IEnumerator.MoveNext

    .method private hidebysig newslot virtual final 
            instance void  System.Collections.IEnumerator.Reset() cil managed
    {
      .override [mscorlib]System.Collections.IEnumerator::Reset
      // Code size       11 (0xb)
      .maxstack  8
      IL_0000:  ldstr      "SR.GetString(SR.resetNotSupported)"
      IL_0005:  newobj     instance void [mscorlib]System.NotSupportedException::.ctor(string)
      IL_000a:  throw
    } // end of method EnumerateThenFinally@148::System.Collections.IEnumerator.Reset

    .method private hidebysig newslot virtual final 
            instance void  System.IDisposable.Dispose() cil managed
    {
      .override [mscorlib]System.IDisposable::Dispose
      // Code size       28 (0x1c)
      .maxstack  6
      .try
      {
        IL_0000:  ldarg.0
        IL_0001:  ldfld      class [mscorlib]System.Collections.Generic.IEnumerator`1<!0> class MyCollections.IEnumerator/EnumerateThenFinally@148<!T>::e
        IL_0006:  callvirt   instance void [mscorlib]System.IDisposable::Dispose()
        IL_000b:  leave.s    IL_001b

      }  // end .try
      finally
      {
        IL_000d:  ldarg.0
        IL_000e:  ldfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [FSharp.Core]Microsoft.FSharp.Core.Unit> class MyCollections.IEnumerator/EnumerateThenFinally@148<!T>::f
        IL_0013:  ldnull
        IL_0014:  callvirt   instance !1 class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [FSharp.Core]Microsoft.FSharp.Core.Unit>::Invoke(!0)
        IL_0019:  pop
        IL_001a:  endfinally
      }  // end handler
      IL_001b:  ret
    } // end of method EnumerateThenFinally@148::System.IDisposable.Dispose

  } // end of class EnumerateThenFinally@148

  .class auto autochar serializable sealed nested assembly beforefieldinit specialname mkSeq@172<U>
         extends [mscorlib]System.Object
         implements [mscorlib]System.Collections.IEnumerable,
                    class [mscorlib]System.Collections.Generic.IEnumerable`1<!U>
  {
    .custom instance void [FSharp.Core]Microsoft.FSharp.Core.CompilationMappingAttribute::.ctor(valuetype [FSharp.Core]Microsoft.FSharp.Core.SourceConstructFlags) = ( 01 00 06 00 00 00 00 00 ) 
    .field public class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [mscorlib]System.Collections.Generic.IEnumerator`1<!U>> f
    .method public specialname rtspecialname 
            instance void  .ctor(class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [mscorlib]System.Collections.Generic.IEnumerator`1<!U>> f) cil managed
    {
      // Code size       16 (0x10)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  ldarg.1
      IL_0002:  stfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [mscorlib]System.Collections.Generic.IEnumerator`1<!0>> class MyCollections.IEnumerator/mkSeq@172<!U>::f
      IL_0007:  ldarg.0
      IL_0008:  callvirt   instance void [mscorlib]System.Object::.ctor()
      IL_000d:  ldarg.0
      IL_000e:  pop
      IL_000f:  ret
    } // end of method mkSeq@172::.ctor

    .method private hidebysig newslot virtual final 
            instance class [mscorlib]System.Collections.Generic.IEnumerator`1<!U> 
            'System.Collections.Generic.IEnumerable<\'U>.GetEnumerator'() cil managed
    {
      .override  method instance class [mscorlib]System.Collections.Generic.IEnumerator`1<!0> class [mscorlib]System.Collections.Generic.IEnumerable`1<!U>::GetEnumerator()
      // Code size       15 (0xf)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  ldfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [mscorlib]System.Collections.Generic.IEnumerator`1<!0>> class MyCollections.IEnumerator/mkSeq@172<!U>::f
      IL_0006:  ldnull
      IL_0007:  tail.
      IL_0009:  callvirt   instance !1 class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [mscorlib]System.Collections.Generic.IEnumerator`1<!U>>::Invoke(!0)
      IL_000e:  ret
    } // end of method mkSeq@172::'System.Collections.Generic.IEnumerable<\'U>.GetEnumerator'

    .method private hidebysig newslot virtual final 
            instance class [mscorlib]System.Collections.IEnumerator 
            System.Collections.IEnumerable.GetEnumerator() cil managed
    {
      .override [mscorlib]System.Collections.IEnumerable::GetEnumerator
      // Code size       13 (0xd)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  ldfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [mscorlib]System.Collections.Generic.IEnumerator`1<!0>> class MyCollections.IEnumerator/mkSeq@172<!U>::f
      IL_0006:  ldnull
      IL_0007:  callvirt   instance !1 class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [mscorlib]System.Collections.Generic.IEnumerator`1<!U>>::Invoke(!0)
      IL_000c:  ret
    } // end of method mkSeq@172::System.Collections.IEnumerable.GetEnumerator

  } // end of class mkSeq@172

  .method public static !!a  noReset<a>() cil managed
  {
    // Code size       11 (0xb)
    .maxstack  8
    IL_0000:  ldstr      "SR.GetString(SR.resetNotSupported)"
    IL_0005:  newobj     instance void [mscorlib]System.NotSupportedException::.ctor(string)
    IL_000a:  throw
  } // end of method IEnumerator::noReset

  .method public static !!a  notStarted<a>() cil managed
  {
    // Code size       11 (0xb)
    .maxstack  8
    IL_0000:  ldstr      "SR.GetString(SR.enumerationNotStarted)"
    IL_0005:  newobj     instance void [mscorlib]System.InvalidOperationException::.ctor(string)
    IL_000a:  throw
  } // end of method IEnumerator::notStarted

  .method public static !!a  alreadyFinished<a>() cil managed
  {
    // Code size       11 (0xb)
    .maxstack  8
    IL_0000:  ldstr      "SR.GetString(SR.enumerationAlreadyFinished)"
    IL_0005:  newobj     instance void [mscorlib]System.InvalidOperationException::.ctor(string)
    IL_000a:  throw
  } // end of method IEnumerator::alreadyFinished

  .method public static void  check(bool started) cil managed
  {
    // Code size       17 (0x11)
    .maxstack  8
    IL_0000:  ldarg.0
    IL_0001:  brfalse.s  IL_0005

    IL_0003:  br.s       IL_0010

    IL_0005:  ldstr      "SR.GetString(SR.enumerationNotStarted)"
    IL_000a:  newobj     instance void [mscorlib]System.InvalidOperationException::.ctor(string)
    IL_000f:  throw

    IL_0010:  ret
  } // end of method IEnumerator::check

  .method public static void  dispose(class [mscorlib]System.IDisposable r) cil managed
  {
    // Code size       9 (0x9)
    .maxstack  8
    IL_0000:  ldarg.0
    IL_0001:  tail.
    IL_0003:  callvirt   instance void [mscorlib]System.IDisposable::Dispose()
    IL_0008:  ret
  } // end of method IEnumerator::dispose

  .method public static class [mscorlib]System.Collections.Generic.IEnumerator`1<!!T> 
          cast<T>(class [mscorlib]System.Collections.IEnumerator e) cil managed
  {
    // Code size       7 (0x7)
    .maxstack  8
    IL_0000:  ldarg.0
    IL_0001:  newobj     instance void class MyCollections.IEnumerator/cast@21<!!T>::.ctor(class [mscorlib]System.Collections.IEnumerator)
    IL_0006:  ret
  } // end of method IEnumerator::cast

  .method public static class [mscorlib]System.Collections.Generic.IEnumerator`1<!!T> 
          Empty<T>() cil managed
  {
    // Code size       6 (0x6)
    .maxstack  8
    IL_0000:  newobj     instance void class MyCollections.IEnumerator/EmptyEnumerator`1<!!T>::.ctor()
    IL_0005:  ret
  } // end of method IEnumerator::Empty

  .method public static class [mscorlib]System.Collections.Generic.IEnumerator`1<!!T> 
          Singleton<T>(!!T x) cil managed
  {
    // Code size       7 (0x7)
    .maxstack  8
    IL_0000:  ldarg.0
    IL_0001:  newobj     instance void class MyCollections.IEnumerator/Singleton`1<!!T>::.ctor(!0)
    IL_0006:  ret
  } // end of method IEnumerator::Singleton

  .method public static class [mscorlib]System.Collections.Generic.IEnumerator`1<!!T> 
          EnumerateThenFinally<T>(class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [FSharp.Core]Microsoft.FSharp.Core.Unit> f,
                                  class [mscorlib]System.Collections.Generic.IEnumerator`1<!!T> e) cil managed
  {
    .custom instance void [FSharp.Core]Microsoft.FSharp.Core.CompilationArgumentCountsAttribute::.ctor(int32[]) = ( 01 00 02 00 00 00 01 00 00 00 01 00 00 00 00 00 ) 
    // Code size       8 (0x8)
    .maxstack  8
    IL_0000:  ldarg.0
    IL_0001:  ldarg.1
    IL_0002:  newobj     instance void class MyCollections.IEnumerator/EnumerateThenFinally@148<!!T>::.ctor(class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [FSharp.Core]Microsoft.FSharp.Core.Unit>,
                                                                                                            class [mscorlib]System.Collections.Generic.IEnumerator`1<!0>)
    IL_0007:  ret
  } // end of method IEnumerator::EnumerateThenFinally

  .method public static void  checkNonNull<class a>(string argName,
                                                    !!a arg) cil managed
  {
    .custom instance void [FSharp.Core]Microsoft.FSharp.Core.CompilationArgumentCountsAttribute::.ctor(int32[]) = ( 01 00 02 00 00 00 01 00 00 00 01 00 00 00 00 00 ) 
    // Code size       16 (0x10)
    .maxstack  8
    IL_0000:  ldarg.1
    IL_0001:  box        !!a
    IL_0006:  brtrue.s   IL_000f

    IL_0008:  ldarg.0
    IL_0009:  newobj     instance void [netstandard]System.ArgumentNullException::.ctor(string)
    IL_000e:  throw

    IL_000f:  ret
  } // end of method IEnumerator::checkNonNull

  .method public static class [mscorlib]System.Collections.Generic.IEnumerable`1<!!U> 
          mkSeq<U>(class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [mscorlib]System.Collections.Generic.IEnumerator`1<!!U>> f) cil managed
  {
    // Code size       7 (0x7)
    .maxstack  8
    IL_0000:  ldarg.0
    IL_0001:  newobj     instance void class MyCollections.IEnumerator/mkSeq@172<!!U>::.ctor(class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [mscorlib]System.Collections.Generic.IEnumerator`1<!0>>)
    IL_0006:  ret
  } // end of method IEnumerator::mkSeq

} // end of class MyCollections.IEnumerator

.class private abstract auto ansi sealed '<StartupCode$RealsigPlusOptimisePlus>'.$Nested_generic_closure
       extends [mscorlib]System.Object
{
  .field static assembly int32 init@
  .custom instance void [mscorlib]System.Diagnostics.DebuggerBrowsableAttribute::.ctor(valuetype [mscorlib]System.Diagnostics.DebuggerBrowsableState) = ( 01 00 00 00 00 00 00 00 ) 
  .custom instance void [mscorlib]System.Runtime.CompilerServices.CompilerGeneratedAttribute::.ctor() = ( 01 00 00 00 ) 
  .custom instance void [mscorlib]System.Diagnostics.DebuggerNonUserCodeAttribute::.ctor() = ( 01 00 00 00 ) 
  .method public static void  main@() cil managed
  {
    .entrypoint
    // Code size       6 (0x6)
    .maxstack  8
    IL_0000:  call       void Microsoft.FSharp.Core.CompilerServices.doIt::staticInitialization@()
    IL_0005:  ret
  } // end of method $Nested_generic_closure::main@

} // end of class '<StartupCode$RealsigPlusOptimisePlus>'.$Nested_generic_closure

.class private auto ansi serializable sealed System.Diagnostics.CodeAnalysis.DynamicallyAccessedMemberTypes
       extends [mscorlib]System.Enum
{
  .custom instance void [mscorlib]System.FlagsAttribute::.ctor() = ( 01 00 00 00 ) 
  .custom instance void [mscorlib]System.Runtime.CompilerServices.CompilerGeneratedAttribute::.ctor() = ( 01 00 00 00 ) 
  .custom instance void [mscorlib]System.Diagnostics.DebuggerNonUserCodeAttribute::.ctor() = ( 01 00 00 00 ) 
  .field public specialname rtspecialname int32 value__
  .field public static literal valuetype System.Diagnostics.CodeAnalysis.DynamicallyAccessedMemberTypes All = int32(0xFFFFFFFF)
  .field public static literal valuetype System.Diagnostics.CodeAnalysis.DynamicallyAccessedMemberTypes None = int32(0x00000000)
  .field public static literal valuetype System.Diagnostics.CodeAnalysis.DynamicallyAccessedMemberTypes PublicParameterlessConstructor = int32(0x00000001)
  .field public static literal valuetype System.Diagnostics.CodeAnalysis.DynamicallyAccessedMemberTypes PublicConstructors = int32(0x00000003)
  .field public static literal valuetype System.Diagnostics.CodeAnalysis.DynamicallyAccessedMemberTypes NonPublicConstructors = int32(0x00000004)
  .field public static literal valuetype System.Diagnostics.CodeAnalysis.DynamicallyAccessedMemberTypes PublicMethods = int32(0x00000008)
  .field public static literal valuetype System.Diagnostics.CodeAnalysis.DynamicallyAccessedMemberTypes NonPublicMethods = int32(0x00000010)
  .field public static literal valuetype System.Diagnostics.CodeAnalysis.DynamicallyAccessedMemberTypes PublicFields = int32(0x00000020)
  .field public static literal valuetype System.Diagnostics.CodeAnalysis.DynamicallyAccessedMemberTypes NonPublicFields = int32(0x00000040)
  .field public static literal valuetype System.Diagnostics.CodeAnalysis.DynamicallyAccessedMemberTypes PublicNestedTypes = int32(0x00000080)
  .field public static literal valuetype System.Diagnostics.CodeAnalysis.DynamicallyAccessedMemberTypes NonPublicNestedTypes = int32(0x00000100)
  .field public static literal valuetype System.Diagnostics.CodeAnalysis.DynamicallyAccessedMemberTypes PublicProperties = int32(0x00000200)
  .field public static literal valuetype System.Diagnostics.CodeAnalysis.DynamicallyAccessedMemberTypes NonPublicProperties = int32(0x00000400)
  .field public static literal valuetype System.Diagnostics.CodeAnalysis.DynamicallyAccessedMemberTypes PublicEvents = int32(0x00000800)
  .field public static literal valuetype System.Diagnostics.CodeAnalysis.DynamicallyAccessedMemberTypes NonPublicEvents = int32(0x00001000)
  .field public static literal valuetype System.Diagnostics.CodeAnalysis.DynamicallyAccessedMemberTypes Interfaces = int32(0x00002000)
} // end of class System.Diagnostics.CodeAnalysis.DynamicallyAccessedMemberTypes

.class private auto ansi beforefieldinit System.Diagnostics.CodeAnalysis.DynamicDependencyAttribute
       extends [mscorlib]System.Attribute
{
  .custom instance void [mscorlib]System.Runtime.CompilerServices.CompilerGeneratedAttribute::.ctor() = ( 01 00 00 00 ) 
  .field private valuetype System.Diagnostics.CodeAnalysis.DynamicallyAccessedMemberTypes MemberType@
  .custom instance void [mscorlib]System.Runtime.CompilerServices.CompilerGeneratedAttribute::.ctor() = ( 01 00 00 00 ) 
  .custom instance void [mscorlib]System.Diagnostics.DebuggerNonUserCodeAttribute::.ctor() = ( 01 00 00 00 ) 
  .field private class [mscorlib]System.Type Type@
  .custom instance void [mscorlib]System.Runtime.CompilerServices.CompilerGeneratedAttribute::.ctor() = ( 01 00 00 00 ) 
  .custom instance void [mscorlib]System.Diagnostics.DebuggerNonUserCodeAttribute::.ctor() = ( 01 00 00 00 ) 
  .method public specialname rtspecialname 
          instance void  .ctor(valuetype System.Diagnostics.CodeAnalysis.DynamicallyAccessedMemberTypes MemberType,
                               class [mscorlib]System.Type Type) cil managed
  {
    .custom instance void [mscorlib]System.Runtime.CompilerServices.CompilerGeneratedAttribute::.ctor() = ( 01 00 00 00 ) 
    .custom instance void [mscorlib]System.Diagnostics.DebuggerNonUserCodeAttribute::.ctor() = ( 01 00 00 00 ) 
    // Code size       21 (0x15)
    .maxstack  8
    IL_0000:  ldarg.0
    IL_0001:  call       instance void [mscorlib]System.Attribute::.ctor()
    IL_0006:  ldarg.0
    IL_0007:  ldarg.1
    IL_0008:  stfld      valuetype System.Diagnostics.CodeAnalysis.DynamicallyAccessedMemberTypes System.Diagnostics.CodeAnalysis.DynamicDependencyAttribute::MemberType@
    IL_000d:  ldarg.0
    IL_000e:  ldarg.2
    IL_000f:  stfld      class [mscorlib]System.Type System.Diagnostics.CodeAnalysis.DynamicDependencyAttribute::Type@
    IL_0014:  ret
  } // end of method DynamicDependencyAttribute::.ctor

  .method public hidebysig specialname instance class [mscorlib]System.Type 
          get_Type() cil managed
  {
    .custom instance void [mscorlib]System.Runtime.CompilerServices.CompilerGeneratedAttribute::.ctor() = ( 01 00 00 00 ) 
    .custom instance void [mscorlib]System.Diagnostics.DebuggerNonUserCodeAttribute::.ctor() = ( 01 00 00 00 ) 
    // Code size       7 (0x7)
    .maxstack  8
    IL_0000:  ldarg.0
    IL_0001:  ldfld      class [mscorlib]System.Type System.Diagnostics.CodeAnalysis.DynamicDependencyAttribute::Type@
    IL_0006:  ret
  } // end of method DynamicDependencyAttribute::get_Type

  .method public hidebysig specialname instance valuetype System.Diagnostics.CodeAnalysis.DynamicallyAccessedMemberTypes 
          get_MemberType() cil managed
  {
    .custom instance void [mscorlib]System.Runtime.CompilerServices.CompilerGeneratedAttribute::.ctor() = ( 01 00 00 00 ) 
    .custom instance void [mscorlib]System.Diagnostics.DebuggerNonUserCodeAttribute::.ctor() = ( 01 00 00 00 ) 
    // Code size       7 (0x7)
    .maxstack  8
    IL_0000:  ldarg.0
    IL_0001:  ldfld      valuetype System.Diagnostics.CodeAnalysis.DynamicallyAccessedMemberTypes System.Diagnostics.CodeAnalysis.DynamicDependencyAttribute::MemberType@
    IL_0006:  ret
  } // end of method DynamicDependencyAttribute::get_MemberType

  .property instance valuetype System.Diagnostics.CodeAnalysis.DynamicallyAccessedMemberTypes
          MemberType()
  {
    .custom instance void [mscorlib]System.Runtime.CompilerServices.CompilerGeneratedAttribute::.ctor() = ( 01 00 00 00 ) 
    .custom instance void [mscorlib]System.Diagnostics.DebuggerNonUserCodeAttribute::.ctor() = ( 01 00 00 00 ) 
    .get instance valuetype System.Diagnostics.CodeAnalysis.DynamicallyAccessedMemberTypes System.Diagnostics.CodeAnalysis.DynamicDependencyAttribute::get_MemberType()
  } // end of property DynamicDependencyAttribute::MemberType
  .property instance class [mscorlib]System.Type
          Type()
  {
    .custom instance void [mscorlib]System.Runtime.CompilerServices.CompilerGeneratedAttribute::.ctor() = ( 01 00 00 00 ) 
    .custom instance void [mscorlib]System.Diagnostics.DebuggerNonUserCodeAttribute::.ctor() = ( 01 00 00 00 ) 
    .get instance class [mscorlib]System.Type System.Diagnostics.CodeAnalysis.DynamicDependencyAttribute::get_Type()
  } // end of property DynamicDependencyAttribute::Type
} // end of class System.Diagnostics.CodeAnalysis.DynamicDependencyAttribute


// =============================================================

.data cil I_0000702A = bytearray (
                 01 02 03) 
.data cil I_0000702D = bytearray (
                 01 02 03) 
.data cil I_00007030 = bytearray (
                 01 02 03) 
// *********** DISASSEMBLY COMPLETE ***********************
// WARNING: Created Win32 resource file artifacts\Temp\RealsigPlusOptimisePlus.res


Please propose code fixes to ensure that the compiler emits the lines of code correctly

That is all, thank you

SECTION D - REQUIRED ANALYSIS (BOUNDED)

SECTION E - OUTPUT FORMAT (STRICT)

Your output must contain exactly two sections:

OUTPUT SECTION 1 - Analysis
A detailed, mechanism-first explanation of the changes requested.

OUTPUT SECTION 2 - Updated Code
Provide complete, copy-pastable F# logging code blocks for the changes for each
modified file. Only include the code that must be added. Do not rewrite the
entire file.


