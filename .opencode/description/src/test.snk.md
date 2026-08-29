# test.snk

## Pipeline role
A 596-byte strong-name key pair used to sign assemblies during test and local builds.

## Details
- Standard `.snk` (SNK — Strong Name Key) format: a binary blob containing the RSA public
  and private key parameters.
- The repo public key/hash for `test.snk` is a well-known F# tooling key. Because the
  private key ships in the repository, it is used only for **test** signing
  (`PublicSign`/delay-sign scenarios); shipping binaries are signed with the Microsoft key
  or are public-signed with the public key alone.
- Referenced from the build via `AssemblyOriginatorKeyFile` / `--keyfile`-style properties
  so that locally produced `FSharp.Compiler.Service.dll`, `fsc`, `fsi`, `FSharp.Core`,
  and test assemblies get a stable strong name, enabling friend-assembly
  (`InternalsVisibleTo`) links between debug binaries.
- Being a binary file it has no readable text content; its purpose is inferred from repo
  conventions for the `test.*` naming pattern (VS/mono convention for test-only SNKs).