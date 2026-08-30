# LanguageFeatures.fs

**Purpose**: Defines the `#lang "F#"` language-version feature gate: the `LanguageFeature` union (every versioned feature since F# 5.0 through F# 11.0 and preview), the `LanguageVersion` management object, and the static feature→version table that decides whether a feature is enabled for the user's selected language version.

**Namespace(s)**: module `FSharp.Compiler.Features` (internal per .fsi)

**TypeDefs declared**:
- `[<RequireQualifiedAccess>] type LanguageFeature`: ~90 cases, e.g. `NameOf`, `StringInterpolation`, `NestedCopyAndUpdate`, `NullnessChecking`, `WhileBang`, `PreprocessorElif`, `RecordConstructorSyntax`, `RecordSpreads`
- `type LanguageVersion(versionText, ?disabledFeaturesArray)`: the manager/holder

**Public API surface** (per .fsi, internal):
- `new: string * ?disabledFeatures -> LanguageVersion`; `static member Default`
- Query: `SpecifiedVersion: decimal`, `SpecifiedVersionString`, `VersionText`, `IsPreviewEnabled`, `IsExplicitlySpecifiedAs50OrBefore()`
- `ContainsVersion: string -> bool` (valid?), `IsVersionSupported: string -> bool` (≥ 8.0, or `SKIP_VERSION_SUPPORTED_CHECK=1`)
- `SupportsFeature: LanguageFeature -> bool` — core gate
- `DisabledFeatures: LanguageFeature array`, `WithDisabledFeatures: array -> LanguageVersion`
- Help text: `ValidOptions: string[]` (`preview|default|latest|latestmajor`), `ValidVersions: string[]`
- Feature strings: `GetFeatureString`, `GetFeatureVersionString`, `TryParseFeature` (reflection over union case names)
- `Equals`/`GetHashCode` overridden on `SpecifiedVersion` + `DisabledFeatures`

**Significant internal logic**:
- Version constants: 4.6, 4.7, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0; `previewVersion = 9999m`; `defaultVersion = latestVersion = latestMajorVersion = 11.0`
- `getVersionFromString` maps `?`, `PREVIEW`, `DEFAULT`, `LATEST`, `LATESTMAJOR`, and `"5.0"/"5"` etc.; anything unknown → `0m`
- The `features` dict maps each `LanguageFeature` to its release version; `SupportsFeature` = feature's version ≤ specified and feature not in `disabledFeatures`
- F# 11.0 batch includes: `PreprocessorElif`, `RecordSpreads`, `DirectDelegateConstruction`, `MethodOverloadsCache`, `ErrorOnMissingSignatureAttribute` (FS3888 warning→error), etc.
- `previewVersion`-only features: `MoreConcreteTiebreaker`, `OverloadResolutionPriority` (carried over), `RecordConstructorSyntax`, `FromEndSlicing` (unfinished)
- `GetFeatureString` maps every feature to an `FSComp.SR.feature*` resource
- `TryParseFeature` uses `FSharpValue.MakeUnion` on the reflection-located case

**Cross-references**: DiagnosticsLogger.fs (`languageFeatureError` etc. raise "feature not supported in F# X" errors), Driver `--langversion` parsing, Checker (feature gates in checking), service `CheckOptions`.
