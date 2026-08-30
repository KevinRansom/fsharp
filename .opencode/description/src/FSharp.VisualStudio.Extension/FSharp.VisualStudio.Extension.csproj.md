# FSharp.VisualStudio.Extension.csproj

## Pipeline role
Builds `FSharp.VisualStudio.Extension.dll` — the new-generation Visual Studio extension
(VisualStudio.Extensibility SDK) that launches and hosts the F# LSP server
(`FSharp.Compiler.LanguageServer`) in-process inside Visual Studio.

## Project type / frameworks
- `Microsoft.NET.Sdk`, C# (`.csproj`); `TargetFramework=net8.0-windows` on Windows,
  `net8.0` otherwise; `Nullable=enable`; `LangVersion=12`; `ImplicitUsings=enable`;
  `NeutralLanguage=en-US`; `Platforms AnyCPU`.
- VSIX: `GeneratePkgDefFile=true` (legacy interop), `IncludeAssemblyInVSIXContainer=true`,
  `GenerateVSMergedManifest` (from `source.extension.vsixmanifest` next to the project).

## PackageReferences
- `Microsoft.VisualStudio.Extensibility.Sdk` / `Build` (17.13.x) — the VS Extensibility SDK
  (extension host, contributions, commands).
- `Microsoft.VisualStudio.LanguageServer.Protocol.Internal` — internal snapshot of the LSP
  JSON-RPC protocol types; enables memory-safe `Vers` registration.
- `Microsoft.VisualStudio.ProjectSystem.Query` — query API used to locate the current
  project needles for the LSP server.
- `Microsoft.VisualStudio.Threading` 17.13.2.
- FSharp.Core (from `FSharp.Compiler.LanguageServer` `FrameworkReference`-style reference)
  via project reference and `FSHARPCORE_USE_PACKAGE` conditional.

## References (project)
- `..\FSharp.Compiler.LanguageServer\FSharp.Compiler.LanguageServer.fsproj`
  (ReferenceOutputAssembly=true; `TreatAsExisting=true`).
- `..\Compiler\FSharp.Compiler.Service.fsproj` (needed for `FSharpOption`/`SR` interop and
  the LSP host API).
- Proxy project for the LSP framework bridge.

## Sources
- `ExtensionEntrypoint.cs`, `FSharpLanguageServerProvider.cs`, `FSharpExtensionSettings.cs`.
- `.vsextension\string-resources.json` + `source.extension.vsixmanifest` packaged.

## Output
`FSharp.VisualStudio.Extension.dll` => VSIX delivering the F# Analyzer LSP server to VS.