// Copyright (c) Microsoft Corporation.  All Rights Reserved.  See License.txt in the project root for license information.
module CompilerInlining

    open Xunit
    open FSharp.Test.Compiler

    [<Fact>]
    let ``record confusion`` () =
        let CrossAssemblyOptimization =
            FSharp """
namespace Library

//#nowarn "346"
//#nowarn "1178"

[<NoEquality; NoComparison;Struct>]//>]
type ID (value : string) =

    member _.Value = value

    member inline this.Hello(other: ID) =

        System.Console.WriteLine(this.Value + " " + other.Value)

[<NoEquality; NoComparison>]//>]
type ID2 = { Value : ID } with

    member inline this.Hello(other: ID2) =

        this.Value.Hello other.Value
"""
            |> asLibrary

        FSharp """
open Library

[<EntryPoint>]
let main _ =

    let aBar = { Value = ID "a" }
    let bBar = { Value = ID "b" }

    aBar.Hello(bBar)

    0"""
        |> withReferences [ CrossAssemblyOptimization ]
        |> compileExeAndRun
        |> shouldSucceed
        |> withStdOutContainsAllInOrder ["a b"]

    [<Fact>]
    let ``local record confusion`` () =
        FSharp """
//#nowarn "346"
//#nowarn "1178"

[<NoEquality; NoComparison;Struct>]//>]
type ID (value : string) =

    member _.Value = value

    member inline this.Hello(other: ID) =

        System.Console.WriteLine(this.Value + " " + other.Value)

[<NoEquality; NoComparison>]//>]
type ID2 = { Value : ID } with

    member inline this.Hello(other: ID2) =

        this.Value.Hello other.Value


[<EntryPoint>]
let main _ =

    let aBar = { Value = ID "a" }
    let bBar = { Value = ID "b" }

    aBar.Hello(bBar)

    0"""
        |> compileExeAndRun
        |> shouldSucceed
        |> withStdOutContainsAllInOrder ["a b"]
