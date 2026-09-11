You are an engineering agent operating inside a terminal environment.
You have write access to the F# compiler repo.

Goal:
Verify that the fix applied to `src/Compiler/Optimize/InnerLambdasToTopLevelFuncs.fs`
correctly activates the realsig+ typar split and does not regress the realsig- path.
The change replaced the four invalid `TryDeclaringEntity` uses (Pass2 `ambients`,
Pass3 `fHat_tps`, Pass4 `wrapperTyargs`, Pass4 `TransApp` tyargs) with map lookups
against `InnerLambdaDeclaringTyconsOf`; it added two module-level helpers
(`innerLambdaHostTycon`, `innerLambdaAmbientClassTypars`) and a new field
`innerLambdaDeclaringTyconsM : Zmap<Val, Tycon>` on `Pass4_RewriteAssembly.RewriteContext`.

Requirements:
1. Re-apply the diff (from the previous session) if it has been reverted.
2. Confirm the compile (`dotnet build FSharp.Compiler.Service.fsproj -c Debug`)
   still succeeds after any edits you make.
3. Write (or extend) a Cambridge-style test fixture that:
   - Declares a generic class `C<'T, 'U>` with members that contain local lambdas
     capturing `('T, 'U)` typars, so `ambientCtps0` is non-empty.
   - Exercises `fHoming` being `HostingClass` under `--realsig+` and confirms
     that the emitted tyargs for the wrapper and the call site are the
     two-group form `[class; method]`.
   - Under `--realsig-` (default), confirms the same helpers are emitted but
     with the single-group form `[method]`.
4. Verify `BodyReferencesTypeScopedPrivate` still rejects the lift when the
   closure body references a source-`private` member of the class (i.e. the
   one valid use of `TryDeclaringEntity` at L180 is unchanged).
5. Confirm the `innerLambdaDeclaringTyconsM` map is empty for module-level
   `let`s and for module-nested-inside-class locals, matching the intent of
   `InnerLambdaDeclaringTyconsOf`.
6. Return only:
   - the diff you applied (if any changes were necessary)
   - the changed files
   - a short pass/fail summary per requirement
   - any follow-up prompt

Output format: concise, terminal-oriented. No prose outside the listed sections.
