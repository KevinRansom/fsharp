# logo.png

## Pipeline role
Package icon (4,357 bytes PNG) for the `FSharp.Compiler.Service` NuGet package.

## How it is used
- Referenced from `FSharp.Compiler.Service.fsproj`:
  `<PackageIconFullPath>$(MSBuildThisFileDirectory)logo.png</PackageIconFullPath>`.
- The SDK embeds it into the nuspec as the package icon (NuGet 5.3+ icon-in-package /
  `icon`+`iconUrl` conventions).

## Content (inferred)
- A PNG raster graphic, 180x180-class size typical for NuGet icons — the F# visual brand
  (the four-block blue "F#" square marking) used across dotnet/fsharp packages. Since it
  is a binary asset it cannot be read as text; its role is inferred from the fsproj
  property and package conventions.