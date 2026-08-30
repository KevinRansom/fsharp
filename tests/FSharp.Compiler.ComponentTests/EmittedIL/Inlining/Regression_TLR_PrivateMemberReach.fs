/// Purpose: cover the intersection of TLR and realsig+ PRIVACY -- an inner-recursive group
/// inside a generic class that reads a type-private (source-`private`, IL `private` under
/// --realsig+) static of its own hosting class.
///
/// Why this corner exists: a flat lift to the module class cannot reach an IL-`private`
/// method (MethodAccessException, the #19933 class of bug), so today's compiler is forced
/// to emit a closure NESTED inside the generic class instead of a static. The class-homing
/// change is precisely what unfreezes this: a static homed on the hosting class is
/// type-scoped and CAN reach the private member, so the lift becomes possible again. These
/// tests pin the current nested-closure behavior under --realsig+ and the flat behavior
/// under --realsig-, and the runtime cases prove access never throws.
///
/// Variant policy: runtime = full 4-way matrix; IL = realsig +/- under --optimize+ only
/// (TLR is an optimize+ transform; the closure fragments differ per realsig and the test
/// branches on it). No IL baselines are generated; the comments note where the manual
/// capture/fragment-update goes when homing lands.
namespace EmittedIL.RealInternalSignature

open Xunit
open FSharp.Test
open FSharp.Test.Compiler

module Regression_TLR_PrivateMemberReach =

    let private compileWithFlags realsig optimize source =
        FSharp source
        |> withRealInternalSignature realsig
        |> asExe
        |> withOptimization optimize
        |> ignoreWarnings

    let private runAllFour realsig optimize (source: string) =
        source
        |> compileWithFlags realsig optimize
        |> compileAndRun
        |> shouldSucceed
        |> ignore

    /// What: an inner mutual-rec group in a GENERIC class member that calls a type-private
    /// static of the hosting class must run (no MethodAccessException) under all four
    /// realsig/optimize combos. Accesses a private static, so the lift is never allowed to
    /// cross the privacy boundary illegally.
    /// Why: under --realsig+ private members are IL `private`; a naive flat lift throws.
    /// This is the exact bug the homing change fixes by making the lift a member-scoped
    /// static, and the realsig- row must keep working via the legacy layout.
    /// Breaks if: any future routing puts the lift in a scope that cannot reach the private
    /// member, i.e. a MethodAccessException on first invocation.
    [<Theory; InlineData(true, true); InlineData(true, false); InlineData(false, true); InlineData(false, false)>]
    let ``Generic class member rec reaching a type-private static runs`` (realsig: bool, optimize: bool) =
        """
module Sample
type Safe<'T>(mark: 'T) =
    static let mutable stage = 0
    static member Set v = stage <- v
    member _.Mark = mark
    [<NoCompilerInlining>]
    static member private Secret() = stage + 1
    member _.Run<'U>(u: 'U) =
        let rec go (n: int) (acc: int) (p: 'U) =
            if n <= 0 then acc
            elif box p = null then acc - 1
            else skip (n - 1) (acc + Safe<'T>.Secret()) p
        and skip (n: int) (acc: int) (p: 'U) =
            if n % 2 = 0 then skip (n - 1) acc p
            else go (n - 1) acc p
        go 1000 0 u
[<EntryPoint>]
let main _ =
    let s = Safe<int>(0)
    Safe<int>.Set 41
    if s.Run<string>("x") = 21000 then 0 else 1
"""
        |> runAllFour realsig optimize

    /// What: IL lock for the shape above. Under --realsig+ the compiler must emit the rec
    /// as closures NESTED inside `Safe<'T>`, and never as module siblings; under --realsig-
    /// the legacy flat statics on the module class are emitted.
    /// Why: both layouts are correctness-required scope decisions; the fragments document
    /// which scope owns the rec today.
    /// Breaks if: the nested closure is replaced by a module sibling (MethodAccessException),
    /// or --realsig- accidentally nests. When class-homing lands under --realsig+, the first
    /// branch is intended to flip from `Safe`1/go@` (nested closure) to `Safe`1::go@` (homed
    /// member static) -- update the fragment in the same PR as the codegen change.
    [<Theory; InlineData(true); InlineData(false)>]
    let ``Private-reach rec nests inside generic class under realsig+, lifts under realsig-`` (realsig: bool) =
        let src =
            """
module Sample
type Safe<'T>(mark: 'T) =
    static let mutable stage = 0
    static member Set v = stage <- v
    member _.Mark = mark
    [<NoCompilerInlining>]
    static member private Secret() = stage + 1
    member _.Run<'U>(u: 'U) =
        let rec go (n: int) (acc: int) (p: 'U) =
            if n <= 0 then acc
            elif box p = null then acc - 1
            else skip (n - 1) (acc + Safe<'T>.Secret()) p
        and skip (n: int) (acc: int) (p: 'U) =
            if n % 2 = 0 then skip (n - 1) acc p
            else go (n - 1) acc p
        go 1000 0 u
[<EntryPoint>]
let main _ =
    let s = Safe<int>(0)
    Safe<int>.Set 41
    if s.Run<string>("x") = 21000 then 0 else 1
"""
        let (present, absent) =
            if realsig then
                [ "Safe`1::go@"; "Safe`1::skip@" ], [ "Sample::go@"; "Sample::skip@" ]
            else
                [ "Sample::go@"; "Sample::skip@" ], [ "Safe`1::go@"; "Safe`1::skip@" ]

        let result =
            src
            |> compileWithFlags realsig true
            |> compile
            |> shouldSucceed
            |> verifyPEFileWithSystemDlls
            |> shouldSucceed
        result |> verifyILPresent present
        result |> verifyILNotPresent absent

    /// What: the same private-reach scenario hosted on a STRUCT generic class; the rec
    /// references the struct's private static member and must run under all four combos.
    /// Why: struct-hosted closures/lifts have a different class-layout (value type, no
    /// instance ctor path), so reachability of a struct-private static is a distinct failure
    /// mode from the reference-type case above.
    /// Breaks if: the lift or closure is placed outside the struct where the private static
    /// is out of reach (MethodAccessException), or struct field init interferes.
    [<Theory; InlineData(true, true); InlineData(true, false); InlineData(false, true); InlineData(false, false)>]
    let ``Struct generic class member rec reaching a type-private static runs`` (realsig: bool, optimize: bool) =
        """
module Sample
[<Struct>]
type Ticker<'T> =
    val Stage: int
    [<NoCompilerInlining>]
    static member private Advance (v: int) = v + 1
    member this.Run() =
        let rec walk (n: int) (acc: int) =
            if n <= 0 then acc
            else walk (n - 1) (Ticker<'T>.Advance acc)
        walk 1000 this.Stage
[<EntryPoint>]
let main _ =
    let t = Ticker<int>()
    if t.Run() = 1000 then 0 else 1
"""
        |> runAllFour realsig optimize

    /// What: IL lock for the struct case. Under --realsig+ the walk rec must live inside the
    /// struct (`Ticker`1/walk@`), never as a module sibling; under --realsig- the flat static
    /// is emitted.
    /// Why: structs cannot be extended by the nested-closure fix the same way reference
    /// types are, so this locks the struct-specific scope decision.
    /// Breaks if: the walk closure is emitted as a sibling (MethodAccessException at first
    /// call). When homing lands, expect the --realsig+ branch to flip to `Ticker`1::walk@`
    /// (homed member static) -- update in the same PR.
    [<Theory; InlineData(true); InlineData(false)>]
    let ``Struct private-reach rec nests under realsig+, lifts under realsig-`` (realsig: bool) =
        let src =
            """
module Sample
[<Struct>]
type Ticker<'T> =
    val Stage: int
    [<NoCompilerInlining>]
    static member private Advance (v: int) = v + 1
    member this.Run() =
        let rec walk (n: int) (acc: int) =
            if n <= 0 then acc
            else walk (n - 1) (Ticker<'T>.Advance acc)
        walk 1000 this.Stage
[<EntryPoint>]
let main _ =
    let t = Ticker<int>()
    if t.Run() = 1000 then 0 else 1
"""
        let (present, absent) =
            if realsig then
                [ "Ticker`1/walk@" ], [ "Sample/walk@" ]
            else
                [ "Sample/walk@" ], [ "Ticker`1/walk@" ]

        let result =
            src
            |> compileWithFlags realsig true
            |> compile
            |> shouldSucceed
            |> verifyPEFileWithSystemDlls
            |> shouldSucceed
        result |> verifyILPresent present
        result |> verifyILNotPresent absent
