====================================================================
SECTION 1 — FILES
====================================================================
src/Compiler/SyntaxTree/SyntaxTree.fs
src/Compiler/SyntaxTree/SyntaxTree.fs
src/Compiler/SyntaxTree/SyntaxTreeOps.fs
src/Compiler/SyntaxTree/SyntaxTrivia.fs
src/Compiler/Parser/SYNTAXTREE (pars.fsy)
src/Compiler/Parser/pars.fsy
src/Compiler/Parser/ParseHelpers.fs
src/Compiler/Checking/CheckBasics.fs
src/Compiler/Checking/CheckPatterns.fs
src/Compiler/Checking/CheckDeclarations.fs
src/Compiler/Checking/MethodCalls.fs
src/Compiler/Checking/Expressions/CheckExpressions.fs
src/Compiler/Checking/Expressions/CheckComputationExpressions.fs
src/Compiler/TypdTtReE/TypedTree.fs
src/Compiler/TypedTree/TypedTree.fsi
src/Compiler/TypedTree/TypedTreeOps.ExprConstruction.fs
src/Compiler/TypedTree/TypedTreeOps.ExprConstruction.fsi
src/Compiler/TypedTree/TypedTreeOps.ExprOps.fs
src/Compiler/Service/SymbolResolution.fs (not directly relevant)
(only .fs / .fsi / .fsy that touch ExprLambda, closures, captured variables, or the early typechecking path)
====================================================================
SECTION 2 — FUNCTIONS
====================================================================
src/Compiler/SyntaxTree/SyntaxTreeOps.fs
- PushPatternToExpr                     ~423
- PushCurriedPatternsToExpr             ~437
- SimplePatsOfPat                       ~399
- mkSynFunMatchLambdas                  ~564
- mkSynDelay                            ~531
src/Compiler/Parser/pars.fsy
- anonLambdaExpr rule                   ~6191
- anonMatchingExpr rule                 ~6235
- DotLambda rule (parsDotLambda)        ~5388
src/Compiler/Checking/Expressions/CheckExpressions.fs
- TcExpr                                ~5518
- TcExprThen                            ~5636
- TcExprMatch (for function bodies)     (dispatched at ~5968)
- TcExprMatchLambda                     ~6287
- TcIteratedLambdas                     ~6675
- KeepFamilyRegionForClosure            ~177
- ExitFamilyRegion (called from ^)      ~163
- MakeAndPublishSimpleVals              ~1798
- MakeAndPublishSimpleValsForMergedScope ~1811
- MakeAndPublishVals                    ~1485
- MakeAndPublishVal                     ~1323
- AddLocalVal                           ~243
- AddLocalValMap                        ~219
- AddLocalVals                          (referenced at 13464)
- UseNoValReprInfo                      ~1794
- UseCombinedValReprInfo                ~1790
- bindLetRec                            ~11106
- TcLetBinding                          ~12066
- TcLetrecBindings                      ~13455
- TcLetrecBinding                       ~12918
- TcIncrementalLetRecGeneralization     ~13005
- TcLetrecComputeAndGeneralizeGenericTyparsForBinding ~13200
- TcLetrecGeneralizeBinding             ~13244
- TcLetrecAdjustMemberForSpecialVals    ~13307
- TcNormalizedBinding                   ~11412
- AnalyzeAndMakeAndPublishRecursiveValues (~referenced at 13462)
- CheckRecursiveBindingIds              ~11113
src/Compiler/Checking/CheckPatterns.fs
- TcSimplePat                           ~80
- TcSimplePats                          ~150
- TcSimplePatsOfUnknownType             (in .fsi)
- ValidateOptArgOrder                   ~130
src/Compiler/Checking/CheckBasics.fs
- TcEnv (record def)                    ~190
- cenv interface                        ~354
src/Compiler/Checking/CheckDeclarations.fs
- MutRecBindings_TcLetrecBinding caller (line ~1341, ~1503)
- TcMutRecBindings_Phase2B_TypeCheckAndIncrementalGeneralization ~1297
- TcMutRecBindings_Phase2C_FixupRecursiveReferences ~1540
src/Compiler/Checking/MethodCalls.fs
- GenWitnessExprLambda                  ~2419
- ExprDepth / loop for SynExpr.Lambda   ~886
src/Compiler/Checking/Expressions/CheckComputationExpressions.fs
- mkSynLambda                           ~114
- TcLetOrUse (let handling)             ~918, ~935, 1902, 1966, ~2789
- ComputationExpression LetOrUse handling ~1025
src/Compiler/TypedTree/TypedTreeOps.ExprConstruction.fs
- mkMultiLambda                         ~227
- mkLambda                              ~233
- mkLambdas                             ~248
- mkMultiLambdasCore                    ~251
- mkMultiLambdas                        ~254
- mkMemberLambdas                       ~257
- mkMultiLambdaBind                     ~270
- mkLetBind                             ~275
- mkLetsBind                            ~278
- mkLetsFromBindings                    ~280
- mkLet                                 ~282
- mkCompGenBind                         ~285
- mkInvisibleBind                       ~292
- mkLetRecBinds                         ~305
- mkLocalAux / mkLocal / mkCompGenLocal / mkMutableCompGenLocal  ~222-224
- rebuildLambda                         ~230
- mkTypeLambda                          ~235
- mkObjExpr                             ~245
src/Compiler/TypedTree/TypedTreeOps.ExprOps.fs
- mkMultiLambda (fold-back usage)        ~1915, ~2155, 2160, 2214
====================================================================
SECTION 3 — DATA STRUCTURES
====================================================================
// ---- Parsed tree ----
SynSimplePats = SimplePats of
  pats: SynSimplePat list
  commaRanges: range list
  range: range
(SyntaxTree.fs:944)
SynExpr.Lambda =
  fromMethod: bool
  inLambdaSeq: bool
  args: SynSimplePats
  body: SynExpr
  parsedData: (SynPat list * SynExpr) option
  range: range
  trivia: SynExprLambdaTrivia
(SyntaxTree.fs:604–611)
SynExpr.MatchLambda =
  isExnMatch: bool
  keywordRange: range
  matchClauses: SynMatchClause list
  matchDebugPoint: DebugPointAtBinding
  range: range
(SyntaxTree.fs:613–618)
SynExpr.DotLambda = (expr, range, trivia) (SyntaxTree.fs:816)
SynExprLambdaTrivia = { ArrowRange: range option } with static Zero member (SyntaxTrivia.fs:79)
SynLetOrUse =
  IsRecursive: bool
  Bindings: SynBinding list
  Body: SynExpr
  Range: range
  Trivia: SynLetOrUseTrivia
  IsFromSource: bool
(SyntaxTree.fs:1154–1173)
// ---- Typed tree ----
Expr.Lambda =
  unique: Unique
  ctorThisValOpt: Val option
  baseValOpt: Val option
  valParams: Val list
  bodyExpr: Expr
  range: range
  overallType: TType
(TypedTree.fs:5241–5248)
Expr.TyLambda =
  unique: Unique
  typeParams: Typars
  bodyExpr: Expr
  range: range
  overallType: TType
(TypedTree.fs:5252–5257)
Expr.LetRec =
  bindings: Bindings
  bodyExpr: Expr
  range: range
  frees: FreeVarsCache
(TypedTree.fs:5272–5276)
Expr.Let =
  binding: Binding
  bodyExpr: Expr
  range: range
  frees: FreeVarsCache
(TypedTree.fs:5279–5283)
Bindings = Binding list (TypedTree.fs:5071)
Binding = TBind of
  var: Val
  expr: Expr
  debugPoint: DebugPointAtBinding
(TypedTree.fs:5078–5082)
Val =
  val_logical_name: string
  val_range: range
  val_type: TType
  val_stamp: Stamp
  val_flags: ValFlags
  val_opt_data: ValOptionalData option
(TypedTree.fs:2927–2943)
ValOptionalData =
  val_compiled_name: string option
  val_other_range: (range*bool) option
  val_const: Const option
  val_defn: Expr option
  val_repr_info: ValReprInfo option
  val_repr_info_for_display: ValReprInfo option
  arg_repr_info_for_display: ArgReprInfo option
  val_access: Accessibility
  val_xmldoc: XmlDoc
  val_other_xmldoc: XmlDoc option
  val_member_info: ValMemberInfo option
  val_declaring_entity: ParentRef
  val_xmldocsig: string
  val_attribs: WellKnownValAttribs
(TypedTree.fs:2854–2917)
ValFlags (int64 flags struct, TypedTree.fs:96): packed bits for
  recValInfo: ValNotInRecScope | ValInRecScope of bool
  baseOrThis: BaseVal | CtorThisVal | NormalVal | MemberThisVal
  isCompGen: bool
  inlineInfo: ValInline
  isMutable: Immutable|Mutable
  isModuleOrMemberBinding: bool
  isExtensionMember: bool
  isIncrClassSpecialMember: bool
  isTyFunc: bool
  allowTypeInst: bool
  isGeneratedEventVal: bool
ValReprInfo =
  typars: TyparReprInfo list
  args: ArgReprInfo list list
  result: ArgReprInfo
(TypedTree.fs:5128–5133)
ArgReprInfo =
  Attribs: WellKnownValAttribs
  Name: Ident option
  (additional fields — see TypedTree.fs:5181)
ValScheme =
  id: Ident
  typeScheme: GeneralizedType
  valReprInfo: ValReprInfo option
  valReprInfoForDisplay: ValReprInfo option
  memberInfo: PrelimMemberInfo option
  isMutable: bool
  inlineInfo: ValInline
  baseOrThisInfo: ValBaseOrThisInfo
  visibility: SynAccess option
  isCompGen: bool
  isIncrClass: bool
  isTyFunc: bool
  hasDeclaredTypars: bool
(CheckExpressions.fs:397–411)
RecursiveBindingInfo =
  recBindIndex: int
  containerInfo: ContainerInfo
  enclosingDeclaredTypars: Typars
  inlineFlag: ValInline
  vspec: Val
  explicitTyparInfo: ExplicitTyparInfo
  prelimValReprInfo: PrelimValReprInfo
  memberInfoOpt: PrelimMemberInfo option
  baseValOpt: Val option
  safeThisValOpt: Val option
  safeInitInfo: SafeInitData
  visibility: SynAccess option
  ty: TType
  declKind: DeclKind
(CheckExpressions.fs:4055–4070)
PreCheckingRecursiveBinding =
  SyntacticBinding: NormalizedBinding
  RecBindingInfo: RecursiveBindingInfo
(CheckExpressions.fs:4080)
PreGeneralizationRecursiveBinding =
  ExtraGeneralizableTypars: Typars
  CheckedBinding: CheckedBindingInfo
  RecBindingInfo: RecursiveBindingInfo
(CheckExpressions.fs:4084)
PostGeneralizationRecursiveBinding =
  ValScheme: ValScheme
  CheckedBinding: CheckedBindingInfo
  RecBindingInfo: RecursiveBindingInfo
(CheckExpressions.fs:4089)
DeclKind =
  | ModuleOrMemberBinding
  | IntrinsicExtensionBinding
  | ExtrinsicExtensionBinding
  | ClassLetBinding of isStatic: bool
  | ObjectExpressionOverrideBinding
  | ExpressionBinding
(CheckExpressions.fs:300–313)
// ---- Closure environment / capturing data ----
TcEnv =
  eNameResEnv: NameResolutionEnv
  eUngeneralizableItems: UngeneralizableItem list
  ePath: Ident list
  eCompPath: CompilationPath
  eAccessPath: CompilationPath
  eAccessRights: AccessorDomain
  eInternalsVisibleCompPaths: CompilationPath list
  eModuleOrNamespaceTypeAccumulator: ModuleOrNamespaceType ref
  eContextInfo: ContextInfo
  eFamilyType: TyconRef option
  eCtorInfo: CtorInfo option
  eCallerMemberName: string option
  eLambdaArgInfos: ArgReprInfo list list
  eIsControlFlow: bool
  eInObjectExpr: bool
  eCachedImplicitYieldExpressions: HashMultiMap<range, SynExpr * TType * Expr>
  eUseBoundValStamps: Set<Stamp>
(CheckBasics.fs:190–255)
Unique = int64 (CompilerGlobalState.fs:134)
FreeLocals = Zset<Val> (TypedTree.fs:6153)
FreeVars =
  FreeLocals: FreeLocals
  UsesMethodLocalConstructs: bool
  UsesUnboundRethrow: bool
  ContainsILFieldAccess: bool
  FreeLocalTyconReprs: FreeTycons
  FreeRecdFields: FreeRecdFields
  FreeUnionCases: FreeUnionCases
  FreeTyvars: FreeTyvars
(TypedTree.fs:6198–6229)
FreeVarsCache = FreeVars cache (TypedTree.fs:6194)
====================================================================
SECTION 4 — LAMBDA DISCOVERY (PARSING)
====================================================================
4.1  pars.fsy rule anonLambdaExpr, pars.fsy:6191
anonLambdaExpr:
  | FUN atomicPatterns RARROW typedSequentialExprBlock
      { let mAll = unionRanges (rhs parseState 1) $4.Range
        let mArrow = Some(rhs parseState 3)
        mkSynFunMatchLambdas (getSynArgNameGenerator parseState.LexBuffer) false mAll $2 mArrow $4 }
  | FUN atomicPatterns RARROW error
      { ...
        mkSynFunMatchLambdas ... false mAll $2 mArrow (arbExpr ("anonLambdaExpr1", (rhs parseState 4))) }
  | OFUN atomicPatterns RARROW typedSequentialExprBlockR OEND
      { ...
        mkSynFunMatchLambdas ... false mAll $2 (Some mArrow) expr }
  ...
Fields populated: fromMethod (=false, passed as isMember),
  inLambdaSeq (set inside PushCurriedPatternsToExpr),
  args (from $2 = atomicPatterns),
  body ($4 = the RHS),
  range (mAll),
  trivia (mArrow ? SynExprLambdaTrivia { ArrowRange = arrow }).
Fields left empty:
  parsedData = None (set only in the outermost lambda of a curried chain).
4.2  SyntaxTreeOps.fs:564 — mkSynFunMatchLambdas
let mkSynFunMatchLambdas synArgNameGenerator isMember wholem ps arrow e =
    let _, e = PushCurriedPatternsToExpr synArgNameGenerator wholem isMember ps arrow e
    e
4.3  SyntaxTreeOps.fs:437 — PushCurriedPatternsToExpr (the lambda maker)
let PushCurriedPatternsToExpr synArgNameGenerator wholem isMember pats arrow rhs =
    let spatsl, rhs =
        (pats, ([], rhs))
        ||> List.foldBack (fun arg (spatsl, body) ->
            let spats, bodyf = SimplePatsOfPat synArgNameGenerator arg
            let body = appFunOpt bodyf body
            let spatsl = spats :: spatsl
            (spatsl, body))
    let expr =
        match spatsl with
        | [] -> rhs
        | h :: t ->
            let expr =
                List.foldBack (fun spats e -> SynExpr.Lambda(isMember, true, spats, e, None, wholem, { ArrowRange = arrow })) t rhs
            let expr =
                SynExpr.Lambda(isMember, false, h, expr, Some(pats, rhs), wholem, { ArrowRange = arrow })
            expr
    spatsl, expr
Nested lambda structure (right-to-left fold):
- each inner lambda (spats, e, ...) has inLambdaSeq=true, parsedData=None
- the outermost lambda has inLambdaSeq=false, parsedData=Some(pats, rhs) (original patterns + original body preserved)
- all set: fromMethod=isMember, args=spats, body=(next lambda or rhs), range=wholem, trivia={ArrowRange=arrow}
4.4  SyntaxTreeOps.fs:422 — PushPatternToExpr (used for let bindings that have a pattern)
let PushPatternToExpr synArgNameGenerator isMember pat (rhs: SynExpr) =
    let nowPats, laterF = SimplePatsOfPat synArgNameGenerator pat
    nowPats, SynExpr.Lambda(isMember, false, nowPats, appFunOpt laterF rhs, None, rhs.Range, SynExprLambdaTrivia.Zero)
Single lambda node, parsedData=None, trivial trivia.
4.5  SyntaxTreeOps.fs:531 — mkSynDelay (unit-arity delay lambda for let x = delay e)
let mkSynDelay m e =
    let svar = mkSynCompGenSimplePatVar (mkSynId m "unitVar")
    SynExpr.Lambda(false, false, SynSimplePats.SimplePats([ svar ], [], m), e, None, m, SynExprLambdaTrivia.Zero)
4.6  DotLambda — pars.fsy:5388 / 5402
| <expr> . _ 
    { let trivia: SynExprDotLambdaTrivia = { UnderscoreRange = mUnderscore ; DotRange = mDot }
      SynExpr.DotLambda(expr, unionRanges mUnderscore expr.Range, trivia), false }
SynExpr.DotLambda is a separate SynExpr constructor (SyntaxTree.fs:816). It is not a Lambda node at parse time. In typechecking (CheckExpressions.fs:5952–5963) it is desugared to a SynExpr.Lambda with parsedData=None:
| SynExpr.DotLambda (synExpr, m, trivia) ->
    ...
    let unaryArg = mkSynId trivia.UnderscoreRange (cenv.synArgNameGenerator.New())
    let svar = mkSynCompGenSimplePatVar unaryArg
    let pushedExpr = pushUnaryArg synExpr unaryArg
    let lambda = SynExpr.Lambda(false, false, SynSimplePats.SimplePats([ svar ],[], svar.Range), pushedExpr, None, m, SynExprLambdaTrivia.Zero)
    TcIteratedLambdas cenv true env overallTy Set.empty tpenv lambda
====================================================================
SECTION 5 — TYPECHECKING (TcExpr, TcIteratedLambdas, TcLetrecBinding)
====================================================================
5.1 Entry dispatch, CheckExpressions.fs:5964
    | SynExpr.Lambda _ ->
        TcIteratedLambdas cenv true env overallTy Set.empty tpenv synExpr
5.2  CheckExpressions.fs:6675 — TcIteratedLambdas
and TcIteratedLambdas (cenv: cenv) isFirst (env: TcEnv) overallTy takenNames tpenv e =
    let g = cenv.g
    match e with
    | SynExpr.Lambda (isMember, isSubsequent, synSimplePats, bodyExpr, parsedData, m, _trivia)
        when isMember || isFirst || isSubsequent ->
        let domainTy, resultTy = UnifyFunctionType None cenv env.DisplayEnv m overallTy.Commit
        let parsedPatterns =
            parsedData |> Option.map fst |> Option.defaultValue []
        let vs, TcPatLinearEnv (tpenv, names, takenNames, _) =
            cenv.TcSimplePats cenv isMember CheckCxs domainTy env (TcPatLinearEnv (tpenv, Map.empty, takenNames, false)) synSimplePats (parsedPatterns, isFirst)
        let envinner, _, vspecMap = MakeAndPublishSimpleValsForMergedScope cenv env m names
        let byrefs = vspecMap |> Map.map (fun _ v -> isByrefTy g v.Type, v)
        let envinner =
            if isMember then envinner else KeepFamilyRegionForClosure g envinner
        let vspecs = vs |> List.map (fun nm -> NameMap.find nm vspecMap)
        for v in vspecs do
            v.SetIsParameter()
        let envinner =
            match envinner.eLambdaArgInfos with
            | infos :: rest ->
                 if infos.Length = vspecs.Length then
                    (vspecs, infos) ||> List.iter2 (fun v argInfo ->
                        v.SetArgReprInfoForDisplay (Some argInfo)
                        let inlineIfLambda = ArgReprInfoHasWellKnownAttribute g WellKnownValAttributes.InlineIfLambdaAttribute argInfo
                        if inlineIfLambda then
                            v.SetInlineIfLambda())
                 { envinner with eLambdaArgInfos = rest }
            | [] -> envinner
        let bodyExpr, tpenv = TcIteratedLambdas cenv false envinner (MustConvertTo (false, resultTy)) takenNames tpenv bodyExpr
        CallExprHasTypeSink cenv.tcSink (m, env.NameEnv, overallTy.Commit, env.AccessRights)
        byrefs |> Map.iter (fun _ (orig, v) ->
            if not orig && isByrefTy g v.Type then errorR(Error(FSComp.SR.tcParameterInferredByref (RichText.mkParameter v.DisplayName), v.Range)))
        mkMultiLambda m vspecs (bodyExpr, resultTy), tpenv

    | e ->
        let env = { env with eIsControlFlow = true }
        TcExpr cenv overallTy env tpenv e
How captured variables are detected:
- There is no explicit "capture analysis" pass at this stage.
- "Captured" == any Val referenced inside bodyExpr that is not in vspecs and was already present in env (the TcEnv's name-resolution env) when this lambda was created.
- The body is typechecked with envinner; every Expr.Val reference made during that check to a value in the outer env is by construction a capture.
- The only environment adjustment specific to closure formation is KeepFamilyRegionForClosure (line 6692): a closure cannot retain the enclosing type's family access (unless the AccessProtectedBaseFieldFromClosure feature is on AND we're not inside an object-expr body). Implemented by ExitFamilyRegion (line 163) — sets eFamilyType=None and recomputes eAccessRights.
How closure environments are built:
- envinner is formed by MakeAndPublishSimpleValsForMergedScope cenv env m names (line 6688).
- Inside MakeAndPublishSimpleValsForMergedScope (line 1811):
- if names.Count <= 1 ? MakeAndPublishSimpleVals (direct)
- if > 1 ? intercept NotifyNameResolution from a new sink, call MakeAndPublishSimpleVals, and then emit a merged CallEnvSink and per-name CallMethodGroupNameResolutionSink.
- MakeAndPublishSimpleVals (line 1798) does:
let tyschemes = DontGeneralizeVals names
let valSchemes = NameMap.map UseNoValReprInfo tyschemes
let values = MakeAndPublishVals cenv env (ParentNone, false, ExpressionBinding, ValNotInRecScope, valSchemes, [], XmlDoc.Empty, None)
- Finally (line 1870): let envinner = AddLocalValMap g cenv.tcSink m vspecMap env
  so envinner = env + the freshly created Val for each argument. The outer env (with the captured vals) is still present — that is the closure environment: env + the added args, passed down to typecheck bodyExpr.
How Vals are created for lambdas (the arguments):
- MakeAndPublishVals (line 1485) iterates valSchemes, calling MakeAndPublishVal per entry.
- MakeAndPublishVal (line 1323) for the lambda-arg case:
- declKind = ExpressionBinding, valRecInfo = ValNotInRecScope
- isTopBinding = false, isExtrinsic = false
- vspec = Construct.NewVal (logicalName, id.idRange, compiledName, ty, mut, isCompGen, valReprInfo, vis, valRecInfo, memberInfoOpt, baseOrThis, attrs, inlineFlag, xmlDoc, isTopBinding, isExtrinsic, isIncrClass, isTyFunc, (hasDeclaredTypars || inSig), isGeneratedEventVal, konst, actualParent) (line 1436-1441)
- For lambda args: baseOrThis=NormalVal, valReprInfo=None, memberInfoOpt=None, isCompGen=true (because the name was synthesized by TcSimplePats)
- PublishValueDefn cenv env declKind vspec (line 1450) registers the Val in the compilation unit (ccu).
- If eLambdaArgInfos has a matching list, v.SetArgReprInfoForDisplay (Some argInfo) is called, and v.SetInlineIfLambda() if the attribute is present (lines 6704-6710).
- v.SetIsParameter() is always called (line 6698).
- The overall value (the lambda as a value) is NOT given its own Val at this stage. The typed tree represents the lambda directly as an Expr.Lambda node; the arguments are the only Vals.
What is attached (metadata) at this stage:
  On each argument Val:
    - val_logical_name, val_range, val_type (fresh inference type at this moment), val_stamp
    - val_flags: recValInfo=ValNotInRecScope, baseOrThis=NormalVal, isCompGen=true, isModuleOrMemberBinding=false, isExtensionMember=false, isTyFunc=false, inline per attribute
    - val_opt_data.val_repr_info = None (UseNoValReprInfo at line 1794)
    - val_opt_data.val_repr_info_for_display = None (lambda-arg path) — or Some if arg-info was matched
    - val_opt_data.arg_repr_info_for_display = None — or Some if matched
    - val_opt_data.val_attribs, val_opt_data.val_xmldoc (empty), val_opt_data.val_access (computed)
    - Parameter flag (ValFlags inline/parameter marking)
  On the Expr.Lambda node:
    - unique (new fresh id)
    - valParams = the argument Vals list
    - bodyExpr (the checked body)
    - overallType (the function type)
    - ctorThisValOpt=None, baseValOpt=None
    - range
What is NOT attached yet:
- No Val for the lambda-as-a-value (that is done in later passes / InnerLambdasToTopLevelFuncs)
- val_repr_info (ValReprInfo arity/shape) — attached later for top-level, None here
- val_repr_info_for_display — None for the lambda-as-value (only set if arg-info matches)
- val_compiled_name for the lambda-as-value (set in TLR)
- val_defn (closed-term definition) — set later by InnerLambdasToTopLevelFuncs
- frees (FreeVars) is a Construct.NewFreeVarsCache() placeholder — the real FreeLocals are computed in a later pass
- The lambda-as-value's Unique is on Expr.Lambda only; there is no separate Val for it
5.3  TypedTreeOps.ExprConstruction.fs:227 — mkMultiLambda
    let mkMultiLambda m vs (body, bodyTy) =
        Expr.Lambda(newUnique (), None, None, vs, body, m, bodyTy)
This is what TcIteratedLambdas calls to produce the typed node from its inputs. The unique is fresh; ctorThisValOpt/baseValOpt are None for a plain function lambda (those would only be set in the object-override / incremental-class path via rebuildLambda).
If the lambda's type has generalized type parameters (from overallTy being an forall type), the caller wraps in an Expr.TyLambda via mkMultiLambdas (line 254) or mkTypeLambda (line 235). That is the typed tree's way of expressing a polymorphic closure.
5.4  let rec path — TcLetrecBindings / TcLetrecBinding
Dispatch (CheckExpressions.fs:11150-11160):
  | LetOrUse({ IsRecursive = isRec ; Bindings = binds; Body = body; Range = m }, _, isUse)
      when not (isUse && isCompExpr) ->
      if isRec then
          CheckRecursiveBindingIds binds
          let binds = List.map (fun x -> RecDefnBindingInfo(ExprContainerInfo, NoNewSlots, ExpressionBinding, x)) binds
          if isUse then errorR(Error(FSComp.SR.tcBindingCannotBeUseAndRec(), m))
          let binds, envinner, tpenv = TcLetrecBindings ErrorOnOverrides cenv env tpenv (binds, m, m)
          let envinner = { envinner with eIsControlFlow = true }
          let bodyExpr, tpenv = bodyChecker overallTy envinner tpenv body
          let bodyExpr = bindLetRec binds m bodyExpr
          cont (bodyExpr, tpenv)
TcLetrecBindings (CheckExpressions.fs:13455):
and TcLetrecBindings overridesOK (cenv: cenv) env tpenv (binds, bindsm, scopem) =
    let g = cenv.g
    let normalizedBinds = binds |> List.map (fun (RecDefnBindingInfo(a, b, c, bind)) ->
        NormalizedRecBindingDefn(a, b, c, BindingNormalization.NormalizeBinding ValOrMemberBinding cenv env bind))
    let uncheckedRecBinds, prelimRecValues, (tpenv, _) =
        AnalyzeAndMakeAndPublishRecursiveValues overridesOK cenv env tpenv normalizedBinds
    let envRec = AddLocalVals g cenv.tcSink scopem prelimRecValues env
    let uncheckedRecBindsTable = uncheckedRecBinds |> List.map (fun rbind -> rbind.RecBindingInfo.Val.Stamp, rbind) |> Map.ofList
    let _, generalizedRecBinds, preGeneralizationRecBinds, tpenv, _ =
        ((env, [], [], tpenv, uncheckedRecBindsTable), uncheckedRecBinds)
        ||> List.fold (TcLetrecBinding (cenv, envRec, scopem, [], None))
    assert preGeneralizationRecBinds.IsEmpty
    let generalizedRecBinds = generalizedRecBinds |> List.sortBy (fun pgrbind -> pgrbind.RecBindingInfo.Index)
    let generalizedTyparsForRecursiveBlock =
         generalizedRecBinds |> List.map (fun pgrbind -> pgrbind.GeneralizedTypars) |> unionGeneralizedTypars
    let vxbinds = generalizedRecBinds |> List.map (TcLetrecAdjustMemberForSpecialVals cenv)
    ...
TcLetrecBinding (CheckExpressions.fs:12918) — for each binding:
- Type-checks the RHS (TcNormalizedBinding) against the fresh inference type of the Val (vspec) that was created for the pattern.
- Unifies.
- Incrementally generalizes via TcIncrementalLetRecGeneralization (line 13005) — a greatest-fixed-point computation over the "free-in-later-bindings" set, using cenv.recUses to shortcut the quadratic case.
- Yields a PostGeneralizationRecursiveBinding {ValScheme; CheckedBinding; RecBindingInfo}.
The final binding node (TBind) is created by TcLetrecAdjustMemberForSpecialVals (line 13307) — for each generalized binding, ValScheme + CheckedBinding ? Binding (TBind with fresh Unique, debug point).
The letrec body is assembled by bindLetRec (line 11106):
and bindLetRec (binds: Bindings) m e =
    if isNil binds then e
    else Expr.LetRec (binds, e, m, Construct.NewFreeVarsCache())
Note: frees is a FreeVarsCache placeholder — Construct.NewFreeVarsCache() creates an empty/uncached cache; actual FreeLocals content is computed lazily in a later analysis pass.
Captured-variable detection in let rec:
- Same mechanism as above — any Val in envRec (which is env + the fresh recursive Vals via AddLocalVals) referenced in the body that is not the recursive vals being defined is a capture.
- There is no explicit "is this a closure?" check at this point; the decision to make the letrec into a closure vs a top-level function is made by InnerLambdasToTopLevelFuncs later.
Metadata attached to the recursive Vals:
- Same Val construction path as lambda args: vspec produced by AnalyzeAndMakeAndPublishRecursiveValues, added to the name env by AddLocalVals, type-checked, generalized, and its ValScheme materialized via TcLetrecAdjustMemberForSpecialVals.
- val_recInfo = ValInRecScope true for the recursive ones (set during AnalyzeAndMakeAndPublishRecursiveValues); ValNotInRecScope for the non-recursive case.
- val_repr_info is still None at this point (the UseCombine... / valReprInfo is only filled for top-level bindings during TLR).
5.5  let (non-recursive) path — dispatch at CheckExpressions.fs:11163:
          let mkf, envinner, tpenv = TcLetBinding cenv isUse env ExprContainerInfo ExpressionBinding tpenv (binds, m, body.Range)
TcLetBinding (line 12066) creates one Val per binding with declKind=ExpressionBinding, type-checks the RHS, and returns a mkf function that, when applied to the checked body and overall type, wraps in an Expr.Let node via the same mkLetBind (line 275) primitive:
let mkLetBind m bind body =
    Expr.Let(bind, body, m, Construct.NewFreeVarsCache())
Metadata attached to the let-Val:
- Same Val shape; val_recurInfo=ValNotInRecScope; val_repr_info=None; val_repr_info_for_display=None; the val is added to the env for the body (closure environment = env + that single val).
5.6  function (MatchLambda) path — TcExprMatchLambda at line 6287:
and TcExprMatchLambda (cenv: cenv) overallTy env tpenv (isExnMatch, mFunction, clauses, spMatch, m) =
    let envinner = KeepFamilyRegionForClosure cenv.g env
    let mFunction = ...
    let idv1 = mkSynId m (cenv.synArgNameGenerator.New())
    ...
    let matchExpr, resultTy = TcExprMatch cenv ... synInputExpr ...
    let idv2 = mkSynCompGen ...
    let overallExpr = mkMultiLambda m [idv1] ((mkLet spMatch m idv2 idve1 matchExpr), resultTy)
So a function desugars to a Lambda whose body is a Match node, with an extra let for the scrutinee. The env and Val handling is identical to the fun-lambda case.
====================================================================
(Report ends here — stopped at the end of typechecking, per scope.)