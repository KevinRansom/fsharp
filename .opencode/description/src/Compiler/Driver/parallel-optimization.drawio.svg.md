# parallel-optimization.drawio.svg

## Pipeline role
The embedded diagram in `Driver\parallel-optimization.md` (referenced via
`![Optimisation chart](parallel-optimization.drawio.svg)`).

## Content
- A 832x971 diagrams.net (draw.io) SVG, exported with `width/height/viewBox` and an
  `mxfile` payload inside the `content` attribute. The single-page diagram is named
  "Page-1" and was last edited with the `drawio-plugin` (drawio v20.5.3, 2023).
- It visualizes the pipeline rows described in the markdown: the **sequential** baseline
  (files compiled file-by-file, each running its up-to-7 optimization "phases"
  back-to-back) versus the **parallel** schedule where phase P of each file is launched as
  soon as all earlier files have produced their outputs for that phase, honoring the rule
  that phase P of file F never depends on phases P+1... of preceding files.
- Because this is an SVG/XML binary-ish asset, text content was not fully read; the
  drawing's meaning is inferred from the companion `parallel-optimization.md` and the
  upstream F# docs.

## Consumers
- Packaged as a `None` item in `FSharp.Compiler.Service.fsproj` and shipped/distributed
  alongside the compiler docs; the markdown links it for rendering.
- Do-not-edit-by-hand caveat: produced by diagrams.net.