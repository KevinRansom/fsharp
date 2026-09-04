# fsihelp.fsi

## Pipeline role

This file is the signature of `fsihelp.fs`, part of `FSharp.Compiler.Interactive` (the `fsi` interactive REPL). It defines the `FsiHelp` module used to render XML-documentation help for an arbitrary F# quoted expression (`#help`-style functionality / help on the current selection). Given a quotation like `typeof<List<_>>` or `List.map`, it computes a formatted "Description / Remarks / Parameters / Returns / Exceptions / Examples / Full name / Assembly" help string by locating the corresponding `<doc>` XML entry for the underlying method, property, constructor, union case, or type. It exposes two nested sub-modules: `Parser` (the help data model + display formatting) and `Logic` (the public entry points for looking up help from a quotation).

## Modules, types and values

### `module FSharp.Compiler.Interactive.FsiHelp`

- `module Parser`:
  - `type Help` — a record of the doc-model fields: `Summary: string`, `Remarks: string option`, `Parameters: (string * string) list`, `Returns: string option`, `Exceptions: (string * string) list`, `Examples: (string * string) list`, `FullName: string`, `Assembly: string`.
    - `member ToDisplayString: unit -> string` — formats the record as the final help text (titled sections with a `Full name:`/`Assembly:` trailer).
  - `module Logic`:
    - `module Quoted`:
      - `val tryGetHelp: expr: Quotations.Expr -> Parser.Help voption` — `ValueSome` help when the quotation names a documented member/type, else `ValueNone`.
      - `val h: expr: Quotations.Expr -> string` — `tryGetHelp` rendered via `ToDisplayString`, or the fallback `"unable to get documentation\n"`.

## Relation to `fsihelp.fs`

The `.fs` additionally defines the XML loading/caching, name-mapping and quotation inspection machinery (`Parser.cleanupXmlContent`, `trimDotNet`, `xmlDocCache`, `tryGetXmlDocument`, `getTexts`, `tryMkHelp`; `Expr.tryGetSourceName`, `getInfos`, `exprNames`) as private implementation details behind the `Logic.Parser`/`Logic` surface.