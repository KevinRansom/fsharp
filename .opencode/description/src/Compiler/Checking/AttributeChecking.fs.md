# AttributeChecking.fs

**Purpose**: Implementation of logic for checking attributes on items during the F# Checking phase — notably `ObsoleteAttribute` (and DiagnosticId/UrlFormat extraction), `HiddenAttribute`, `ExperimentalAttribute`, `UnverifiableAttribute`, compiler-message attributes, security attributes, and "unseen" (hidden/obsolete-only) filtering of members. Works over both F# declarative attributes (`Attrib`) and imported IL attributes (`ILAttributes`), and type-provider provided attributes.

**Namespace(s)**: `module internal FSharp.Compiler.AttributeChecking`

**Types declared**:
- `AttribInfo` — either `FSAttribInfo of TcGlobals * Attrib` or `ILAttribInfo of TcGlobals * ImportMap * ILScopeRef * ILAttribute * range`; exposes `ConstructorArguments`, `NamedArguments` (decoded to typed `objnull` values), `Range`, `TyconRef`.
- `WellKnownMethAttribute` struct — `{ ILFlag: WellKnownILAttributes; ValFlag: WellKnownValAttributes; AttribInfo: BuiltinAttribInfo }`, a spec for "does this method have this well-known attribute".

**Public API surface** (major vals):
- `AttribInfosOfIL`, `AttribInfosOfFS` — normalize IL/F# attributes to `AttribInfo`, evaluating/decoding constructor and named arguments (`evalILAttribElem`, `evalFSharpAttribArg` for that).
- `GetAttribInfosOfEntity/Method/Prop/Event` — attribute lookups over type definitions, `MethInfo`, `PropInfo`, `EventInfo` (recursive over the hierarchy in the method/prop cases).
- `TryBindMethInfoAttribute` (with `f1`/`f2`/`f3` continuation style; `f3` only present under type providers), `TryFindMethInfoStringAttribute`, `MethInfoHasAttribute`.
- `MethInfoHasWellKnownAttribute` / `MethInfoHasWellKnownAttributeSpec` — well-known attribute flags (IL vs F# side).
- `CheckFSharpAttributes : TcGlobals -> Attrib list -> range -> OperationResult<unit>` — the general "check attribute list of an item" entry point.
- Obsolete extraction: `TryGetFSharpObsoleteInfo`, `TryGetILObsoleteInfo` (internal), `TryGetMethodObsoleteInfo`, `TryGetPropObsoleteInfo`, `TryGetEntityObsoleteInfo`, `TryGetEventObsoleteInfo`, `TryGetILFieldObsoleteInfo`, `TryGetProvidedObsoleteInfo` — produce `ObsoleteDiagnosticInfo` (message, DiagnosticId, UrlFormat, isError).
- Unseen filtering: `CheckILAttributesForUnseen/Stored`, `CheckFSharpAttributesForHidden/ForObsolete/ForUnseen`, `CheckProvidedAttributesForUnseen`, `MethInfoIsUnseen`, `PropInfoIsUnseen`, `ILFieldInfoIsUnseen`, `EventInfoIsUnseen` — used by InfoReader/NameResolution to hide members.
- `CheckMethInfoAttributes`, `CheckPropInfoAttributes`, `CheckEntityAttributes`, `CheckUnionCaseAttributes`, `CheckRecdFieldAttributes`, `CheckValAttributes`, `CheckRecdFieldInfoAttributes`, `CheckUnitOfMeasureAttributes`, `CheckILEventAttributes`, `CheckILFieldAttributes`.
- `IsSecurityAttribute`, `IsSecurityCriticalAttribute`, `IsAssemblyVersionAttribute`.

**Internal helpers**:
- `evalILAttribElem` / `evalFSharpAttribArg` — decode attribute argument elements to `objnull` values (with a `fail()` for unsupported conversions).
- `extractILAttribValueFrom`, `extractObsoleteAttributeInfo`, `extractILObsoleteAttributeInfo` — read `DiagnosticId`/`UrlFormat`/`Message` named arguments.
- `reportObsoleteDiagnostic`, `HasCompilerFeatureRequiredAttribute`, `CheckILExperimentalAttributes`, `CheckObsoleteAttributes`, `CheckCompilerMessageAttribute` (produces `UserCompilerMessage`), `CheckFSharpExperimentalAttribute` (experimental feature gating), `CheckUnverifiableAttribute`.
- `BindMethInfoAttributes` — generic bind used by `TryBindMethInfoAttribute`.

**Significant internal logic**:
- F# and IL attribute forms are unified via `AttribInfo` so obsolete/security/etc. checks work uniformly for local and imported members.
- "Unseen" logic: a member is unseen if it carries `HiddenAttribute` or is obsolete (unless `allowObsolete`); this drives member enumeration in InfoReader/NameResolution.
- Obsolete diagnostics carry an optional diagnostic id and URL format from the attribute's named arguments, enabling tooling to customize error codes.

**Cross-references**: `AttributeChecking.fsi` (contract), `InfoReader.fs` (hierarchy-based attribute lookup), `CheckDeclarations.fs` (checks attributes on declarations), `import.fs` (IL attribute decoding), `infos.fs` (`BuiltinAttribInfo`, `WellKnown*` flags).
