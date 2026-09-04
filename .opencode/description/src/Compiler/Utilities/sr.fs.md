# sr.fs

**Purpose**: Resource-string lookup machinery for compiler diagnostic/error messages. `SR.GetString` fetches localized message templates from the compiler's `fsstrings` resources, and `DiagnosticMessage.DeclareResourceString` binds a message template (with `Printf.StringFormat<'T>` placeholders) to its resource string, validating the format holes against the `%d/%s/%f` specifiers in DEBUG builds. This is how compiler errors (`error 1234`, etc.) are looked up by message ID and formatted with arguments.

**Namespace(s)**: `FSharp.Compiler`

**Modules / Types declared**:

- `module internal SR` — the resource lookup module.
- `module internal DiagnosticMessage` — message-string validation/formatting, including:
  - `type ResourceString<'T>(fmtString, fmt)` — a resource message string paired with its `Printf.StringFormat<'T>`; `member Format : 'T` is the result of applying `createMessageString` to the resource string.

**Public API surface** (all internal):

`SR`:
- `GetString (name: string) : string` — fetches `fsstrings` resource by name using `CurrentUICulture`; in DEBUG, asserts on a missing key (`**RESOURCE ERROR**: Resource token %s does not exist!`); returns the non-null string (`!!`).

`DiagnosticMessage`:
- `DeclareResourceString (messageID: string, fmt: Printf.StringFormat<'T>) : ResourceString<'T>` — looks up the resource string, post-processes escaped newlines/tabs, and wraps it in `ResourceString<'T>` carrying the format specifiers.
- `ResourceString<'T>.Format : 'T` — the formatted message function.

**Internal helpers**:

- `private resources = lazy (ResourceManager("fsstrings", Assembly.GetExecutingAssembly()))` — lazily created once.
- `mkFunctionValue (tys) impl` — builds an F# function value via `FSharpValue.MakeFunction` (used to lift arg-capturing closures).
- `isNamedType`, `isFunctionType`, `destFunTy` — find the `(arg, result)` generic args of the `obj->obj` chain of `fmt`'s type (`unbox` of the format function).
- `buildFunctionForOneArgPat ty impl` — builds a one-arg function value wrapping the next step of the capture chain (commented as a bit slow, e.g. in simple `sprintf "%x"` cases).
- `capture1 fmt i args ty go` — handles one format specifier: `'%'` (a format hole for the next value) and `'d'`/`'f'`/`'s'` (consume a resource argument); anything else is `failwith "bad format specifier"`.
- `postProcessString s` — converts literal `\n`/`\t` sequences (stored as escaped text in resource files) back in to real newlines/tabs, preserving the resource author's intent.
- `createMessageString (messageString) (fmt) : 'T` — the core binder: walks the resource template character by character, and at each `%` hole invokes the next argument of the F# `sprintf`-style function carried by `fmt` (using `FSharpValue.MakeFunction`-built thunks, `capture1`/`buildFunctionForOneArgPat`, to draw each argument one at a time); arguments are accumulated (in reverse) and finally supplied to `StringBuilder.AppendFormat(messageString, args)`. Surrogate pairs in the template are skipped via `System.Char.IsSurrogatePair` so astral characters aren't miscounted as holes.
- DEBUG-only validators: `countFormatHoles` (parse `{N}`-style holes in the resource string, ignoring escaped `{{`/`}}`) and `countFormatPlaceholders` (count `%d/%s/%f` in the format string, ignoring `%%`); `DeclareResourceString` asserts that hole count equals placeholder count and that hole indices are within range, emitting a `**DECLARED MESSAGE ERROR**` assert when they disagree.

**Significant internal logic**:

- The two-string protocol: each compiler error message has both an ID in `fsstrings.resx` (the localizable template, with `%d/%s/%f` holes) and a `Printf.StringFormat` signature in the F# source (e.g. `sprintf "%s%s" x y`). `createMessageString` bridges them so a DEBUG build can assert they agree; at runtime, `String.Format(messageString, args)` fills the result.
- `String.Char.IsSurrogatePair` handling in the template walk keeps emoji/astral characters in format strings from being miscounted.
- `ResourceString<'T>` defers formatting: the `Format` value is computed when `DeclareResourceString` is called, producing a value of the exact `'T` (typically a function returning `string`), which call sites then invoke lazily with their arguments — i.e. messages are looked up once and formatted on demand.

**Cross-references**: `sr.fsi` (same directory). Pervasive across the compiler — every error message in `checks.fs`/`tastcheck.fs`/`lookup.fs` and elsewhere is declared via `DiagnosticMessage.DeclareResourceString "errXXXX" ...`. Sits in the `FSharp.Compiler` namespace alongside the checkers, and reads from the compiler assembly's `fsstrings` resources.
