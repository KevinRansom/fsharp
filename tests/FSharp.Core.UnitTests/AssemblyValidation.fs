// Copyright (c) Microsoft Corporation.  All Rights Reserved.  See License.txt in the project root for license information.
module FSharp.Core.UnitTests.AssemblyValidation

    open Xunit
    open System
    open System.IO
    open FSharp.Test
    open FSharp.Test.Compiler
    open FSharp.Test.SurfaceArea
    open FSharp.Test.Utilities
    open TestFramework

    let dummySuccessResult outputFilePath outputType : CompilationResult=
        CompilationResult.Success {
            OutputPath    = Some $"{outputFilePath}"
            Dependencies  = []
            Adjust        = 0
            Diagnostics   = []
            PerFileErrors = []
            Output        = None
            Compilation   =
                FS {
                    Source            = SourceCodeFileKind.Fs { FileName = "test.fs"; SourceText = Some $"module TestCase" }
                    AdditionalSources = []
                    Baseline          = None
                    Options           = Compiler.defaultOptions
                    OutputType        = outputType
                    OutputDirectory   = Some (DirectoryInfo $"{outputFilePath}")
                    Name              = Some "test"
                    IgnoreWarnings    = false
                    References        = []
                    TargetFramework   = TargetFramework.Current
                    StaticLink        = false
                }
        }


// We are testing the surface area of the FSharp.Core assembly.
// NETCOREAPP builds with netstandard2.1
// Net472 builds with netstandard1.0
//
    let platform =
#if NETCOREAPP
        "netstandard21"
#else
        "netstandard20"
#endif
    let flavor =
#if DEBUG
        "debug"
#else
        "release"
#endif

    // This relies on a set of baselines to update the baseline set an environment variable before running the tests, then on failure the baselines will be updated
    // Handled by SurfaceArea.verify
    //
    // CMD:
    //    set TEST_UPDATE_BSL=1
    // PowerShell:
    //    $env:TEST_UPDATE_BSL=1
    // Linux/macOS:
    //    export TEST_UPDATE_BSL=1
    [<Fact>]
    let surfaceAreaFSharpCore () : unit =
        let assembly = typeof<int list>.Assembly
        let baseline = Path.Combine(__SOURCE_DIRECTORY__, $"FSharp.Core.SurfaceArea.{platform}.{flavor}.bsl")
        let outFileName = $"FSharp.Core.SurfaceArea.{platform}.{flavor}.out"
        verify assembly baseline outFileName


    [<Fact>]
    let ilverifyCleanFSharpCore () : CompilationResult =
        let platform =
            #if NETCOREAPP
                    "netstandard2.1"
            #else
                    "netstandard2.0"
            #endif

        let fsharpCoreAssemblyLocation = Path.Combine(System.IO.Path.GetDirectoryName(typeof<unit>.Assembly.Location), "ilverify", platform, "FSharp.Core.dll")
        let compilationResult =
            let compilationResult = dummySuccessResult fsharpCoreAssemblyLocation CompileOutput.Library
            match (dummySuccessResult fsharpCoreAssemblyLocation CompileOutput.Library) with
            | CompilationResult.Success output ->
                match output.Compilation with
                | FS _ ->
                    verifyPEFileWithSystemDlls (compilationResult, false)
                | _ -> compilationResult
            | _ -> compilationResult

        compilationResult
        |> shouldSucceed
        |> withOutputMatchesBaselineWithWildcards (Path.Combine(__SOURCE_DIRECTORY__, $"FSharp.Core.ILVerify.bsl"))
//        |> withOutputContainsAllInOrderWithWildcards [
//          "37 Error(s) Verifying *FSharp.Core.dll"
//            "All Classes and Methods in*FSharp.Core.dll Verified."
//        ]
