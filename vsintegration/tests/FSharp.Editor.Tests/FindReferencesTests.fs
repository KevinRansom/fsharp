﻿module FSharp.Editor.Tests.FindReferencesTests

open System.Threading.Tasks
open System.Threading
open System.IO
open System.Collections.Concurrent

open Microsoft.CodeAnalysis.ExternalAccess.FSharp.Editor.FindUsages
open Microsoft.CodeAnalysis.ExternalAccess.FSharp.FindUsages
open Microsoft.VisualStudio.FSharp.Editor

open Xunit

open FSharp.Test.ProjectGeneration
open FSharp.Editor.Tests.Helpers

let getPositionOf (subString: string) (filePath) =
    filePath |> File.ReadAllText |> (fun source -> source.IndexOf subString)

module FindReferences =

    let project =
        SyntheticProject.Create(
            { sourceFile "First" [] with
                SignatureFile = AutoGenerated
                ExtraSource =
                    "let someFunc funcParam = funcParam * 1\n"
                    + "let sharedFunc funcParam = funcParam * 2\n"
            },
            { sourceFile "Second" [] with
                ExtraSource = "let someFunc funcParam = funcParam * 1"
            },
            { sourceFile "Third" [ "First" ] with
                ExtraSource = "let someFunc x = ModuleFirst.sharedFunc x + 10"
            }
        )

    let solution, checker = RoslynTestHelpers.CreateSolution project

    let findUsagesService = FSharpFindUsagesService() :> IFSharpFindUsagesService

    let getContext () =
        let foundDefinitions = ConcurrentBag()
        let foundReferences = ConcurrentBag()

        let context =
            { new IFSharpFindUsagesContext with

                member _.OnDefinitionFoundAsync(definition: FSharpDefinitionItem) =
                    foundDefinitions.Add definition
                    Task.CompletedTask

                member _.OnReferenceFoundAsync(reference: FSharpSourceReferenceItem) =
                    foundReferences.Add reference
                    Task.CompletedTask

                member _.ReportMessageAsync _ = Task.CompletedTask
                member _.ReportProgressAsync(_, _) = Task.CompletedTask
                member _.SetSearchTitleAsync _ = Task.CompletedTask
                member _.CancellationToken = CancellationToken.None
            }

        context, foundDefinitions, foundReferences

    [<Fact>]
    let ``Find references to a document-local symbol`` () =

        let context, foundDefinitions, foundReferences = getContext ()

        let documentPath = project.GetFilePath "Second"

        let document =
            solution.TryGetDocumentFromPath documentPath
            |> ValueOption.defaultWith (fun _ -> failwith "Document not found")

        findUsagesService.FindReferencesAsync(document, getPositionOf "funcParam" documentPath, context).Wait()

        // We cannot easily inspect what exactly was found here, but that should be verified
        // in FSharp.Compiler.ComponentTests.FSharpChecker.FindReferences
        if foundDefinitions.Count <> 1 then
            failwith $"Expected 1 definition but found {foundDefinitions.Count}"

        if foundReferences.Count <> 1 then
            failwith $"Expected 1 reference but found {foundReferences.Count}"

    [<Fact>]
    let ``Find references to an implementation + signature symbol`` () =

        let context, foundDefinitions, foundReferences = getContext ()

        let documentPath = project.GetFilePath "First"

        let document =
            solution.TryGetDocumentFromPath documentPath
            |> ValueOption.defaultWith (fun _ -> failwith "Document not found")

        findUsagesService.FindReferencesAsync(document, getPositionOf "funcParam" documentPath, context).Wait()

        if foundDefinitions.Count <> 1 then
            failwith $"Expected 1 definition but found {foundDefinitions.Count}"

        if
            foundReferences.Count <> 2 // One in signature file, one in function body
        then
            failwith $"Expected 2 references but found {foundReferences.Count}"

    [<Fact>]
    let ``Find references to a symbol in project`` () =
        let context, foundDefinitions, foundReferences = getContext ()

        let documentPath = project.GetFilePath "First"

        let document =
            solution.TryGetDocumentFromPath documentPath
            |> ValueOption.defaultWith (fun _ -> failwith "Document not found")

        findUsagesService.FindReferencesAsync(document, getPositionOf "sharedFunc" documentPath, context).Wait()

        if foundDefinitions.Count <> 1 then
            failwith $"Expected 1 definition but found {foundDefinitions.Count}"

        if
            foundReferences.Count <> 2 // One in signature file, one in Third file
        then
            failwith $"Expected 2 references but found {foundReferences.Count}"

    [<Theory>]
    [<InlineData(">=>")>]
    [<InlineData(">++")>]
    let ``Find references to operators start with >`` operator =

        let project2 =
            SyntheticProject.Create(
                { sourceFile "First" [] with
                    SignatureFile = No
                    ExtraSource =
                        "let compose x = fun y -> x - y\n"
                        + $"let ({operator}) = compose\n"
                        + $"let test t = t {operator} 5\n"
                },
                { sourceFile "Second" [ "First" ] with
                    ExtraSource = "open ModuleFirst\n" + $"let z = 4 {operator} 5\n"
                }
            )

        let solution2, _ = RoslynTestHelpers.CreateSolution project2

        let context, foundDefinitions, foundReferences = getContext ()

        let documentPath = project2.GetFilePath "Second"

        let document =
            solution2.TryGetDocumentFromPath documentPath
            |> ValueOption.defaultWith (fun _ -> failwith "Document not found")

        findUsagesService.FindReferencesAsync(document, getPositionOf operator documentPath, context).Wait()

        // We cannot easily inspect what exactly was found here, but that should be verified
        // in FSharp.Compiler.ComponentTests.FSharpChecker.FindReferences
        if foundDefinitions.Count <> 1 then
            failwith $"Expected 1 definition but found {foundDefinitions.Count}"

        if foundReferences.Count <> 2 then
            failwith $"Expected 2 reference but found {foundReferences.Count}"
