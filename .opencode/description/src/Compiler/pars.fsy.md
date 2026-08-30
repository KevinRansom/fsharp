# pars.fsy — F# PARS Parser Specification

**Purpose**: The PARS (occamyacc-style) grammar specification that turns the token stream
produced by `lex.fsl` into the typed-syntax AST (the `SynExpr`/`SynPat`/`SynType`/
`SynTypeDefn`/`SynModuleDecl` algebra, i.e. `SyntaxTree`) consumed by the F# type checker.
It defines the five entry points `implementationFile`, `signatureFile`, `interaction`,
`typedSequentialExprEOF`, and `typEOF`.

> **Note on naming (do not confuse):** this *large* `pars.fsy` (≈5900+ lines) is the
> **active full F# parser** in this repo — the build compiles it to the
> `FSharp.Compiler.Parser` module (see `FSharp.Compiler.Service.fsproj`,
> `<FsYacc Include="pars.fsy"> … --module FSharp.Compiler.Parser`). Do **not** confuse it
> with the small 62-line `pppars.fsy`, which is a separate, tiny `#if`/`#elif`-condition
> parser generated as `FSharp.Compiler.PPParser`. Similarly, `lex.fsl` (the full lexer,
> module `FSharp.Compiler.Lexer`) is the companion to this file, while `pplex.fsl`
> (module `FSharp.Compiler.PPLexer`) is the companion to `pppars.fsy`.

The grammar is compiled to the `FSharp.Compiler.Parser` PARS module; actions are embedded
F# that build `SyntaxTree` nodes via the `SyntaxTreeOps` helpers and the
`SynExpr`/`SynPat`/… constructors.

## Header (the `%{ ... %}` F# block, lines 3-36)

- `open`s the needed namespaces: `Internal.Utilities(.Text.Parsing)`,
  `FSharp.Compiler.{AbstractIL, DiagnosticsLogger, Features, LexerStore, ParseHelpers,
  Syntax, SyntaxTrivia, Syntax.PrettyNaming, SyntaxTreeOps, Text(.Position/.Range), Xml}`.
- `#nowarn "1182"`/`"3261"` silence warnings in generated code.
- **`parse_error_rich` (lines 33-34)** — the **callback the generated parser** invokes to
  initiate error recovery. It wraps the current `ParseErrorContext` into a
  `SyntaxError(box ctxt, ctxt.ParseState.LexBuffer.LexemeRange)` and reports it via
  `errorR`. This is the central error-handling hook: whenever a rule containing an `error`
  non-terminal fires, `parse_error_rich` runs first, so every recovery point is also a
  report point. (Note: the name is special — the generator requires it to be
  exactly `parse_error_rich`.)

## Tokens / `%type` declarations (lines 38-158)

- **State-changing string/brace tokens** (lines 38-45): `BYTEARRAY`, `STRING`,
  `INTERP_STRING_BEGIN_END`, `INTERP_STRING_BEGIN_PART`, `INTERP_STRING_PART`,
  `INTERP_STRING_END`, `LBRACE`, `RBRACE` — each carries a
  `ParseHelpers.LexerContinuation` so the parser can hand lexer state back to the lexer
  when it resumes (see the `LexerContinuation` mechanism in `lex.fsl`).
- `KEYWORD_STRING` (e.g. `__SOURCE_DIRECTORY__`), `IDENT`, `HASH_IDENT`, the operator
  families (`INFIX_STAR_STAR_OP`, `INFIX_COMPARE_OP`, `INFIX_AT_HAT_OP`, `INFIX_BAR_OP`,
  `PREFIX_OP`, `INFIX_STAR_DIV_MOD_OP`, `INFIX_AMP_OP`, `PLUS_MINUS_OP`,
  `ADJACENT_PREFIX_OP`, `FUNKY_OPERATOR_NAME`, `PERCENT_OP`, `BINDER`).
- All integer/float/char literals: `INT8`/`UINT8` (with a "bad max" `bool`), `INT16`/
  `UINT16`, `INT32`/`INT32_DOT_DOT`/`UINT32`, `INT64`/`UINT64`, `NATIVEINT`/
  `UNATIVEINT`, `IEEE32`, `IEEE64`, `CHAR`, `DECIMAL`, `BIGNUM`.
- `LESS`/`GREATER` with a `bool` flag the LexFilter sets when the tokens are type
  applications vs. comparison.
- All F# keywords: `LET`, `YIELD`, `YIELD_BANG`, `AND_BANG`, `MODULE`, `NAMESPACE`,
  `DELEGATE`, `CONSTRAINT`, `BASE`, `AND`, `AS`, `ASSERT`, `ASR`, `BEGIN`, `DO`, `DONE`,
  `DOWNTO`, `ELSE`, `ELIF`, `END`, `EXCEPTION`, `FALSE`, `FOR`, `FUN`, `FUNCTION`, `IF`,
  `IN`, `JOIN_IN`, `FINALLY`, `LAZY`, `OLAZY`, `MATCH`, `MATCH_BANG`, `MUTABLE`, `NEW`,
  `OF`, `OPEN`, `OR`, `REC`, `THEN`, `TO`, `TRUE`, `TRY`, `TYPE`, `VAL`, `INLINE`,
  `INTERFACE`, `INSTANCE`, `CONST`, `WHILE`, `WHILE_BANG`, `WITH`, `HASH`, `AMP`,
  `AMP_AMP`, … plus punctuation (`LPAREN`/`RPAREN`/`RPAREN_COMING_SOON`/`RPAREN_IS_HERE`,
  `LPAREN_STAR_RPAREN`, `STAR`, `COMMA`, `RARROW`, `G…`, `LBRACE_BAR`, `LBRANK_LESS`,
  `BAR_RBRACK`/`BAR_RBRACE`, `GREATER_RBRANK`, `BAR_JUST_BEFORE_NULL`, …) and
  access/visibility (`PUBLIC`, `PRIVATE`, `INTERNAL`, `GLOBAL`), members (`STATIC`,
  `MEMBER`, `CLASS`, `ABSTRACT`, `OVERRIDE`, `DEFAULT`, `CONSTRUCTOR`, `INHERIT`,
  `EX…`, `VOID`, `SIG`).
- **LexFilter `#light` offside tokens** (lines 106-149): `OLET`, `OBINDER`, `OAND_BANG`,
  `ODO`, `ODO_BANG`, `OTHEN`, `OELSE`, `OWITH`, `OFUNCTION`, `OFUN`, `ORESET`,
  `OBLOCKBEGIN`, `OBLOCKSEP`, `OEND`, `ODECLEND`, `ORIGHT_BLOCK_END`, `OBLOCKEND`,
  `OBLOCKEND_COMING_SOON`/`OBLOCKEND_IS_HERE`, `OINTERFACE_MEMBER`, `FIXED`, `ODUMMY`.
  These are **injected by the LexFilter** (not the raw lexer) to implement #light
  indentation-based block structure.
- `HIGH_PRECEDENCE_BRACK_APP` / `HIGH_PRECEDENCE_PAREN_APP` /
  `HIGH_PRECEDENCE_TYAPP` — artificial tokens inserted to resolve `f (x)` vs `f(x)`
  application/type-application precedence.
- Artificial/trivia tokens: `LEX_FAILURE`, `COMMENT`, `WHITESPACE`, `HASH_LINE`,
  `INACTIVECODE`, `LINE_COMMENT`, `STRING_TEXT`, `EOF`, and `HASH_IF`/`HASH_ELSE`/
  `HASH_ENDIF`/`HASH_ELIF`/`WARN_DIRECTIVE` (each with range + lexed text +
  `LexerContinuation`).

## `%start` (line 157)

```
%start signatureFile implementationFile interaction typedSequentialExprEOF typEOF
```

`%type` declarations (lines 158-193) assign concrete types to every non-terminal, e.g.
`SynExpr` for `atomicExpr`/`appExpr`/`declExpr`/`minusExpr`/`atomType`/…;
`SynPat` for `atomicPatterns`/`headBindingPattern`/…; `SynType` for `typ`/`atomType`/…;
`SynModuleDecl list` for `moduleDefnsOrExprPossiblyEmptyOrBlock`; `SynTypeDefnSig list`
for `tyconSpfnList`; `ParsedImplFile` for `implementationFile`; `ParsedSigFile` for
`signatureFile`; `ParsedScriptInteraction` for `interaction`; `Ident` for `ident`.

## Precedence declarations (lines 195-383)

A long, heavily-commented block establishing associativity/precedence for shift-reduce
conflict resolution. Selected (lowest→highest), from the file:

- `%nonassoc prec_recover` — lowest; the "last chance" error-recovery precedence.
- `%nonassoc prec_args_error`, `%nonassoc prec_atomexpr_lparen_error`.
- `%right AS`; `%nonassoc prec_wheretyp_prefix`; `%right WHEN`;
  `%nonassoc prec_pat_pat_action`.
- `%left prec_then_before` / `%nonassoc prec_then_if` / `%left BAR`.
- `%right SEMICOLON prec_semiexpr_sep OBLOCKSEP` / `%right prec_defn_sep`.
- `%nonassoc prec_atompat_pathop`; `%nonassoc INT8 UINT8 … DECIMAL`;
  `%nonassoc INTERP_STRING_*`; `%nonassoc LPAREN LBRACE LBRACK_BAR`;
  `%nonassoc TRUE FALSE UNDERSCORE NULL`.
- `%nonassoc prec_typ_prefix` / `prec_tuptyp_prefix` / `prec_tuptyptail_prefix` /
  `prec_toptuptyptail_prefix`; `%right RARROW`; `%nonassoc IDENT LBRACK`.
- `%nonassoc prec_opt_attributes_none`.
- `%left HIGH_PRECEDENCE_BRACK_APP` / `HIGH_PRECEDENCE_PAREN_APP` /
  `HIGH_PRECEDENCE_TYAPP` (highest, lines 380).
- `%nonassoc prec_interaction_empty`.

The leading comment (lines 195-240) explains the precedence model, advises using
precedences sparingly ("cookbook" advice), and notes how dummy precedence terminals
(`prec_*`) can be assigned to rules via `%prec` to disambiguate.

## Major productions and their roles

- **`interaction:` (line 394)** — the F# Interactive (FSI) entry. Wraps
  `interactiveItemsTerminator` into `ParsedScriptInteraction.Definitions`; handles the
  `SEMICOLON` separator and `OBLOCKSEP`. `interactiveTerminator` (line 406) is
  `SEMICOLON_SEMICOLON` or `EOF` (calling `checkEndOfFileError`).
  `interactiveItemsTerminator`/`interactiveDefns`/`interactiveExpr`/`interactiveHash`
  (lines 412-476) define what can be swallowed in one FSI chunk (module defs, decl
  exprs, `#` directives) — notably **not** `#`-directives that must be processed
  separately (e.g. `#use`).
- **`hashDirective:` (line 482)** — `# id args…`; produces a `SynModuleDecl.HashDirective`.
  `hashDirectiveArgs`/`hashDirectiveArg` (lines 489-498) for the argument list.
- **`signatureFile:` (line 520)** — F# signature `.fsi` entry; delegates to
  `fileNamespaceSpecs`. `moduleIntro`/`namespaceIntro` (536/556) are the `module path`,
  `namespace path`, `module path = path'`, `namespace path = path'` starts.
  `fileNamespaceSpecs`/`fileNamespaceSpecList`/`fileNamespaceSpec` (567-599) build
  `ParsedSigFile` (+ `ParsedSigFileFragment.NamespaceFragment` / `.NamedModule`).
  `fileModuleSpec` (line 602) is the single module that makes up the signature and
  produces a `SynModuleOrNamespaceSig`.
- **`moduleSpfnsPossiblyEmptyBlock:` (line 632)** — the `OBLOCKBEGIN`/`oblockend`
  block wrapper (with `recover` variants for error recovery).
  `moduleSpfns`/`moduleSpfn` (660/671) enumerate the allowed signature decls.
- **`valSpfn:` (line 745)** — `val` binding specification with optional type / literal
  value / `static optimization` / return type. `optLiteralValueSpfn` (765) for
  `val x = <const>`, `moduleSpecBlock` (779) wraps block-structured specs.
- **`tyconSpfnList:` (line 796)** and related `tyconSpfn`/`tyconSpfnRhs`
  (820/865)/`tyconClassSpfn` (907)/`classSpfnBlock*` (925-1005)/`classMemberSpfn`
  (968)/`classMemberSpfnGetSet` (1052)/`memberSpecFlags` (1106)/`exconSpfn` (1112)/
  `opt_classSpfn` (1119) — the full surface for **type definitions in signature files**
  (including record, union, class, delegate, exception specs).
- **`implementationFile:` (line 1132)** — the compiler's main entry for `.fs` files.
  ```
  | fileNamespaceImpls EOF      { checkEndOfFileError $2; $1 }
  | fileNamespaceImpls error EOF { $1 }
  | error EOF                    { …emptyImplFileFrag … }
  ```
  The "catastrophic" `error EOF` rule (line 1142) yields a single empty
  `ParsedImplFileFragment.AnonModule` so the compiler is still well-formed even though
  no intellisense is available (see the comment at 1139-1141).
- **`fileNamespaceImpls:` (line 1148)** — assembles the top-level structure, emitting
  `ParsedImplFile` and `ParsedImplFileFragment.{AnonModule|NamespaceFragment|NamedModule}`.
  Enforces the rule: if a namespace is present, the first file module may only contain
  `#` directives (enforced by `FSComp.SR.parsOnlyHashDirectivesAllowed`).
  `fileNamespaceImpl`/`fileNamespaceImplList` (1170-1185) and
  `fileModuleImpl` (line 1186) follow the same pattern.
- **`moduleDefnsOrExprPossiblyEmptyOrBlock:` (1217)** — the block content that can
  follow `OBLOCKBEGIN` in an implementation file. `moduleDefns` (1274) is the
  top-level `let`/`module`/`type`/`open`/… decl sequence;
  `moduleDefnOrDirective` (1295) separates `SynModuleDecl`s from `SynModuleDecl.HashDirective`s.
- **`moduleDefn:` (line 1305)** — the workhorse. Alternatives (each with `%prec` where
  needed) cover:
  1. non-`#light` `let` definitions (`opt_attributes opt_access defnBindings %prec decl_let`)
  2. `#light` `let`/`do` bindings (`hardwhiteLetBindings %prec decl_let`)
  3. non-`#light` `do` definitions (`doBinding %prec decl_let`)
  4. `type …` definitions (`typeNameInfo opt_ACCESS typeKeyword tyconDefn tyconDefnList`)
     — emits `SynModuleDecl.Types`.
  5. `exception …` definitions (`exconDefn`) — emits `SynModuleDecl.Exception`.
  6. `module` definitions (`moduleIntro EQUALS namedModuleDefnBlock`) — emits
     `SynModuleDecl.ModuleAbbrev` or `SynModuleDecl.NamedModule`.
  7. incomplete `module` / `OPEN` / other decls — each has an `error`-terminated variant
     (e.g. lines 1379-1394) that reports the missing part, attaches the best
     available `SynComponentInfo`, and returns a `SynModuleDecl.???` with
     `mNone`/partial fields so the rest of the file is still parsed.
  8. `open` decls — `openDecl` (line 1396).
- **`namedModuleAbbrevBlock:` (1418)** and **`namedModuleDefnBlock:` (1427)** — the
  right-hand side of `module x = path'` (`Choice1Of2 eqn`) or `module x = ...`
  (`Choice2Of2 (def, mEndOpt)`).
- **`opt_attributes` / `attributes` / `attributeList` / `attribute` (1499-1580)** —
  `[<attr>]` syntax. `attributeListElements` (1533) for the comma-separated list;
  `attributeTarget` (1565) for the `: …` attribute target.
  `memberFlags` (line 1580) for `abstract`/`static`/`override`/`final` etc.
- **`typeNameInfo:` (line 1604)** — `type` vs `and type`/`type … end` context.
- **`tyconDefn:` (line 1634)** — full type definition. `tyconDefnList` (1612),
  `tyconDefnRhsBlock:` (1722), `tyconDefnRhs:` (1761), `tyconClassDefn:` (1793) for the
  RHS; supports records (`recdFieldDeclList` 2492), unions (`unionCase*` 2702-2948),
  classes (`classDefnBlock*` 1812-1906), `interface`, `delegate`, `struct`.
  `unionTypeRepr`/`attrUnionCaseDecl`/`unionCaseDecl`/`unionCaseRepr` (lines
  2712-2948) for the union-case syntax.
- **`tyconNameAndTyparDecls:` (2539)** with `prefixTyparDecls` (2552)/
  `postfixTyparDecls` (2574)/`explicitValTyparDecls` (2592)/`typarDecl` (2563)/
  `hashConstraint` (2606)/`typeConstraints` (2621)/`intersectionConstraints`(2630)/
  `typeConstraint:` (2649) — the full constraint set (`#`-generic constraints,
  `when`, `&`-intersection).
- **`valDefnDecl:` (2171)** — `val` binding definitions inside a class/interface
  (a distinct non-terminal from `localBinding`). `autoPropsDefnDecl` (2197) for
  `member val prop = …` auto-props.
- **`localBinding:` (line 3333)** — `let`/`and` local bindings;
  `headBindingPattern` (3576), `ceBindingCore:` (3539), `opt_simplePatterns` (3556),
  `barCanBeRightBeforeNull` (3569) — the pattern side. `localBindings` (3291)
  for the `and`-chained decl. `doBinding` (3090), `hardwhiteLetBindings`(3100),
  `hardwhiteDoBinding` (3140), `classDefnBindings` (3159) — the #light variants.
- **`opt_typ:` (2244)** — the `: typ` optional type annotation on bindings.
- **`cPrototype:` (3194)** — native signature for `extern "..."` declarations.
  `externArgs` (3222), `externMoreArgs` (3234), `externArg:` (3246),
  `cType:` (3256), `cRetType:` (3282) — the C-prototype argument list.
- **`typedExprWithStaticOptimizationsBlock:` (3386)** — `static optimization` block
  wrapper; `staticOptimization` (3409) / `staticOptimizationConditions` (3413) /
  `staticOptimizationCondition:` (3420) — the `x in "a.b"` / `x not in "a.b"`
  / `x = 3` predicates.
- **`rawConstant:` (line 3427)** — the `let x = …`-level integer/float/bool/char/etc.
  constant recognizers, with the `B`/`I`/`N`/`Z`/`Q`/`R`/`G` scale tags parsed
  from the INT/UINT/… tokens (which carry the "bad max" flag that the actions use to
  decide whether to report an overflow or accept the wrap-around).
  `rationalConstant:` (3490), `atomicUnsignedRationalConstant:` (3511),
  `atomicRationalConstant:` (3518), `constant:` (3524) — the constant ladder.
- **`patternAndGuard:` (5069)** — `| pat when guard ->`.
  `patternClauses:` (line 5073) — the `|`-separated list used by `function`
  expressions. `patternGuard:` (5134), `patternResult:` (5141).
- **`ifExprCases:` (5147)** — the `then … [elif …] … else …` chain of an `if`
  expression. `ifExprThen` (5159), `ifExprElifs` (5174).
- **`tupleExpr:` (line 5201)** — `(a, b, c)`; `minusExpr:` (5254) for unary minus;
  `appExpr:` (5304) / `argExpr:` (5312) for curried application;
  `atomicExpr:` (5324) — the big atomic-expression rule with its `|`-alternatives
  (dot-lambda `_ … x` at 5325, HIGH_PRECEDENCE_BRACK_APP/PAREN_APP/TYAPP variants at
  5355-5363, and everything else: paren, parenExpr, string, interpolatedString,
  list/array/record expr, function/object, for-while-try-match, etc.);
  `atomicExprQualification:` (5441) for `.m`, `.M`, `.m arg` forms;
  `atomicExprAfterType:` (5498) for `f a : typ` (the "type-annotated arg" form).
- **`beginEndExpr` (5533), `quoteExpr` (5546), `arrayExpr` (5563), `parenExpr`
  (5579)/`parenExprBody` (5639), `braceExpr` (5669)/`braceExprBody` (5698),
  `recdExprCore` (5814) — the structured-expression literals.)
- **`forLoopBinder:` (line 5733)** — `for x in … do …` with `forLoopRange` (5747)/
  `forLoopDirection` (5753). `inlineAssemblyExpr:` (5758) for `asm {}`.
- **`opt_atomicExprAfterType:` (5773)** — the `f x : int` form.
- **`recdExpr:` / `recdExprCore:` (5797-5814)** — `{ a = b; c = d }` record literal.
  `opt_objExprBindings` (6024)/`objExprBindings` (6045)/`objExprInterfaces` (6058)/
  `objExprInterface` (6069) — the `let ... in`-scoped object member block.
- **`braceBarExpr` (6069-6077)** — `{| a = b; c = d |}` record with optional
  fields. `braceBarExprCore` (line 6077).
- **`anonLambdaExpr:` (6133)** — `fun … ->`. `anonMatchingExpr:` (6176) for
  `function …`.
- **`typ:` (line 6382)** — the top-level type expression; `typEOF:` (6406) for the
  same with EOF context. `tupleType` (6410)/`tupleOrQuotTypeElements` (6458)/
  `intersectionType` (6495)/`appTypeCon` (6504)/`appTypeConPower` (6511)/
  `appTypeCanBeNullable` (6524)/`appTypeNullableInParens` (6531)/
  `appTypeWithoutNull` (6538)/`arrayTypeSuffix` (6564)/`typeArgListElements`
  (6661)/`powerType` (6674)/`atomTypeOrAnonRecdType` (6687)/`atomType` (6701)/
  `typeArgsNoHpaDeprecated:` (6778)/`typeArgsActual:` (6789)/`typeArgActual:`
  (6831)/`typeArgActualOrDummyIfEmpty:` (6844)/`dummyTypeArg:` (6852)/
  `measureTypeArg:` (6860)/`measureTypeAtom:` (6873)/`measureTypePower:` (6884)/
  `measureTypeSeq:` (6904)/`measureTypeExpr:` (6911)/`typar:` (6927).
- **`ident:` (line 6937)** — the `ident` non-terminal returning an `Ident` record;
  `path:` (line 6942, `SynLongIdent`); `pathOp:` (line 7097, operator path);
  `opName` (6960)/`operatorName` (6993) with their `recover`/`error` variants.
  `activePatternCaseName` (7072)/`activePatternCaseNames` (7079) for the
  `|`-separated active-pattern names.
- **`string` (line 7214)** — the `STRING` token alternative; `interpolatedString`
  (line 7245) — the `$"…"`, `$@"…"`, `$$"…"` interpolated-string rule that composes
  `interpolatedStringFill` (7222)/`interpolatedStringParts` (7229) with
  `INTERP_STRING_BEGIN_BEGIN`/`INTERP_STRING_PART`/`INTERP_STRING_END` tokens and
  embeds the `declExpr` alternatives in the `{ … }` holes via
  `opt_HIGH_PRECEDENCE_APP` (7261) / `opt_HIGH_PRECEDENCE_TYAPP` (7266).
- **`oblockend` (7295)** — the `OEND`/`OBLOCKEND`/`ODECLEND`/`ORIGHT_BLOCK_END`/
  `OBLOCKEND_COMING_SOON`/`OBLOCKEND_IS_HERE`/`RPAREN`/`RPAREN_COMING_SOON`/`RPAREN_IS_HERE`
  terminators. `ends_coming_soon_or_recover` (line 7307)/
  `ends_other_than_rparen_coming_soon_or_recover` (7300) — the
  `error`-bearing variants.
- **Recovery machinery (throughout)** — nearly every significant non-terminal has a
  `… recover` alternative, typically:
  ```
  | … recover { <report a specific FSComp.SR.pars* error> <build a partial Syn* node> }
  ```
  This is the **PARS error-recovery model**: `parse_error_rich` reports an
  error, and the recovery rule then builds the best partial AST from what was
  already parsed. `recover:` (line 4141) itself is the catch-all `| error { true }`.
  `seps:` (line 7148)/`opt_seps` (7186) and `topSeparator:` (7134)/
  `topSeparators:` (7139)/`opt_topSeparators:` (7143) are the `SEMICOLON`/
  `OBLOCKSEP`-separator machinery used between top-level decls.
  `declEnd:` (line 7155)/`opt_declEnd` (7164)/`opt_ODECLEND` (7174)/
  `deprecated_opt_equals` (7178)/`opt_OBLOCKSEP` (7182)/`opt_rec` (7190)/`opt_inline`
  (7194)/`opt_mutable` (7198)/`doToken` (7203)/`doneDeclEnd` (7207) — the small
  helper non-terminals that make the `#light` offside grammar work.

## Notable embedded F# actions

- **`checkEndOfFileError $1`** (e.g. `interaction`, `implementationFile`,
  `signatureFile`) — reports a `FSComp.SR.parsUnexpectedEndOfFile*` if the EOF was
  not expected in context.
- **`raiseParseErrorAt <range> (FSComp.SR.pars…)`** — the dominant "report an error
  on this token range" helper; used in *almost* every recovery branch (see the
  `grep` output above: `parsInvalidUseOfRec`, `parsModuleAbbreviationMustBeSimpleName`,
  `parsVisibilityDeclarationsShouldComePriorToIdentifier`, `parsSyntaxError`, etc.).
- **`reportParseErrorAt <range> (FSComp.SR.pars…)`** — the "soft" variant (does not
  abort recovery) used when the parser can continue usefully after the error.
- **`errorR(SyntaxError(...))`** — inside `parse_error_rich` (line 34), the
  canonical hook the generated parser calls before dispatching into a recovery
  rule.
- **`grabXmlDoc(parseState, $attrs, $n)`** — reads the XML doc comment accumulated
  by `lex.fsl` and attaches it to the `Syn*` node being built (via
  `unionRangeWithXmlDoc`).
- **`lhsparseState`/`rhsparseState`/`rhs2 parseState i j`** — produce a
  `range` (and `range list`) for the non-terminal being built; combined with
  `unionRanges`/`unionRangeWithListBy` to compute the `Range` recorded on every
  `Syn*` node.
- **`SyntaxTreeOps` helpers** — `mkSynExprDecl`, `mkSynPrefix`, `mkDefnBindings`,
  `mkSynModuleSigDecl`, `mkSynUnionCase`, `mkSynRecordField`, `mkSynMemberDefn`,
  `mkSynTypeApp`, `mkPathIdent`/`mkIdent`, etc., all used to build the AST nodes.
- **`isSingleton`, `isNil`** — small list/path predicates used in the validation
  branches of `moduleDefn`, `moduleSpfn`, etc.

## Language-feature gates

Actions call `parseState.LexBuffer.CheckLanguageFeatureAndRecover
LanguageFeature.<Name> <range>` to enforce opt-in features (e.g.
`AccessorFunctionShorthand` at 5328/5338, `AttributesToRightOfModuleKeyword` at
545/551). The same pattern appears in lex.fsl's `#`-directive and operator rules.

## Cross-references

- **`lex.fsl`** — the companion lexer. Every `%token` declared here is produced by
  the rules in `lex.fsl`, and every `LexerContinuation`-bearing token here is
  threaded **back** into `lex.fsl` via the LexFilter.
- **`pplex.fsl` / `pppars.fsy`** — an unrelated *small* lexer/parser pair (modules
  `FSharp.Compiler.PPLexer` / `FSharp.Compiler.PPParser`). They are used by `lex.fsl`'s
  `evalIfDefExpression` (lex.fsl:204-210) to evaluate `#if`/`#elif`
  conditional-compilation conditions, and they build only a `LexerIfdefExpression` — not
  the full `SyntaxTree` that this parser produces.
- **`SyntaxTreeOps.fs`, `SyntaxTree/*.fs`** — the node constructors and helpers the
  actions call.
- **`LexerStore` / `ParseHelpers` (`SyntaxTree/LexHelpers.fs`)** — the
  `LexArgs`, `LexerContinuation`, `LexerIfdefEval`, `SyntaxError`, `errorR`,
  `reportParseErrorAt` machinery.
