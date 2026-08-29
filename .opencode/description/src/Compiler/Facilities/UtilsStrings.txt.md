# UtilsStrings.txt

## Pipeline role
Two-entry compiler-utility string table, embedded (as `EmbeddedText`) in
`FSharp.Compiler.Service.fsproj`, `FSharp.Build.fsproj` and
`FSharp.DependencyManager.Nuget.fsproj`.

## Content (id = value)
- `buildProductName,"Microsoft (R) F# Compiler version %s"` — the classic fsc banner line.
- `fSharpBannerVersion,"%s for F# %s"` — the "# LightweightFSharp banner" continuation
  used by fsc/fsi to print tool + F# language version.

## Format / consumption
- Standard `name,"value"` table: the build's `FSharpEmbedResourceText` task generates a
  `.resources` satellite plus a typed accessor F# module from it (same mechanism as
  FSComp.txt).
- Consumers: compiler/fsi driver code that formats the version banner (Facilities +
  Interactive), and FSharp.Build task implementations that report the fsc tool banner.

## xlf
Localized satellites are produced from the generated .resources via XLIFF (`.xlf`)
translation files, giving culture-specific resource DLLs.