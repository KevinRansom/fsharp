# FSharpCommandLineBuilder.fs

> Pipeline role: Command-line argument builder for the MSBuild tasks — it builds both the *combined quoted* command line for `cmd.exe` *and* a parallel array of individual unquoted arguments. The comment (lines 17–20) motivates this: "we also generate an array of individual arguments. The former needs to be quoted (and cmd.exe will strip the quotes while parsing), whereas the latter is not. See bug 4357 for background; this helper class gets us out of the business of unparsing-then-reparsing arguments." Also declares the `ComVisible(false)`/`CLSCompliant(true)` assembly attributes.
> Namespace: `FSharp.Build` (line 3).

---

## `type FSharpCommandLineBuilder()`

Wraps `Microsoft.Build.Utilities.CommandLineBuilder` (`builder`) plus two reverse-order lists `args` and `srcs` capturing the unquoted individual arguments for the HostObject API.

**Members**:

- `member InternalCapturedArguments` / `CapturedArguments() = List.rev args` — unquoted individual args.
- `member CapturedFilenames() = List.rev srcs` — unquoted source file names.
- `override x.ToString() = builder.ToString()` — the quoted command line.
- `member AppendFileNamesIfNotNull(filenames: ITaskItem[], sep)` — delegates to base, then pushes each unquoted `ItemSpec` onto `srcs` (using `AppendSwitchUnquotedIfNotNull("", item.ItemSpec)` to avoid quoting).
- `member AppendSwitchesIfNotNull(switch, values: string[], sep)` — delegates, pushes a single combined unquoted entry from a temp builder onto `args`.
- `member AppendSwitchIfNotNull(switch, value: string | null, ?metadataNames: string[])` — delegates; when `value` non-null, pushes `switch + value` onto `args`; the optional `metadataNames` controls which `ITaskItem` metadata to include on the entries (only items' ItemSpec are used, unless metadata names are given).
- `member AppendOptionalSwitch(switch, value: bool option)` — only appends `switch` when the option is `Some` (for tri-state switches like `--compressmetadata`).
- `member AppendSwitchUnquotedIfNotNull(switch, value: string | null)` — push an unquoted arg entry.
- `member AppendSwitch(switch: string)` — bare switch (e.g. `-g`, `--noframework`), recorded into `args`.
- `member internal GetCapturedArguments()` / `GetCapturedFilenames()` — internal accessors used by `Fsc`/`Fsi` to hand the host object the per-argument arrays.

---

## Related

- Used by `Fsc.fs` and `Fsi.fs`; consumed by the `IFscHostObject`/`IFsiHostObject` "compile in VS" protocol.