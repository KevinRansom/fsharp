




.assembly extern runtime { }
.assembly extern FSharp.Core { }
.assembly assembly
{
  .custom instance void [FSharp.Core]Microsoft.FSharp.Core.FSharpInterfaceDataVersionAttribute::.ctor(int32,
                                                                                                      int32,
                                                                                                      int32) = ( 01 00 02 00 00 00 00 00 00 00 00 00 00 00 00 00 ) 

  
  

  .hash algorithm 0x00008004
  .ver 0:0:0:0
}
.mresource public FSharpSignatureCompressedData.assembly
{
  
  
}
.mresource public FSharpOptimizationCompressedData.assembly
{
  
  
}
.module assembly.exe

.imagebase {value}
.file alignment 0x00000200
.stackreserve 0x00100000
.subsystem 0x0003       
.corflags 0x00000001    





.class public abstract auto ansi sealed assembly
       extends [runtime]System.Object
{
  .custom instance void [FSharp.Core]Microsoft.FSharp.Core.CompilationMappingAttribute::.ctor(valuetype [FSharp.Core]Microsoft.FSharp.Core.SourceConstructFlags) = ( 01 00 07 00 00 00 00 00 ) 
  .method public static void  funcC3<a,b,c>(class [FSharp.Core]Microsoft.FSharp.Core.FSharpChoice`3<!!a,!!b,!!c> n) cil managed
  {
    
    .maxstack  3
    .locals init (class [FSharp.Core]Microsoft.FSharp.Core.FSharpChoice`3<!!a,!!b,!!c> V_0,
             class [FSharp.Core]Microsoft.FSharp.Core.FSharpChoice`3<!!a,!!b,!!c> V_1,
             class [FSharp.Core]Microsoft.FSharp.Core.FSharpChoice`3/Choice3Of3<!!a,!!b,!!c> V_2,
             class [FSharp.Core]Microsoft.FSharp.Core.FSharpChoice`3/Choice2Of3<!!a,!!b,!!c> V_3,
             class [FSharp.Core]Microsoft.FSharp.Core.FSharpChoice`3/Choice1Of3<!!a,!!b,!!c> V_4)
    IL_0000:  ldarg.0
    IL_0001:  stloc.0
    IL_0002:  ldloc.0
    IL_0003:  stloc.1
    IL_0004:  ldloc.1
    IL_0005:  isinst     class [FSharp.Core]Microsoft.FSharp.Core.FSharpChoice`3/Choice2Of3<!!a,!!b,!!c>
    IL_000a:  brtrue.s   IL_0026

    IL_000c:  ldloc.1
    IL_000d:  isinst     class [FSharp.Core]Microsoft.FSharp.Core.FSharpChoice`3/Choice1Of3<!!a,!!b,!!c>
    IL_0012:  brtrue.s   IL_0038

    IL_0014:  ldloc.0
    IL_0015:  castclass  class [FSharp.Core]Microsoft.FSharp.Core.FSharpChoice`3/Choice3Of3<!!a,!!b,!!c>
    IL_001a:  stloc.2
    IL_001b:  ldstr      "C"
    IL_0020:  call       void [runtime]System.Console::WriteLine(string)
    IL_0025:  ret

    IL_0026:  ldloc.0
    IL_0027:  castclass  class [FSharp.Core]Microsoft.FSharp.Core.FSharpChoice`3/Choice2Of3<!!a,!!b,!!c>
    IL_002c:  stloc.3
    IL_002d:  ldstr      "B"
    IL_0032:  call       void [runtime]System.Console::WriteLine(string)
    IL_0037:  ret

    IL_0038:  ldloc.0
    IL_0039:  castclass  class [FSharp.Core]Microsoft.FSharp.Core.FSharpChoice`3/Choice1Of3<!!a,!!b,!!c>
    IL_003e:  stloc.s    V_4
    IL_0040:  ldstr      "A"
    IL_0045:  call       void [runtime]System.Console::WriteLine(string)
    IL_004a:  ret
  } 

} 

.class private abstract auto ansi sealed '<StartupCode$assembly>'.$assembly
       extends [runtime]System.Object
{
  .method public static void  main@() cil managed
  {
    .entrypoint
    
    .maxstack  8
    IL_0000:  ret
  } 

} 






