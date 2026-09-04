# FSharpEmbedResourceText.fs

> Pipeline role: MSBuild code generator that embeds a text resource as an F# type — it converts .NET-style resource strings (with message-format holes) into a generated F# `SR` class of static members whose bodies create the strings via `System.String.Format`/`SR.GetString`, along with an optional `.fsi` signature file. Also performs hole-type analysis (function-typed holes map to special "rich" message construction) and copies `.resx` back. Used by FSharp.Core and the compiler itself to build their `SR` diagnostic-message types.
> Namespace: `FSharp.Build` (line 3).

---

## `type FSharpEmbedResourceText() = inherit Task()`

**Properties**: `_embeddedText: ITaskItem[]` (`.txt` inputs each with a name), `_generatedSource: ITaskItem[]` (output `.fs`), `_generatedResx: ITaskItem[]` (output `.resx`), `_outputPath: string`; plus `EmbeddedResources`, `GeneratedSource`, `GeneratedResx` (all `[<Required>]`/`[<Output>]` surfaces).

**`Execute()`** — for each embedded-text item: reads the resource `key = value` lines (also tolerating resource with `[[]]`? no — it reads .NET `.resx`-ish text). Emits an F# file with:

- header comment `// This is a generated file; the original input is '%s'` (515).
- `namespace <justFileName>` (517) and the boilerplate prefix (banner + `open System` etc.).
- `type internal SR private() =` class with `static member GetString(key, ...args)`/`GetString(key, ?culture)` helpers and `SwallowResourceText` static switch (369–382: `static let mutable swallowResourceText = false`), plus the `GetTextOpt` member.
- For each resource entry: a `static member` `<Ident> =
        let s = GetString("<key>")` — with message-format args keyed by `{0}`/`{1}`/etc. recognised from the format string, listed in `formalArgs`; holes detected by scanning the string; for `System.String`-typed holes the member renders plain; for `Func<>`/function holes (`isFunctionType`, `capture1`) it builds rich message delegates.
- Emits `type internal SR =` (public, non-private) variant when `GenerateResx` flows; also writes `RichMessage`-flavoured `SR` members (`"static member %s(%s) = RichMessage.%s (fun rich -> SR.%s(%s))"`) for tooling display.
- `GenerateSignatureFile`/`GenerateSource` metadata and holes-as-parameter handling (`holeNumber`, `errNum` validation — errors on unmatched braces).

Also emits the matching `.fsi` (`outSignature` writer, e.g. `static member GetTextOpt: key:string -> string option`, `SwallowResourceText: bool with get, set`).

---

## Related

- Sibling generator: `FSharpEmbedResXSource.fs`. Consumed in build by `FSharp.Core`'s `SR.fs` and by the compiler service builds (project wiring in `Microsoft.FSharp.Core.targets`?).