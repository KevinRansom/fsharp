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

    member inline thisID.Hello(other: ID) =

        System.Console.WriteLine(thisID.Value + " " + other.Value)

[<NoEquality; NoComparison>]//>]
type ID2 = { Value : ID } with

    member inline thisID2.Hello(other: ID2) =

        thisID2.Value.Hello other.Value
"""
            |> withOptimize
            |> asLibrary

        FSharp """
module LibraryMain
open Library

[<EntryPoint>]
let main _ =

    let aBar = { Value = ID "a" }
    let bBar = { Value = ID "b" }

    aBar.Hello(bBar)

    0"""
        |> asExe
        |> withOptimize
        |> withReferences [ CrossAssemblyOptimization ]
        |> compile//ExeAndRun
        |> shouldSucceed
//        |> withStdOutContainsAllInOrder ["a b"]

    [<Fact>]
    let ``local record confusion`` () =
        FSharp """
module LibraryMain
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
        |> asExe
        |> withOptimize
        |> compile//ExeAndRun
        |> shouldSucceed
//        |> withStdOutContainsAllInOrder ["a b"]
