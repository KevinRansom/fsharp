# FSDependencyManager.txt

## Pipeline role
String table for the `FSharp.DependencyManager.Nuget` package manager (the shipped `#r
"nuget:..."` dependency manager for F# Interactive). Embedded via `EmbeddedText` in
`FSharp.DependencyManager.Nuget.fsproj`, whose header comment labels it
"# FSharp.Build resource strings".

## Content (id = value)
- `cantReferenceSystemPackage,"PackageManager cannot reference the System Package '%s'"`
- `requiresAValue,"%s requires a value"`
- `unableToApplyImplicitArgument,"Unable to apply implicit argument number %d"`
- `notUsed,"Not used"`
- `loadNugetPackage,"Load Nuget Package"`
- `version,"version"` / `highestVersion,"with the highest version"`
- `sourceDirectoryDoesntExist,"The source directory '%s' not found"`
- `timedoutResolvingPackages,"Timed out resolving packages, process: '%s' '%s'"`
- `invalidTimeoutValue,"Invalid value for timeout '%s', valid values: none, -1 and
  integer milliseconds to wait"`
- `missingTimeoutValue,"Missing value for timeout"`
- `invalidBooleanValue,"Invalid value for boolean '%s', valid values: true or false"`

## Roles
Command/argument parsing failures (`requiresAValue`, `invalidBooleanValue`,
`invalidTimeoutValue`, `missingTimeoutValue`), package resolution pipeline messages
(`timedoutResolvingPackages`, `sourceDirectoryDoesntExist`, `cantReferenceSystemPackage`),
and user-facing language of the manager's `getRequiredArguments` interface output
(`loadNugetPackage`, `version`, `highestVersion`, `notUsed`).

## Format / consumption
Standard `name,"value"` table -> `.resources` + typed accessor module via
`FSharpEmbedResourceText`; used by `FSharp.DependencyManager.fs`. xlf satellites localize
`FSharp.DependencyManager.Nuget.resources.dll`.