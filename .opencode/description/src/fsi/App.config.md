# App.config

## Pipeline role
.NET Framework host config for the `fsi` (net472) console executable. Token
`{{FSCoreVersion}}` is substituted by `fsi.targets` via `NoneSubstituteText` before
deployment next to `fsi.exe`.

## Settings
- `<runtime>`
  - `gcAllowVeryLargeObjects enabled="true"` — allows large (>2 GB) object layouts.
  - `legacyUnhandledExceptionPolicy enabled="true"` — process dies on unhandled exceptions
    rather than interactive unwind.
  - `assemblyBinding` — binding redirect for `FSharp.Core`
    (`publicKeyToken=b03f5f7f11d50a3a`) `2.0.0.0-{{FSCoreVersion}}` -> `{{FSCoreVersion}}`,
    unifying mixed FSharp.Core loads in the interactive process.

## Why it exists
fsi's .NET Framework host needs these runtime behaviors (shadow-copied references, server
mode toggled at runtime, and redirects) which the Core host handles equivalently through
other means. Identical in spirit to `fsc/App.config`.