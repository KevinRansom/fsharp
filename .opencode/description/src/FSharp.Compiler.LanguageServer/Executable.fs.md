# Executable.fs

> Pipeline role: The LSP server host executable entry point — wires a `JsonRpc` transport over the process stdin/stdout (the standard LSP channel) and runs the `FSharpLanguageServer` until cancelled.
> Namespace: `module FSharp.Compiler.LanguageServer.Executable` (line 1).

---

## Implementation

- `[<EntryPoint>] let main _argv` (6):
  - `new JsonRpc(Console.OpenStandardOutput(), Console.OpenStandardInput())` — StreamJsonRpc over console streams (LSP protocol framing handled by `HeaderDelimitedMessageHandler` inside the server when created without streams; here it is a plain JSON-RPC over the raw console).
  - Constructs `FSharpLanguageServer(jsonRpc, LspLogger Console.Out.Write)`.
  - `jsonRpc.StartListening()`, then an infinite `async { while true do do! Async.Sleep 1000 } |> Async.RunSynchronously` keeps the process alive; returns `0`.
- Does not call `FSharpLanguageServer.Create` — direct construction is used so the entry point owns the `JsonRpc` channel.

---

## Related

- Depends on `FSharpLanguageServer`, `Utils.LspLogger`; this is the *standalone* `fsharp-languageserver` process (in contrast with the in-VS hosted server).