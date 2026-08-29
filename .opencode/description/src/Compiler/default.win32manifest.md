# default.win32manifest

## Pipeline role
Default Windows application manifest embedded into compiler executables (fsc/fsi) and
shipped alongside FSharp.Compiler.Service.

## Content
- `assemblyIdentity version="1.0.0.0" name="MyApplication.app"` — Generic identity.
- `trustInfo/requestedExecutionLevel level="asInvoker" uiAccess="false"` — Requests no
  elevation (UAC) so the compiler runs as an ordinary user and needs no admin rights.
- No `compatibility`/`dependency`/`application` sections, so no deprecated-OS messages and
  no forced common-control version.

## How it is used
- Referenced by `fsi.rc` (embedded into `fsi.res` as resource type 24) via
  `rc.exe /i ...` when compiling `fsi.res`.
- CopyToOutputDirectory in `FSharp.Compiler.Service.fsproj` so the manifest ship in NuGet
  packages (`FSharp.Compiler.Service.nuspec` and `Microsoft.FSharp.Compiler.nuspec` place
  it under `contentFiles\any\any`).
- The manifest is the standard "no manifest" behavior contract for console hosts: it
  guarantees asInvoker process activation for the fsc/fsi host executables.