# FSIstrings.txt

## Pipeline role
String table for the F# Interactive tool (`fsi.exe` / `fsi.dll` front-ends and the
FSharpInteractiveServer). Embedded into `FSharp.Compiler.Service.fsproj` as
`Interactive\FSIstrings.txt` (RichText) and consumed by the interactive driver code.

## Format
Classic `id,message,"value"` lines; `#` comment header. Numbered diagnostics use the 23xx
band (fsi-specific):
- `2301,fsiInvalidAssembly,"'%s' is not a valid assembly name"`
- `2302,fsiDirectoryDoesNotExist,"Directory '%s' doesn't exist"`
- `2304,fsiEntryPointWontBeInvoked,"Functions with [<EntryPoint>] are not invoked in FSI..."`

## Role of the strings
- Usage/help text: `fsiUsage`, section headers (`fsiInputFiles`, `fsiCodeGeneration`,
  `fsiErrorsAndWarnings`, `fsiLanguage`, `fsiMiscellaneous`, `fsiAdvanced`), individual
  option descriptions (`fsiUse`, `fsiLoad`, `fsiRemaining`, `fsiHelp`, `fsiExec`, `fsiGui`,
  `fsiQuiet`, `fsiReadline`, `fsiEmitDebugInfoInQuotations`, `shadowCopyReferences`,
  `fsiMultiAssemblyEmitOption`).
- Interactive banner/directive help: `fsiProductName`, `fsiProductNameCommunity`,
  `fsiBanner3` ("For help type #help;;"), the `fsiIntroText*` two-column directives and
  command-line lists, `#r/#I/#time/#load` narration (`fsiDidAHashr`, `fsiDidAHashI`,
  `fsiTurnedTimingOn/Off`, `fsiLoadingFilesPrefixText`).
- Runtime-communication messages for server/embedded scenarios (used by the VS F# window):
  `fsiConsoleProblem`, `fsiExceptionRaisedStartingServer`, `fsiCouldNotInstallCtrlCHandler`,
  `fsiInterrupt/fsiExit/fsiAbortingMainThread`, `fsiUnexpectedThreadAbortException`,
  `fsiOperationCouldNotBeCompleted`/`fsiOperationFailed` (the latter directing users to the
  NonThrowing Eval* APIs), `fsiTimeInfoMainString`/`fsiTimeInfoGCGenerationLabel...`,
  `fsiExceptionDuringPrettyPrinting`, `fsiFailedToResolveAssembly`,
  `fsiBindingSessionTo`, `fsiLineTooLong`.

## Build-time
The `FSharpEmbedResourceText` task generates `FSIstrings.resources` + typed accessors
(`SR`-style) used by `Interactive\fsi.fs` / `fsihelp.fs`; xlf satellite translations do the
localization.