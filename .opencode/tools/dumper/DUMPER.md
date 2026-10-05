# dumper — how to invoke it correctly

This is a small C# tool (`.opencode/tools/dumper/dumper.csproj`) that reads an
assembly's metadata and dumps a type's generic parameters + their constraint
blobs, so you can confirm VAR vs MVAR / correct constraint references in the
emitted IL.

## Invocation (the part that is easy to get wrong)

The dumper reads generic-arity types whose **emitted name is `` ` + digit `**,
NOT an apostrophe. For example the source `type ConcatEnumerator<'T,'U>(...)`
emits exactly:

    ConcatEnumerator`2      <- backtick (char 96) + "2"

NOT `ConcatEnumerator'2` (apostrophe, char 39).

**PowerShell will corrupt the backtick** if you wrap the class argument in
double quotes, or if you escape it, or route through `cmd.exe /c "..."`. The
arg arrives at the process argv as an apostrophe and the lookup fails with
`Type 'ConcatEnumerator'2' not found.` even though the type definitely exists.

### Do this (PowerShell)
Pass the class token with **single quotes** so the backtick is preserved, and
the other two args single-quoted too:

    dotnet run --project .opencode\tools\dumper\dumper.csproj 'artifacts\Temp\RealsigPlusOptimisePlus.exe' 'ConcatEnumerator`2' 'takeInner@301'

### Do NOT do this
    dotnet run ... "artifacts\Temp\...exe" "ConcatEnumerator`2" "takeInner@301"   # backtick -> apostrophe
    cmd.exe /c "dotnet run ... ""ConcatEnumerator`2"""                            # same corruption

If you are unsure of the exact emitted type / method names, use `--list` first
(it prints every type with its `[g=N]` generic count and its method names) and
read the real codepoints off that output.

## `--list` mode (use this first to discover the exact names)

    dotnet run --project .opencode\tools\dumper\dumper.csproj --list 'artifacts\Temp\RealsigPlusOptimisePlus.exe'

Prints all types, the generic parameter count, and their method names — e.g.
you can see `.ConcatEnumerator'2 [g=2]` plus `takeInner@301` / `takeOuter@308`,
so you know the exact strings to feed to the normal mode.

## Rebuilding the F# compiler (for verification)

Only use `build.cmd` / `build.sh` to build the compiler (do not call MSBuild
directly). Both Debug and Release exist under `artifacts\bin\fsc\{Debug,Release}\net472\`.
After a successful build you may directly invoke the built compiler to compile
the repro file (a "cheat mode" shortcut — see `AGENTS.md`).
