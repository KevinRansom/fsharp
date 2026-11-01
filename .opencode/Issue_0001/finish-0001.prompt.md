# Issue_0001 — realsig+ phantom-typar fix (finish & verify)

## One-line goal
Make the F# repro below compile under `--realsig+ --optimize+`, pass PEVerify, and run — by completing the "register the module-scope non-rec closure's free typars" fix so the TLR reqdTypars filter drops the phantom typar.

## Repro
File: `C:\kevinransom\fsharp\.opencode\Issue_0001\test.fsx`
- `module SeqTestsOnEnumerableEnforcingDisposalAtEnd` with `let mutable numActiveEnumerators = 0` and two functions (`countEnumeratorsAndCheckedDisposedAtMostOnceAtEnd`, `countEnumeratorsAndCheckedDisposedAtMostOnce`) that each do:
  ```fsharp
  let countEnumeratorsAndCheckedDisposedAtMostOnceAtEnd (seq: seq<'a>) =
      let enumerator() =
          numActiveEnumerators <- numActiveEnumerators + 1;
          let disposed = ref false in
          let endReached = ref false in
          let ie = seq.GetEnumerator() in
          { new System.Collections.Generic.IEnumerator<'a> with ... } in
      { new seq<'a> with member x.GetEnumerator() = enumerator() ... }
  ```
- Correct under `--realsig- --optimize+` (PASS PEVerify). Bug under `--realsig+ --optimize+`:
  - ILVerify: `System.IndexOutOfRangeException ... Internal.TypeSystem.Instantiation.get_GenericParameters` at `ILVerify.Verifier.VerifyMethod`
  - Runtime: `System.TypeLoadException: The generic type 'SeqTestsOnEnumerableEnforcingDisposalAtEnd' was used with the wrong number of generic arguments`

## Root cause (confirmed)
- realsig+ emits a closure CLASS `enumerator@37-2` and a METHOD `enumerator@32` (a TLR-lifted top-level val). The closure body references a **phantom typar**: `let ie = seq.GetEnumerator()` introduces a fresh typar `'b` for `IEnumerator<'b>`, while the object `{ new IEnumerator<'a> ... }` uses `'a`. Under realsig+ these remain distinct; under realsig- they unify to one.
- The METHOD `enumerator@32` is 1-tp; its body references `!!1` (the phantom `'b`), which is out of bounds for a 1-tp method → the errors.
- The **existing realsig mechanism** is the TLR reqdTypars owner-typar filter in `src/Compiler/Optimize/InnerLambdasToTopLevelFuncs.fs` `FlatEnvPacks.packEnv` (~line 802-819):
  ```fsharp
  let ownerTypars = g.RealsigOwnerTypars()
  let isClassHosted = fc.Vals |> List.exists (fun v ->
      match g.RealsigClosureParentTryGet v with
      | Some info -> info.ownerTycon.IsSome
      | None -> false)
  let reqdTypars =
      if g.realsig && isClassHosted && not (List.isEmpty ownerTypars) then
          env.reqdTypars |> Zset.filter (fun tp -> not (List.exists (fun o -> tp.Name=o.Name && tp.Range=o.Range) ownerTypars))
      else env.reqdTypars
  ```
  This drops the phantom by (Name,Range) **iff** a closure is registered with non-empty ownerTypars AND `isClassHosted`.
- `enumerator@32` is **NOT registered**: the `TcLetBinding` site (CheckExpressions.fs ~12268) only registers when `env.eFamilyType.IsSome` (class-body); the `None` (module-scope) branch was `| None -> ()`. The rec-path site (~13339) DOES register the module-scope case with free-but-undeclared typars — that's the precedent.

## The chosen general fix (approved by user)
Complete the registration so the pre-existing TLR filter runs — do NOT add a downstream dedup:
1. `src/Compiler/Checking/Expressions/CheckExpressions.fs` `TcLetBinding` (~line 12268-12276): replace the `| None -> ()` branch with logic that, for `g.realsig && eFamilyType=None`, computes the typars free in the closure's full type but not declared (`freeInType CollectAllNoCaching` minus `allDeclaredTypars`, distinctBy (Name,Range)) and, if non-empty, calls `g.AddRealsigClosureParent(v, familyTypars, None)` for the val(s). This mirrors the rec-path logic.
2. `src/Compiler/Optimize/InnerLambdasToTopLevelFuncs.fs` `packEnv` (~line 809-814): relax `isClassHosted` to `info.ownerTycon.IsSome || not (List.isEmpty info.ownerTypars)` so the filter fires for module-scope registered closures too.

## CURRENT working-tree state (git)
- `src/Compiler/Checking/Expressions/CheckExpressions.fs`: the TcLetBinding `| None ->` branch is now expanded (see `git diff`). **BUT line ~12289 `let v0: Val = NameMap.toList values |> List.head |> snd |> fst` CRASHES with `FS0193: The input list was empty`** when compiling the repro (at repro lines 24 and 103), because `values` is empty for at least one of the two `let` bindings. **This is the immediate bug to fix.**
- `src/Compiler/Optimize/InnerLambdasToTopLevelFuncs.fs`: the `isClassHosted` relaxation is in place.
- Both files were last built successfully with the CURRENT (crashing) code — the build succeeds, the *compile of the repro* is what crashes.

## Remaining work (do in this order, then verify)
1. **Fix the empty-`values` crash in CheckExpressions.fs.** The TcLetBinding site iterates over `values : NameMap<_, Val * GeneralizedType>` (i.e. `Map<string, Val * GeneralizedType>`). For a normal `let` it should have ≥1 entry, but evidently one of the repro's two `let` sites yields an empty map (or the `values` in that scope is a different/empty map). Replace `NameMap.toList values |> List.head |> snd |> fst` with a SAFE form:
   - `let (v0: Val) = match NameMap.toList values |> List.tryHead with Some (_, (v, _)) -> v | None -> ...`
   - **If `values` can be empty for a legitimate binding, skip registration entirely in that case** (guard the whole `if g.realsig && eFamilyType=None` block with `values.IsEmpty` check → do nothing). Determine WHY it's empty (add a temporary `System.Console.Error.WriteLine` of `NameMap.count values` and the binding name, OR re-read the surrounding code 12230-12276 to confirm which `values` is in scope), remove the debug line, and keep the fix minimal and correct. Prefer: guard with `if not (NameMap.isEmpty values) then ...` (or `List.tryHead |> Option.forNone`... i.e. only proceed if there's a val).
   - Use `NameMap` (from `src/Compiler/Utilities/lib.fs:73`; standard `Map<string,'T>`). Available ops: `toList`, `iter`, `map`, `find`, `tryFind`, `range`, `isEmpty`.
2. **Rebuild**: `.\build.cmd -c Release -norestore` (workdir `C:\kevinransom\fsharp`). (Note: the `timeout` tool param rejects scientific notation — omit it or use a plain integer.)
3. **Compile the repro (realsig+)**:
   `artifacts\bin\fsc\Release\net472\fsc.exe --nologo --realsig+ --optimize+ .opencode\Issue_0001\test.fsx --out:artifacts\Temp\test_RealsigPlusOptimisePlus.exe`
   - Must exit 0 with no `FS0193`/internal errors. (Info/Warn FS3873 deprecation is fine.)
   - If it still crashes or the IL is wrong, set `$env:"FSHARP_REALSIG_DEBUG"="1"` before compiling and read `$env:TEMP\realsig.log` to see `RealsigClosureParentTryGet` / `GValRepr` / `GMethodForBinding` entries for ``enumerator@32``.
4. **Confirm the phantom typar is gone.** Dump IL:
   `& "C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.7.2 Tools\ildasm.exe" artifacts\Temp\test_RealsigPlusOptimisePlus.exe -out:artifacts\Temp\plus.il`
   - `enumerator@32` method should be 1-tp `<a>` and its body must NOT reference `!!1` (the local `V` and `GetEnumerator()` call must be `IEnumerator<!!0>` / `IEnumerable<!!0>::GetEnumerator()`). The class `enumerator@37-2` should be 1-tp `<a>` with `ie` field `IEnumerator<!0>`. The `newobj` instantiating `enumerator@37-2` should be `<!!a>` (one arg). Sibling `enumerator@73-3` likewise.
5. **PEVerify realsig+**: `& "C:\kevinransom\fsharp\.opencode\Issue_0001\Issue_0001_plus.peverifierCommandPath.cmd"` — must print `All Classes and Methods in ...\test_RealsigPlusOptimisePlus.exe Verified.` and exit 0. (PEVerify writes noise `System.IndexOutOfRangeException`/`TypeLoadException` lines when it FAILS — those are the failure symptom, not normal output.)
6. **Run the exe** to confirm no runtime TypeLoadException: `& artifacts\Temp\test_RealsigPlusOptimisePlus.exe` — must exit 0 and print normal output (the test prints enumerator counts / "AtEnd" / "Disposed" style lines).
7. **Regression check (realsig- must be unchanged & still pass)**:
   - Build already recompiled all targets. Compile realsig-:
     `artifacts\bin\fsc\Release\net472\fsc.exe --nologo --realsig- --optimize+ .opencode\Issue_0001\test.fsx --out:artifacts\Temp\test_RealsigMinusOptimisePlus.exe`
   - `& "C:\kevinransom\fsharp\.opencode\Issue_0001\Issue_0001_minus.peverifierCommandPath.cmd"` → must be `Verified`.
   - Optionally run the realsig-related component tests to guard against the `isClassHosted` relaxation affecting other re-hosted closures:
     `dotnet test .\tests\FSharp.Component.Test\tests.fsproj --framework net472 --filter "FullyQualifiedName~emitting"` (and the RealInternalSignature / EmittedIL tests) if the test infra is available. At minimum, confirm the realsig- test still passes PEVerify (step 7) and spot-check a known realsig+ nested-closure test file (e.g. anything under `tests/` referencing `GenericClassConstrainedClosure`) compiles under `--realsig+` without new errors.
8. **Clean up**: remove any temporary debug writes; ensure `git diff` only contains the two intended file changes (CheckExpressions.fs TcLetBinding None-branch + InnerLambdasToTopLevelFuncs.fs isClassHosted) — no stray artifacts.

## Verification command cheat-sheet
| Step | Command (workdir `C:\kevinransom\fsharp`) |
|---|---|
| Build | `.\build.cmd -c Release -norestore` |
| Compile realsig+ | `artifacts\bin\fsc\Release\net472\fsc.exe --nologo --realsig+ --optimize+ .opencode\Issue_0001\test.fsx --out:artifacts\Temp\test_RealsigPlusOptimisePlus.exe` |
| Compile realsig- | `artifacts\bin\fsc\Release\net472\fsc.exe --nologo --realsig- --optimize+ .opencode\Issue_0001\test.fsx --out:artifacts\Temp\test_RealsigMinusOptimisePlus.exe` |
| ildasm | `& "C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.7.2 Tools\ildasm.exe" <exe> -out:<il>` |
| PEVerify plus | `& "C:\kevinransom\fsharp\.opencode\Issue_0001\Issue_0001_plus.peverifierCommandPath.cmd"` |
| PEVerify minus | `& "C:\kevinransom\fsharp\.opencode\Issue_0001\Issue_0001_minus.peverifierCommandPath.cmd"` |
| Run | `& artifacts\Temp\test_RealsigPlusOptimisePlus.exe` |
| Debug log | `PS> $env:"FSHARP_REALSIG_DEBUG"="1"` then rebuild+recompile; log at `$env:TEMP\realsig.log` |

## F# editing rules (user constraint)
- Indentation is significant. If the line **after** your insertion point is an `and` binding and you are adding a `let`, make it `and`. A function block must NOT end with a `let` binding.
- Prefer minimal, targeted edits.

## Acceptance criteria (all must be true)
1. `--realsig+ --optimize+` compile of the repro exits 0 (no FS0193 / internal error).
2. `Issue_0001_plus.peverifierCommandPath.cmd` reports `Verified` and exits 0.
3. Running the realsig+ exe exits 0 (no TypeLoadException).
4. `--realsig- --optimize+` still compiles, is `Verified`, and runs (no regression).
5. `git diff` contains only the two intended source-file changes.
