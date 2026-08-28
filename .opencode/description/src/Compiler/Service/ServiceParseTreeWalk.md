# ServiceParseTreeWalk

**Purpose:** A generic, extensible AST-walking framework over the **untyped** syntax tree (`ParsedInput`). Provides a visitor base class (`SyntaxVisitorBase<'T>`) for custom traversals, a high-level traversal entry point (`SyntaxTraversal.Traverse`), and a curated collection of node-level operations (`SyntaxNode`, `SyntaxNodes`, `ParsedInput`) used by classification, navigation, and code-analysis features to find the node/range containing a position.

**Namespace(s):** `FSharp.Compiler.Syntax`

## Declared types / modules
- `SyntaxNode` (union, `RequireQualifiedAccess`): represents a "major" AST node — `SynPat`, `SynType`, `SynExpr`, `SynModule`, `SynModuleOrNamespace`, `SynTypeDefn`, `SynMemberDefn`, `SynMatchClause`, `SynBinding`, `SynModuleOrNamespaceSig`, `SynModuleSigDecl`, `SynValSig`, `SynTypeDefnSig`, `SynMemberSig`; has `Range` member.
- `SyntaxVisitorPath` (typedef): `SyntaxNode list` — ancestor chain at a node during traversal.
- `SyntaxVisitorBase<'T>` (abstract class): visitor with virtual `Visit*` methods for each node category — `VisitBinding`, `VisitComponentInfo`, `VisitExpr`, `VisitHashDirective`, `VisitImplicitInherit`, `VisitInheritSynMemberDefn`, `VisitRecordDefn`, `VisitUnionDefn`, `VisitEnumDefn`, `VisitInterfaceSynMemberDefnType`, `VisitLetOrUse`, `VisitMatchClause`, `VisitModuleDecl`, `VisitModuleOrNamespace`, `VisitPat`, `VisitRecordField`, `VisitSimplePats`, `VisitType`, `VisitTypeAbbrev`, `VisitAttributeApplication`, `VisitModuleOrNamespaceSig`, `VisitModuleSigDecl`, `VisitValSig`. Each receives `path`, a `defaultTraverse` (or `traverseSynExpr`) continuation, and the node; returns `'T option` (short-circuit on `Some`).
- `ParsedInputExtensions` (private module) + `type ParsedInput with` — extension helpers on `ParsedInput`.
- `SyntaxTraversal` (public module): `rangeContainsPosLeftEdgeInclusive/EdgesExclusive/LeftEdgeExclusiveAndRightEdgeInclusive` (range/pos predicates), `dive`/`pick` (low-level helpers), and `Traverse: pos * ParsedInput * SyntaxVisitorBase<'T> -> 'T option` — the main entry point.
- `SyntaxNode` (public module, `RequireQualifiedAccess`, ModuleSuffix): node-level operations, e.g. `(|Attributes|)` active pattern extracting `SynAttributes` from a `SyntaxNode`; (further operators listed through the .fsi — see file).
- `SyntaxNodes` (internal module, `RequireQualifiedAccess`, ModuleSuffix): combinators over node lists — `exists`, `fold`, `foldWhile`, `tryNode` (deepest node + path at a position), `tryPick` (first node matching a chooser down to a position), `tryPickLast` (last/deepest such node). All are short-circuited at the requested position.
- `ParsedInput` (public module, `RequireQualifiedAccess`, ModuleSuffix): the same combinators (`exists`, `fold`, `foldWhile`, `tryNode`, `tryPick`, `tryPickLast`) but taking a `ParsedInput` directly rather than a `SyntaxNode list`.

## Public API surface
- `SyntaxTraversal.Traverse (pos, parseTree, visitor)` — custom traversal with a visitor.
- `ParsedInput.tryNode/tryPick/tryPickLast/exists/fold/foldWhile` — high-level "find node at position" queries used e.g. for semantic classification, unnecessary-parens detection (see doc examples), and similar features.
- `SyntaxVisitorBase<'T>` — for writing custom AST walkers in the language-server/consumers.

## Internal helpers / notable details
- `dive`/`pick`: `dive node range project -> (range * (unit -> 'c))` defers the projection; `pick` selects the dive result containing `pos` — this lazy design is what makes traversal efficient when many branches don't contain the target position.
- `SyntaxNodes` is internal; `ParsedInput` (public) and `SyntaxNode` are the exposed surfaces.

## Significant internal logic
- The visitor design separates *which* sub-node to descend into (caller-controlled via `defaultTraverse`/`traverseSynExpr`) from *what* to report (`'T option`), enabling both full-tree visits and position-targeted searches with early exit.
- `foldWhile` is the general short-circuiting primitive; `exists`/`tryPick`/`tryPickLast` build on top.
- Range predicates use inclusive/exclusive edge variants to handle the ambiguity of a position exactly on a range boundary (e.g. cursor just before/after a paren).

## Cross-references
- `src/Compiler/SyntaxTree` (`SynExpr`, `SynPat`, `SynType`, `SynModuleOrNamespace`, `SynTypeDefn`, `SynMemberDefn`, etc. — the node types being wrapped)
- `SemanticClassification.fs` (consumer of `SyntaxTraversal.Traverse` / `ParsedInput.tryPick`)
- `ServiceStructure.fs` (alternative range-collection approach for outlining)
- `ServiceParamInfoLocations.fs` (uses `SyntaxTraversal.rangeContainsPos*`)
