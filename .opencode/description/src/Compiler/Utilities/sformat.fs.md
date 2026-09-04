# sformat.fs

**Purpose**: The compiler's structured (pretty-)printing engine. This single file is compiled **twice** in the codebase: in the compiler (where `#if COMPILER` selects `namespace FSharp.Compiler.Text`) as the internal implementation of `printf "%A"` formatting and F# Interactive's rich formatter, and in FSharp.Core (without `COMPILER`, `namespace Microsoft.FSharp.Text.StructuredPrintfImpl`) as the engine behind `printfn "%A"` — kept as one implementation so `%A` printing and fsi.exe stay behaviorally identical. It converts values to a `Layout` DAG (with breakable joints) and then squashes that layout to a width, optionally emitting tagged (syntax-colored) text.

**Namespace(s)**: `FSharp.Compiler.Text` when `COMPILER`, else `Microsoft.FSharp.Text.StructuredPrintfImpl` (conditional).

**Modules / Types declared**:

- `type TextTag` — `[<StructuralEquality; NoComparison>]` UDT: ~35 tags classifying text (`Keyword`, `StringLiteral`, `NumericLiteral`, `Class`, `Record`, `UnionCase`, `Module`, `Namespace`, `TypeParameter`, `Punctuation`, `ActivePatternCase`, ...).
- `type TaggedText(tag, text)` — a string with a `TextTag`; `Tag`, `Text` members, `ToString` includes the tag.
- `type TaggedTextWriter` — abstract: `Write: TaggedText -> unit`, `WriteLine`.
- `type Joint` — `[<StructuralEquality; NoComparison>]` UDT: `Unbreakable | Breakable of indentation:int | Broken of indentation:int` — a joint between two layouts.
- `type Layout` — `[<NoEquality; NoComparison>]` UDT: `ObjLeaf of bool*obj*bool | Leaf of bool*TaggedText*bool | Node of Layout*Layout*Joint | Attr of string*(string*string)list*Layout`; plus `JuxtapositionLeft`/`JuxtapositionRight` (suppress spacing) and `static JuxtapositionMiddle`.
- `[<NoEquality; NoComparison>] type IEnvironment` — `GetLayout: obj -> Layout`, `MaxColumns`, `MaxRows` (the extensibility point for FSI print intercepts).
- `[<AutoOpen>] module TaggedText` — `mkTag`, `length`, `toText`, and ~60 tagged literals/helpers (`tagClass`, `tagKeyword`, `leftParen`, `comma`, `keywordTrue`, `structUnit`, `arrow`, ...). Compiler-only additions include `keywordFunctions` (a `Set<string>` of built-in function keyword names used to color module-bindings like `list`), `tagModuleBinding`, `tagAlias`, `tagNamespace`, `tagSpace`, etc.
- `[<AutoOpen>] module Layout` — layout combinators (see API).
- `type FormatOptions` — `[<NoEquality; NoComparison>]` record: `FloatingPointFormat`, `AttributeProcessor`, `FormatProvider`, `BindingFlags`, `PrintWidth`, `PrintDepth`, `PrintLength`, `PrintSize`, `ShowProperties`, `ShowIEnumerable`, plus (COMPILER-only) `PrintIntercepts` and `StringLimit`; `static member Default` (width 80, depth/length 100, size 10000, `g10`, `ShowIEnumerable = true`).
- `module ReflectUtils` — reflection analysis of values: `type TypeInfo`, `type ValueInfo` (`TupleValue`, `FunctionClosureValue`, `RecordValue`, `UnionCaseValue`, `ExceptionValue`, `NullValue`, `UnitValue`, `ObjectValue`), `type TupleType`, `type RecordKind`, `module Value` (`GetValueInfoOfObject`, `GetValueInfo`), and type predicates (`isListType`, `isUnitType`, `isOptionTy`, `isNamedType`, `equivHeadTypes`).
- `module Display` — the formatting engine (see API).

**Public API surface** (significant):

`module Layout`: `emptyL`, `isEmptyL`, `objL`, `wordL`, `sepL`, `leftL`, `rightL`, `endsWithL` (COMPILER), joins `^^` (unbreakable), `++/--/---/----/-----` (breakable, indent 0–4), `@@`, `@@-`, `@@--`, `@@---`, `@@----` (broken, indent 0–4), `commaListL`, `spaceListL`, `semiListL`, `sepListL`, `bracketL`, `squareBracketL`, `braceL`, `tupleL`, `aboveL`, `aboveListL`, `optionL`, `listL`, `tagAttrL`, `unfoldL` (bounded unfold with truncation).

`module Display`: `string_of_int`, `typeUsesSystemObjectToString`, `catchExn`, `type Breaks` (a savings stack used by the squasher; `pushBreak`/`popBreak`/`forceBreak`/`breaks0`), `squashToAux (maxWidth, leafFormatter) layout` (the break-forcing fit algorithm), `combine`, `showL opts leafFormatter layout` (render a broken layout to a string), `outL outAttribute leafFormatter chan layout` (COMPILER; render to a `TaggedTextWriter`, invoking the attribute processor around `Attr` nodes), `unpackCons`, `getListValueInfo`, layout builders `structL`/`nullL`/`unitL`/`makeRecordL`/`makePropertiesL`/`makeListL`/`makeArrayL`/`makeArray2L`, `getProperty`, `getField`, `formatChar`, `formatString`, `formatStringInWidth` (COMPILER; truncates very long strings to `"prefix"+[N chars]`), `type Precedence` (`BracketIfTupleOrNotAtomic | BracketIfTuple | NeverBracket`), `[<StructuralEquality>] type ShowMode` (`ShowAll | ShowTopLevelBinding`), `isSetOrMapType`, `messageRegexLookup`/`illFormedBracketPatternLookup`, `leafFormatter opts obj` (formats scalars to F# literal text: `null`, `nan`, `1L`, `255uy`, `4.0f`, `'c'`, etc.), and the COMPILER entry points `any_to_layout options (value, type)`, `squashTo width layout`, `squash_layout`, `asTaggedTextWriter`, `output_layout_tagged`, `layout_to_string`, `fsi_any_to_layout`; and the non-COMPILER entry point `anyToStringForPrintf`.

**Internal helpers**:

- `ObjectGraphFormatter(opts, bindingFlags)` (COMPILER) — the per-value formatter: `nestedObjL`/`objL` (recursive descent with cycle detection via a `path` Dictionary, depth/size budgeting via `PrintDepth`/`PrintSize`), `reprL` (dispatch on `ValueInfo`: tuples, records, lists, unions, exceptions, closures, strings, arrays, maps/sets, sequences, enums, properties), `stringValueL`, `arrayValueL` (1-D and 2-D with `bound1/bound2` annotations), `mapSetValueL`, `sequenceValueL` (respects `ShowIEnumerable`; suppresses `IQueryable`), `objectValueWithPropertiesL` (honors `DebuggerBrowsable(Never)`), `functionClosureL` (`<fun:typename>`), `unionCaseValueL`, `fsharpExceptionL`, `recordValueL`, `tupleValueL`, `bracketIfL`; `format(showMode, x, xty)`.
- `structuredFormatObjectL` — implements `[<StructuredFormatDisplay("{Prop}...")>]` with escaped-bracket (`\{`) support via regex, string property results rendered raw, non-string property results re-logged with a reduced depth (`depthLim / 10`).
- `Display.Precedence` drives where brackets are inserted when combining nested values.

**Significant internal logic**:

- **Two-compilation design**: one source, `#if COMPILER` guards the FSI-extensions (`PrintIntercepts`, `StringLimit`, tagged text writers, `PrintIntercepts`) and the FSharp.Core-only `anyToStringForPrintf` entry point, keeping FSI and `%A` identical.
- **Squashing** (`squashToAux`): a single pass over the layout maintaining a "breaks" stack of savings (space saved by breaking a joint). When a leaf doesn't fit on the line, the engine breaks the innermost breakable joint with positive saving (negating its stack entry to record "broken") and re-fits; this is the classic de Clercq-style break optimization that avoids exponential blowup. Broken joints re-indent by their `indent` parameter.
- **Juxtaposition flags** on `Leaf`/`ObjLeaf` suppress the space around operators/brackets so layouts like `a::b` or `(x)` render without spurious spaces.
- **Cycle detection** in `objL` (a `HashIdentity.Reference` dictionary of objects seen on the current path) renders `...` for self-referential values.
- **Bounded printing**: `PrintDepth` (nesting), `PrintLength` (per-collection items via `boundedUnfoldL`), and `PrintSize` (total node count) are all enforced, truncating with `...`.

**Cross-references**: `sformat.fsi` in the same directory is the corresponding public-internal contract. Related compiler text utilities: `TaggedCollections.fs`, `lib.fs` (namespace home of `Internal.Utilities` siblings used here via `Internal.Utilities.Library`). The F# Interactive fsi object wires `PrintIntercepts` into `FormatOptions`; the language services (FSharp.Compiler.Service) call `any_to_layout`/`output_layout_tagged` to emit highlighted display text for editor tooltips and F#.
