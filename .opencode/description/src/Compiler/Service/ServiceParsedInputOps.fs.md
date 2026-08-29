# ServiceParsedInputOps.fs

Full implementation of service-layer queries over the untyped F# parse tree (`ParsedInput`).

## Pipeline role

`FSharpChecker` service-layer file for F# IDE/tooling. It powers completion-list classification, dot/duck-typing completion, "add missing open"-style quick fixes, and expression evaluation in the debugger — all operating purely on the syntax tree, so they run before/without type checking.

## Module `SourceFileImpl`

- `IsSignatureFile file` — `.fsi` extension check (ordinal-ignore-case).
- `GetImplicitConditionalDefinesForEditing isInteractive` — `["INTERACTIVE"; "EDITING"]` or `["COMPILED"; "EDITING"]` (used by the foreground parse).

## Completion/context data types

- `CompletionPath = string list * string option`.
- `FSharpInheritanceOrigin` (internal) and `InheritanceContext` (`Class | Interface | Unknown`).
- `RecordContext` with `CopyOnUpdate(range, path) | Constructor(typeName) | Empty | New(path, isFirstField) | Declaration(isInIdentifier)`.
- `RecordSpreadContext` (`Declaration | Construction`).
- `PatternContext` — positional/named union-case fields, union-case field idents, record field idents.
- `MethodOverrideCompletionContext` (`Class | Interface mInterfaceName | ObjExpr mExpr`, struct).
- `CompletionContext` — the full enumeration (listed in the signature).
- `ShortIdent`/`ShortIdents`/`MaybeUnresolvedIdent`; `ModuleKind`; `EntityKind` (`Attribute | Type | FunctionOrValue of isActivePattern | Module of ModuleKind`, with `ToString`).
- `InsertionContextEntity` (`FullRelativeName`, `Qualifier`, `Namespace: string option`, `FullDisplayName`, `LastIdent`, with `ToString`).
- `ScopeKind`; `InsertionContext { ScopeKind; Pos }`.
- `FSharpModule = { Idents: ShortIdents; Range: range }` (internal).
- `OpenStatementInsertionPoint` (`TopLevel | Nearest`).

## Module `Entity` (internal, `ModuleSuffix`)

- `getRelativeNamespace targetNs sourceNs` — strips the target namespace prefix from the source.
- `cutAutoOpenModules autoOpenParent candidateNs` — removes auto-open-module prefix segments.
- `tryCreate (targetNamespace, targetScope, partiallyQualifiedName, requiresQualifiedAccessParent, autoOpenParent, candidateNamespace, candidate)` — the core unresolved-identifier fixer: enumerates prefixes of the unresolved ident (`Array.heads`), requires at least one unresolved part (avoids `open System` false-positives for `System.DateTime.Naaaw`), matches candidate-suffixes, computes `fullOpenableNs`/`restIdents` (respecting `RequireQualifiedAccess` parent length), trims auto-open modules, makes namespaces relative, and produces one `InsertionContextEntity` per candidate (`FullRelativeName`, `Qualifier`, `Namespace`, `FullDisplayName`, `LastIdent`).

## Module `ParsedInput` (public)

Shared helper: `emptyStringSet = HashSet<string>()`.

### `GetRangeOfExprLeftOfDot (pos, parsedInput)`

- `CheckLongIdent longIdent` — walks the idents before `pos`, building `(couldBeBeforeFront, range)`.
- `SyntaxVisitorBase` handling:
  - single ident → DefaultTraverse.
  - `SynExpr.LongIdent` → range of the idents before the dot.
  - `LongIdentSet` → traverse target if the caret is in the RHS, else the lid range.
  - `DotLambda(LongIdent, …)` → itself; `DotLambda(e, …)` → traverse e, mapping to whole range if the result starts where the target starts.
  - `DotGet(e, _, lid, _)` → traverse target, else `CheckLongIdent`; the result unioned with the expr range (so `f(0).X.Y.Z` at the dot gives the whole `f(0).X` prefix).
  - `Set`/`DotSet`/`DotNamedIndexedPropertySet` — same "left of the dot" idea (target first, then the lid); documented comments for the union-ranges logic.
  - `DiscardAfterMissingQualificationAfterDot` (e.g. `bar().`) → target range.
  - `FromParseError` → inner result or the error range.
  - `App(NonAtomic, true, LongIdent(op_ArrayLookup), rhs, _)` when caret is not in rhs — ML `(e).(i)` array lookup: defaultTraverse, else the whole expr range (so intellisense works "on the dot").
  - `Const(Double, …)` → the range (so numeric `.` completions work).
- Result from `SyntaxTraversal.Traverse(pos, parsedInput, visitor)`.

### `TryFindExpressionIslandInPosition (pos, parsedInput)`

Finds a `DotGet`/`LongIdent` chain containing the caret and returns the dotted string (`parts |> String.concat "."`) suitable for debugger evaluation:
- `getLidParts lid` — idents of the long id whose start is at/before the caret.
- Recursive `TryGetExpression foundCandidate expr` — unwraps `Paren` (once a candidate is found), `LongIdent` → lid parts, `DotGet` → left part + lid parts when the caret is in the lid range or a candidate was already found, `FromParseError` → recurse.
- A visitor that first checks `rangeContainsPos expr.Range pos`.

### `TryFindExpressionASTLeftOfDotLeftOfCursor (pos, parsedInput)`

Returns `Some (thatPos, boolTrueIfCursorIsAfterTheDotButBeforeTheIdentifier)` (or `None` when there's no dot):
- `traverseLidOrElse pos optExprIfLeftOfLongId (SynLongIdent(lid, dots, _))` — finds the last dot before `pos`; if none, returns `(expr.End, posGeq lidwd.Range.Start pos)`; otherwise `(lid[n].idRange.End, flag)` where `flag = (lid.Length = n+1) || posGeq lid[n+1].idRange.Start pos` (i.e. `foo.$` vs `foo.$bar`).
- Visitor: when the caret is not in the expr range, only `DiscardAfterMissingQualificationAfterDot` yields `(e.Range.End, false)` (cases like `f(x) . $`); otherwise handles `LongIdent`, `LongIdentSet`, `DotGet` (with an `afterDotBeforeLid` slot yielding `(range.End, true)`), `DotSet`, `Set`, `NamedIndexedPropertySet`, `DotNamedIndexedPropertySet`, `Const(Double)` (at the dot → `(m.End, false)`), `DiscardAfterMissingQualificationAfterDot` (at the dot → `(e.Range.End, false)`), and the `op_ArrayLookup` case. Multiple candidate positions are collected with `dive` and picked with `SyntaxTraversal.pick pos`.

### `GetEntityKind (pos, parsedInput)`

Determines whether the position is on an attribute (`Attribute`), a type (`Type`), a function or value (`FunctionOrValue false`), or a module (`Module kind`):
- `ConstructorPats` active pattern (pats of `SynArgPats.Pats` / `NamePatPairs`).
- Recursive `walk*` family over: attributes (name → `Attribute`, args → `Type`), typars/constraints → `Type`, patterns (`walkPatWithKind` where `LongIdent` patterns carry the given kind), bindings (attrs, head pat, expr, return-info type), interface impls, types (`SynType.LongIdent` → `Type`, wrapped with try/with due to `rangeOfLidwd` corner cases), match clauses (`Some EntityKind.Type` on the pat), and a very broad `walkExprWithKind parentKind`:
  - LongIdent: single ident with arity → `FunctionOrValue false`; dotted idents — if the caret sits on the first part (or no dots), return `parentKind` or `FunctionOrValue false`; else keep drilling.
  - Transparent wrappers pass `parentKind`; binary/ternary nodes try both children; `New`/`TypeTest`/casts try expr then target type.
  - `Record` fields/spreads; `ObjExpr` (obj type, bindings from `unionBindingAndMembers`, interface impls).
  - `TypeApp` passes `Some EntityKind.Type` into the inner expr; `LetOrUse` walk bindings then body; `IfThenElse`; `Ident`; `TraitCall`.
  - `walkSimplePat`, `walkField`, `walkTypeSpread`, `walkValSig`, `walkMemberSig`, `walkMember` (AbstractSlot/Member/GetSetMember/ImplicitCtor/ImplicitInherit/LetBindings/Interface/Inherit/ValField/NestedType/AutoProperty), enum/union cases, `walkTypeDefnSimple`, `walkComponentInfo` (→ `Type` for non-modules), type defns (impl and sig). Dispatch: `SigFile` → None, `ImplFile` → walk.

### `TryGetCompletionContext` machinery

- `insideAttributeApplicationRegex` — matches the most nested `[< … >]` pair.
- `(|Class|Interface|Struct|Unknown|Invalid|)` active pattern over `SynAttribute` lists — categorizes `[<Class/AbstractClass/Interface/Struct>]`; conflicting → `Invalid`.
- `GetCompletionContextForInheritSynMember (componentInfo, typeDefnKind, completionPath)` — maps `SynTypeDefnKind` + attributes to `CompletionContext.Inherit` (Class/Interface/Unknown), `Invalid` (structs, mismatched attributes, ambiguous), or `None`.
- `(|Operator|_|) name e` — matches binary-operator applications (`op_<name>`).
- `isAtRangeOp path` — checks for an `IndexRange` ancestor (`..` completion).
- `(|Setter|_|) e` — `Operator "op_Equality" (SynExpr.Ident id, _)`.
- `posAfterRangeAndBetweenSpaces lineStr m pos` — pos past `m.End` with only whitespace between (on the same line).
- `rangeContainsPosOrIsSpacesBetweenRangeAndPos lineStr m pos` — in-range, or before, or in the whitespace after the range.
- `findSetters argList` — set of already-used property names from a tupled arg list (named-parameter dedup for `ParameterList`).
- `endOfLastIdent` / `lastIdentOfSynLongIdent` / `endOfClosingTokenOrLastIdent` / `endOfClosingTokenOrIdent` — position helpers for constructor/lid ends with optional `>`.
- `(|NewObjectOrMethodCall|_|) e` — `new A(`, `new A<_>(`, `A(`, `A<_>(`, `A.B(`, `A.B<_>(` → `(end-of-name, setters)`.
- `isOnTheRightOfComma pos elements commas current` — pos past the comma matching the given element (via `===`).
- `(|PartOfParameterList|_|) pos precedingArgument path` — matches `Paren :: NewObjectOrMethodCall` paths (and the `Tuple :: Paren :: NewObjectOrMethodCall` variant), gating on `precedingArgument`; used to decide `ParameterList` vs "inside the previous argument".
- `parseLidAux pos plid parts dots` / `parseLid pos (SynLongIdent…)` — splits a long id at the caret into `(plid, residue)`; `A $.B` → None.

### `TryGetCompletionContextOfAttributes (pos, lineStr)`

Fallback used when the AST traversal finds nothing: uncompleted attribute applications (`[< …`) don't appear in the tree, so the current line is analyzed textually — cut leading `;`-separated attributes, verify the remainder is a valid long ident (`IsIdentifierPartCharacter`, `.`, `:`) and return `AttributeApplication` (paired `[< >]` via regex, or a trailing `[<` without closing).

### `TryGetCompletionContextInPattern suppressIdentifierCompletions pat previousContext pos`

Recursive pattern analysis (docstring explains the member/function/lambda suppression rule: `fun x| ->` suppresses, `fun (SingleCase (v1, v|)) ->` shows suggestions):
- `SynPat.LongIdent` in its id-range → `Pattern … Other`.
- `NamePatPairs` → when caret on a field name → `UnionCaseFieldIdentifier(referencedFields, caseIdRange)` (with `NamedUnionCaseField` propagated into the inner pattern); positional tuple handling for last-resort after the last pair.
- `Pats` cases: single `Named` (`Some v|`) → `PositionalUnionCaseField(None, true, …)`; single `Paren(Unit)` / `Paren(Named)` → `PositionalUnionCaseField(Some 0, true, …)`; `Paren(Tuple)` → positional index + per-element recursion with index threading.
- `SynPat.Record` — caret in field id → `RecordFieldIdentifier(referencedFields)`; else recurse; last-resort after the last field (only when all prior fields are `= Wild` with a real name range).
- `Ands`/`ArrayOrList` → any child; `Tuple` → indexed per-element with `PositionalUnionCaseField(Some i, …)` threading + last-comma fallback; `Named` → `Invalid` when suppressed, else the previous context (or `Other`); `FromParseError`/`Attrib`/`Paren` → recurse; `ListCons`/`As`/`Or` → both sides; `IsInst` → `Type`; `Wild` (with nonempty range) → `Invalid`; `Typed` → pat or `Type` by range.

### Main `TryGetCompletionContext (pos, parsedInput, lineStr)` visitor

`SyntaxVisitorBase` with `VisitExpr` and friends:
- `isAtRangeOp path` → `RangeOperator` if nothing deeper.
- `Const(Unit)` under `NewObjectOrMethodCall` → `ParameterList`; `Ident`/single `LongIdent` at end under `PartOfParameterList` → `ParameterList`; `Setter` id at end or before pos → `ParameterList` (with `precedingArgument` to disambiguate `A = 1, $` vs inside `A$ = 1`).
- `Record(None, None, [], _)` → `RecordField Empty`; `TypeApp` with caret in type args → `Type`; `Lambda` → patterns via `TryGetCompletionContextInPattern true …`; `ComputationExpr(ArbitraryAfterError)` when the line contains `"new"` → `Inherit(Unknown, ([], None))` (`{ new | }`).
- `Record`/`AnonRecd` spreads → `RecordSpread Construction`.
- `VisitRecordField (path, copyOpt, field)`: `CopyOnUpdate s.Range` when a copy expr exists; otherwise `contextFromTreePath` — constructor-case (`Record` inside a `SynBinding` inside a type → `Constructor id.idText`), `Record(None, …)` first-field → `New(path, isFirstField)`, unfinished computation expr → `New(path, true)`, else `New(path, false)`; parses the field long id via `parseLid`.
- `VisitInheritSynMemberDefn` → `GetCompletionContextForInheritSynMember` (with `parseLid`).
- `VisitBinding`: return-info (`: int`) → `Type`; head-pattern override contexts:
  - `static member |` → `MethodOverride(Class, …, isStatic=true)`;
  - `override |` / `override _. |` / `override this. |` / `override this.ToStr|` / `static member A|` → `MethodOverride` with the right `hasThis`/`isStatic`/`isMember` flags;
  - `overrideContext path` uses a three-way path match: enclosing plain `TypeDefn` → `Class` (with `spacesBeforeOverrideKeyword` etc.); enclosing `MemberDefn.Interface` in a type → `Interface mInterfaceName`; enclosing `Interface` in an `ObjExpr` → `ObjExpr expr.Range`; a bare `ObjExpr` with `newExprRange` → `ObjExpr`; else `Invalid`.
  - Other `LongIdent` head pats (in `lidwd` range → `Invalid`; in args → per-pattern context), `Named`/`As … Named` → `Invalid` (`let fo|o = 1`).
- `VisitHashDirective` → `Invalid`; `VisitModuleOrNamespace` → `Invalid` when the module/namespace name is followed only by spaces/dots up to the caret; `VisitComponentInfo` → `Invalid` (attrs handled earlier); `VisitLetOrUse` with empty bindings on the same line → `Invalid`.
- `VisitSimplePats` (primary-constructor args): `Named`/`Unit` → `Invalid`; `Typed` → `Type` when in the type range; tuple → per pat.
- `VisitPat` → `TryGetCompletionContextInPattern false …`.
- `VisitModuleDecl`: `Open` → `OpenDeclaration isOpenType` (with a `pos-1` adjustment because the trailing dot is not in the tree — the comment explains the attribute caveat); `NestedModule` ident → `Invalid`.
- `VisitType`: `LongIdent` in range → `Type`.
- `VisitRecordDefn`: field ids → `RecordField(Declaration true)`; in field range or with `FromParseError` type → `Declaration false`; spread → `RecordSpread Declaration`; else `Invalid` in the defn range.
- `VisitUnionDefn`: case id → `Invalid`; field id → `Invalid`; in field range (type) → `UnionCaseFieldsDeclaration`.
- `VisitEnumDefn` → `Invalid` on case ids; `VisitTypeAbbrev` → `TypeAbbreviationOrSingleCaseUnion`; `VisitAttributeApplication` → `AttributeApplication` (or `ParameterList` inside `[<Attr($`); `VisitInterfaceSynMemberDefnType` → `Inherit(Interface, …)` for `FromParseError` types.
- Top level: `SyntaxTraversal.Traverse` result, falling back to `TryGetCompletionContextOfAttributes` when `None`.

### Insertion-context (add-open) machinery

- `GetFullNameOfSmallestModuleOrNamespaceAtPoint (pos, parsedInput)` — accumulates `VisitModuleOrNamespace` ids containing the caret.
- `ConstructorPats` (again); `getLongIdents parsedInput : IDictionary<pos, LongIdent>` — a huge untyped walker registering every `Ident`/long-ident ending position (`addIdent`, `addLongIdent`, `addLongIdentWithDots` register dot-before-id positions for multi-part lids) across attributes, typars, constraints, patterns, bindings, member sigs, members, union/enum cases, records (`SynExpr.Record` field lids), types, measures (walkMeasure), expressions (all `SynExpr` cases incl. `For` loop idents, `ObjExpr` ctor arg idents, `LetOrUse`), type defns (impl + sig), and module decls.
- `GetLongIdentAt parsedInput pos` — dictionary lookup of the long ident ending at `pos`.
- `type Scope = { ShortIdents; Kind: ScopeKind }` (internal).
- `tryFindNearestPointAndModules currentLine ast insertionPoint`:
  - Runs under `DiagnosticsScope(false)` (ignored diagnostics).
  - `doRange kind scope line col` — tracks the nearest point above the current line, preferring the innermost enclosing scope (with `OpenStatementInsertionPoint.TopLevel` snapping); computes the module body indentation from the first decl (`getMinColumn`).
  - `walkSynModuleOrNamespace parent modul` — records `ns`, top-level "Ns1.Ns2.TopModule" namespace split, `TopModule`/`NestedModule`/`Namespace` scope kind using leading-keyword trivia (module keyword line; namespace line minus 1); `addModule`.
  - `walkSynModuleDecl` — nested modules (with `ModuleKeyword` trivia and body indentation), `Open` → `OpenDeclaration` (col = start - 5), `HashDirective` → `HashDirective`.
  - Returns `(scope, ns, pos+1) option` plus a `FSharpModule` list sorted by length descending (shortest prefix first).
- `findBestPositionToInsertOpenDeclaration modules scope pos entity` — if an already-declared module (ending before the current line) starts with the entity idents, place the `open` after that winning module at its start column (TopModule→NestedModule); else the given scope/pos.
- `TryFindInsertionContext currentLine parsedInput partiallyQualifiedName insertionPoint` — returns the closure over `(requiresQualifiedAccessParent, autoOpenParent, entityNamespace, entity)` computing `Entity.tryCreate` results mapped with the best insertion point.
- `AdjustInsertionPoint getLineStr ctx` — corrects the line number: for `TopModule`, snaps to line 1 (implicit module detection via the previous line not being a `module … =`); for `Namespace`, moves below the `namespace` keyword line (searching the preceding lines); others pass through.
- `FindNearestPointToInsertOpenDeclaration currentLine parsedInput entity insertionPoint` — runs the scan and applies `findBestPositionToInsertOpenDeclaration` (fallback `TopModule` at `(1,0)`); then, for **scripts**, ensures leading `#r`/`#reference`/`#load` directives stay above the inserted `open`: finds the last such directive line and remaps the ctx to `HashDirective` scope at `max (lastReferenceLine + 1) pos`.