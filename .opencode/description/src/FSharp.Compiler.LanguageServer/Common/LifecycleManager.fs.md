# LifecycleManager.fs

> Pipeline role: LSP lifecycle handling for the F# server — `ILifeCycleManager` implementation (shutdown/exit) plus the `ILspServices` wrapper (`FSharpLspServices`) built over a `IServiceCollection` DI container.
> Namespace: `FSharp.Compiler.LanguageServer.Common` (line 1).

---

## `type LspServiceLifeCycleManager()` (line 11)

- `interface ILifeCycleManager`:
  - `ShutdownAsync(_message: string)` — prints "Shutting down", swallowing `ObjectDisposedException`/`ConnectionLostException`.
  - `ExitAsync()` — `Task.CompletedTask`.

## `type FSharpLspServices(serviceCollection: IServiceCollection) as this` (line 25)

- `do serviceCollection.AddSingleton<ILspServices>(this)` — self-registration before building the provider.
- `serviceProvider = serviceCollection.BuildServiceProvider()`.
- `interface ILspServices`: `GetRequiredService()`, `GetService()`, `GetRequiredServices()`, `TryGetService(type, service)` (out-param style for C#), `Dispose()` (→ `serviceProvider.Dispose()`).

---

## Related

- Dropped into `FSharpLanguageServer.ConstructLspServices`; consumed by the handlers via `context.LspServices.GetRequiredService<ContextHolder>()`.