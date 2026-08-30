# Docs.md

## Pipeline role
In-depth design document for **parallel type-checking of independent files** in the F#
compiler. Shipped as a `Content` item in `FSharp.Compiler.Service.fsproj` and lives next to
the `GraphChecking` implementation (DependencyResolution.fs, GraphProcessing.fs,
TrieMapping.fs, FileContentMapping.fs, Types.fs). Implementation language: F#.

## Content summary
- Motivation: type-checking is often ~50% of wall-clock compile time (and an even larger
  fraction for IDE analysis) because files are type-checked sequentially in project order.
- Baseline: `allowed dependencies` (by file position) vs `necessary dependencies` (what
  actually influences results). A dependency graph anywhere between the two is sound; the
  closer to "necessary", the more parallelism is possible, and wall-clock time equals the
  longest path `D(G)=max(D(f))`.
- Two-phase precursor feature (parallel `.fs` backed by `.fsi`, PR #13737; ~17.49s ->
  14.28s Fantomas, 112s -> 92s F# build) — separate from the graph approach.
- **Graph-based approach**: (1) scan each file's AST in parallel to extract top-level
  modules/namespaces, opens, prefixed identifiers, nested modules; (2) build a global
  `Trie` of namespaces/modules remembering contributing file indices (signature-file-backed
  files contribute only their `.fsi`); (3) per file, query the Trie to add dependency edges
  to preceding files; files in the Trie `Root` are always matches.
- Edge cases discussed: `[<AutoOpen>]` handling (alias-scanning caveats, warning when
  `AutoOpenAttribute` is aliased, nested AutoOpen modules don't need checking), module
  abbreviations (no special handling needed), shared namespaces with no type definitions
  (add `ghost dependencies` to satisfy unnecessary `open` statements), numeric ordering of
  diagnostics via per-work-item loggers replayed in order.
- Server GC: parallel work needs Server GC to avoid single-threaded Workstation GC becoming
  a bottleneck (tables: 16.0s -> 2.7s with Server + Parallel on a synthetic solution).
- State maintenance: each file's type-check produces a delta function `'State -> 'State`;
  a file's input state is rebuilt from deltas of its dependencies.
- Performance data: BenchmarkDotNet table showing FSharpPlus 32.2s -> 30.9s and
  FSharp.Compiler.Service 18.6s -> 10.9s with `GraphTypeChecking=true`.

## Consumers
Developers implementing/evolving parallel type-checking in the compiler; references the
original proposal https://github.com/dotnet/fsharp/discussions/11634 by @kerams and PRs
#13521 (Server GC) and #13737 (fsi-backed parallelism).