# ILLink.Substitutions.xml

## Pipeline role
ILLink trimming substitution file embedded into `FSharp.Core.dll` (LogicalName
`ILLink.Substitutions.xml`, wired in `FSharp.Core.fsproj`) so the .NET trimmer removes
compiler-internal F# metadata resources from FSharp.Core.

## Content
- `<linker><assembly fullname="FSharp.Core">` with `action="remove"` on these embedded
  resources:
  - `FSharpOptimizationCompressedData.FSharp.Core` / `FSharpOptimizationInfo.FSharp.Core`
  - `FSharpSignatureCompressedData.FSharp.Core` / `FSharpSignatureInfo.FSharp.Core`
  - `FSharpOptimizationCompressedDataB.FSharp.Core` / `FSharpOptimizationDataB.FSharp.Core`
  - `FSharpSignatureCompressedDataB.FSharp.Core` / `FSharpSignatureDataB.FSharp.Core`

## Why
F#-compiled DLLs embed signature/optimization metadata resources
(`FSharpSignatureData.*`, `FSharpOptimizationData.*` families, with `...CompressedData.*`
and the `...B` variants used for FSharp.Core's back-compat tables). FSharp.Core's copy is
never needed at runtime by consumers, so trimming it slashes binary size in trimmed,
NativeAOT, and self-contained apps.

## Companion
The F# SDK auto-generates the same substitutions for user projects via the
`GenerateILLinkSubstitutions` task in `Microsoft.FSharp.NetSdk.targets` (skipped for
AssemblyName=FSharp.Core, since this shipped file already covers it).