# NicePrint.fsi

**Purpose**
Public contract (internal module) for the compiler's "nice printing" of TAST signatures and types, used to
generate user-facing text for signatures, IntelliSense, quick info, and FSI responses. Declares the family
of `layout*` / `output*` / `richText*` / `string*` entry points over types, members, methods, properties,
union cases, and type definitions, plus the `PrintUtilities` layout helpers.

**Namespace(s)**
`module internal FSharp.Compiler.NicePrint`

**Modules / Types declared**
- `PrintUtilities` — `layoutBuiltinAttribute: DisplayEnv -> BuiltinAttribInfo -> Layout`, `squashToWidth: int option -> Layout -> Layout`.

**Public API surface**
- Types: `layoutTyparConstraint`, `outputType`, `layoutType`, `outputTypars`, `outputTyconRef`, `layoutTyconRef`, `layoutConst`, `prettyLayoutOfType(NoCx)`, `prettyLayoutOfTrait`, `prettyLayoutOfTypar`, `prettyRichTextOfTy`, `prettyStringOfTy(NoCx)`, `richTextOfTy`, `stringOfTy`, `richTextOfTyparConstraints`, `stringOfTyparConstraints`, `richTextOfTyparConstraint`, `stringOfTyparConstraint`.
- Signatures: `prettyLayoutOfMemberSig`, `prettyLayoutOfUncurriedSig`, `prettyLayoutsOfUnresolvedOverloading`, `layoutOfValReturnType`, `prettyLayoutOfInstAndSig`.
- Values/members: `dataExprL`, `outputValOrMember`, `richTextValOrMember`, `stringValOrMember`, `layoutQualifiedValOrMember`, `outputQualifiedValOrMember`, `outputQualifiedValSpec`, `richTextOfQualifiedValOrMember`, `stringOfQualifiedValOrMember`, `prettyLayoutOfValOrMember(NoInst)`, `prettyLayoutOfMemberNoInstShort`.
- Methods: `formatMethInfoToBufferFreeStyle`, `prettyLayoutOfMethInfoFreeStyle`, `richTextOfMethInfo`, `stringOfMethInfo`, `richTextOfMethInfoForOverloadError`, `stringOfMethInfoForOverloadError`, `richTextOfMethInfoFSharpStyle`, `stringOfMethInfoFSharpStyle`, `multiLineRichTextOfMethInfos`, `multiLineStringOfMethInfos`.
- Properties: `prettyLayoutOfPropInfoFreeStyle`, `stringOfPropInfo`, `multiLineStringOfPropInfos`.
- Parameters: `stringOfParamData`, `layoutOfParamData`.
- Definitions: `layoutExnDef`, `stringOfExnDef`, `layoutTyconDefn`, `layoutEntityDefn`, `layoutUnionCases`, `isGeneratedUnionCaseField`, `isGeneratedExceptionField`, `richTextOfRecdField`, `stringOfRecdField`, `richTextOfUnionCase`, `stringOfUnionCase`, `richTextOfExnDef`, `stringOfExnDef`, `stringOfFSAttrib`, `stringOfILAttrib`, `fqnOfEntityRef`.
- Signatures of modules: `layoutImpliedSignatureOfModuleOrNamespace: showHeader -> DisplayEnv -> InfoReader -> AccessorDomain -> range -> ModuleOrNamespaceContents -> Layout`.
- Minimal renderings: `minimalRichTextsOfTwoTypes`, `minimalStringsOfTwoTypes`, `minimalRichTextsOfTwoValues`, `minimalStringsOfTwoValues`, `minimalRichTextOfType`, `minimalStringOfType`, `minimalRichTextOfTypeWithNullness`, `minimalStringOfTypeWithNullness`.

**Significant notes**
- All functions take a `DisplayEnv` which controls how types are rendered (e.g. showing typar bindings,
  hiding redundant keywords); some also take an `InfoReader` for cross-assembly symbol lookup.
- `richTextOfMethInfoForOverloadError` is documented as using the extension method's *declaring* type (not
  the receiver type) in "Available overloads" lists, so C#-style extension methods render non-misleadingly
  (issue dotnet/fsharp#9838).
- `layoutImpliedSignatureOfModuleOrNamespace` is the core of signature generation for FSI/reflection.
- `minimalString*`/`minimalRichText*` produce compact renderings that drop shared context, intended for
  tight error messages.

**Cross-references**
- `NicePrint.fs` — implementation of all of the above.
- `MethodOverrides.fsi` — `FormatMethInfoSig` / `FormatOverride` produce `RichText` via these helpers.
- `MethodCalls.fsi` — overload-resolution errors render `MethInfo` groups.
- `SignatureConformance.fsi` — sig/impl mismatch diagnostics render types and members.
- `Text/TaggedText`, `Text/Layout` (Text dir) — `RichText`, `Layout` primitives used as return types.
