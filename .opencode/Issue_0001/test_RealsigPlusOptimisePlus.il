
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
.assembly test_RealsigPlusOptimisePlus
{
  .custom instance void [FSharp.Core]Microsoft.FSharp.Core.FSharpInterfaceDataVersionAttribute::.ctor(int32,
                                                                                                      int32,
                                                                                                      int32) = ( 01 00 02 00 00 00 00 00 00 00 00 00 00 00 00 00 ) 
  .hash algorithm 0x00008004
  .ver 0:0:0:0
}
.mresource public FSharpSignatureCompressedData.test_RealsigPlusOptimisePlus
{
  // Offset: 0x00000000 Length: 0x00000326
  // WARNING: managed resource file FSharpSignatureCompressedData.test_RealsigPlusOptimisePlus created
}
.mresource public FSharpSignatureCompressedDataB.test_RealsigPlusOptimisePlus
{
  // Offset: 0x00000330 Length: 0x00000022
  // WARNING: managed resource file FSharpSignatureCompressedDataB.test_RealsigPlusOptimisePlus created
}
.mresource public FSharpOptimizationCompressedData.test_RealsigPlusOptimisePlus
{
  // Offset: 0x00000358 Length: 0x000000E0
  // WARNING: managed resource file FSharpOptimizationCompressedData.test_RealsigPlusOptimisePlus created
}
.module test_RealsigPlusOptimisePlus.exe
// MVID: {6ADFD876-20B1-B856-A745-038376D8DF6A}
.imagebase 0x00400000
.file alignment 0x00000200
.stackreserve 0x00100000
.subsystem 0x0003       // WINDOWS_CUI
.corflags 0x00000001    //  ILONLY
// Image base: 0x06A30000


// =============== CLASS MEMBERS DECLARATION ===================

.class public abstract auto ansi sealed Test
       extends [mscorlib]System.Object
{
  .custom instance void [FSharp.Core]Microsoft.FSharp.Core.CompilationMappingAttribute::.ctor(valuetype [FSharp.Core]Microsoft.FSharp.Core.SourceConstructFlags) = ( 01 00 07 00 00 00 00 00 ) 
  .class abstract auto ansi sealed nested public SeqTestsOnEnumerableEnforcingDisposalAtEnd
         extends [mscorlib]System.Object
  {
    .custom instance void [FSharp.Core]Microsoft.FSharp.Core.CompilationMappingAttribute::.ctor(valuetype [FSharp.Core]Microsoft.FSharp.Core.SourceConstructFlags) = ( 01 00 07 00 00 00 00 00 ) 
    .class auto autochar serializable sealed nested assembly beforefieldinit specialname 'enumerator@37-2'<a,a>
           extends [mscorlib]System.Object
           implements [mscorlib]System.Collections.IEnumerator,
                      class [mscorlib]System.Collections.Generic.IEnumerator`1<!1>
    {
      .custom instance void [FSharp.Core]Microsoft.FSharp.Core.CompilationMappingAttribute::.ctor(valuetype [FSharp.Core]Microsoft.FSharp.Core.SourceConstructFlags) = ( 01 00 06 00 00 00 00 00 ) 
      .field public class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool> disposed
      .field public class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool> endReached
      .field public class [mscorlib]System.Collections.Generic.IEnumerator`1<!1> ie
      .method public specialname rtspecialname 
              instance void  .ctor(class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool> disposed,
                                   class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool> endReached,
                                   class [mscorlib]System.Collections.Generic.IEnumerator`1<!1> ie) cil managed
      {
        // Code size       30 (0x1e)
        .maxstack  8
        IL_0000:  ldarg.0
        IL_0001:  ldarg.1
        IL_0002:  stfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool> class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/'enumerator@37-2'<!0,!1>::disposed
        IL_0007:  ldarg.0
        IL_0008:  ldarg.2
        IL_0009:  stfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool> class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/'enumerator@37-2'<!0,!1>::endReached
        IL_000e:  ldarg.0
        IL_000f:  ldarg.3
        IL_0010:  stfld      class [mscorlib]System.Collections.Generic.IEnumerator`1<!1> class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/'enumerator@37-2'<!0,!1>::ie
        IL_0015:  ldarg.0
        IL_0016:  callvirt   instance void [mscorlib]System.Object::.ctor()
        IL_001b:  ldarg.0
        IL_001c:  pop
        IL_001d:  ret
      } // end of method 'enumerator@37-2'::.ctor

      .method private hidebysig newslot virtual final 
              instance !1  'System.Collections.Generic.IEnumerator<\'a>.get_Current'() cil managed
      {
        .override  method instance !0 class [mscorlib]System.Collections.Generic.IEnumerator`1<!1>::get_Current()
        // Code size       62 (0x3e)
        .maxstack  8
        IL_0000:  ldstr      "rvlrve0"
        IL_0005:  ldarg.0
        IL_0006:  ldfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool> class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/'enumerator@37-2'<!0,!1>::endReached
        IL_000b:  call       instance !0 class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool>::get_contents()
        IL_0010:  ldc.i4.0
        IL_0011:  ceq
        IL_0013:  call       void Test::test(string,
                                             bool)
        IL_0018:  ldstr      "rvlrve1"
        IL_001d:  ldarg.0
        IL_001e:  ldfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool> class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/'enumerator@37-2'<!0,!1>::disposed
        IL_0023:  call       instance !0 class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool>::get_contents()
        IL_0028:  ldc.i4.0
        IL_0029:  ceq
        IL_002b:  call       void Test::test(string,
                                             bool)
        IL_0030:  ldarg.0
        IL_0031:  ldfld      class [mscorlib]System.Collections.Generic.IEnumerator`1<!1> class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/'enumerator@37-2'<!0,!1>::ie
        IL_0036:  tail.
        IL_0038:  callvirt   instance !0 class [mscorlib]System.Collections.Generic.IEnumerator`1<!1>::get_Current()
        IL_003d:  ret
      } // end of method 'enumerator@37-2'::'System.Collections.Generic.IEnumerator<\'a>.get_Current'

      .method private hidebysig newslot virtual final 
              instance void  System.IDisposable.Dispose() cil managed
      {
        .override [mscorlib]System.IDisposable::Dispose
        // Code size       83 (0x53)
        .maxstack  7
        IL_0000:  ldstr      "rvlrve2"
        IL_0005:  ldarg.0
        IL_0006:  ldfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool> class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/'enumerator@37-2'<!0,!1>::endReached
        IL_000b:  call       instance !0 class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool>::get_contents()
        IL_0010:  call       void Test::test(string,
                                             bool)
        IL_0015:  ldstr      "rvlrve4"
        IL_001a:  ldarg.0
        IL_001b:  ldfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool> class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/'enumerator@37-2'<!0,!1>::disposed
        IL_0020:  call       instance !0 class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool>::get_contents()
        IL_0025:  ldc.i4.0
        IL_0026:  ceq
        IL_0028:  call       void Test::test(string,
                                             bool)
        IL_002d:  call       int32 Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd::get_numActiveEnumerators()
        IL_0032:  ldc.i4.1
        IL_0033:  sub
        IL_0034:  call       void Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd::set_numActiveEnumerators(int32)
        IL_0039:  ldarg.0
        IL_003a:  ldfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool> class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/'enumerator@37-2'<!0,!1>::disposed
        IL_003f:  ldc.i4.1
        IL_0040:  call       instance void class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool>::set_contents(!0)
        IL_0045:  ldarg.0
        IL_0046:  ldfld      class [mscorlib]System.Collections.Generic.IEnumerator`1<!1> class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/'enumerator@37-2'<!0,!1>::ie
        IL_004b:  tail.
        IL_004d:  callvirt   instance void [mscorlib]System.IDisposable::Dispose()
        IL_0052:  ret
      } // end of method 'enumerator@37-2'::System.IDisposable.Dispose

      .method private hidebysig newslot virtual final 
              instance bool  System.Collections.IEnumerator.MoveNext() cil managed
      {
        .override [mscorlib]System.Collections.IEnumerator::MoveNext
        // Code size       88 (0x58)
        .maxstack  7
        IL_0000:  ldstr      "rvlrve0"
        IL_0005:  ldarg.0
        IL_0006:  ldfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool> class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/'enumerator@37-2'<!0,!1>::endReached
        IL_000b:  call       instance !0 class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool>::get_contents()
        IL_0010:  ldc.i4.0
        IL_0011:  ceq
        IL_0013:  call       void Test::test(string,
                                             bool)
        IL_0018:  ldstr      "rvlrve3"
        IL_001d:  ldarg.0
        IL_001e:  ldfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool> class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/'enumerator@37-2'<!0,!1>::disposed
        IL_0023:  call       instance !0 class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool>::get_contents()
        IL_0028:  ldc.i4.0
        IL_0029:  ceq
        IL_002b:  call       void Test::test(string,
                                             bool)
        IL_0030:  ldarg.0
        IL_0031:  ldfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool> class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/'enumerator@37-2'<!0,!1>::endReached
        IL_0036:  ldarg.0
        IL_0037:  ldfld      class [mscorlib]System.Collections.Generic.IEnumerator`1<!1> class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/'enumerator@37-2'<!0,!1>::ie
        IL_003c:  callvirt   instance bool [mscorlib]System.Collections.IEnumerator::MoveNext()
        IL_0041:  ldc.i4.0
        IL_0042:  ceq
        IL_0044:  call       instance void class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool>::set_contents(!0)
        IL_0049:  ldarg.0
        IL_004a:  ldfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool> class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/'enumerator@37-2'<!0,!1>::endReached
        IL_004f:  call       instance !0 class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool>::get_contents()
        IL_0054:  ldc.i4.0
        IL_0055:  ceq
        IL_0057:  ret
      } // end of method 'enumerator@37-2'::System.Collections.IEnumerator.MoveNext

      .method private hidebysig newslot virtual final 
              instance object  System.Collections.IEnumerator.get_Current() cil managed
      {
        .override [mscorlib]System.Collections.IEnumerator::get_Current
        // Code size       65 (0x41)
        .maxstack  7
        IL_0000:  ldstr      "qrvlrve0"
        IL_0005:  ldarg.0
        IL_0006:  ldfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool> class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/'enumerator@37-2'<!0,!1>::endReached
        IL_000b:  call       instance !0 class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool>::get_contents()
        IL_0010:  ldc.i4.0
        IL_0011:  ceq
        IL_0013:  call       void Test::test(string,
                                             bool)
        IL_0018:  ldstr      "qrvlrve1"
        IL_001d:  ldarg.0
        IL_001e:  ldfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool> class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/'enumerator@37-2'<!0,!1>::disposed
        IL_0023:  call       instance !0 class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool>::get_contents()
        IL_0028:  ldc.i4.0
        IL_0029:  ceq
        IL_002b:  call       void Test::test(string,
                                             bool)
        IL_0030:  ldarg.0
        IL_0031:  ldfld      class [mscorlib]System.Collections.Generic.IEnumerator`1<!1> class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/'enumerator@37-2'<!0,!1>::ie
        IL_0036:  callvirt   instance !0 class [mscorlib]System.Collections.Generic.IEnumerator`1<!1>::get_Current()
        IL_003b:  box        !1
        IL_0040:  ret
      } // end of method 'enumerator@37-2'::System.Collections.IEnumerator.get_Current

      .method private hidebysig newslot virtual final 
              instance void  System.Collections.IEnumerator.Reset() cil managed
      {
        .override [mscorlib]System.Collections.IEnumerator::Reset
        // Code size       14 (0xe)
        .maxstack  8
        IL_0000:  ldarg.0
        IL_0001:  ldfld      class [mscorlib]System.Collections.Generic.IEnumerator`1<!1> class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/'enumerator@37-2'<!0,!1>::ie
        IL_0006:  tail.
        IL_0008:  callvirt   instance void [mscorlib]System.Collections.IEnumerator::Reset()
        IL_000d:  ret
      } // end of method 'enumerator@37-2'::System.Collections.IEnumerator.Reset

    } // end of class 'enumerator@37-2'

    .class auto autochar serializable sealed nested assembly beforefieldinit specialname countEnumeratorsAndCheckedDisposedAtMostOnceAtEnd@62<a>
           extends [mscorlib]System.Object
           implements [mscorlib]System.Collections.IEnumerable,
                      class [mscorlib]System.Collections.Generic.IEnumerable`1<!a>
    {
      .custom instance void [FSharp.Core]Microsoft.FSharp.Core.CompilationMappingAttribute::.ctor(valuetype [FSharp.Core]Microsoft.FSharp.Core.SourceConstructFlags) = ( 01 00 06 00 00 00 00 00 ) 
      .field public class [mscorlib]System.Collections.Generic.IEnumerable`1<!a> seq
      .method public specialname rtspecialname 
              instance void  .ctor(class [mscorlib]System.Collections.Generic.IEnumerable`1<!a> seq) cil managed
      {
        // Code size       16 (0x10)
        .maxstack  8
        IL_0000:  ldarg.0
        IL_0001:  ldarg.1
        IL_0002:  stfld      class [mscorlib]System.Collections.Generic.IEnumerable`1<!0> class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/countEnumeratorsAndCheckedDisposedAtMostOnceAtEnd@62<!a>::seq
        IL_0007:  ldarg.0
        IL_0008:  callvirt   instance void [mscorlib]System.Object::.ctor()
        IL_000d:  ldarg.0
        IL_000e:  pop
        IL_000f:  ret
      } // end of method countEnumeratorsAndCheckedDisposedAtMostOnceAtEnd@62::.ctor

      .method private hidebysig newslot virtual final 
              instance class [mscorlib]System.Collections.Generic.IEnumerator`1<!a> 
              'System.Collections.Generic.IEnumerable<\'a>.GetEnumerator'() cil managed
      {
        .override  method instance class [mscorlib]System.Collections.Generic.IEnumerator`1<!0> class [mscorlib]System.Collections.Generic.IEnumerable`1<!a>::GetEnumerator()
        // Code size       13 (0xd)
        .maxstack  8
        IL_0000:  ldarg.0
        IL_0001:  ldfld      class [mscorlib]System.Collections.Generic.IEnumerable`1<!0> class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/countEnumeratorsAndCheckedDisposedAtMostOnceAtEnd@62<!a>::seq
        IL_0006:  ldnull
        IL_0007:  call       class [mscorlib]System.Collections.Generic.IEnumerator`1<!0> class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd<!a>::enumerator@32<!0>(class [mscorlib]System.Collections.Generic.IEnumerable`1<!0>,
                                                                                                                                                                       class [FSharp.Core]Microsoft.FSharp.Core.Unit)
        IL_000c:  ret
      } // end of method countEnumeratorsAndCheckedDisposedAtMostOnceAtEnd@62::'System.Collections.Generic.IEnumerable<\'a>.GetEnumerator'

      .method private hidebysig newslot virtual final 
              instance class [mscorlib]System.Collections.IEnumerator 
              System.Collections.IEnumerable.GetEnumerator() cil managed
      {
        .override [mscorlib]System.Collections.IEnumerable::GetEnumerator
        // Code size       13 (0xd)
        .maxstack  8
        IL_0000:  ldarg.0
        IL_0001:  ldfld      class [mscorlib]System.Collections.Generic.IEnumerable`1<!0> class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/countEnumeratorsAndCheckedDisposedAtMostOnceAtEnd@62<!a>::seq
        IL_0006:  ldnull
        IL_0007:  call       class [mscorlib]System.Collections.Generic.IEnumerator`1<!0> class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd<!a>::enumerator@32<!0>(class [mscorlib]System.Collections.Generic.IEnumerable`1<!0>,
                                                                                                                                                                       class [FSharp.Core]Microsoft.FSharp.Core.Unit)
        IL_000c:  ret
      } // end of method countEnumeratorsAndCheckedDisposedAtMostOnceAtEnd@62::System.Collections.IEnumerable.GetEnumerator

    } // end of class countEnumeratorsAndCheckedDisposedAtMostOnceAtEnd@62

    .class auto autochar serializable sealed nested assembly beforefieldinit specialname 'enumerator@73-3'<a,a>
           extends [mscorlib]System.Object
           implements [mscorlib]System.Collections.IEnumerator,
                      class [mscorlib]System.Collections.Generic.IEnumerator`1<!1>
    {
      .custom instance void [FSharp.Core]Microsoft.FSharp.Core.CompilationMappingAttribute::.ctor(valuetype [FSharp.Core]Microsoft.FSharp.Core.SourceConstructFlags) = ( 01 00 06 00 00 00 00 00 ) 
      .field public class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool> disposed
      .field public class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool> endReached
      .field public class [mscorlib]System.Collections.Generic.IEnumerator`1<!1> ie
      .method public specialname rtspecialname 
              instance void  .ctor(class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool> disposed,
                                   class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool> endReached,
                                   class [mscorlib]System.Collections.Generic.IEnumerator`1<!1> ie) cil managed
      {
        // Code size       30 (0x1e)
        .maxstack  8
        IL_0000:  ldarg.0
        IL_0001:  ldarg.1
        IL_0002:  stfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool> class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/'enumerator@73-3'<!0,!1>::disposed
        IL_0007:  ldarg.0
        IL_0008:  ldarg.2
        IL_0009:  stfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool> class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/'enumerator@73-3'<!0,!1>::endReached
        IL_000e:  ldarg.0
        IL_000f:  ldarg.3
        IL_0010:  stfld      class [mscorlib]System.Collections.Generic.IEnumerator`1<!1> class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/'enumerator@73-3'<!0,!1>::ie
        IL_0015:  ldarg.0
        IL_0016:  callvirt   instance void [mscorlib]System.Object::.ctor()
        IL_001b:  ldarg.0
        IL_001c:  pop
        IL_001d:  ret
      } // end of method 'enumerator@73-3'::.ctor

      .method private hidebysig newslot virtual final 
              instance !1  'System.Collections.Generic.IEnumerator<\'a>.get_Current'() cil managed
      {
        .override  method instance !0 class [mscorlib]System.Collections.Generic.IEnumerator`1<!1>::get_Current()
        // Code size       62 (0x3e)
        .maxstack  8
        IL_0000:  ldstr      "qrvlrve0"
        IL_0005:  ldarg.0
        IL_0006:  ldfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool> class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/'enumerator@73-3'<!0,!1>::endReached
        IL_000b:  call       instance !0 class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool>::get_contents()
        IL_0010:  ldc.i4.0
        IL_0011:  ceq
        IL_0013:  call       void Test::test(string,
                                             bool)
        IL_0018:  ldstr      "qrvlrve1"
        IL_001d:  ldarg.0
        IL_001e:  ldfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool> class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/'enumerator@73-3'<!0,!1>::disposed
        IL_0023:  call       instance !0 class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool>::get_contents()
        IL_0028:  ldc.i4.0
        IL_0029:  ceq
        IL_002b:  call       void Test::test(string,
                                             bool)
        IL_0030:  ldarg.0
        IL_0031:  ldfld      class [mscorlib]System.Collections.Generic.IEnumerator`1<!1> class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/'enumerator@73-3'<!0,!1>::ie
        IL_0036:  tail.
        IL_0038:  callvirt   instance !0 class [mscorlib]System.Collections.Generic.IEnumerator`1<!1>::get_Current()
        IL_003d:  ret
      } // end of method 'enumerator@73-3'::'System.Collections.Generic.IEnumerator<\'a>.get_Current'

      .method private hidebysig newslot virtual final 
              instance void  System.IDisposable.Dispose() cil managed
      {
        .override [mscorlib]System.IDisposable::Dispose
        // Code size       62 (0x3e)
        .maxstack  8
        IL_0000:  ldstr      "qrvlrve4"
        IL_0005:  ldarg.0
        IL_0006:  ldfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool> class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/'enumerator@73-3'<!0,!1>::disposed
        IL_000b:  call       instance !0 class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool>::get_contents()
        IL_0010:  ldc.i4.0
        IL_0011:  ceq
        IL_0013:  call       void Test::test(string,
                                             bool)
        IL_0018:  call       int32 Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd::get_numActiveEnumerators()
        IL_001d:  ldc.i4.1
        IL_001e:  sub
        IL_001f:  call       void Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd::set_numActiveEnumerators(int32)
        IL_0024:  ldarg.0
        IL_0025:  ldfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool> class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/'enumerator@73-3'<!0,!1>::disposed
        IL_002a:  ldc.i4.1
        IL_002b:  call       instance void class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool>::set_contents(!0)
        IL_0030:  ldarg.0
        IL_0031:  ldfld      class [mscorlib]System.Collections.Generic.IEnumerator`1<!1> class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/'enumerator@73-3'<!0,!1>::ie
        IL_0036:  tail.
        IL_0038:  callvirt   instance void [mscorlib]System.IDisposable::Dispose()
        IL_003d:  ret
      } // end of method 'enumerator@73-3'::System.IDisposable.Dispose

      .method private hidebysig newslot virtual final 
              instance bool  System.Collections.IEnumerator.MoveNext() cil managed
      {
        .override [mscorlib]System.Collections.IEnumerator::MoveNext
        // Code size       88 (0x58)
        .maxstack  7
        IL_0000:  ldstr      "qrvlrve0"
        IL_0005:  ldarg.0
        IL_0006:  ldfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool> class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/'enumerator@73-3'<!0,!1>::endReached
        IL_000b:  call       instance !0 class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool>::get_contents()
        IL_0010:  ldc.i4.0
        IL_0011:  ceq
        IL_0013:  call       void Test::test(string,
                                             bool)
        IL_0018:  ldstr      "qrvlrve3"
        IL_001d:  ldarg.0
        IL_001e:  ldfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool> class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/'enumerator@73-3'<!0,!1>::disposed
        IL_0023:  call       instance !0 class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool>::get_contents()
        IL_0028:  ldc.i4.0
        IL_0029:  ceq
        IL_002b:  call       void Test::test(string,
                                             bool)
        IL_0030:  ldarg.0
        IL_0031:  ldfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool> class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/'enumerator@73-3'<!0,!1>::endReached
        IL_0036:  ldarg.0
        IL_0037:  ldfld      class [mscorlib]System.Collections.Generic.IEnumerator`1<!1> class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/'enumerator@73-3'<!0,!1>::ie
        IL_003c:  callvirt   instance bool [mscorlib]System.Collections.IEnumerator::MoveNext()
        IL_0041:  ldc.i4.0
        IL_0042:  ceq
        IL_0044:  call       instance void class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool>::set_contents(!0)
        IL_0049:  ldarg.0
        IL_004a:  ldfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool> class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/'enumerator@73-3'<!0,!1>::endReached
        IL_004f:  call       instance !0 class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool>::get_contents()
        IL_0054:  ldc.i4.0
        IL_0055:  ceq
        IL_0057:  ret
      } // end of method 'enumerator@73-3'::System.Collections.IEnumerator.MoveNext

      .method private hidebysig newslot virtual final 
              instance object  System.Collections.IEnumerator.get_Current() cil managed
      {
        .override [mscorlib]System.Collections.IEnumerator::get_Current
        // Code size       65 (0x41)
        .maxstack  7
        IL_0000:  ldstr      "qrvlrve0"
        IL_0005:  ldarg.0
        IL_0006:  ldfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool> class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/'enumerator@73-3'<!0,!1>::endReached
        IL_000b:  call       instance !0 class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool>::get_contents()
        IL_0010:  ldc.i4.0
        IL_0011:  ceq
        IL_0013:  call       void Test::test(string,
                                             bool)
        IL_0018:  ldstr      "qrvlrve1"
        IL_001d:  ldarg.0
        IL_001e:  ldfld      class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool> class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/'enumerator@73-3'<!0,!1>::disposed
        IL_0023:  call       instance !0 class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool>::get_contents()
        IL_0028:  ldc.i4.0
        IL_0029:  ceq
        IL_002b:  call       void Test::test(string,
                                             bool)
        IL_0030:  ldarg.0
        IL_0031:  ldfld      class [mscorlib]System.Collections.Generic.IEnumerator`1<!1> class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/'enumerator@73-3'<!0,!1>::ie
        IL_0036:  callvirt   instance !0 class [mscorlib]System.Collections.Generic.IEnumerator`1<!1>::get_Current()
        IL_003b:  box        !1
        IL_0040:  ret
      } // end of method 'enumerator@73-3'::System.Collections.IEnumerator.get_Current

      .method private hidebysig newslot virtual final 
              instance void  System.Collections.IEnumerator.Reset() cil managed
      {
        .override [mscorlib]System.Collections.IEnumerator::Reset
        // Code size       14 (0xe)
        .maxstack  8
        IL_0000:  ldarg.0
        IL_0001:  ldfld      class [mscorlib]System.Collections.Generic.IEnumerator`1<!1> class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/'enumerator@73-3'<!0,!1>::ie
        IL_0006:  tail.
        IL_0008:  callvirt   instance void [mscorlib]System.Collections.IEnumerator::Reset()
        IL_000d:  ret
      } // end of method 'enumerator@73-3'::System.Collections.IEnumerator.Reset

    } // end of class 'enumerator@73-3'

    .class auto autochar serializable sealed nested assembly beforefieldinit specialname countEnumeratorsAndCheckedDisposedAtMostOnce@97<a>
           extends [mscorlib]System.Object
           implements [mscorlib]System.Collections.IEnumerable,
                      class [mscorlib]System.Collections.Generic.IEnumerable`1<!a>
    {
      .custom instance void [FSharp.Core]Microsoft.FSharp.Core.CompilationMappingAttribute::.ctor(valuetype [FSharp.Core]Microsoft.FSharp.Core.SourceConstructFlags) = ( 01 00 06 00 00 00 00 00 ) 
      .field public class [mscorlib]System.Collections.Generic.IEnumerable`1<!a> seq
      .method public specialname rtspecialname 
              instance void  .ctor(class [mscorlib]System.Collections.Generic.IEnumerable`1<!a> seq) cil managed
      {
        // Code size       16 (0x10)
        .maxstack  8
        IL_0000:  ldarg.0
        IL_0001:  ldarg.1
        IL_0002:  stfld      class [mscorlib]System.Collections.Generic.IEnumerable`1<!0> class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/countEnumeratorsAndCheckedDisposedAtMostOnce@97<!a>::seq
        IL_0007:  ldarg.0
        IL_0008:  callvirt   instance void [mscorlib]System.Object::.ctor()
        IL_000d:  ldarg.0
        IL_000e:  pop
        IL_000f:  ret
      } // end of method countEnumeratorsAndCheckedDisposedAtMostOnce@97::.ctor

      .method private hidebysig newslot virtual final 
              instance class [mscorlib]System.Collections.Generic.IEnumerator`1<!a> 
              'System.Collections.Generic.IEnumerable<\'a>.GetEnumerator'() cil managed
      {
        .override  method instance class [mscorlib]System.Collections.Generic.IEnumerator`1<!0> class [mscorlib]System.Collections.Generic.IEnumerable`1<!a>::GetEnumerator()
        // Code size       13 (0xd)
        .maxstack  8
        IL_0000:  ldarg.0
        IL_0001:  ldfld      class [mscorlib]System.Collections.Generic.IEnumerable`1<!0> class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/countEnumeratorsAndCheckedDisposedAtMostOnce@97<!a>::seq
        IL_0006:  ldnull
        IL_0007:  call       class [mscorlib]System.Collections.Generic.IEnumerator`1<!0> class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd<!a>::'enumerator@68-1'<!0>(class [mscorlib]System.Collections.Generic.IEnumerable`1<!0>,
                                                                                                                                                                           class [FSharp.Core]Microsoft.FSharp.Core.Unit)
        IL_000c:  ret
      } // end of method countEnumeratorsAndCheckedDisposedAtMostOnce@97::'System.Collections.Generic.IEnumerable<\'a>.GetEnumerator'

      .method private hidebysig newslot virtual final 
              instance class [mscorlib]System.Collections.IEnumerator 
              System.Collections.IEnumerable.GetEnumerator() cil managed
      {
        .override [mscorlib]System.Collections.IEnumerable::GetEnumerator
        // Code size       13 (0xd)
        .maxstack  8
        IL_0000:  ldarg.0
        IL_0001:  ldfld      class [mscorlib]System.Collections.Generic.IEnumerable`1<!0> class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/countEnumeratorsAndCheckedDisposedAtMostOnce@97<!a>::seq
        IL_0006:  ldnull
        IL_0007:  call       class [mscorlib]System.Collections.Generic.IEnumerator`1<!0> class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd<!a>::'enumerator@68-1'<!0>(class [mscorlib]System.Collections.Generic.IEnumerable`1<!0>,
                                                                                                                                                                           class [FSharp.Core]Microsoft.FSharp.Core.Unit)
        IL_000c:  ret
      } // end of method countEnumeratorsAndCheckedDisposedAtMostOnce@97::System.Collections.IEnumerable.GetEnumerator

    } // end of class countEnumeratorsAndCheckedDisposedAtMostOnce@97

    .class auto ansi serializable sealed nested assembly beforefieldinit clo@103
           extends class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<int32,bool>
    {
      .field static assembly initonly class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/clo@103 @_instance
      .method assembly specialname rtspecialname 
              instance void  .ctor() cil managed
      {
        .custom instance void [mscorlib]System.Runtime.CompilerServices.CompilerGeneratedAttribute::.ctor() = ( 01 00 00 00 ) 
        .custom instance void [mscorlib]System.Diagnostics.DebuggerNonUserCodeAttribute::.ctor() = ( 01 00 00 00 ) 
        // Code size       7 (0x7)
        .maxstack  8
        IL_0000:  ldarg.0
        IL_0001:  call       instance void class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<int32,bool>::.ctor()
        IL_0006:  ret
      } // end of method clo@103::.ctor

      .method public strict virtual instance bool 
              Invoke(int32 n) cil managed
      {
        // Code size       8 (0x8)
        .maxstack  8
        IL_0000:  ldarg.1
        IL_0001:  ldc.i4.1
        IL_0002:  ceq
        IL_0004:  ldc.i4.0
        IL_0005:  ceq
        IL_0007:  ret
      } // end of method clo@103::Invoke

      .method private specialname rtspecialname static 
              void  .cctor() cil managed
      {
        // Code size       11 (0xb)
        .maxstack  10
        IL_0000:  newobj     instance void Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/clo@103::.ctor()
        IL_0005:  stsfld     class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/clo@103 Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/clo@103::@_instance
        IL_000a:  ret
      } // end of method clo@103::.cctor

    } // end of class clo@103

    .field static assembly int32 numActiveEnumerators@29
    .custom instance void [mscorlib]System.Diagnostics.DebuggerBrowsableAttribute::.ctor(valuetype [mscorlib]System.Diagnostics.DebuggerBrowsableState) = ( 01 00 00 00 00 00 00 00 ) 
    .method public specialname static int32 
            get_numActiveEnumerators() cil managed
    {
      // Code size       6 (0x6)
      .maxstack  8
      IL_0000:  ldsfld     int32 Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd::numActiveEnumerators@29
      IL_0005:  ret
    } // end of method SeqTestsOnEnumerableEnforcingDisposalAtEnd::get_numActiveEnumerators

    .method public specialname static void 
            set_numActiveEnumerators(int32 'value') cil managed
    {
      // Code size       7 (0x7)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  stsfld     int32 Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd::numActiveEnumerators@29
      IL_0006:  ret
    } // end of method SeqTestsOnEnumerableEnforcingDisposalAtEnd::set_numActiveEnumerators

    .method public static class [mscorlib]System.Collections.Generic.IEnumerable`1<!!a> 
            countEnumeratorsAndCheckedDisposedAtMostOnceAtEnd<a>(class [mscorlib]System.Collections.Generic.IEnumerable`1<!!a> seq) cil managed
    {
      // Code size       7 (0x7)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  newobj     instance void class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/countEnumeratorsAndCheckedDisposedAtMostOnceAtEnd@62<!!a>::.ctor(class [mscorlib]System.Collections.Generic.IEnumerable`1<!0>)
      IL_0006:  ret
    } // end of method SeqTestsOnEnumerableEnforcingDisposalAtEnd::countEnumeratorsAndCheckedDisposedAtMostOnceAtEnd

    .method public static class [mscorlib]System.Collections.Generic.IEnumerable`1<!!a> 
            countEnumeratorsAndCheckedDisposedAtMostOnce<a>(class [mscorlib]System.Collections.Generic.IEnumerable`1<!!a> seq) cil managed
    {
      // Code size       7 (0x7)
      .maxstack  8
      IL_0000:  ldarg.0
      IL_0001:  newobj     instance void class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/countEnumeratorsAndCheckedDisposedAtMostOnce@97<!!a>::.ctor(class [mscorlib]System.Collections.Generic.IEnumerable`1<!0>)
      IL_0006:  ret
    } // end of method SeqTestsOnEnumerableEnforcingDisposalAtEnd::countEnumeratorsAndCheckedDisposedAtMostOnce

    .method private specialname rtspecialname static 
            void  .cctor() cil managed
    {
      // Code size       13 (0xd)
      .maxstack  8
      IL_0000:  ldc.i4.0
      IL_0001:  stsfld     int32 '<StartupCode$test_RealsigPlusOptimisePlus>'.$Test$fsx::init@
      IL_0006:  ldsfld     int32 '<StartupCode$test_RealsigPlusOptimisePlus>'.$Test$fsx::init@
      IL_000b:  pop
      IL_000c:  ret
    } // end of method SeqTestsOnEnumerableEnforcingDisposalAtEnd::.cctor

    .method assembly static void  staticInitialization@() cil managed
    {
      // Code size       54 (0x36)
      .maxstack  8
      IL_0000:  ldc.i4.0
      IL_0001:  stsfld     int32 Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd::numActiveEnumerators@29
      IL_0006:  ldstr      "Seq.filter-length"
      IL_000b:  ldsfld     class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/clo@103 Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/clo@103::@_instance
      IL_0010:  ldc.i4.1
      IL_0011:  ldc.i4.1
      IL_0012:  ldc.i4     0xf4240
      IL_0017:  call       class [mscorlib]System.Collections.Generic.IEnumerable`1<int32> [FSharp.Core]Microsoft.FSharp.Core.Operators/OperatorIntrinsics::RangeInt32(int32,
                                                                                                                                                                       int32,
                                                                                                                                                                       int32)
      IL_001c:  call       class [mscorlib]System.Collections.Generic.IEnumerable`1<!!0> Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd::countEnumeratorsAndCheckedDisposedAtMostOnceAtEnd<int32>(class [mscorlib]System.Collections.Generic.IEnumerable`1<!!0>)
      IL_0021:  call       class [mscorlib]System.Collections.Generic.IEnumerable`1<!!0> [FSharp.Core]Microsoft.FSharp.Collections.SeqModule::Filter<int32>(class [FSharp.Core]Microsoft.FSharp.Core.FSharpFunc`2<!!0,bool>,
                                                                                                                                                            class [mscorlib]System.Collections.Generic.IEnumerable`1<!!0>)
      IL_0026:  call       int32 [FSharp.Core]Microsoft.FSharp.Collections.SeqModule::Length<int32>(class [mscorlib]System.Collections.Generic.IEnumerable`1<!!0>)
      IL_002b:  ldc.i4     0xf423f
      IL_0030:  call       void Test::check<int32>(string,
                                                   !!0,
                                                   !!0)
      IL_0035:  ret
    } // end of method SeqTestsOnEnumerableEnforcingDisposalAtEnd::staticInitialization@

    .method assembly static class [mscorlib]System.Collections.Generic.IEnumerator`1<!!a> 
            enumerator@32<a>(class [mscorlib]System.Collections.Generic.IEnumerable`1<!!a> seq,
                             class [FSharp.Core]Microsoft.FSharp.Core.Unit unitVar0) cil managed
    {
      // Code size       42 (0x2a)
      .maxstack  5
      .locals init (class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool> V_0,
               class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool> V_1,
               class [mscorlib]System.Collections.Generic.IEnumerator`1<!!1> V_2)
      IL_0000:  call       int32 Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd::get_numActiveEnumerators()
      IL_0005:  ldc.i4.1
      IL_0006:  add
      IL_0007:  call       void Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd::set_numActiveEnumerators(int32)
      IL_000c:  ldc.i4.0
      IL_000d:  newobj     instance void class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool>::.ctor(!0)
      IL_0012:  stloc.0
      IL_0013:  ldc.i4.0
      IL_0014:  newobj     instance void class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool>::.ctor(!0)
      IL_0019:  stloc.1
      IL_001a:  ldarg.0
      IL_001b:  callvirt   instance class [mscorlib]System.Collections.Generic.IEnumerator`1<!0> class [mscorlib]System.Collections.Generic.IEnumerable`1<!!1>::GetEnumerator()
      IL_0020:  stloc.2
      IL_0021:  ldloc.0
      IL_0022:  ldloc.1
      IL_0023:  ldloc.2
      IL_0024:  newobj     instance void class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/'enumerator@37-2'<!!a,!!1>::.ctor(class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool>,
                                                                                                                                 class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool>,
                                                                                                                                 class [mscorlib]System.Collections.Generic.IEnumerator`1<!1>)
      IL_0029:  ret
    } // end of method SeqTestsOnEnumerableEnforcingDisposalAtEnd::enumerator@32

    .method assembly static class [mscorlib]System.Collections.Generic.IEnumerator`1<!!a> 
            'enumerator@68-1'<a>(class [mscorlib]System.Collections.Generic.IEnumerable`1<!!a> seq,
                                 class [FSharp.Core]Microsoft.FSharp.Core.Unit unitVar0) cil managed
    {
      // Code size       42 (0x2a)
      .maxstack  5
      .locals init (class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool> V_0,
               class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool> V_1,
               class [mscorlib]System.Collections.Generic.IEnumerator`1<!!1> V_2)
      IL_0000:  ldc.i4.0
      IL_0001:  newobj     instance void class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool>::.ctor(!0)
      IL_0006:  stloc.0
      IL_0007:  ldc.i4.0
      IL_0008:  newobj     instance void class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool>::.ctor(!0)
      IL_000d:  stloc.1
      IL_000e:  ldarg.0
      IL_000f:  callvirt   instance class [mscorlib]System.Collections.Generic.IEnumerator`1<!0> class [mscorlib]System.Collections.Generic.IEnumerable`1<!!1>::GetEnumerator()
      IL_0014:  stloc.2
      IL_0015:  call       int32 Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd::get_numActiveEnumerators()
      IL_001a:  ldc.i4.1
      IL_001b:  add
      IL_001c:  call       void Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd::set_numActiveEnumerators(int32)
      IL_0021:  ldloc.0
      IL_0022:  ldloc.1
      IL_0023:  ldloc.2
      IL_0024:  newobj     instance void class Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd/'enumerator@73-3'<!!a,!!1>::.ctor(class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool>,
                                                                                                                                 class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<bool>,
                                                                                                                                 class [mscorlib]System.Collections.Generic.IEnumerator`1<!1>)
      IL_0029:  ret
    } // end of method SeqTestsOnEnumerableEnforcingDisposalAtEnd::'enumerator@68-1'

    .property int32 numActiveEnumerators()
    {
      .custom instance void [FSharp.Core]Microsoft.FSharp.Core.CompilationMappingAttribute::.ctor(valuetype [FSharp.Core]Microsoft.FSharp.Core.SourceConstructFlags) = ( 01 00 09 00 00 00 00 00 ) 
      .set void Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd::set_numActiveEnumerators(int32)
      .get int32 Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd::get_numActiveEnumerators()
    } // end of property SeqTestsOnEnumerableEnforcingDisposalAtEnd::numActiveEnumerators
  } // end of class SeqTestsOnEnumerableEnforcingDisposalAtEnd

  .field static assembly class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<string>> failures@10
  .custom instance void [mscorlib]System.Diagnostics.DebuggerBrowsableAttribute::.ctor(valuetype [mscorlib]System.Diagnostics.DebuggerBrowsableState) = ( 01 00 00 00 00 00 00 00 ) 
  .field static assembly object aa@109
  .custom instance void [mscorlib]System.Diagnostics.DebuggerBrowsableAttribute::.ctor(valuetype [mscorlib]System.Diagnostics.DebuggerBrowsableState) = ( 01 00 00 00 00 00 00 00 ) 
  .method public specialname static class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<string>> 
          get_failures() cil managed
  {
    // Code size       6 (0x6)
    .maxstack  8
    IL_0000:  ldsfld     class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<string>> Test::failures@10
    IL_0005:  ret
  } // end of method Test::get_failures

  .method public static void  reportFailure(string s) cil managed
  {
    // Code size       52 (0x34)
    .maxstack  8
    IL_0000:  call       class [netstandard]System.IO.TextWriter [netstandard]System.Console::get_Out()
    IL_0005:  ldstr      "\n................TEST FAILED...............\n"
    IL_000a:  callvirt   instance void [mscorlib]System.IO.TextWriter::WriteLine(string)
    IL_000f:  call       class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<string>> Test::get_failures()
    IL_0014:  call       class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<string>> Test::get_failures()
    IL_0019:  call       instance !0 class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<string>>::get_contents()
    IL_001e:  ldarg.0
    IL_001f:  call       class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<!0> class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<string>::get_Empty()
    IL_0024:  call       class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<!0> class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<string>::Cons(!0,
                                                                                                                                                                     class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<!0>)
    IL_0029:  call       class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<!!0> [FSharp.Core]Microsoft.FSharp.Core.Operators::op_Append<string>(class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<!!0>,
                                                                                                                                                           class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<!!0>)
    IL_002e:  call       instance void class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<string>>::set_contents(!0)
    IL_0033:  ret
  } // end of method Test::reportFailure

  .method public static void  check<a>(string s,
                                       !!a e,
                                       !!a r) cil managed
  {
    .custom instance void [FSharp.Core]Microsoft.FSharp.Core.CompilationArgumentCountsAttribute::.ctor(int32[]) = ( 01 00 03 00 00 00 01 00 00 00 01 00 00 00 01 00 
                                                                                                                    00 00 00 00 ) 
    // Code size       66 (0x42)
    .maxstack  6
    IL_0000:  ldarg.2
    IL_0001:  ldarg.1
    IL_0002:  call       bool [FSharp.Core]Microsoft.FSharp.Core.LanguagePrimitives/HashCompare::GenericEqualityIntrinsic<!!0>(!!0,
                                                                                                                               !!0)
    IL_0007:  brfalse.s  IL_0021

    IL_0009:  call       class [netstandard]System.IO.TextWriter [netstandard]System.Console::get_Out()
    IL_000e:  ldarg.0
    IL_000f:  ldstr      ": YES"
    IL_0014:  call       string [mscorlib]System.String::Concat(string,
                                                                string)
    IL_0019:  tail.
    IL_001b:  callvirt   instance void [mscorlib]System.IO.TextWriter::WriteLine(string)
    IL_0020:  ret

    IL_0021:  call       class [netstandard]System.IO.TextWriter [netstandard]System.Console::get_Out()
    IL_0026:  ldstr      "\n***** "
    IL_002b:  ldarg.0
    IL_002c:  ldstr      ": FAIL\n"
    IL_0031:  call       string [mscorlib]System.String::Concat(string,
                                                                string,
                                                                string)
    IL_0036:  callvirt   instance void [mscorlib]System.IO.TextWriter::WriteLine(string)
    IL_003b:  ldarg.0
    IL_003c:  call       void Test::reportFailure(string)
    IL_0041:  ret
  } // end of method Test::check

  .method public static void  test(string s,
                                   bool b) cil managed
  {
    .custom instance void [FSharp.Core]Microsoft.FSharp.Core.CompilationArgumentCountsAttribute::.ctor(int32[]) = ( 01 00 02 00 00 00 01 00 00 00 01 00 00 00 00 00 ) 
    // Code size       32 (0x20)
    .maxstack  8
    IL_0000:  ldarg.1
    IL_0001:  brfalse.s  IL_0004

    IL_0003:  ret

    IL_0004:  call       class [netstandard]System.IO.TextWriter [netstandard]System.Console::get_Error()
    IL_0009:  ldstr      "failure: "
    IL_000e:  ldarg.0
    IL_000f:  call       string [mscorlib]System.String::Concat(string,
                                                                string)
    IL_0014:  callvirt   instance void [mscorlib]System.IO.TextWriter::WriteLine(string)
    IL_0019:  ldarg.0
    IL_001a:  call       void Test::reportFailure(string)
    IL_001f:  ret
  } // end of method Test::test

  .method public static !!f  format_uint64<a,b,c,d,e,f>(!!a outc,
                                                        char formatc,
                                                        !!b width,
                                                        !!c left_justify,
                                                        !!d add_zeros,
                                                        !!e num_prefix_if_pos,
                                                        uint64 n) cil managed
  {
    .custom instance void [FSharp.Core]Microsoft.FSharp.Core.CompilationArgumentCountsAttribute::.ctor(int32[]) = ( 01 00 07 00 00 00 01 00 00 00 01 00 00 00 01 00 
                                                                                                                    00 00 01 00 00 00 01 00 00 00 01 00 00 00 01 00 
                                                                                                                    00 00 00 00 ) 
    // Code size       108 (0x6c)
    .maxstack  4
    IL_0000:  ldarg.1
    IL_0001:  ldc.i4.s   88
    IL_0003:  sub
    IL_0004:  switch     ( 
                          IL_0054)
    IL_000d:  ldarg.1
    IL_000e:  ldc.i4.s   100
    IL_0010:  sub
    IL_0011:  switch     ( 
                          IL_0050)
    IL_001a:  ldarg.1
    IL_001b:  ldc.i4.s   105
    IL_001d:  sub
    IL_001e:  switch     ( 
                          IL_0050)
    IL_0027:  ldarg.1
    IL_0028:  ldc.i4.s   111
    IL_002a:  sub
    IL_002b:  switch     ( 
                          IL_0052)
    IL_0034:  ldarg.1
    IL_0035:  ldc.i4.s   117
    IL_0037:  sub
    IL_0038:  switch     ( 
                          IL_0050)
    IL_0041:  ldarg.1
    IL_0042:  ldc.i4.s   120
    IL_0044:  sub
    IL_0045:  switch     ( 
                          IL_0054)
    IL_004e:  br.s       IL_0056

    IL_0050:  br.s       IL_0061

    IL_0052:  br.s       IL_0061

    IL_0054:  br.s       IL_0061

    IL_0056:  ldstr      "invalid value"
    IL_005b:  newobj     instance void [netstandard]System.Exception::.ctor(string)
    IL_0060:  throw

    IL_0061:  ldstr      "hello"
    IL_0066:  newobj     instance void [netstandard]System.Exception::.ctor(string)
    IL_006b:  throw
  } // end of method Test::format_uint64

  .method public specialname static object 
          get_aa() cil managed
  {
    // Code size       6 (0x6)
    .maxstack  8
    IL_0000:  ldsfld     object Test::aa@109
    IL_0005:  ret
  } // end of method Test::get_aa

  .method private specialname rtspecialname static 
          void  .cctor() cil managed
  {
    // Code size       13 (0xd)
    .maxstack  8
    IL_0000:  ldc.i4.0
    IL_0001:  stsfld     int32 '<StartupCode$test_RealsigPlusOptimisePlus>'.$Test$fsx::init@
    IL_0006:  ldsfld     int32 '<StartupCode$test_RealsigPlusOptimisePlus>'.$Test$fsx::init@
    IL_000b:  pop
    IL_000c:  ret
  } // end of method Test::.cctor

  .method assembly static void  staticInitialization@() cil managed
  {
    // Code size       110 (0x6e)
    .maxstack  4
    .locals init (class [FSharp.Core]Microsoft.FSharp.Core.PrintfFormat`4<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [mscorlib]System.IO.TextWriter,class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [FSharp.Core]Microsoft.FSharp.Core.Unit> V_0)
    IL_0000:  call       class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<!0> class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<string>::get_Empty()
    IL_0005:  newobj     instance void class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<string>>::.ctor(!0)
    IL_000a:  stsfld     class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<string>> Test::failures@10
    IL_000f:  call       void Test/SeqTestsOnEnumerableEnforcingDisposalAtEnd::staticInitialization@()
    IL_0014:  call       class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<string>> Test::get_failures()
    IL_0019:  call       instance !0 class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<string>>::get_contents()
    IL_001e:  call       instance class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<!0> class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<string>::get_TailOrNull()
    IL_0023:  brtrue.s   IL_0053

    IL_0025:  call       class [netstandard]System.IO.TextWriter [netstandard]System.Console::get_Out()
    IL_002a:  ldstr      "Test Passed"
    IL_002f:  callvirt   instance void [mscorlib]System.IO.TextWriter::WriteLine(string)
    IL_0034:  ldstr      "TEST PASSED OK"
    IL_0039:  newobj     instance void class [FSharp.Core]Microsoft.FSharp.Core.PrintfFormat`5<class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [mscorlib]System.IO.TextWriter,class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [FSharp.Core]Microsoft.FSharp.Core.Unit>::.ctor(string)
    IL_003e:  stloc.0
    IL_003f:  call       class [netstandard]System.IO.TextWriter [netstandard]System.Console::get_Out()
    IL_0044:  ldloc.0
    IL_0045:  call       !!0 [FSharp.Core]Microsoft.FSharp.Core.PrintfModule::PrintFormatToTextWriter<class [FSharp.Core]Microsoft.FSharp.Core.Unit>(class [mscorlib]System.IO.TextWriter,
                                                                                                                                                     class [FSharp.Core]Microsoft.FSharp.Core.PrintfFormat`4<!!0,class [mscorlib]System.IO.TextWriter,class [FSharp.Core]Microsoft.FSharp.Core.Unit,class [FSharp.Core]Microsoft.FSharp.Core.Unit>)
    IL_004a:  pop
    IL_004b:  ldc.i4.0
    IL_004c:  call       !!0 [FSharp.Core]Microsoft.FSharp.Core.Operators::Exit<object>(int32)
    IL_0051:  br.s       IL_0068

    IL_0053:  call       class [netstandard]System.IO.TextWriter [netstandard]System.Console::get_Out()
    IL_0058:  ldstr      "Test Failed"
    IL_005d:  callvirt   instance void [mscorlib]System.IO.TextWriter::WriteLine(string)
    IL_0062:  ldc.i4.1
    IL_0063:  call       !!0 [FSharp.Core]Microsoft.FSharp.Core.Operators::Exit<object>(int32)
    IL_0068:  stsfld     object Test::aa@109
    IL_006d:  ret
  } // end of method Test::staticInitialization@

  .property class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<string>>
          failures()
  {
    .custom instance void [FSharp.Core]Microsoft.FSharp.Core.CompilationMappingAttribute::.ctor(valuetype [FSharp.Core]Microsoft.FSharp.Core.SourceConstructFlags) = ( 01 00 09 00 00 00 00 00 ) 
    .get class [FSharp.Core]Microsoft.FSharp.Core.FSharpRef`1<class [FSharp.Core]Microsoft.FSharp.Collections.FSharpList`1<string>> Test::get_failures()
  } // end of property Test::failures
  .property object aa()
  {
    .custom instance void [FSharp.Core]Microsoft.FSharp.Core.CompilationMappingAttribute::.ctor(valuetype [FSharp.Core]Microsoft.FSharp.Core.SourceConstructFlags) = ( 01 00 09 00 00 00 00 00 ) 
    .get object Test::get_aa()
  } // end of property Test::aa
} // end of class Test

.class private abstract auto ansi sealed '<StartupCode$test_RealsigPlusOptimisePlus>'.$Test$fsx
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
    IL_0000:  call       void Test::staticInitialization@()
    IL_0005:  ret
  } // end of method $Test$fsx::main@

} // end of class '<StartupCode$test_RealsigPlusOptimisePlus>'.$Test$fsx


// =============================================================

// *********** DISASSEMBLY COMPLETE ***********************
// WARNING: Created Win32 resource file ..\..\artifacts\Temp\test_RealsigPlusOptimisePlus.res
