# AttributeChecking.fsi

**Purpose**: Public contract for attribute-checking logic in the F# type-checker. Describes the unified `AttribInfo` view over F# and IL attributes and the full set of `Check*Attributes` / `TryGet*ObsoleteInfo` / `IsUnseen` entry points used by CheckDeclarations, InfoReader, and NameResolution.

**Namespace(s)**: `module internal FSharp.Compiler.AttributeChecking`

**Types declared**:
- `AttribInfo` — `FSAttribInfo of TcGlobals * Attrib` | `ILAttribInfo of TcGlobals * ImportMap * ILScopeRef * ILAttribute * range`; members `ConstructorArguments : (TType * objnull) list`, `NamedArguments : (TType * string * bool * objnull) list`, `Range`, `TyconRef`.
- `WellKnownMethAttribute` ([<Struct; NoEquality; NoComparison>]) — `{ ILFlag: WellKnownILAttributes; ValFlag: WellKnownValAttributes; AttribInfo: BuiltinAttribInfo }`.

**Public API surface** (val contracts):
- `AttribInfosOfIL : TcGlobals -> ImportMap -> ILScopeRef -> range -> ILAttributes -> AttribInfo list`
- `GetAttribInfosOfEntity/Method/Prop/Event` — per-entity attribute accessors (method/prop versions are recursive over inherited infos).
- `TryBindMethInfoAttribute` — bind against a `BuiltinAttribInfo` of an F# or IL method, invoking one of three continuations depending on source; the `f3` (provided attributes) overload is only declared when `NO_TYPEPROVIDERS` is not defined.
- `TryFindMethInfoStringAttribute`, `MethInfoHasAttribute` — simple boolean/string queries on `MethInfo`.
- `MethInfoHasWellKnownAttribute` / `MethInfoHasWellKnownAttributeSpec` — well-known attribute flag queries.
- `CheckFSharpAttributes : TcGlobals -> Attrib list -> range -> OperationResult<unit>` — validate an attribute list.
- Obsolete diagnostics: `TryGetMethodObsoleteInfo`, `TryGetPropObsoleteInfo`, `TryGetEntityObsoleteInfo`, `TryGetEventObsoleteInfo`, `TryGetILFieldObsoleteInfo`, `TryGetFSharpObsoleteInfo : TcGlobals -> Attrib list -> ObsoleteDiagnosticInfo option`.
- Unseen predicates: `CheckILAttributesForUnseen/Stored`, `CheckFSharpAttributesForHidden/ForObsolete/ForUnseen`, `MethInfoIsUnseen`, `PropInfoIsUnseen`, `ILFieldInfoIsUnseen`, `EventInfoIsUnseen` (most accept `allowObsolete : bool` to keep obsolete items visible).
- Declaration checks: `CheckMethInfoAttributes`, `CheckPropInfoAttributes`, `CheckEntityAttributes`, `CheckUnionCaseAttributes`, `CheckRecdFieldAttributes`, `CheckValAttributes`, `CheckRecdFieldInfoAttributes`, `CheckUnitOfMeasureAttributes`, `CheckILEventAttributes`, `CheckILFieldAttributes`.
- Security/assembly: `IsSecurityAttribute` (with a `casmap : IDictionary<Stamp, bool>` cycle guard), `IsSecurityCriticalAttribute`, `IsAssemblyVersionAttribute`.

**Notes**:
- The .fsi is the complete public surface; the `.fs` adds private helpers (`evalILAttribElem`, `evalFSharpAttribArg`, `reportObsoleteDiagnostic`, `CheckILExperimentalAttributes`, `CheckCompilerMessageAttribute`, `CheckFSharpExperimentalAttribute`, `CheckUnverifiableAttribute`, etc.) that are not part of the contract.
- `TryGetProvidedObsoleteInfo` and `CheckProvidedAttributes*` exist in the `.fs` (type-provider path) but are not in the .fsi.

**Cross-references**: `AttributeChecking.fs` (implementation), `CheckDeclarations.fs` (per-declaration checks), `InfoReader.fs` (uses unseen predicates to filter member sets), `infos.fs` (`BuiltinAttribInfo`, `WellKnownILAttributes`/`WellKnownValAttributes`), `import.fs` (`ILAttributes`, `decodeILAttribData`).
