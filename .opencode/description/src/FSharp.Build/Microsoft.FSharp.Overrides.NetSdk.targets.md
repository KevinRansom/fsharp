# Microsoft.FSharp.Overrides.NetSdk.targets

## Pipeline role
Small SDK add-on that overrides the .NET SDK's assembly-info generation for F# projects.
Imported at the bottom of evaluation (targets semantics) so it can override targets already
defined by the SDK.

## Target
- `CoreGenerateAssemblyInfo`
  - Condition `'$(Language)'=='F#'`; DependsOn `CreateGeneratedAssemblyInfoInputsCacheFile`;
    incremental via Inputs/Outputs cache file -> generated assembly-info source.
  - First escapes the SDK bug
    (https://github.com/dotnet/sdk/issues/114) where the generated assembly-info file could
    end up duplicated in `@(Compile)` — it `Compile Remove`ing the `GeneratedAssemblyInfoFile`.
  - Runs `WriteCodeFragment` (the FSharp.Build task) with `Language=F#` over
    `@(AssemblyAttribute)`, registering the output as `CompileBefore`, `FsGeneratedSource`,
    and `FileWrites`.

## Import / output
Shipped inside the FSharp.SDK / bundled with FSharp.Build; included in
`Microsoft.FSharp.Compiler.nuspec` and deployed under `contentFiles\any\any`. Without the
F# language's `GeneratedAssemblyInfoFile` handling the C#-oriented default task would not
produce valid F# assembly attributes.