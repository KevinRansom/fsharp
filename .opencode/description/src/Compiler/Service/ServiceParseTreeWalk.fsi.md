# ServiceParseTreeWalk.fsi

**Signature for `ServiceParseTreeWalk.fs`.** Declares the generic visitor/traversal framework over the untyped F# AST: the `SyntaxNode` discriminated union of major nodes, the `SyntaxVisitorBase<'T>` visitor class (with default fall-through behaviors so concrete visitors only override what they need), the `SyntaxTraversal.Traverse` entry point, and the `SyntaxNodes` / `ParsedInput` convenience folding/search modules.

## Pipeline role

`FSharpChecker` service-layer file for F# IDE/tooling, and a general AST-walking utility used by several other service modules (e.g. completion contexts, parameter-infos, semantic classification). It is position-driven: `Traverse(pos, parseTree, visitor)` uses a "dive and pick" strategy — every visit offers its child nodes as candidate dives (each with a lazy projection and its range), and `pick` selects the node whose range contains the caret. This powers "what is the (deepest) node under the cursor?"-style IDE queries. `SyntaxNode`/`SyntaxVisitorPath` also give each visited node its ancestry path.

## Namespaces

- `FSharp.Compiler.Syntax` with `open FSharp.Compiler.Syntax`, `FSharp.Compiler.Text`.

## Public types (declared)

- `type SyntaxNode` (`[<RequireQualifiedAccess>]`) — one case per major node kind:
  - `SynPat of SynPat | SynType of SynType | SynExpr of SynExpr | SynModule of SynModuleDecl | SynModuleOrNamespace of SynModuleOrNamespace | SynTypeDefn of SynTypeDefn | SynMemberDefn of SynMemberDefn | SynMatchClause of SynMatchClause | SynBinding of SynBinding | SynModuleOrNamespaceSig of SynModuleOrNamespaceSig | SynModuleSigDecl of SynModuleSigDecl | SynValSig of SynValSig | SynTypeDefnSig of SynTypeDefnSig | SynMemberSig of SynMemberSig`.
  - `member Range: range` — the node's content range.
- `type SyntaxVisitorPath = SyntaxNode list` — the ancestor list.
- `type SyntaxVisitorBase<'T>` (`[<AbstractClass>]`) — each `abstract` member has a `default` implementation:
  - `VisitExpr (path, traverseSynExpr, defaultTraverse, synExpr)` — default `None`; the key extension point (comments document `defaultTraverse expr` vs `traverseSynExpr subExpr` usage).
  - `VisitBinding (path, defaultTraverse, synBinding)` — default: `defaultTraverse`.
  - `VisitComponentInfo (path, synComponentInfo)` — default `None`.
  - `VisitHashDirective (path, hashDirective, range)` — default `None`.
  - `VisitImplicitInherit (path, defaultTraverse, inheritedType, synArgs, range)` — default: visit `synArgs`.
  - `VisitInheritSynMemberDefn (path, componentInfo, typeDefnKind, synType, members, range)` — default `None`.
  - `VisitRecordDefn (path, fieldsAndSpreads, range)` — default `None`.
  - `VisitUnionDefn (path, cases, range)`, `VisitEnumDefn (path, cases, range)` — default `None`.
  - `VisitInterfaceSynMemberDefnType (path, synType)` — default `None`.
  - `VisitLetOrUse (path, isRecursive, defaultTraverse: SynBinding -> _, bindings, range)` — default `None`.
  - `VisitMatchClause`, `VisitModuleDecl` (`defaultTraverse`), `VisitModuleOrNamespace` (`None`), `VisitPat` (`defaultTraverse`), `VisitRecordField (path, copyOpt, recordField: SynLongIdent option)` (`None`), `VisitSimplePats (path, pat)` (`None`), `VisitType` (`defaultTraverse`), `VisitTypeAbbrev (path, synType, range)` (`None`), `VisitAttributeApplication (path, attributes: SynAttributeList)` (`None`), `VisitModuleOrNamespaceSig` (`None`), `VisitModuleSigDecl` (`defaultTraverse`), `VisitValSig (path, defaultTraverse, valSig)` (`defaultTraverse`).
- `module SyntaxTraversal` (public):
  - `val internal rangeContainsPosLeftEdgeInclusive`, `rangeContainsPosEdgesExclusive`, `rangeContainsPosLeftEdgeExclusiveAndRightEdgeInclusive` — the position-in-range predicates with distinct edge semantics.
  - `val internal dive: node: 'a -> range: 'b -> project: ('a -> 'c) -> 'b * (unit -> 'c)` — builds an extendable dive triple.
  - `val internal pick: pos: pos -> outerRange: range -> debugObj: obj -> diveResults: (range * (unit -> 'a option)) list -> 'a option` — selects the first dive whose range contains the caret.
  - `val Traverse: pos: pos * parseTree: ParsedInput * visitor: SyntaxVisitorBase<'T> -> 'T option`.
- `module SyntaxNode` (public, `ModuleSuffix`): active pattern `(|Attributes|) : SyntaxNode -> SynAttributes` — collects attribute applications from a node.
- `module SyntaxNodes` (internal, `ModuleSuffix`):
  - `exists: predicate: (SyntaxVisitorPath -> SyntaxNode -> bool) -> position: pos -> ast: SyntaxNode list -> bool`.
  - `fold: folder: ('State -> SyntaxVisitorPath -> SyntaxNode -> 'State) -> state: 'State -> ast: SyntaxNode list -> 'State`.
  - `foldWhile: folder: ('State -> SyntaxVisitorPath -> SyntaxNode -> 'State option) -> state: 'State -> ast: SyntaxNode list -> 'State`.
  - `tryNode: position: pos -> ast: SyntaxNode list -> (SyntaxNode * SyntaxVisitorPath) option`.
  - `tryPick` / `tryPickLast` — first/deepest matching node (both documented with code examples).
- `module ParsedInput` (public, `ModuleSuffix`): same five operations lifted to `ParsedInput` (`exists`, `fold`, `foldWhile`, `tryNode`, `tryPick`, `tryPickLast`).

## Relation to .fs

The `.fs` additionally contains: the `Range` member implementation on `SyntaxNode` (multi-case range projection), internal `ParsedInputExtensions` (`parsedInput.Contents` mapping `ImplFile`/`SigFile` to `SyntaxNode` lists), the private `traverseUntil` plus the whole `SyntaxTraversal` machinery — a large `traverseSynExpr` default-traverse enumerating every `SynExpr` case, attribute dive helper, stack-safe `traverseSequentials` for deeply nested `Sequential` nodes, Get/Set member normalization (`normalizeMembersToDealWithPeculiaritiesOfGettersAndSetters`), record/inherit "dive into separator" special cases, the signature-side mirrors (`traverseSynModuleOrNamespaceSig`/`traverseSynModuleSigDecl`/`traverseSynValSig`/`traverseSynTypeDefnSig`/`traverseSynMemberSig`), and the two internal folding implementations (`fold`/`foldWhileImpl` with their `pickAll` visitors). The signature exposes the public API and hides those internals.