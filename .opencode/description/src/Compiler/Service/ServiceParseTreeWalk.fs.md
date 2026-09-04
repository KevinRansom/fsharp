# ServiceParseTreeWalk.fs

Full implementation of the generic position-driven AST traversal framework.

## Pipeline role

`FSharpChecker` service-layer file for F# IDE/tooling. `SyntaxTraversal.Traverse(pos, parseTree, visitor)` walks the untyped parse tree and lets `visitor` observe (or override) every major node on the way down to the caret. Instead of a simple recursive descent, traversal uses a **dive-and-pick** protocol: each visited node proposes its children as `dive` results `(range, lazy-project)`; `pick` runs the projections for the children whose ranges contain `pos` (with a whitespace/after-end fallback), returning the first `Some`. This gives correct results even when the caret is at whitespace or just past the end of the last node.

## Namespaces / opens

- `FSharp.Compiler.Syntax` with `open FSharp.Compiler.SyntaxTreeOps`, `FSharp.Compiler.Text`, `Text.Position`, `Text.Range`.

## `SyntaxNode` (RequireQualifiedAccess DU)

Same 14 cases as the signature. The added member:
- `Range` — `SynPat`→`pat.Range`, `SynType`→`ty.Range`, `SynExpr`→`expr.Range`, `SynModule`→`modul.Range`, `SynModuleOrNamespace`→its `Range`, `SynTypeDefn`→`tyDef.Range`, `SynMemberDefn`→`memberDef.Range`, `SynMatchClause`→`matchClause.Range`, **`SynBinding`→`binding.RangeOfBindingWithRhs`** (distinct!), `SynModuleOrNamespaceSig`/`SynModuleSigDecl`→`Range`, `SynValSig`→inner range, `SynTypeDefnSig`/`SynMemberSig`→`Range`.

## `SyntaxVisitorBase<'T>` (AbstractClass)

All members as in the signature, with these notable default behaviors: `VisitExpr`→`None`, `VisitBinding`/`VisitMatchClause`/`VisitModuleDecl`/`VisitPat`/`VisitType`/`VisitModuleSigDecl`/`VisitValSig`→`defaultTraverse`, `VisitImplicitInherit`→visit `synArgs`, everything else→`None`.

## `ParsedInputExtensions` (AutoOpen, private)

Extends `ParsedInput` with `Contents` — `ImplFile file` → `file.Contents |> List.map SyntaxNode.SynModuleOrNamespace`, `SigFile file` → `List.map SyntaxNode.SynModuleOrNamespaceSig`. Entry point for all traversal.

## `SyntaxTraversal` module

### Range predicates
- `rangeContainsPosLeftEdgeInclusive m1 p` — half-open `[,)`: handles the parser's zero-width block-of-lets-without-body case (`range [n,n)` contains `n`).
- `rangeContainsPosEdgesExclusive m1 p` — fully open `(,)`.
- `rangeContainsPosLeftEdgeExclusiveAndRightEdgeInclusive m1 p`.

### Dive/pick protocol
- `dive node range project = (range, fun () -> project node)`.
- `pick pos outerRange debugObj diveResults`:
  - DEBUG-only assertions: dive ranges must be ordered (`posGeq r2.Start r1.End` pairwise) and contained in `outerRange` (`rangeContainsRange outerRange innerTotalRange`); violations are formatted into strings (asserts are commented out — deliberate).
  - Skips zero-width ranges (parser-injected synthetic completions) and ranges not containing the caret.
  - No containing range found → picks the last range left of the caret (the whitespace/after-end case).
  - More than one containing range → DEBUG `printf` about disjoint claims, otherwise `None` (rare; indicates overlapping synthetic nodes).

### `traverseUntil pick pos visitor ast`

The whole traversal engine. Key per-node functions (each wraps its terminal handling in `visitor.VisitX(origPath, defaultTraverse, …)`):

- `traverseSynModuleDecl` — `ModuleAbbrev`/`Exception`/`Open` → None; `NestedModule` (dives decls + attribute-applications); `Let` → `VisitLetOrUse` then binding dives; `Expr` → expr; `Types` → type-defn dives; `Attributes` → attribute dives; `HashDirective` → `VisitHashDirective`; `NamespaceFragment` → recurse.
- `traverseSynModuleOrNamespace` — `VisitModuleOrNamespace` then decl dives with the node pushed on the path.
- `traverseSynExpr` — `VisitExpr(origPath, traverseSynExpr origPath, defaultTraverse, expr)`. The `defaultTraverse` enumerates **every** `SynExpr` case:
  - unary wrappers (LongIdentSet, DotGet, Do, DoBang, Assert, Fixed, DebugPoint, AddressOf, TraitCall, Lazy, InferredUpcast/Downcast, YieldOrReturn(From), FromParseError, DiscardAfterMissingQualificationAfterDot, IndexFromEnd, New, ArrayOrListComputed, TypeApp, DotLambda, Quote, Paren) → dive the inner expr.
  - `InterpolatedString` → dive each `FillExpr`.
  - `Typed` → expr then type; `Tuple`/`ArrayOrList` → element dives.
  - `AnonRecd` → copy-with field dive (`VisitRecordField` after `with`), per-field `VisitRecordField` and value dives, spread dives.
  - `Record` → inherits, copy-with, and per-field handling, with careful offside-column special cases: caret below `inherit` (no separator), caret directly after a field name without a value (`{ r with Field1$ }`), caret between field bindings (`field1 = 5\n$\nfield2 = 5`) via `diveIntoSeparator` which uses a semicolon-position (`scPosOpt`) or the offside column.
  - `ObjExpr` → first `VisitInterfaceSynMemberDefnType` over the implemented interfaces, then dives the base-constructor call (mocked up as `SynExpr.New`) and all bindings/members (each interface's binder path prepends a synthetic `SynMemberDefn.Interface`).
  - `ForEach` (pat, enum, body); `ComputationExpr` — detects `{ Identifier }` being a record-in-progress (`LongOrSingleIdent` → `VisitRecordField` with the lid; array/list computation exprs are excluded); `Lambda` (parsedData pats + body); `MatchLambda`/`Match`/`MatchBang`/`TryWith` (expr + clauses); `App` (reverse order for infix); `LetOrUse` via `VisitLetOrUse`; `IfThenElse`; `IndexRange`; `Sequential` — nested sequentials handled by the stack-safe `traverseSequentials` iterator; binary nodes (`Set`, `DotSet`, `TryFinally`, `While`, `WhileBang`, `DotIndexedGet`, `JoinIn`, `NamedIndexedPropertySet`, `SequentialOrImplicitYield`); ternary (`For`, `DotIndexedSet`, `DotNamedIndexedPropertySet`); `TypeTest`/`Upcast`/`Downcast` (expr + type); and leaves (`Dynamic`, `Ident`, `LongIdent`, `Typar`, `Const`, `Null`, `ImplicitZero`, `LibraryOnly*`, `ArbitraryAfterError`) → None.
- `traversePat` — `Paren`→inner; `As`/`Or`/`ListCons`→both; `Ands`/`Tuple`/`ArrayOrList`→all; `Record`→field patterns; `Attrib`→pat then attribute dives; `LongIdent`→arg pats (`Pats`/`NamePatPairs`); `Typed`→pat then type; `QuoteExpr`→expr; `IsInst`→type; `FromParseError`→inner.
- `traverseSynSimplePats` (used for primary-constructor args) — `Paren`/`Typed`→inner, `Tuple`→try all, `Attrib`→attribute dives.
- `traverseSynType` (starts with `StripParenTypes`) — `App`/`LongIdentApp`→typeName+args; `Fun`; `MeasurePower`/`HashConstraint`/`WithNull`/`WithGlobalConstraints`/`Array`; `StaticConstantNamed`/`Or`; `Tuple` (via `getTypeFromTuplePath`); `StaticConstantExpr`→**`traverseSynExpr []`** (fresh path); `Paren`/`SignatureParameter`; `Intersection`; leaves→None.
- `normalizeMembersToDealWithPeculiaritiesOfGettersAndSetters path traverseInherit` — property getter/setter pairs can share a range: single accessors are rewrapped as `SynMemberDefn.Member`; a get+set pair keeps both projections in one dive slot (trying get first, then set).
- `traverseSynTypeDefn` — `VisitComponentInfo`; then dives attribute applications; `ObjectModel` members via the getter/setter normalizer (with `traverseInherit` capturing the type + range for `VisitInheritSynMemberDefn`); `Simple` reprs: `Record`→`traverseRecordDefn`, `Union`→`traverseUnionDefn`, `Enum`→`traverseEnumDefn`, `TypeAbbrev`→`VisitTypeAbbrev`; then normal members.
- `traverseRecordDefn`/`traverseEnumDefn`/`traverseUnionDefn` — per-field/case attribute dives, then `VisitRecordDefn`/`VisitEnumDefn`/`VisitUnionDefn`.
- `traverseSynMemberDefn` — `Open`→None; `Member`/`GetSetMember`→bindings; `ImplicitCtor`→simple pats; `ImplicitInherit`→dives the type range (`VisitInheritSynMemberDefn` then `VisitImplicitInherit`) and the args (`VisitImplicitInherit`); `AutoProperty`→expr then attrs; `LetBindings` via `VisitLetOrUse`; `AbstractSlot`→slot type then attrs; `Interface`→`VisitInterfaceSynMemberDefnType` then interface member dives; `Inherit`→`traverseInherit`; `ValField`→None; `NestedType`→recurse.
- `traverseSynMatchClause` — `VisitMatchClause`; dives pat, optional `when` guard, result expr.
- `traverseSynBinding` — `SynBindingKind.Do`→expr only; else attribute dives + head pat + expr (via `VisitBinding`).
- `attributeApplicationDives path attributes` — dive per `SynAttributeList` → `VisitAttributeApplication`.
- Signature-side mirrors: `traverseSynModuleOrNamespaceSig`, `traverseSynModuleSigDecl` (`ModuleAbbrev`→None; `NestedModule`; `Val`→val sig; `Types`→type-defn sigs; `Exception`→None; `Open`→None; `HashDirective`; `NamespaceFragment`), `traverseSynValSig` (attrs + type + optional default expr), `traverseSynTypeDefnSig` (component info, attrs, `ObjectModel`→member sigs, `Simple`→records/unions/enums/abbrevs, then members), `traverseSynMemberSig` (`Member`→val sig; `Interface`/`Inherit`→type; `ValField`→attrs; `NestedType`→type-defn sig).
- **Top-level dispatch** (end of `traverseUntil`): folds the whole `ast` node list, unions their ranges into `fileRange`, and dives content modules (impl/sig) or whatever node kinds were passed in.

### `Traverse (pos, parseTree, visitor)`

Just `traverseUntil pick pos visitor parseTree.Contents` — the public entry.

## Module `SyntaxNode`

`(|Attributes|)` — the attribute-collecting active pattern, implemented for: `SynModuleOrNamespace`/`SynModuleOrNamespaceSig` (module attrs), module `Attributes` decls, `SynTypeDefn` component-info attrs, record/union/enum cases/fields, `AutoProperty`, `AbstractSlot`, `ImplicitCtor`, `SynBinding` (incl. return-info), `SynPat.Attrib`, `SynType.SignatureParameter`, `SynValSig`; typar decls (`PrefixList`/`PostfixList`/`SinglePrefix`); via helper active patterns `All` (`List.collect`), `fieldOrSpread`, `unionCase`, `enumCase`, `typar`, `SynComponentInfo`, `SynBinding`; otherwise `[]`.

## Module `SyntaxNodes` (internal)

- `fold folder state ast` — uses a `pickAll` picker (runs **every** dive's projection) and a visitor that, for each node, first folds the enclosing `SynMemberDefn`/`SynMemberSig` parent (so member definitions are visited exactly once from any of their sub-parts) then the node itself; `Types` decls contribute `SynTypeDefn`/`SynTypeDefnSig` nodes; drives `traverseUntil pickAll m.End` over the union range.
- `foldWhileImpl pick pos folder state ast` — same shape but stops as soon as `folder` returns `None` (returning `Some()` as a sentinel `'T option`). Backs `foldWhile`.
- `tryPick chooser position ast` / `tryPickLast` (via `foldWhileImpl`, keeping the last `Some`) / `tryNode position ast` (deepest node whose range contains the position, with its path) / `exists predicate position ast` (via `tryPick` + `Option.isSome`).

## Module `ParsedInput` (public)

Lifts `SyntaxNodes.fold`, `foldWhile`, `tryPick`, `tryPickLast`, `tryNode`, `exists` onto `parsedInput.Contents`.