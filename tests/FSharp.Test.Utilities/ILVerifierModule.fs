// Copyright (c) Microsoft Corporation.  All Rights Reserved.  See License.txt in the project root for license information.
module FSharp.Test.ILVerifierTool

    open FSharp.Test
    open System
    open System.IO
    open System.Text.RegularExpressions
    open TestFramework

    type ILVerifierModule =

        static let config = initialConfig

        static let fsharpCoreReference = $"--reference \"{typeof<unit>.Assembly.Location}\""

        static let stripDllPaths (text: string) = Regex.Replace(text, @"(?:[A-Za-z]:)?(?:\\|/)(?:.*?[/\\])*([^\\/]+\.dll)", "$1")

        static let exec (dotnetExe: string) args workingDirectory =
            let arguments = args |> String.concat " "
            let exitCode, _output, errors = Commands.executeProcess dotnetExe arguments workingDirectory
            let errors = errors |> String.concat Environment.NewLine
            errors, exitCode

        static member verifyPEFileCore peverifierArgs dllFilePath =
            let nuget_packages =
                match Environment.GetEnvironmentVariable("NUGET_PACKAGES") with
                | null ->
                    let profile = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile)
                    $"""{profile}/.nuget/packages"""
                | path -> path
            let workingDirectory = createTemporaryDirectory().FullName
            let peverifyFullArgs = [
                yield "exec"
                yield $"""{nuget_packages}/dotnet-ilverify/9.0.0/tools/net9.0/any/ILVerify.dll"""
                yield dllFilePath
                yield! peverifierArgs
            ]
            let _, exitCode =
                let peverifierCommandPath = Path.ChangeExtension(dllFilePath, ".peverifierCommandPath.cmd")
                let args = peverifyFullArgs |> Seq.fold(fun a acc -> $"{a} " + acc) ""
                File.WriteAllLines(Path.Combine(workingDirectory, peverifierCommandPath), [| $"{args}" |] )
                File.Copy(typeof<RequireQualifiedAccessAttribute>.Assembly.Location, Path.GetDirectoryName(dllFilePath) ++ "FSharp.Core.dll", true)
                exec config.DotNetExe peverifyFullArgs workingDirectory

            // Grab output
            let outputText = File.ReadAllText(Path.Combine(workingDirectory, "StandardOutput.txt")) |> stripDllPaths
            File.WriteAllText(Path.Combine(workingDirectory, "StandardOutput.cleaned"), outputText)
            let errorText = File.ReadAllText(Path.Combine(workingDirectory, "StandardError.txt")) |> stripDllPaths
            File.WriteAllText(Path.Combine(workingDirectory, "StandardError.cleaned"), errorText)

            match exitCode with
            | 0 -> {Outcome = NoExitCode; StdOut = outputText; StdErr = errorText } 
            | _ -> {Outcome = ExitCode exitCode; StdOut = outputText; StdErr = errorText }

        static member systemDllReferences =
            // Get the path containing mecorlib.dll or System.Core.Private.dll
            let refs =
                let systemPath = Path.GetDirectoryName(typeof<obj>.Assembly.Location)
                DirectoryInfo(systemPath).GetFiles("*.dll")
                |> Array.map (fun dll -> $"--reference \"{Path.Combine(systemPath, dll.FullName)}\"")
                |> Array.toList
            (fsharpCoreReference :: refs)


