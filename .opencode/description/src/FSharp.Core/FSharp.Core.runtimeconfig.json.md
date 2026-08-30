# FSharp.Core.runtimeconfig.json

## Pipeline role
Minimal runtimeconfig for running `FSharp.Core` targets under a self-contained/standalone
host context; content is simply:

```json
{
  "runtimeOptions": {}
}
```

## Notes
- No `framework`, `tfm`, or GC settings — everything is inherited from the host process
  (fsc/fsi/LSP host carry their own runtimeconfig).
- Nominal purpose: satisfies tooling (e.g. dotnet SDK packs, `Microsoft.FSharp.Compiler`
  packaging, or standalone test harnesses) that expects a runtimeconfig when reflecting on
  or deploying the library, while asserting no extra runtime knobs for FSharp.Core itself.