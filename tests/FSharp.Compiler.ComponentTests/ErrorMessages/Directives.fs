﻿// Copyright (c) Microsoft Corporation.  All Rights Reserved.  See License.txt in the project root for license information.
namespace ErrorMessages

open Xunit
open FSharp.Test.Compiler

module HashDirectives =

    // #nowarn is super forgiving the only real error is FS alerts you that you forgot the error ID
    [<Fact>]
    let ``NoWarn Errors F# 8`` () =

        FSharp """
#nowarn "988"
#nowarn FS
#nowarn FSBLAH
#nowarn ACME 
#nowarn "FS"
#nowarn "FSBLAH"
#nowarn "ACME"
        """
        |> withLangVersion80
        |> asExe
        |> compile
        |> shouldFail
        |> withDiagnostics[
            (Warning 203, Line 6, Col 1, Line 6, Col 13, "Invalid warning number 'FS'")
            (Error 3350, Line 3, Col 9, Line 3, Col 11, "Feature '# directives with non-quoted string arguments' is not available in F# 8.0. Please use language version 'PREVIEW' or greater.")
            (Error 3350, Line 4, Col 9, Line 4, Col 15, "Feature '# directives with non-quoted string arguments' is not available in F# 8.0. Please use language version 'PREVIEW' or greater.")
            (Error 3350, Line 5, Col 9, Line 5, Col 13, "Feature '# directives with non-quoted string arguments' is not available in F# 8.0. Please use language version 'PREVIEW' or greater.")
            ]


    [<Fact>]
    let ``NoWarn Errors F# 9`` () =

        FSharp """
#nowarn FS988
#nowarn FS
#nowarn FSBLAH
#nowarn ACME 
#nowarn "FS"
#nowarn "FSBLAH"
#nowarn "ACME"
        """
        |> asExe
        |> withLangVersionPreview
        |> compile
        |> shouldFail
        |> withDiagnostics [
            (Warning 203, Line 3, Col 1, Line 3, Col 11, "Invalid warning number 'FS'")
            (Warning 203, Line 6, Col 1, Line 6, Col 13, "Invalid warning number 'FS'")
            ]


    [<Fact>]
    let ``NoWarn Errors collection F# 8`` () =

        FSharp """
#nowarn "988"
#nowarn FS FSBLAH ACME "FS" "FSBLAH" "ACME"
        """
        |> withLangVersion80
        |> asExe
        |> compile
        |> shouldFail
        |> withDiagnostics [
            (Warning 203, Line 3, Col 1, Line 3, Col 44, "Invalid warning number 'FS'")
            (Error 3350, Line 3, Col 9, Line 3, Col 11, "Feature '# directives with non-quoted string arguments' is not available in F# 8.0. Please use language version 'PREVIEW' or greater.")
            (Error 3350, Line 3, Col 12, Line 3, Col 18, "Feature '# directives with non-quoted string arguments' is not available in F# 8.0. Please use language version 'PREVIEW' or greater.")
            (Error 3350, Line 3, Col 19, Line 3, Col 23, "Feature '# directives with non-quoted string arguments' is not available in F# 8.0. Please use language version 'PREVIEW' or greater.")
            ]

    [<Fact>]
    let ``NoWarn Errors collection F# 9`` () =

        FSharp """
#nowarn "988"
#nowarn FS FSBLAH ACME "FS" "FSBLAH" "ACME"
        """
        |> withLangVersionPreview
        |> asExe
        |> compile
        |> shouldFail
        |> withDiagnostics [
            (Warning 203, Line 3, Col 1, Line 3, Col 44, "Invalid warning number 'FS'")
            ]

    [<Fact>]
    let ``Mixed Warnings F# 8`` () =

        FSharp """
module Exception =
    exception ``Crazy@name.p`` of string

module Decimal =
    type T1 = { a : decimal }
    module M0 =
        type T1 = { a : int;}
    let x = { a = 10 }              // error - 'expecting decimal' (which means we are not seeing M0.T1)

module MismatchedYields =
    let collection () = [
        yield "Hello"
        "And this"
        ]
module DoBinding =
    let square x = x * x
    square 32
        """
        |> withLangVersion80
        |> asExe
        |> compile
        |> shouldFail
        |> withDiagnostics [
            (Warning 1104, Line 3, Col 15, Line 3, Col 31, "Identifiers containing '@' are reserved for use in F# code generation")
            (Warning 3391, Line 9, Col 19, Line 9, Col 21, """This expression uses the implicit conversion 'System.Decimal.op_Implicit(value: int) : decimal' to convert type 'int' to type 'decimal'. See https://aka.ms/fsharp-implicit-convs. This warning may be disabled using '#nowarn "3391".""")
            (Warning 3221, Line 14, Col 9, Line 14, Col 19, "This expression returns a value of type 'string' but is implicitly discarded. Consider using 'let' to bind the result to a name, e.g. 'let result = expression'. If you intended to use the expression as a value in the sequence then use an explicit 'yield'.")
            (Warning 20, Line 18, Col 5, Line 18, Col 14, "The result of this expression has type 'int' and is implicitly ignored. Consider using 'ignore' to discard this value explicitly, e.g. 'expr |> ignore', or 'let' to bind the result to a name, e.g. 'let result = expr'.")
            ]


    [<Fact>]
    let ``Mixed Warnings F# 9`` () =

        FSharp """
module Exception =
    exception ``Crazy@name.p`` of string

module Decimal =
    type T1 = { a : decimal }
    module M0 =
        type T1 = { a : int;}
    let x = { a = 10 }              // error - 'expecting decimal' (which means we are not seeing M0.T1)

module MismatchedYields =
    let collection () = [
        yield "Hello"
        "And this"
        ]
module DoBinding =
    let square x = x * x
    square 32
        """
        |> withLangVersionPreview
        |> asExe
        |> compile
        |> shouldFail
        |> withDiagnostics [
            (Warning 1104, Line 3, Col 15, Line 3, Col 31, "Identifiers containing '@' are reserved for use in F# code generation")
            (Warning 3391, Line 9, Col 19, Line 9, Col 21, """This expression uses the implicit conversion 'System.Decimal.op_Implicit(value: int) : decimal' to convert type 'int' to type 'decimal'. See https://aka.ms/fsharp-implicit-convs. This warning may be disabled using '#nowarn "3391".""")
            (Warning 3221, Line 14, Col 9, Line 14, Col 19, "This expression returns a value of type 'string' but is implicitly discarded. Consider using 'let' to bind the result to a name, e.g. 'let result = expression'. If you intended to use the expression as a value in the sequence then use an explicit 'yield'.")
            (Warning 20, Line 18, Col 5, Line 18, Col 14, "The result of this expression has type 'int' and is implicitly ignored. Consider using 'ignore' to discard this value explicitly, e.g. 'expr |> ignore', or 'let' to bind the result to a name, e.g. 'let result = expr'.")
            ]


    [<Fact>]
    let ``Mixed Nowarns F# 8`` () =

        FSharp """
#nowarn 20 FS1104 "3391" "FS3221"

module Exception =
    exception ``Crazy@name.p`` of string

module Decimal =
    type T1 = { a : decimal }
    module M0 =
        type T1 = { a : int;}
    let x = { a = 10 }              // error - 'expecting decimal' (which means we are not seeing M0.T1)

module MismatchedYields =
    let collection () = [
        yield "Hello"
        "And this"
        ]
module DoBinding =
    let square x = x * x
    square 32
        """
        |> withLangVersion80
        |> asExe
        |> compile
        |> shouldFail
        |> withDiagnostics [
            (Warning 1104, Line 5, Col 15, Line 5, Col 31, "Identifiers containing '@' are reserved for use in F# code generation")
            (Error 3350, Line 2, Col 9, Line 2, Col 11, "Feature '# directives with non-quoted string arguments' is not available in F# 8.0. Please use language version 'PREVIEW' or greater.")
            (Error 3350, Line 2, Col 12, Line 2, Col 18, "Feature '# directives with non-quoted string arguments' is not available in F# 8.0. Please use language version 'PREVIEW' or greater.")
            ]


    [<Fact>]
    let ``Mixed Nowarns F# 9`` () =

        FSharp """
#nowarn 20 FS1104 "3391" "FS3221"

module Exception =
    exception ``Crazy@name.p`` of string

module Decimal =
    type T1 = { a : decimal }
    module M0 =
        type T1 = { a : int;}
    let x = { a = 10 }              // error - 'expecting decimal' (which means we are not seeing M0.T1)

module MismatchedYields =
    let collection () = [
        yield "Hello"
        "And this"
        ]
module DoBinding =
    let square x = x * x
    square 32
        """
        |> withLangVersionPreview
        |> asExe
        |> compile
        |> shouldSucceed


    [<Fact>]
    let ``Time Errors F# 8`` () =

        Fsx """
#time ono;;
#time 0n;;
#time of;;
printfn "Hello, World"
        """
        |> withLangVersion80
        |> asExe
        |> compile
        |> shouldFail
        |> withDiagnostics [
            (Error 10, Line 3, Col 7, Line 3, Col 9, "Unexpected integer literal in implementation file")
            (Error 3350, Line 2, Col 7, Line 2, Col 10, "Feature '# directives with non-quoted string arguments' is not available in F# 8.0. Please use language version 'PREVIEW' or greater.")
            (Error 235, Line 2, Col 1, Line 2, Col 10, """Invalid directive. Expected '#time', '#time "on"' or '#time "off"'.""")
            ]


    [<Fact>]
    let ``Time Errors F# 9`` () =

        Fsx """
#time ono;;
#time 0n;;
#time of;;
printfn "Hello, World"
        """
        |> asExe
        |> withLangVersionPreview
        |> compile
        |> shouldFail
        |> withDiagnostics [
            (Error 10, Line 3, Col 7, Line 3, Col 9, "Unexpected integer literal in implementation file")
            (Error 235, Line 2, Col 1, Line 2, Col 10, """Invalid directive. Expected '#time', '#time "on"' or '#time "off"'.""")
            ]


    [<InlineData("8.0")>]
    [<InlineData("preview")>]
    [<Theory>]
    let ``Mixed time commands - Fsc`` (langversion) =

        Fsx """
#time on;;
#time off;;
#time;;
#time "on";;
#time "off";;

printfn "Hello, World"
        """
        |> withLangVersion langversion
        |> asExe
        |> compile
        |> shouldFail
        |> withDiagnostics [
            ]


    [<InlineData("8.0")>]
    [<InlineData("preview")>]
    [<Theory>]
    let ``Mixed time commands - Fsx`` (langversion) =

        Fsx """
#time on;;
#time off;;
#time blah;;
#time;;
#time "on";;
#time "off";;
#time "blah";;

printfn "Hello, World"
        """
        |> withLangVersion langversion
        |> asExe
        |> compile
        |> shouldFail
        |> withDiagnostics [
            ]


    [<InlineData("8.0")>]
    [<InlineData("preview")>]
    [<Theory>]
    let ``Reference Errors - Fsc`` (langVersion) =

        FSharp """
        #r;;
        #r "";;
        #r Ident;;
        #r Long.Ident;;
        #r 123;;

        printfn "Hello, World"
        """
        |> withLangVersion langVersion
        |> asExe
        |> compile
        |> shouldFail
        |> withDiagnostics[
            (Error 76, Line 2, Col 9, Line 2, Col 11, "This directive may only be used in F# script files (extensions .fsx or .fsscript). Either remove the directive, move this code to a script file or delimit the directive with '#if INTERACTIVE'/'#endif'.")
            (Error 76, Line 3, Col 9, Line 3, Col 14, "This directive may only be used in F# script files (extensions .fsx or .fsscript). Either remove the directive, move this code to a script file or delimit the directive with '#if INTERACTIVE'/'#endif'.")
            (Error 76, Line 4, Col 9, Line 4, Col 17, "This directive may only be used in F# script files (extensions .fsx or .fsscript). Either remove the directive, move this code to a script file or delimit the directive with '#if INTERACTIVE'/'#endif'.")
            (Error 76, Line 5, Col 9, Line 5, Col 22, "This directive may only be used in F# script files (extensions .fsx or .fsscript). Either remove the directive, move this code to a script file or delimit the directive with '#if INTERACTIVE'/'#endif'.")
            (Error 76, Line 6, Col 9, Line 6, Col 15, "This directive may only be used in F# script files (extensions .fsx or .fsscript). Either remove the directive, move this code to a script file or delimit the directive with '#if INTERACTIVE'/'#endif'.")
            ]


    [<InlineData("8.0")>]
    [<InlineData("preview")>]
    [<Theory>]
    let ``Reference Errors - Fsi`` (langVersion) =

        Fsx """
        #r;;
        #r "";;
        #r Ident;;
        #r Long.Ident;;
        #r 123;;

        printfn "Hello, World"
        """
        |> withLangVersion langVersion
        |> asExe
        |> compile
        |> shouldFail
        |> withDiagnostics[
            (Warning 213, Line 3, Col 9, Line 3, Col 14, "'' is not a valid assembly name")
            (Error 3869, Line 4, Col 12, Line 4, Col 17, "Unexpected identifier 'Ident'.")
            (Error 3869, Line 5, Col 12, Line 5, Col 22, "Unexpected identifier 'Long.Ident'.")
            (Error 3869, Line 6, Col 12, Line 6, Col 15, "Unexpected integer literal '123'.")
            ]