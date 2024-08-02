// Copyright (c) Microsoft Corporation. All Rights Reserved. See License.txt in the project root for license information.

/// LexFilter - process the token stream prior to parsing.
/// Implements the offside rule and a couple of other lexical transformations.
module internal FSharp.Compiler.LexFilter

open Internal.Utilities.Text.Lexing
open FSharp.Compiler.Lexhelp
open FSharp.Compiler.Parser

/// Match the close of '>' of a set of type parameters.
/// This is done for tokens such as '>>' by smashing the token
[<Struct>]
val (|TyparsCloseOp|_|): txt: string -> struct ((bool -> token)[] * token voption) voption

/// A stateful filter over the token stream that adjusts it for indentation-aware syntax rules
/// Process the token stream prior to parsing. Implements the offside rule and other lexical transformations.
type LexFilter =

    /// Create a lex filter
    new:
        indentationSyntaxStatus: IndentationAwareSyntaxStatus *
        enablelibraryonlyfeatures: bool *
        lexer: (LexBuffer<char> -> token) *
        lexbuf: LexBuffer<char> *
        debug: bool ->
            LexFilter

    /// The LexBuffer associated with the filter
    member LexBuffer: LexBuffer<char>

    /// Get the next token
    member GetToken: unit -> token
