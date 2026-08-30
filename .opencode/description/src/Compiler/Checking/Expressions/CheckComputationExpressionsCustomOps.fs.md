# CheckComputationExpressionsCustomOps.fs

**Purpose**
Supports correct language-service reporting of *overloaded* `[<CustomOperation>]` members used inside
computation expressions. When a custom operation (e.g. `where`, `sortBy`, `join`) resolves to one of
several overloads, this module sinks the *resolved* overload's `MethInfo` at the keyword range of the
usage — fixing #11612 / #15206 (the previously reported symbol was the fallback/default member, which
misled colorization and go-to-definition).

**Namespace(s)**
`module internal FSharp.Compiler.CheckComputationExpressionsCustomOps`

**Types declared**
- `DeferredCustomOpSink` — record describing one pending custom-operation use awaiting resolution capture: `KeywordRange`, `OpName`, `UsageText: unit -> RichText option`, `SyntheticCallRange`, `Fallback: MethInfo`, `NameEnv`, `AccessRights`.

**Public API surface**
- `enqueueDeferredCustomOpSink : sink: TcResultsSink -> nenv: NameResolutionEnv -> ad: AccessorDomain -> queue: ResizeArray<DeferredCustomOpSink> -> nm: Ident -> opName -> usageText -> syntheticCallRange -> fallback: MethInfo -> unit` — record the fallback resolution immediately (so the symbol is available even if resolution is later skipped) and enqueue a `DeferredCustomOpSink` for later capture.
- `captureCustomOperationOverloads : sink: TcResultsSink -> queue: ResizeArray<DeferredCustomOpSink> -> action: unit -> 'T -> 'T` — run `action` under a capturing sink; afterwards, for each enqueued sink whose resolved method is not identical to the fallback, report the resolved overload with `CallNameResolutionSinkReplacing` at the keyword range.

**Internal helpers**
- `makeCustomOpResolutionCapturingSink (forwardTo: ITypecheckResultsSink) (capturedResolutions: Dictionary<range, string * MethInfo * TyparInstantiation>) : ITypecheckResultsSink` — a delegating sink. Its `NotifyNameResolution` / `NotifyMethodGroupNameResolution` intercept `Item.MethodGroup(name, [ mi ], _)` resolutions at a synthetic-call range that maps to an expected op name, recording the winning `MethInfo`; everything is still forwarded to the real sink.

**Significant internal logic**
- Flow: `CheckComputationExpressions.fs` registers a `DeferredCustomOpSink` for each custom-operation
  keyword use (with its fallback `MethInfo`); when it checks the synthesized builder call, it wraps the
  call in `captureCustomOperationOverloads`. During that call, the capturing sink observes the
  name-resolution report for the *resolved* overload and stores it keyed by the synthetic-call range.
  Afterwards, if `MethInfo.MethInfosUseIdenticalDefinitions resolved fallback` is false, the fallback
  report is *replaced* (`CallNameResolutionSinkReplacing`) with the resolved overload, carrying the
  keyword range, the original `NameEnv`, and `ItemOccurrence.Use`.
- Using a *delegating* sink (rather than suspending reporting) preserves all other reporting behavior
  (envs, expr types, open declarations, related symbols) — only the method-group resolution is captured
  and then replaced.
- The `Range.comparer`-based dictionary keys captured resolutions by the exact synthetic-call range,
  disambiguating multiple custom-operation uses in the same body.

**Cross-references**
- `CheckComputationExpressions.fs` (sibling) — the consumer: calls `enqueueDeferredCustomOpSink` during
  custom-op discovery and wraps builder-call checking in `captureCustomOperationOverloads`.
- `NameResolution.fsi` (Checking dir) — `ITypecheckResultsSink`, `TcResultsSink`,
  `CallNameResolutionSinkReplacing`, `Item.MethodGroup`, `Item.CustomOperation`, `ItemOccurrence`,
  `NameResolutionEnv`, `WithNewTypecheckResultsSink`.
- `RelatedSymbolUse.fs` — surfaced via the sink's `NotifyRelatedSymbolUse` forwarding.
