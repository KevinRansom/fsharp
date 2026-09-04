# fsi.ico

## Pipeline role
Application icon for the F# Interactive executable, 59,508 bytes (multi-resolution ICO).

## How it is used
- Referenced by `fsi.rc` (`1 ICON "fsi.ico"`), which the Windows SDK `rc.exe` compiles into
  `fsi.res` (resource ID 1). `fsi.targets` sets `Win32Resource=fsi.res`, so the icon is
  embedded as the executable's application icon shown in Explorer/taskbar for `fsi.exe`.
- Conventionally the F#/FSharp Interactive square logo glyph in ICO packaging (16/24/32/48
  and larger sizes for scale). As a binary asset its content is inferred from naming and
  resource usage — no textual content.