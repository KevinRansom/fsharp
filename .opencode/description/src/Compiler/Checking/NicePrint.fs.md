# NicePrint.fs

**Purpose**
Implements the "nice printing" of TAST types, signatures, and declarations into `Layout`/`RichText`/`string`
form. Used across the compiler for error messages, IntelliSense/quick-info text, FSI responses, and
signature generation (`#si`-style output). A very large module (~3100 lines) of layout combinators and
type-signature printers.

**Namespace(s)**
`module internal FSharp.Compiler.NicePrint`

**Modules / Types declared**
- `PrintUtilities` (`AutoOpen` module) — layout primitive helpers: brackets/angles/braces (`bracketIfL`, `squareAngleL`, `squareAngleReturn`, `angleL`, `braceL`, `braceMultiLineL`, `braceBarL`), `addColonL`, `comment`, `isDiscard`, `ensureFloat`, plus multi-line curried-argument layout helpers.
- `layoutBuiltinAttribute` — renders a `BuiltinAttribInfo` as a type layout.
- `squashToWidth` — collapses a layout to a target width (for single-line rendering).

**Type layout / printing entry points**
- `layoutTyparConstraint`, `layoutType`, `outputType` — lay out / print a `TType` under a `DisplayEnv`.
- `outputTypars`, `outputTyconRef`, `layoutTyconRef` — printers for typar lists and tycon refs.
- `layoutConst` — render a `Const` within a type.
- `prettyLayoutOfType`, `prettyLayoutOfTypeNoCx`, `prettyRichTextOfTy`, `prettyStringOfTy(NoCx)` — pretty type rendering (with/without context info).
- `richTextOfTy` / `stringOfTy` — raw (non-pretty) type rendering.
- `prettyLayoutOfTypar`, `layoutTyparConstraint` — typar/constraint rendering.
- `richTextOfTyparConstraints`, `stringOfTyparConstraints`, `richTextOfTyparConstraint`, `stringOfTyparConstraint`.
- `prettyLayoutOfTrait` — render a trait constraint info.

**Signature layouts**
- `prettyLayoutOfMemberSig` — full member signature (typars, params, return type).
- `prettyLayoutOfUncurriedSig` — uncurried signature layout (used for "available overloads").
- `prettyLayoutsOfUnresolvedOverloading` — layout triple for overloads that couldn't be disambiguated.
- `prettyLayoutOfInstAndSig` — instantiation + signature layout composite.
- `layoutOfValReturnType` — layout of a value's return type.

**Value / member printers**
- `outputValOrMember`, `richTextValOrMember`, `stringValOrMember` — print a value member.
- `layoutQualifiedValOrMember`, `outputQualifiedValOrMember`, `outputQualifiedValSpec`, `richTextOfQualifiedValOrMember`, `stringOfQualifiedValOrMember`.
- `prettyLayoutOfValOrMember`, `prettyLayoutOfValOrMemberNoInst`, `prettyLayoutOfMemberNoInstShort`.
- `dataExprL` — layout of a data expression (pattern-ish).

**Method / property printers**
- `formatMethInfoToBufferFreeStyle`, `prettyLayoutOfMethInfoFreeStyle` — free-style (unqualified) method layout.
- `richTextOfMethInfo` / `stringOfMethInfo` — render a `MethInfo`.
- `richTextOfMethInfoForOverloadError` / `stringOfMethInfoForOverloadError` — "Available overloads" list rendering (C#-style extension methods use the declaring type, issue dotnet/fsharp#9838).
- `richTextOfMethInfoFSharpStyle` / `stringOfMethInfoFSharpStyle` — F#-style signature rendering.
- `multiLineRichTextOfMethInfos` / `multiLineStringOfMethInfos`.
- `prettyLayoutOfPropInfoFreeStyle`, `stringOfPropInfo`, `multiLineStringOfPropInfos`.
- `layoutOfParamData`, `stringOfParamData`.

**Type-definition printers**
- `layoutTyconDefn`, `layoutEntityDefn` — full type/entity definition layout.
- `layoutUnionCases`, `richTextOfUnionCase` / `stringOfUnionCase`.
- `richTextOfRecdField` / `stringOfRecdField`.
- `layoutExnDef`, `richTextOfExnDef` / `stringOfExnDef`.
- `isGeneratedUnionCaseField`, `isGeneratedExceptionField` — detect compiler-generated members.
- `stringOfFSAttrib`, `stringOfILAttrib`.
- `fqnOfEntityRef` — fully-qualified name of an entity.
- `layoutImpliedSignatureOfModuleOrNamespace` — `#si`-style signature of a module/namespace (used by FSI/reflection).

**"Minimal" printers (for error messages)**
- `minimalRichTextsOfTwoTypes` / `minimalStringsOfTwoTypes` — render two types side by side, omitting shared context.
- `minimalRichTextsOfTwoValues` / `minimalStringsOfTwoValues`.
- `minimalRichTextOfType` / `minimalStringOfType` — compact single-type rendering.
- `minimalRichTextOfTypeWithNullness` / `minimalStringOfTypeWithNullness`.

**Significant internal logic**
- Layouts are built from `FSharp.Compiler.Text.Layout` combinators (`^^`, `@@--`, etc.) and rendered
  through `LayoutRender`; the `PrintUtilities` module supplies the bracketing/keyword primitives shared by
  all the printers.
- `squashToWidth` enforces single-line output (used e.g. in tooltips).
- `layoutImpliedSignatureOfModuleOrNamespace` is the workhorse behind `#si` and the "implied signature"
  API used by FSI and the reflection API.
- Overload-error rendering (`...ForOverloadError`) was changed to use the extension method's declaring type
  rather than the receiver type so C#-style extension calls are not misleading (dotnet/fsharp#9838).
- The `DisplayEnv` parameter controls how types are displayed (showing typar bindings, hiding redundant
  keywords, etc.).

**Cross-references**
- `NicePrint.fsi` — public contract.
- `MethodOverrides.fs` — `FormatMethInfoSig` / `FormatOverride` rely on these printers.
- `MethodCalls.fs` — overload resolution errors render candidate overloads via `multiLine*OfMethInfos`.
- `SignatureConformance.fs` — error messages render sig vs. impl signatures.
- `TypeHierarchy.fs` — `RichText` building shared.
- `Text.Layout` / `Text.LayoutRender` (Text dir) — the layout engine used here.
