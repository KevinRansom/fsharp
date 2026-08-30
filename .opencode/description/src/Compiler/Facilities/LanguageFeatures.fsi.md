# LanguageFeatures.fsi

**Purpose**: The contract for `LanguageFeatures.fs`: declares the `LanguageFeature` union (the complete list of versioned language features) and the `LanguageVersion` object's public shape.

**Namespace(s)**: module `FSharp.Compiler.Features` (internal)

**TypeDefs declared**:
- `[<RequireQualifiedAccess>] type LanguageFeature` — full enumeration; one notable doc comment: `PreferExtensionMethodOverPlainProperty` marked "RFC-1137"
- `type LanguageVersion` with:
  - `new: string * ?disabledFeaturesArray: LanguageFeature array -> LanguageVersion`
  - `static member ContainsVersion: string -> bool`
  - `static member IsVersionSupported: string -> bool`
  - `member IsPreviewEnabled: bool`
  - `member IsExplicitlySpecifiedAs50OrBefore: unit -> bool` — "Has been explicitly specified as 4.6, 4.7 or 5.0"
  - `member SupportsFeature: LanguageFeature -> bool`
  - `member DisabledFeatures: LanguageFeature array`; `member WithDisabledFeatures: LanguageFeature array -> LanguageVersion`
  - `static member ValidVersions: string[]`; `static member ValidOptions: string[]`
  - `member SpecifiedVersion: decimal`; `member VersionText: string`; `member SpecifiedVersionString: string`
  - `static member GetFeatureString: LanguageFeature -> string`; `static member GetFeatureVersionString: LanguageFeature -> string`
  - `static member TryParseFeature: featureName: string -> LanguageFeature option` — "Try to parse a feature name string to a LanguageFeature option"
  - `static member Default: LanguageVersion`

**Contract notes**: The concrete version table (which feature maps to which release, preview = 9999, default = 11.0) is implementation detail in the .fs; callers depend only on `SupportsFeature` and the string/decimal accessors.

**Cross-references**: Implements LanguageFeatures.fs; used by DiagnosticsLogger.fsi (`languageFeatureError`/`checkLanguageFeatureError` take `LanguageVersion`), driver options, and checker feature gates.
