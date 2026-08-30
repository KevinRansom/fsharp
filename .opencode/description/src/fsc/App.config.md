# App.config

## Pipeline role
.NET Framework host config for the `fsc` (net472) console executable. Also processed by the
build's `NoneSubstituteText` transform which replaces the `{{FSCoreVersion}}` token with
the real FSharp.Core version before the file is deployed next to `fsc.exe`.

## Settings
- `<runtime>`
  - `gcAllowVeryLargeObjects enabled="true"` — lets the compiler address objects >2 GB
    (large-array scenarios).
  - `legacyUnhandledExceptionPolicy enabled="true"` — crash-and-bail semantics on
    unhandled exceptions rather than letting the runtime unwind interactively.
  - `gcServer enabled="true"` — enables Server GC for parallel compilation performance.
  - `assemblyBinding` — a `bindingRedirect` for `FSharp.Core`
    (`publicKeyToken=b03f5f7f11d50a3a`) from `2.0.0.0` up to `{{FSCoreVersion}}`, unifying
    loads of any older FSharp.Core on the machine to the shipped version.

## Why it exists
As a console host that consumes FSharp.Core 4.x against .NET Framework 4.7.2, fsc needs
binding redirects and runtime tweaks that the .NET (Core) host would otherwise get from
`runtimeconfig.json`. The `{{...}}` token is substituted by `fsc.targets`
(`NoneSubstituteText` -> `$(FSCoreVersion)`).