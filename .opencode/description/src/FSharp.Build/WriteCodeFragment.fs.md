# WriteCodeFragment.fs

> Pipeline role: MSBuild task (F# port of Roslyn's `WriteCodeFragment`) that writes a source file containing F# assembly attributes (e.g. `[<assembly: AssemblyVersion("1.0.0")>]`) from `AssemblyAttributes` import items, respecting target framework and language. Behind `GenerateAssemblyInfo` style targets.
> Namespace: `FSharp.Build` (line 2).

---

## Types

- `type EscapedValue = { Escaped: string; Raw: string }` — pairing of an attribute-argument escaped form and its raw text (for languages where escaping defeats parsing).

## `type WriteCodeFragment() as this = inherit Task()`

Fields: `_outputDirectory`, `_outputFile` (nullable `ITaskItem`), `_language: string`, `_assemblyAttributes: ITaskItem[]`.

**`failTask`** — logs `CodeFragment` error (`CouldNotDetermine`-style) and fails the task.

**Escaping** — `escapeString (str: string)` — translates `\u2028`→`\n`, `\r`→`\r`, `\t`, `'`→`\'`, `\`→`\\`, `"`→`\"`, `\u0000`→`\0`.

**`member GenerateAttribute(item: ITaskItem, language: string)`** — turns one `AssemblyAttributes` item into `[<assembly: AttrName(arg1=..., ...)>]`:

- `attributeName = item.ItemSpec`; walks `CloneCustomMetadata()` to collect `parameterPairs` — for each metadata `(name, value)`:
  - name literally `_ParameterArray` → becomes the `params`-array tail, expanding its (semicolon?) values as separate params;
  - `Type`-typed values are wrapped in `typeof<...>`;
  - strings pass through the escape/raw logic, numeric/bool/enum values pass raw.
- Emits `assembly:`-prefixed attribute in the target language's attribute syntax; when the language is a "verbatim" value (`TypeScript`? no — F# always), uses the escaped form.

**`Execute()`** — resolves `_outputFile` (item `ItemSpec` or `_outputDirectory`+generated name), builds the assembly attributes namespace + attribute list, writes the file, and if `ZipOutputPath`/`ZipFileName`? (not here) — it simply returns the `OutputFile` (`= _outputFile.ItemSpec`), `AssemblyAttributes`, `AttributesFile`? outputs. Guards on `_language` (`"f#"`, `"c#"`) — CJLang support was simplified to F# here.

---

## Related

- Port of MSBuild's `Microsoft.Build.Tasks.CodeGeneration.WriteCodeFragment`; used by F# SDK targets to generate `AssemblyInfo.fs` from `AssemblyAttribute` items.