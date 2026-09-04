# parallel-optimization.md

## Pipeline role
Short design note on the parallel optimization pipeline in the compiler driver. Referenced
as a doc asset from `FSharp.Compiler.Service.fsproj` (`Driver\parallel-optimization.md`).

## Content summary
- Problem: the optimization phase costs a large slice of standalone compilation time and
  normally runs fully sequentially, file-by-file.
- Key observation: per-file optimization decomposes into up to **7 distinct phases**, with
  the property that evaluating phase `P` of file `F` never depends on phases `P+1...` of
  any of the preceding files.
- That allowed-dependency structure enables a **pipelined / wave-parallel** schedule across
  files, depicted in `parallel-optimization.drawio.svg`: file B's early phases begin while
  file A is still finishing its later phases.
- Implementation lives in `Driver\OptimizeInputs.fs`; it is gated behind the experimental
  compiler flag `--test:ParallelOptimization`.

## Relevance
Explains the `--test:ParallelOptimization` switch wired through compiler option plumbing and
the accompanying diagram asset; part of the compiler's broader parallel-compilation work
(sibling document: `GraphChecking\Docs.md`).