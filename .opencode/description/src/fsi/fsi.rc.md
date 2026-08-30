# fsi.rc

## Pipeline role
Win32 resource script (RC) that bundles the icon and default application manifest into the
fsi Windows resource blob.

## Content
- `1 ICON "fsi.ico"` — embeds `fsi.ico` as ICON resource with ID 1.
- `1 24 "default.win32manifest"` — embeds `default.win32manifest` as RT_MANIFEST (type 24,
  XML) with ID 1.
- Header comment documents the build step:
  `rc.exe /i <path-with-default.win32manifest> /r fsi.rc` — producing `fsi.res`. The
  `/i` include path is needed only so the compiler can locate `default.win32manifest`.

## Output
`fsi.res` (compiled resource blob, 60,552 bytes) referenced by `fsi.targets` via
`Win32Resource`, giving `fsi.exe` its icon and same-invoker manifest.