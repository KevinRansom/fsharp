// Copyright (c) Microsoft Corporation.  All Rights Reserved.  See License.txt in the project root for license information.
namespace Conformance.Printing

open Xunit
open FSharp.Test
open FSharp.Test.Compiler
open System.IO

module PercentAGeneration =

    let CompileAndRunAsFs compilation =
        compilation
        |> asFs
        |> compileExeAndRun
        |> shouldSucceed


    [<InlineData("""printfn "Value: %A" x """)>]
    [<InlineData("""printfn $"Value: {x}" """)>]
    [<Theory>]
    let ``Tuple: `` (line) =

        FSharp $"""
module TestApp =
    type Code = string * (int * double)
    let x : Code = "Hello", (1,2.0)
    {line}
        """
        |> withLangVersionPreview
        |> withRealInternalSignatureOn
        |> compileExeAndRun
        |> shouldSucceed
        //|> withStdOutContainsAllInOrder [
        //    "Hello, World from MyProgram.MyFirstType"
        //    "Hello, World from MyProgram.MySecondType"
        //    "Hello from implicit main method"
        //]


    [<InlineData("""printfn "Value: %A" x """)>]
    [<InlineData("""printfn $"Value: {x}" """)>]
    [<Theory>]
    let ``Int: `` (line) =

        FSharp $"""
module TestApp =
    let x : int = 27
    {line}
        """
        |> withLangVersionPreview
        |> withRealInternalSignatureOn
        |> compileExeAndRun
        |> shouldSucceed
        //|> withStdOutContainsAllInOrder [
        //    "Hello, World from MyProgram.MyFirstType"
        //    "Hello, World from MyProgram.MySecondType"
        //    "Hello from implicit main method"
        //]

    [<InlineData("""let x = -6L""")>]
    [<InlineData("""let x =-6""")>]
    [<InlineData("""let x = -6=-6 """)>]
    [<Theory>]
    let ``= followed by -`` (line) =

        FSharp $"""{line}"""
        |> withLangVersionPreview
        |> withRealInternalSignatureOn
        |> compileExeAndRun
        |> shouldSucceed
        //|> withStdOutContainsAllInOrder [
        //    "Hello, World from MyProgram.MyFirstType"
        //    "Hello, World from MyProgram.MySecondType"
        //    "Hello from implicit main method"
        //]
