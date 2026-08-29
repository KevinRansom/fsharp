# FSCore.resx

## Pipeline role
`.resx` resource file for `FSharp.Core` runtime exception/error messages. Embedded with
source generation (`GenerateSource=true`, `GenerateLegacyCode=true`), producing a typed
`Microsoft.FSharp.Core.SR` accessor module. 146 data entries (~28 KB resx).

## Format
Standard ResX 2.0 XML: schema + `resheader` rows + `<data name=...><value>...</value>`.
Enabled through `EmbeddedResource Update="FSCore.resx"` in `FSharp.Core.fsproj` with
`GeneratedModuleName=Microsoft.FSharp.Core.SR`, `GenerateLiterals=false`.

## Key string groups
Message names (camelCase) reflect FSharp.Core runtime failure modes:
- Collections/indexing: `indexOutOfBounds`, `matchCasesIncomplete`, `arraysHadDifferentLengths`,
  `listsHadDifferentLengths`, `arrayWasEmpty`, `setContainsNoElements`, `enumerationAlreadyFinished`,
  `enumerationNotStarted`, `enumerationPastIntMaxValue`, `notEnoughElements`,
  `nonZeroBasedDisallowed`, `nullsNotAllowedInArray`, `inputListWasEmpty`, `inputSequenceEmpty`.
- Arithmetic/numerics: `noNegateMinValue`, `endCannotBeNaN`, `dyInv*` family
  (`dyInvOpAddCoerce`, `dyInvOpDivByIntCoerce`, `dyInvOpMultOverload`, ...), `badFormatString`,
  `genericCompareFail1`, `notComparable`, `failedReadEnoughBytes`.
- MailboxProcessor: `mailboxProcessorAlreadyStarted`,
  `mailboxProcessorPostAndAsyncReplyTimedOut`, `mailboxProcessorPostAndReplyTimedOut`,
  `mailboxReceiveTimedOut`, `mailboxScanTimedOut`.
- Async/operation-mismatch: `mismatchIARCancel`, `mismatchIAREnd`, `checkInit`,
  `checkStaticInit`.
- Type-shape errors: `notAFunctionType`, `notATupleType`, `notARecordType`, `notAUnionType`,
  `notAnExceptionType`, `notAPermutation`, `privateExceptionType`, `privateRecordType`,
  `privateUnionType`, `keyNotFound`, `mapCannotBeMutated`, `notUsedForHashing`.
- Quotations/unification helpers: `QexpectedOneType`, `QexpectedTwoTypes`, `addressOpNotFirstClass`,
  `delegateExpected`, `invalidTupleTypes`, `objIsNullAndNoType`, `outOfRange`.

## Consumers
Generated `SR` module used across FSharp.Core implementation (List/Array/Seq, MailboxProcessor,
async, reflection, Numerics, option/result helpers). xlf satellites localize
`FSharp.Core.resources.dll` — but note FSharp.Core may also run in
reflection-free/server scenarios, hence the companion `ILLink.Substitutions.xml` handling.