# fsi.res

## Pipeline role
Prebuilt Win32 resource blob (60,552 bytes) compiled from `fsi.rc` with the Windows SDK
`rc.exe`. Binary asset — no readable text.

## Content
- ICON resource 1: `fsi.ico` (application icon).
- RT_MANIFEST resource (type 24, ID 1): `default.win32manifest` — asInvoker UAC manifest.

## How it is used
`fsi.targets` sets `<Win32Resource>$(MSBuildThisFileDirectory)fsi.res</Win32Resource>`, so
every fsi flavor (`fsi`, `fsiAnyCpu`, `fsiArm64`) embeds the icon and manifest directly
into the generated executable. Kept as a checked-in .res because producing it requires the
Windows SDK rc.exe; it is recompiled by updating `fsi.rc` and re-running rc.exe per the
comment in that file.