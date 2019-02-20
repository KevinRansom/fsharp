// Copyright (c) Microsoft Corporation.  All Rights Reserved.  See License.txt in the project root for license information.

namespace Microsoft.VisualStudio.FSharp.Editor

open System
open System.Collections.Immutable
open System.Composition
open System.Threading.Tasks

open Microsoft.CodeAnalysis
open Microsoft.CodeAnalysis.Text
open Microsoft.CodeAnalysis.CodeFixes

open FSharp.Compiler
open FSharp.Compiler.SourceCodeServices
open Microsoft.VisualStudio.FSharp.Editor.SymbolHelpers
open FSharp.Compiler.SourceCodeServices.Keywords

[<ExportCodeFixProvider(FSharpConstants.FSharpLanguageName, Name = "FSharpRenameParamToMatchSignature"); Shared>]
type internal FSharpRenameParamToMatchSignature
    [<ImportingConstructor>]
    (
        checkerProvider: FSharpCheckerProvider, 
        projectInfoManager: FSharpProjectOptionsManager
    ) =
    
    inherit CodeFixProvider()
    static let userOpName = "RenameParamToMatchSignature"
    let fixableDiagnosticIds = ["FS3218"]
        
        
    override __.FixableDiagnosticIds = Seq.toImmutableArray fixableDiagnosticIds

    override __.RegisterCodeFixesAsync context : Task =
        asyncMaybe {
            match context.Diagnostics |> Seq.filter (fun x -> fixableDiagnosticIds |> List.contains x.Id) |> Seq.toList with 
            | [diagnostic] -> 
                    let message = diagnostic.GetMessage()
                    let parts = System.Text.RegularExpressions.Regex.Match(message, ".+'(.+)'.+'(.+)'.+")
                    if parts.Success then
                    
                        let diagnostics = ImmutableArray.Create diagnostic
                        let suggestion = parts.Groups.[1].Value
                        let replacement = QuoteIdentifierIfNeeded suggestion
                        let computeChanges() = 
                            asyncMaybe {
                                let document = context.Document
                                let! cancellationToken = Async.CancellationToken |> liftAsync
                                let! sourceText = document.GetTextAsync(cancellationToken)
                                let! symbolUses = getSymbolUsesOfSymbolAtLocationInDocument (document, context.Span.Start, projectInfoManager, checkerProvider.Checker, userOpName) 
                                let changes = 
                                    [| for symbolUse in symbolUses do
                                            match RoslynHelpers.TryFSharpRangeToTextSpan(sourceText, symbolUse.RangeAlternate) with 
                                            | None -> ()
                                            | Some span -> 
                                                let textSpan = Tokenizer.fixupSpan(sourceText, span)
                                                yield TextChange(textSpan, replacement) |]
                                return changes 
                            }
                        let title = FSComp.SR.replaceWithSuggestion suggestion
                        let codefix = createTextChangeCodeFix(title, context, computeChanges)
                        context.RegisterCodeFix(codefix, diagnostics)
            | _ -> ()
        } |> Async.Ignore |> RoslynHelpers.StartAsyncUnitAsTask(context.CancellationToken)
