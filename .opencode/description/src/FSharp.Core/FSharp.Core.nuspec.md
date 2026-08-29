# FSharp.Core.nuspec

## Pipeline role
NuGet packaging manifest for the core `FSharp.Core` package. Consumed when
`FSharp.Core.fsproj` is packed (`NuspecFile=`, `CommonMetadataElements/CommonFileElements`
substituted by the SDK/Arcade repack pipeline).

## Structure
- Metadata: `language en-US`; three empty dependency groups —
  `.NETStandard2.0`, `.NETStandard2.1`, and the `$FSharpCoreShippedNetTargetFramework$`
  pin (net-current library TFM, token flowed via `NuspecProperty
  FSharpCoreShippedNetTargetFramework=$(FSharpCoreShippedNetTargetFramework)` from the
  fsproj).
- Files per TFM folder (`lib\<tfm>`): `FSharp.Core.dll`, `FSharp.Core.xml`, and the culture
  satellites `**\FSharp.Core.resources.dll`.
- No `tools/`/content — FSharp.Core is a plain lib package (satellites and trimming
  substitutions stay embedded in the dll itself).

## Output
The `FSharp.Core` nupkg — versioned per the `UseFSharpPackageVersion` scheme; also embedded
inside `Microsoft.FSharp.Compiler.nupkg` contentFiles (Shipping/Release/PreRelease
folders) by the compiler repack flow.